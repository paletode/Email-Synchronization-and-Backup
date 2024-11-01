# Stage 1: Build environment for Imapsync
FROM debian:bookworm-slim AS build

# Set non-interactive environment for installations
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages for building Imapsync (only for the build stage)
RUN apt update && \
    apt install -y --no-install-recommends \
        git make gcc libc6-dev libssl-dev \
        zlib1g-dev libperl-dev ca-certificates && \
    update-ca-certificates && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Clone and build Imapsync
RUN git clone https://github.com/imapsync/imapsync.git /imapsync && \
    cd /imapsync && \
    make

# Stage 2: Build environment for Python and Apprise
FROM debian:bookworm-slim AS python-build

# Install only Python and Pip (no virtual environment)
RUN apt update && \
    apt install -y --no-install-recommends python3 python3-pip && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Apprise
RUN pip3 install --no-cache-dir apprise

# Stage 3: Minimal final image on Alpine
FROM alpine:latest

# Install necessary runtime packages
RUN apk add --no-cache \
    perl curl ca-certificates libintl \
    perl-authen-ntlm perl-io-socket-ssl perl-mail-imapclient \
    python3 py3-pip bash wget && \
    pip3 install --no-cache-dir --break-system-packages apprise

# Manually download and install cpanminus
RUN curl -L https://cpanmin.us -o /usr/local/bin/cpanm && \
    chmod +x /usr/local/bin/cpanm

# Temporarily install build tools and development headers for Perl modules
RUN apk add --no-cache --virtual .build-deps make gcc musl-dev perl-dev openssl-dev

# Install Perl modules in batches, including Sys::MemInfo
RUN cpanm --notest Encode::IMAPUTF7 File::Copy::Recursive && \
    cpanm --notest CGI Crypt::OpenSSL::RSA Data::Uniqid File::Tail && \
    cpanm --notest IO::Socket::INET6 IO::Tee HTML::Parser Parse::RecDescent && \
    cpanm --notest Module::ScanDeps Readonly Term::ReadKey Test::MockObject && \
    cpanm --notest Test::Pod Unicode::String URI LWP::UserAgent Regexp::Common && \
    cpanm --notest Test::NoWarnings Test::Deep Test::Warn Sys::MemInfo

# Remove build dependencies to reduce image size
RUN apk del .build-deps

# Copy Imapsync from the build stage
COPY --from=build /imapsync/imapsync /usr/local/bin/imapsync

# Copy sync.sh script and crontab configuration
COPY sync.sh /usr/local/bin/sync.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/sync.sh /usr/local/bin/entrypoint.sh

# Run the cron service in the foreground
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["crond", "-f"]
