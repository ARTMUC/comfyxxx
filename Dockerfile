ARG BASE_IMAGE=nvidia/cuda:12.6.3-cudnn-runtime-ubuntu24.04
FROM ${BASE_IMAGE} AS base
ARG COMFYUI_VERSION=latest
ARG CUDA_VERSION_FOR_COMFY
ARG ENABLE_PYTORCH_UPGRADE=false
ARG PYTORCH_INDEX_URL
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_PREFER_BINARY=1
ENV PYTHONUNBUFFERED=1
ENV CMAKE_BUILD_PARALLEL_LEVEL=8
ENV PIP_NO_INPUT=1

# --- system packages ---
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    git \
    wget \
    curl \
    unzip \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    ffmpeg \
    && ln -sf /usr/bin/python3.12 /usr/bin/python \
    && ln -sf /usr/bin/pip3 /usr/bin/pip \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# --- uv (virtualenv manager) ---
RUN wget -qO- https://astral.sh/uv/install.sh | sh \
    && ln -s /root/.local/bin/uv /usr/local/bin/uv \
    && ln -s /root/.local/bin/uvx /usr/local/bin/uvx \
    && uv venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

# --- install comfy-cli ---
RUN uv pip install comfy-cli pip setuptools wheel
# Force latest ComfyUI with explicit git clone
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui-git && \
    cp -r /comfyui-git/* /comfyui/ || true

RUN if [ "$ENABLE_PYTORCH_UPGRADE" = "true" ]; then \
      uv pip install --force-reinstall torch torchvision torchaudio --index-url ${PYTORCH_INDEX_URL}; \
    fi

WORKDIR /comfyui

# --- custom nodes ---
RUN mkdir -p custom_nodes && cd custom_nodes && \
    git clone https://github.com/city96/ComfyUI-GGUF.git && \
    git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git

# Install requirements for each custom node
RUN cd custom_nodes/ComfyUI-GGUF && if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi
RUN cd custom_nodes/ComfyUI-VideoHelperSuite && if [ -f requirements.txt ]; then uv pip install -r requirements.txt; fi

# --- extra config + deps ---
ADD src/extra_model_paths.yaml ./
WORKDIR /
RUN uv pip install runpod requests websocket-client
ADD src/start.sh handler.py test_input.json ./
RUN chmod +x /start.sh

COPY scripts/comfy-node-install.sh /usr/local/bin/comfy-node-install
RUN chmod +x /usr/local/bin/comfy-node-install
COPY scripts/comfy-manager-set-mode.sh /usr/local/bin/comfy-manager-set-mode
RUN chmod +x /usr/local/bin/comfy-manager-set-mode

# --- download models with CORRECT paths ---
WORKDIR /comfyui
RUN mkdir -p models/diffusion_models models/text_encoders models/clip_vision models/vae && \
    echo "📥 Downloading Diffusion Model..." && \
    curl -L -o models/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf \
      "https://comfyui-models-mirror-xxx.s3.eu-west-1.amazonaws.com/models/unet/wan2.1-i2v-14b-480p-Q8_0.gguf" && \
    echo "📥 Downloading Text Encoder..." && \
    curl -L -o models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors \
      "https://comfyui-models-mirror-xxx.s3.eu-west-1.amazonaws.com/models/clip/umt5_xxl_fp8_e4m3fn_scaled.safetensors" && \
    echo "📥 Downloading CLIP Vision..." && \
    curl -L -o models/clip_vision/clip_vision_h.safetensors \
      "https://comfyui-models-mirror-xxx.s3.eu-west-1.amazonaws.com/models/clip_vision/clip_vision_h.safetensors" && \
    echo "📥 Downloading VAE..." && \
    curl -L -o models/vae/wan_2.1_vae.safetensors \
      "https://comfyui-models-mirror-xxx.s3.eu-west-1.amazonaws.com/models/vae/wan_2.1_vae.safetensors"

# --- final health check ---
RUN echo "🔍 Verifying model files..." && \
    ls -lh models/diffusion_models/wan2.1-i2v-14b-480p-Q8_0.gguf && \
    ls -lh models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors && \
    ls -lh models/clip_vision/clip_vision_h.safetensors && \
    ls -lh models/vae/wan_2.1_vae.safetensors

CMD ["/start.sh"]
