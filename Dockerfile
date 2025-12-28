FROM ubuntu:22.04

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    git \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:$PATH"

# Install OpenSSL development libraries
RUN apt-get update && apt-get install -y \
    libssl-dev \
    zlib1g-dev \
    libzstd-dev \
    libbrotli-dev \
    && rm -rf /var/lib/apt/lists/*

# Build OpenSSL with MLKEM support
RUN apt-get update && apt-get install -y \
    perl \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
    wget https://github.com/openssl/openssl/archive/refs/tags/openssl-3.6.0.tar.gz && \
    tar xzf openssl-3.6.0.tar.gz && \
    cd openssl-openssl-3.6.0 && \
    ./config --prefix=/usr/local/ssl --openssldir=/usr/local/ssl enable-ml-kem && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf /tmp/openssl-*

ENV PATH="/usr/local/ssl/bin:$PATH"
ENV LD_LIBRARY_PATH="/usr/local/ssl/lib:$LD_LIBRARY_PATH"
ENV OPENSSL_CONF="/usr/local/ssl/openssl.cnf"

WORKDIR /app