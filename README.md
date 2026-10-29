# docker-diffSynth-studio


一个面向 GPU 的 [DiffSynth-Studio](https://github.com/modelscope/DiffSynth-Studio) Docker 封装。

本仓库不直接包含 DiffSynth-Studio 源码。构建镜像时，`Dockerfile` 会从上游 GitHub 仓库拉取源码，安装训练相关依赖，并将容器默认工作目录设置为 `/opt/DiffSynth-Studio`。

## 功能概览

| 项目 | 配置 |
| --- | --- |
| 基础镜像 | `pytorch/pytorch:2.7.1-cuda12.8-cudnn9-devel` |
| CUDA / cuDNN | CUDA 12.8 / cuDNN 9 |
| 上游项目 | `modelscope/DiffSynth-Studio` |
| 安装方式 | editable 安装：`DiffSynth-Studio[training]` |
| 自定义算子 | 通过 `DS_BUILD_OPS=0` 关闭构建 |
| 容器工作目录 | `/opt/DiffSynth-Studio` |
| 默认启动命令 | `/bin/bash` |

## 环境要求

- Docker Engine 或 Docker Desktop。
- 可用的 NVIDIA GPU、兼容 CUDA 12.8 的 NVIDIA 驱动，以及 NVIDIA Container Toolkit。
- Windows 用户需要在 Docker Desktop 中启用 WSL2 GPU 支持。
- 首次构建需要访问 GitHub 和 Python 包索引，并会下载较大的 PyTorch、DiffSynth-Studio 及训练依赖。

当前仓库只提供 CUDA GPU 镜像，没有可直接使用的 CPU Dockerfile。

## 快速开始

### 1. 构建镜像

在本仓库根目录执行：

```bash
docker build --progress=plain -t diffsynth-studio:gpu .
```

### 2. 启动容器

下面的命令会将当前目录挂载到容器中的 `/workspace`，方便访问本地脚本、数据和输出文件：

```bash
docker run --gpus all --rm -it --ipc=host -v "${PWD}:/workspace" -w /workspace diffsynth-studio:gpu
```

进入容器后，可以按照上游项目文档运行训练或推理脚本：

```bash
cd /opt/DiffSynth-Studio
```

上游使用说明和示例请参阅 [DiffSynth-Studio 文档](https://github.com/modelscope/DiffSynth-Studio)。

### 3. 检查 CUDA 和 PyTorch

```bash
docker run --gpus all --rm diffsynth-studio:gpu python -c "import torch; print('PyTorch:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print('CUDA version:', torch.version.cuda)"
```

`CUDA available` 预期为 `True`。如果使用 Docker Desktop，请先确认宿主机和 Docker 已正确启用 GPU 支持。

## 已配置的镜像标签

GitHub Actions 工作流配置为向 Docker Hub 的 `lianshufeng/diffsynth-studio` 仓库推送以下标签：

```bash
docker pull lianshufeng/diffsynth-studio:gpu
docker pull lianshufeng/diffsynth-studio:latest
```

当前 `latest` 和 `gpu` 都使用同一个 GPU `Dockerfile` 构建。只有在对应标签已经发布到 Docker Hub 后，才能直接执行 `docker pull`。

## Dockerfile 做了什么

构建过程主要包含以下步骤：

1. 使用带 CUDA 12.8 和 cuDNN 9 的 PyTorch 开发镜像。
2. 安装 `git`、编译工具、`ninja`、`ffmpeg`、OpenGL 和 GLib 运行库。
3. 将上游 DiffSynth-Studio 克隆到 `/opt/DiffSynth-Studio`。
4. 使用 `DS_BUILD_OPS=0` 和 `[training]` extra 安装上游项目及训练依赖。
5. 执行 `python -m pip check` 检查 Python 依赖关系。
6. 将 `/opt/DiffSynth-Studio` 设置为工作目录，并默认进入 Bash。

构建时未固定上游仓库的提交版本，因此重新构建可能会获得上游默认分支的新代码或新依赖版本。需要可复现构建时，建议在 `Dockerfile` 中固定上游提交或版本标签。

## 自动化流程

### GitHub Actions

`.github/workflows/docker-image.yml` 使用 `workflow_dispatch` 手动触发，并向 Docker Hub 推送 `latest` 和 `gpu` 标签。运行该工作流需要在 GitHub 仓库中配置以下 Secrets：

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

工作流中的 CPU 镜像步骤目前处于注释状态，且仓库中没有对应的 CPU Dockerfile。

### CNB 镜像同步

`.github/workflows/mirror_CNB.yml` 会在任意分支推送时，将 Git 仓库镜像到 `cnb.cool/vvllm/diffsynth-studio`。该流程需要配置：

- `CNB_USERNAME`
- `CNB_TOKEN`

`.cnb.yml` 还配置了 CNB 上的 Docker 构建与推送任务。

> **CNB 配置注意事项：** 当前 `.cnb.yml` 使用了 `-f .Dockerfile`，而仓库实际文件名是 `Dockerfile`。启用 CNB 构建前，请将其改为 `-f ./Dockerfile`。

## 项目结构

```text
.
├── Dockerfile                         # GPU 镜像定义
├── .cnb.yml                           # CNB 构建与推送配置
└── .github/
    └── workflows/
        ├── docker-image.yml           # 手动构建并推送 Docker Hub 镜像
        └── mirror_CNB.yml             # 推送 Git 镜像到 CNB
```

## 上游项目与许可

- 上游项目：[modelscope/DiffSynth-Studio](https://github.com/modelscope/DiffSynth-Studio)
- 本仓库当前未包含单独的 `LICENSE` 文件。使用、修改和分发前，请同时确认上游项目及其依赖的许可证要求。

