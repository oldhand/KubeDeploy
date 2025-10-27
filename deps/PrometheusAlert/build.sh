#!/bin/bash

#######################################
# 第一步：检查并准备 Docker 镜像（本地SWR→本地缓存→拉取SWR远程）
#######################################

echo "===== 第一步：检查并准备 Docker 镜像 ====="
SWR_ALPINE_IMAGE="swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/library/alpine:3.18"
SWR_GOLANG_IMAGE="swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/golang:1.20.6-alpine3.18"
ALPINE_TAR="images/alpine_3.18.tar.gz"
GOLANG_ALPINE_TAR="images/golang_1.20.6-alpine3.18.tar.gz"

echo "确认Docker服务运行中..."
if ! docker info &> /dev/null; then
    echo "错误：Docker服务未运行，请启动（如：sudo systemctl start docker）"
    exit 1
fi

if [ ! -d "images" ]; then
    mkdir -p images || { echo "错误：创建images目录失败"; exit 1; }
fi

ALPINE_READY="false"
GOLANG_READY="false"

if docker inspect "$SWR_ALPINE_IMAGE" &> /dev/null; then
    echo "✅ 本地已存在SWR镜像：$SWR_ALPINE_IMAGE"
    ALPINE_READY="true"
else
    echo "❌ 本地未找到SWR镜像：$SWR_ALPINE_IMAGE"
fi

if docker inspect "$SWR_GOLANG_IMAGE" &> /dev/null; then
    echo "✅ 本地已存在SWR镜像：$SWR_GOLANG_IMAGE"
    GOLANG_READY="true"
else
    echo "❌ 本地未找到SWR镜像：$SWR_GOLANG_IMAGE"
fi

if [ "$ALPINE_READY" = "false" ]; then
    if [ -f "$ALPINE_TAR" ]; then
        echo "使用本地缓存tar包：$ALPINE_TAR"
        if ! tar -xzf "$ALPINE_TAR" -C images/; then
            echo "错误：解压$ALPINE_TAR失败"
            exit 1
        fi
        ALPINE_IMAGE="images/alpine_3.18.tar"
        if ! docker load -i "$ALPINE_IMAGE"; then
            echo "错误：加载$ALPINE_IMAGE失败"
            exit 1
        fi
        ALPINE_READY="true"
    else
        echo "从SWR远程拉取：$SWR_ALPINE_IMAGE"
        if ! docker pull "$SWR_ALPINE_IMAGE"; then
            echo "错误：拉取$SWR_ALPINE_IMAGE失败"
            exit 1
        fi
        ALPINE_READY="true"
    fi
fi

if [ "$GOLANG_READY" = "false" ]; then
    if [ -f "$GOLANG_ALPINE_TAR" ]; then
        echo "使用本地缓存tar包：$GOLANG_ALPINE_TAR"
        if ! tar -xzf "$GOLANG_ALPINE_TAR" -C images/; then
            echo "错误：解压$GOLANG_ALPINE_TAR失败"
            exit 1
        fi
        GOLANG_IMAGE="images/golang_1.20.6-alpine3.18.tar"
        if ! docker load -i "$GOLANG_IMAGE"; then
            echo "错误：加载$GOLANG_IMAGE失败"
            exit 1
        fi
        GOLANG_READY="true"
    else
        echo "从SWR远程拉取：$SWR_GOLANG_IMAGE"
        if ! docker pull "$SWR_GOLANG_IMAGE"; then
            echo "错误：拉取$SWR_GOLANG_IMAGE失败"
            exit 1
        fi
        GOLANG_READY="true"
    fi
fi

echo "Docker镜像准备完成"


#######################################
# 第二步：安装 Go 1.24.0（本地缓存机制）
#######################################

echo -e "\n===== 第二步：安装 Go 1.24.0 ====="
GO_VERSION="1.24.0"
GO_ARCH="amd64"
GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
GO_URL="https://dl.google.com/go/${GO_TAR}"
ALTERNATE_URL="https://mirrors.aliyun.com/golang/${GO_TAR}"
INSTALL_DIR="/usr/local"

if command -v go &> /dev/null; then
    installed_version=$(go version | awk '{print $3}' | sed 's/go//')
    echo "检测到已安装Go版本: $installed_version"
    if [[ $installed_version == 1.24.* ]]; then
        echo "已安装所需的Go 1.24版本，跳过安装"
    else
        read -p "当前Go版本非1.24.x，是否继续安装？(y/N) " response
        if [[ $response != [Yy]* ]]; then
            echo "跳过Go安装"
        else
            rm -rf "${INSTALL_DIR}/go"
            if [ ! -f "./${GO_TAR}" ]; then
                echo "下载Go ${GO_VERSION}..."
                if ! wget -O "./${GO_TAR}" "${GO_URL}"; then
                    echo "官方地址失败，尝试镜像..."
                    if ! wget -O "./${GO_TAR}" "${ALTERNATE_URL}"; then
                        echo "镜像下载失败，请手动下载后重试"
                        exit 1
                    fi
                fi
            else
                echo "使用本地缓存：${GO_TAR}"
            fi
            if ! tar -C "${INSTALL_DIR}" -xzf "./${GO_TAR}"; then
                echo "解压失败，可能文件损坏"
                exit 1
            fi
        fi
    fi
else
    echo "未检测到Go，开始安装..."
    rm -rf "${INSTALL_DIR}/go"
    if [ ! -f "./${GO_TAR}" ]; then
        echo "下载Go ${GO_VERSION}..."
        if ! wget -O "./${GO_TAR}" "${GO_URL}"; then
            echo "官方地址失败，尝试镜像..."
            if ! wget -O "./${GO_TAR}" "${ALTERNATE_URL}"; then
                echo "镜像下载失败，请手动下载后重试"
                exit 1
            fi
        fi
    else
        echo "使用本地缓存：${GO_TAR}"
    fi
    if ! tar -C "${INSTALL_DIR}" -xzf "./${GO_TAR}"; then
        echo "解压失败，可能文件损坏"
        exit 1
    fi
fi

if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo ~${SUDO_USER})
else
    USER_HOME=$HOME
fi
ENV_FILE="${USER_HOME}/.bashrc"
if [ -f "${USER_HOME}/.zshrc" ]; then
    ENV_FILE="${USER_HOME}/.zshrc"
fi
if ! grep -q "export GOROOT=${INSTALL_DIR}/go" "${ENV_FILE}"; then
    cat << EOF >> "${ENV_FILE}"
# Go环境变量
export GOROOT=${INSTALL_DIR}/go
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin
EOF
fi
export GOROOT="${INSTALL_DIR}/go"
export PATH="$PATH:${GOROOT}/bin"

if command -v go &> /dev/null && go version | grep -q "go${GO_VERSION}"; then
    go version
    echo "Go环境准备完成"
else
    echo "错误：Go安装验证失败"
    exit 1
fi


#######################################
# 第三步：本地编译（make clean + make build）
#######################################

echo -e "\n===== 第三步：本地编译 ====="
if [ ! -f "Makefile" ]; then
    echo "错误：未找到Makefile"
    exit 1
fi
if ! command -v make &> /dev/null; then
    echo "未安装make，尝试自动安装..."
    if command -v apt &> /dev/null; then
        apt install -y make || { echo "apt安装make失败"; exit 1; }
    elif command -v yum &> /dev/null; then
        yum install -y make || { echo "yum安装make失败"; exit 1; }
    else
        echo "请手动安装make后重试"
        exit 1
    fi
fi

echo "执行make clean..."
if ! make clean; then
    echo "警告：make clean失败，尝试继续..."
fi

echo "执行make build..."
if ! make build; then
    echo "错误：make build失败"
    exit 1
fi
echo "本地编译完成"


#######################################
# 第四步：执行make docker打包镜像
#######################################

echo -e "\n===== 第四步：打包Docker镜像 ====="
if ! docker info &> /dev/null; then
    echo "错误：Docker服务已停止"
    exit 1
fi
if [ ! -f "Makefile" ]; then
    echo "错误：未找到Makefile"
    exit 1
fi

echo "执行make docker..."
if ! make docker; then
    echo "错误：make docker失败"
    exit 1
fi
echo "镜像打包完成，可通过docker images查看"


#######################################
# 第五步：创建目录并保存压缩Docker镜像（优化路径格式）
#######################################

echo -e "\n===== 第五步：保存并压缩镜像 ====="
TARGET_DIR="../../images/alert/x86_64"
IMAGE_NAME="feiyu563/prometheus-alert:v4.9.1"
ALERT_TAR_FILE="prometheus-alert_v4.9.1.tar"
TAR_FILE="${TARGET_DIR}/${ALERT_TAR_FILE}"
TAR_GZ_FILE="${ALERT_TAR_FILE}.gz"

# 1. 创建目标目录
echo "创建目录：${TARGET_DIR}"
if ! mkdir -p "${TARGET_DIR}"; then
    echo "错误：创建目录${TARGET_DIR}失败（检查路径权限）"
    exit 1
fi

# 2. 检查目标镜像是否存在
echo "检查镜像${IMAGE_NAME}是否存在..."
if ! docker inspect "${IMAGE_NAME}" &> /dev/null; then
    echo "错误：未找到镜像${IMAGE_NAME}，无法执行docker save"
    exit 1
fi

# 3. 保存镜像为tar文件
echo "保存镜像到${TAR_FILE}..."
if ! docker save "${IMAGE_NAME}" -o "${TAR_FILE}"; then
    echo "错误：docker save失败（检查路径写入权限）"
    exit 1
fi

echo "压缩为${ALERT_TAR_FILE}..."
if ! (cd "${TARGET_DIR}" && tar czvf "${TAR_GZ_FILE}" "${ALERT_TAR_FILE}"); then
    echo "错误：tar压缩失败（检查文件是否存在）"
    exit 1
fi

echo "全流程执行完成！"
