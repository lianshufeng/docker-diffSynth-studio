FROM pytorch/pytorch:2.7.1-cuda12.8-cudnn9-devel

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        build-essential \
        ninja-build \
        ffmpeg \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/modelscope/DiffSynth-Studio.git \
        /opt/DiffSynth-Studio \
    && DS_BUILD_OPS=0 python -m pip install \
        -e "/opt/DiffSynth-Studio[training]" \
    && python -m pip check

WORKDIR /opt/DiffSynth-Studio

CMD ["/bin/bash"]