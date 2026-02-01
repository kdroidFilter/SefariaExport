FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Set timezone
ARG TZ_NAME=Asia/Jerusalem
ENV TZ=${TZ_NAME}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install Python 3.9 and basic tools
RUN apt-get update && apt-get install -y \
    python3.9 \
    python3.9-dev \
    python3-pip \
    git \
    curl \
    wget \
    software-properties-common \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.9 as default
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1

# Environment variables
ENV DJANGO_SETTINGS_MODULE=sefaria.settings
ENV MONGO_HOST=mongodb
ENV MONGO_PORT=27017
ENV MONGO_DB_NAME=sefaria
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PYTHONUNBUFFERED=1

# Create workspace
WORKDIR /workspace

# Copy all scripts and files
COPY . /workspace/

# Make all shell scripts executable
RUN find /workspace -name "*.sh" -type f -exec chmod +x {} \;

# Entry point script
CMD ["/bin/bash", "-c", "/workspace/run_workflow.sh"]
