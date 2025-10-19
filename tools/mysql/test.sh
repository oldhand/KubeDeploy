#!/bin/bash
set -e

# 定义变量
MYSQL_IMAGE="swr.cn-north-4.myhuaweicloud.com/ddn-k8s/docker.io/mysql:5.7.44"
LOCAL_IMAGE_TAR="mysql_5.7.44.tar"  # 临时tar文件
ZIP_VOLUME_SIZE="99m"  # 每卷大小99MB
MYSQL_USER="root"
MYSQL_PASSWORD="b57e6fb1e65c175e"
DATA_DIR="/data/mysql"
EXTERNAL_PORT=30306
INTERNAL_PORT=3306
DEPLOYMENT_NAME="mysql-single"
SERVICE_NAME="mysql-service"

# 清理Kubernetes资源（不碰本地缓存）
cleanup_resources() {
  echo "===== 开始清理现有MySQL相关Kubernetes资源 ====="
  if kubectl get deployment "$DEPLOYMENT_NAME" &>/dev/null; then
    kubectl delete deployment "$DEPLOYMENT_NAME"
    echo "已删除Deployment: $DEPLOYMENT_NAME"
  else
    echo "Deployment $DEPLOYMENT_NAME 不存在，无需删除"
  fi

  if kubectl get service "$SERVICE_NAME" &>/dev/null; then
    kubectl delete service "$SERVICE_NAME"
    echo "已删除Service: $SERVICE_NAME"
  else
    echo "Service $SERVICE_NAME 不存在，无需删除"
  fi

  echo "等待Kubernetes资源清理完成..."
  sleep 5
  echo "===== Kubernetes资源清理完成 ====="
}

# 执行Kubernetes资源清理
cleanup_resources

# 镜像处理逻辑
echo "===== 开始处理MySQL镜像 ====="

# 检查本地是否已有镜像
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${MYSQL_IMAGE}$"; then
  echo "本地已存在目标镜像，无需加载缓存或拉取"
else
  echo "本地无目标镜像，尝试加载本地缓存..."
  cat mysql_5.7.44.tar.zip.001 mysql_5.7.44.tar.zip.002 > mysql_5.7.44.tar.zip
  unzip -q -o mysql_5.7.44.tar.zip -d $PWD/
  rm -f mysql_5.7.44.tar.zip
  # 加载解压后的tar镜像
  if [ -f "$LOCAL_IMAGE_TAR" ]; then
    echo "从tar文件加载镜像..."
    docker load -i "$LOCAL_IMAGE_TAR" || {
      echo "镜像加载失败，缓存可能损坏"
    }
    rm -f "$LOCAL_IMAGE_TAR"
  fi
fi

# 数据目录处理
echo "===== 检查数据目录 ====="
if [ ! -d "$DATA_DIR" ]; then
  echo "创建数据目录: $DATA_DIR"
  sudo mkdir -p "$DATA_DIR"
  sudo chmod 777 "$DATA_DIR"
else
  echo "数据目录 $DATA_DIR 已存在，无需创建"
fi

# 部署到Kubernetes
echo "===== 开始部署MySQL到Kubernetes ====="
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOYMENT_NAME
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      tolerations:
      - key: "node-role.kubernetes.io/control-plane"
        operator: "Exists"
        effect: "NoSchedule"
      containers:
      - name: mysql
        image: $MYSQL_IMAGE
        ports:
        - containerPort: $INTERNAL_PORT
        env:
        - name: MYSQL_ROOT_USER
          value: "$MYSQL_USER"
        - name: MYSQL_ROOT_PASSWORD
          value: "$MYSQL_PASSWORD"
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
        livenessProbe:
          exec:
            command: ["mysqladmin", "ping", "-u$MYSQL_USER", "-p$MYSQL_PASSWORD"]
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command: ["mysqladmin", "ping", "-u$MYSQL_USER", "-p$MYSQL_PASSWORD"]
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: mysql-data
        hostPath:
          path: $DATA_DIR
          type: DirectoryOrCreate
---
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE_NAME
spec:
  selector:
    app: mysql
  type: NodePort
  ports:
  - port: $INTERNAL_PORT
    targetPort: $INTERNAL_PORT
    nodePort: $EXTERNAL_PORT
EOF

# 等待部署完成
echo "===== 等待MySQL部署就绪（最长等待5分钟） ====="
kubectl wait --for=condition=available deployment/$DEPLOYMENT_NAME --timeout=300s

echo "===== MySQL部署完成！ ====="
echo "访问信息:"
echo "外部端口: $EXTERNAL_PORT"
echo "用户名: $MYSQL_USER"
echo "密码: $MYSQL_PASSWORD"
echo "数据目录: $DATA_DIR"
echo "连接示例: mysql -h <k8s-node-ip> -P $EXTERNAL_PORT -u$MYSQL_USER -p$MYSQL_PASSWORD"
