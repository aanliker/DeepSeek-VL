FROM nvidia/cuda:11.4.3-runtime-ubuntu20.04

ARG DEFAULT_PATH=/opt/ml/code

SHELL ["/bin/bash", "--login", "-c"]

# To avoid tzdata asking for geographic location...
ARG DEBIAN_FRONTEND=noninteractive
ENV DEBIAN_frontend noninteractive

# Install dependencies
RUN apt-get -y update && apt-get install -y \
    python3-tk \
    vulkan-tools \
    git \ 
    python3-pip \
    libxcursor-dev \
    libxrandr-dev \
    libxinerama-dev \
    libxi-dev \
    mesa-common-dev \
    vulkan-utils \
    mesa-vulkan-drivers \
    libegl1 && \
    rm -rf /var/lib/apt/lists/*

# Git clone and install VLLM (deepseek-ai/DeepSeek-VL)
RUN mkdir -p ${DEFAULT_PATH}/

COPY DeepSeek-VL/ ${DEFAULT_PATH}/DeepSeek-VL

RUN cd ${DEFAULT_PATH}/DeepSeek-VL && \
    pip3 install -r requirements.txt && \
    pip3 install -e .

RUN pip3 install --upgrade torch torchvision

RUN apt purge -y git && apt clean -y && apt autoremove -y

# Copy images into image folder
# RUN mkdir -p ${DEFAULT_PATH}/DeepSeek-VL/images
# COPY images/* ${DEFAULT_PATH}/DeepSeek-VL/images/

# Python logging should alway go to console immediately
ENV PYTHONUNBUFFERED=1

WORKDIR ${DEFAULT_PATH}/DeepSeek-VL

# This will be overwritten for local training to "/home/ascento/gym/docker/entrypoint.sh"
# as it needs arguments which are not possible to be passed in sh -c
ENTRYPOINT ["sh", "-c", "python3 /opt/ml/code/DeepSeek-VL/inference.py"]
