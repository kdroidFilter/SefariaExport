FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jerusalem
ENV DJANGO_SETTINGS_MODULE=sefaria.settings
ENV MONGO_HOST=mongodb
ENV MONGO_PORT=27017
ENV MONGO_DB_NAME=sefaria
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Install base system dependencies and add deadsnakes PPA for Python 3.9
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    gpg-agent \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update -y && \
    apt-get install -y --no-install-recommends \
    aria2 \
    ca-certificates \
    tar \
    zstd \
    wget \
    netcat-openbsd \
    git \
    curl \
    jq \
    unzip \
    python3.9 \
    python3.9-venv \
    python3.9-dev \
    python3.9-distutils \
    libre2-dev \
    pybind11-dev \
    build-essential \
    cmake \
    ninja-build \
    libpq-dev \
    sudo \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.9 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Make python3.9 the default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1

# Install MongoDB Database Tools (detect architecture)
ENV TOOLS_VER=100.9.4
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "arm64" ]; then \
        MONGO_ARCH="arm64"; \
    else \
        MONGO_ARCH="x86_64"; \
    fi && \
    wget -q "https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2204-${MONGO_ARCH}-${TOOLS_VER}.tgz" && \
    tar -xzf "mongodb-database-tools-ubuntu2204-${MONGO_ARCH}-${TOOLS_VER}.tgz" && \
    mv mongodb-database-tools-ubuntu2204-${MONGO_ARCH}-${TOOLS_VER}/bin/* /usr/local/bin/ && \
    rm -rf mongodb-database-tools-ubuntu2204-${MONGO_ARCH}-${TOOLS_VER}*

# Install GitHub CLI (optional, for releases)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy all scripts and Python files
COPY *.sh *.py ./

# Make all scripts executable
RUN chmod +x *.sh

# Create exports and output directories
RUN mkdir -p /app/exports /app/output
ENV SEFARIA_EXPORT_PATH=/app/exports

# Copy entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
