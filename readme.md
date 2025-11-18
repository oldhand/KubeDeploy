# KubeDeploy 部署指南

## 项目概述

KubeDeploy 是面向 Kubernetes 集群的一站式基础设施部署项目，核心聚焦两大核心能力：



1. **分布式存储部署**：基于 Rook 实现高可用、可扩展的 Ceph 存储服务，提供块存储（RBD）、文件系统（CephFS）、对象存储及 NFS 等多样化方案，满足集群应用的存储资源需求；

2. **全栈监控体系搭建**：通过 Prometheus 构建完整可观测性体系，结合多类探针采集全维度指标，搭配 Grafana 可视化与 Alertmanager 告警能力，实现集群、容器、应用的全方位监控。

项目通过自动化部署脚本，大幅简化基础设施搭建流程，降低 Kubernetes 运维复杂度。

## 核心组件说明



| 组件           | 功能描述                                                    |
| ------------ | ------------------------------------------------------- |
| Ceph         | 分布式存储系统，支持 RBD、CephFS、对象存储及 NFS 服务，具备高可用、可扩展特性          |
| Prometheus   | 开源监控引擎，负责指标采集、时序存储与告警规则评估，是监控体系核心                       |
| Grafana      | 数据可视化平台，提供丰富预置仪表盘与自定义报表能力，支持指标探索                        |
| Alertmanager | 告警管理组件，处理 Prometheus 触发的告警，实现去重、分组、路由与多渠道通知             |
| 监控探针         | 含 node-exporter、kube-state-metrics、cAdvisor 等，覆盖多维度指标采集 |

## 前置要求



1. **Kubernetes 集群**：最低版本 `v1.29.0+`，确保集群状态正常（可通过 `kubectl get nodes` 验证）；

2. **工具依赖**：Helm `v3.0.0+`（用于组件部署）、Ansible（用于执行自动化部署脚本）；

3. **存储配置**：部署 Ceph 需提前为节点准备存储设备或目录；

4. **GPU 依赖**：如需启用 GPU 监控，节点需安装 NVIDIA 驱动与 `nvidia-smi` 工具。

## 角色功能说明

### 1. ceph 角色



* 基于 Rook 自动化部署 Ceph 存储集群，支持**设备模式**与**目录模式**两种存储配置；

* 管理 Ceph 相关 Kubernetes 资源：命名空间、RBAC 权限、存储类等，确保资源隔离与安全访问；

* 自动化提供块存储、文件系统、对象存储及 NFS 服务，满足不同应用场景需求；

* 集成 Ceph Toolbox 工具箱，支持集群状态查看、故障排查等运维操作；

* 配置 Prometheus 监控所需 RBAC 权限，实现存储指标的无缝采集。

### 2. prometheus 角色



* 部署 Prometheus 服务器及配套组件（如 PushGateway，可选），构建监控核心；

* 配置完整的 RBAC 权限体系，确保指标采集、数据访问的安全性；

* 集成多类监控探针，实现基础设施、容器、数据库、进程、GPU 的全维度指标采集；

* 部署 Grafana 并预置多类监控仪表盘，支持即开即用的可视化能力；

* 配置 Alertmanager，实现告警聚合、路由与多渠道通知，提升故障响应效率。

## 部署步骤

### 1. 环境准备



* 确认 Kubernetes 集群满足前置要求，所有节点状态为 `Ready`；

* 配置 Ceph 存储节点信息：修改 `roles/ceph/vars/main.yml`（参考【核心配置说明】），指定存储设备或目录。

### 2. 获取项目代码

克隆或下载 KubeDeploy 项目代码到本地控制机（需确保控制机可访问 Kubernetes 集群与 Ansible 清单中的节点）。

### 3. 执行部署

在项目根目录运行以下命令，基于 Ansible 清单启动自动化部署：



```
 格式：ansible-playbook -i \[Ansible清单文件] install.yml

ansible-playbook -i inventory install.yml
```



* `inventory`：需替换为实际的 Ansible 清单文件，文件中需包含 Kubernetes 集群节点的 IP、SSH 账号等信息。

## 核心配置说明

### Ceph 集群配置（roles/ceph/vars/main.yml）



```
 Ceph 集群基础信息

ceph\_cluster\_name: "rook-ceph"  # 集群名称，建议保持默认

ceph\_namespace: "rook-ceph"      # 部署命名空间，建议保持默认

 存储节点配置（二选一：设备模式/目录模式）

 1. 设备模式（适用于物理机或虚拟机挂载的独立存储设备）

 ceph\_nodes:

   - name: "k8s-node-1"        # 节点名称（需与 Kubernetes 节点名一致）

     devices: \["sdb"]          # 存储设备路径（如 /dev/sdb，需提前格式化）

   - name: "k8s-node-2"

     devices: \["sdb"]

 2. 目录模式（适用于本地目录作为存储，示例）

ceph\_nodes:

 - name: "oe2203m01"           # 节点名称

   devices:

     - "nvme2n1p3"             # 本地存储目录路径（如 /mnt/nvme2n1p3）

     - "nvme2n1p4"
```

## Prometheus 监控体系详解

### 1. 探针集成说明

#### （1）基础设施监控探针



| 探针名称               | 部署方式       | 监控范围                              | 采集路径       | 端口   |
| ------------------ | ---------- | --------------------------------- | ---------- | ---- |
| node-exporter      | DaemonSet  | 节点 CPU / 内存 / 磁盘 / 网络等基础指标        | `/metrics` | 9100 |
| kube-state-metrics | Deployment | Kubernetes 对象状态（Pod/Deployment 等） | `/metrics` | 8080 |



* **node-exporter**：关键指标包括节点负载（`node_load1`）、文件系统使用率（`node_filesystem_usage_bytes`）、网络吞吐量（`node_network_transmit_bytes_total`）等；

* **kube-state-metrics**：关键指标包括 Pod 运行状态（`kube_pod_status_phase`）、Deployment 副本数（`kube_deployment_status_replicas_ready`）、Service 端点状态（`kube_service_status_load_balancer_ingress_count`）等。

#### （2）容器监控探针



* **cAdvisor**：kubelet 内置组件，无需单独部署；


* 监控范围：容器 CPU / 内存 / 磁盘 / 网络使用率、启动时间、镜像大小、文件系统读写速率等；

* 采集路径：`/metrics/cadvisor`（通过 kubelet 暴露）；

* 端口：10250（kubelet 默认端口）；

* 特点：与 kube-state-metrics 联动，可通过 Pod 标签关联容器与业务维度。

#### （3）数据库监控探针（mysql-exporter）



* 部署方式：需单独配置（可通过 Helm 或项目脚本部署）；

* 监控范围：MySQL 连接数（`mysql_connections`）、查询吞吐量（`mysql_queries_total`）、表空间使用率（`mysql_innodb_data_fsyncs_total`）、慢查询数（`mysql_slow_queries_total`）等；

* 配置要求：需通过环境变量 `DATA_SOURCE_NAME` 指定数据库连接信息（格式：`user:password@(host:port)/`），建议通过 Kubernetes Secret 存储认证信息；

* 采集路径：`/metrics`；

* 端口：9104。

#### （4）进程监控探针（process-exporter）



* 部署方式：需单独配置；

* 监控范围：指定进程的 CPU / 内存使用率、文件描述符数（`process_open_fds`）、线程数（`process_threads`）、存活状态（`process_up`）等；

* 配置方式：通过 `process_names` 定义进程匹配规则（支持正则），示例：



```
process\_names:

 \- name: "redis"    # 进程别名，用于仪表盘展示

   cmdline: \[".+redis-server"]  # 进程命令行匹配规则

 \- name: "nginx"

   cmdline: \[".+nginx"]
```



* 采集路径：`/metrics`；

* 端口：9256。

#### （5）GPU 监控探针（gpu-exporter）



* 部署方式：通过 DaemonSet 部署在 GPU 节点（需配置节点亲和性 `nodeSelector: ``nvidia.com/gpu.present:`` "true"`）；

* 监控范围：GPU 使用率（`nvidia_smi_gpu_utilization`）、显存使用率（`nvidia_smi_memory_used_percent`）、温度（`nvidia_smi_gpu_temperature`）、功耗（`nvidia_smi_gpu_power_usage`）、进程占用情况等；

* 依赖：节点需安装 NVIDIA 驱动与 `nvidia-smi`，确保可查询 GPU 状态；

* 采集路径：`/metrics`；

* 端口：9445。

### 2. Grafana 仪表盘清单

#### （1）基础设施与 Kubernetes 监控



| 仪表盘名称                         | ID    | 监控范围                    |
| ----------------------------- | ----- | ----------------------- |
| Node Exporter Full            | 1860  | 节点全维度监控（CPU / 内存 / 磁盘等） |
| Kubernetes Cluster Monitoring | 7249  | 集群整体状态（节点 / Pod / 资源）   |
| Kubernetes Pod Monitoring     | 6417  | Pod 细粒度监控（资源 / 重启等）     |
| cAdvisor Metrics              | 14282 | 容器全景监控（资源 / I/O 等）      |

#### （2）数据库与专项监控



| 仪表盘名称                      | ID    | 监控范围                  |
| -------------------------- | ----- | --------------------- |
| MySQL Overview             | 7362  | MySQL 全局状态（连接 / 存储等）  |
| MySQL Performance          | 12633 | MySQL 性能（慢查询 / 索引等）   |
| Process Exporter Dashboard | 4202  | 进程资源监控（CPU / 内存等）     |
| NVIDIA GPU Monitoring      | 12239 | GPU 集群资源监控（使用率 / 显存等） |

##### 仪表盘访问与配置



* **访问地址**：`http://节点IP:30093`（默认 NodePort，生产环境建议用 Ingress 暴露）；

* **初始账号密码**：`admin`/`admin`（首次登录需强制修改密码）；

* **数据源**：已自动配置 Prometheus 数据源（名称：`Prometheus`，地址：`prometheus-service:9090`，无需手动修改）。

### 3. 告警系统配置

#### （1）Alertmanager 部署



* **功能**：接收 Prometheus 触发的告警，实现告警去重（避免重复通知）、分组（按业务 / 组件聚合）、路由（按级别分发）与多渠道通知；

* **部署位置**：`monitoring` 命名空间；

* **配置路径**：`roles/prometheus/files/alertmanager/`（核心配置文件：`alertmanager-config.yaml`）；

* **访问地址**：`http://节点IP:30094`（默认 NodePort，用于查看告警状态与历史）。

#### （2）告警规则分类



* **基础设施规则**：节点 CPU / 内存使用率超限（如 CPU > 85% 持续 5 分钟）、节点失联（持续 3 分钟）、磁盘使用率超限（> 90%）等；

* **Kubernetes 规则**：Pod 未就绪（持续 5 分钟）、Deployment 副本数不匹配（期望 vs 实际）、Job 执行失败等；

* **容器规则**：容器频繁重启（5 分钟内 > 3 次）、容器 CPU / 内存使用率超限（如 CPU > 90% 持续 10 分钟）等；

* **数据库规则**：MySQL 连接数过高（> 80% 最大连接数）、慢查询激增（10 分钟内 > 100 条）、表空间不足（使用率 > 90%）等；

* **进程与 GPU 规则**：关键进程退出（`process_up == 0`）、GPU 使用率持续过高（> 95% 持续 30 分钟）、GPU 显存不足（使用率 > 90%）等。

#### （3）告警级别与通知渠道



| 告警级别     | 适用场景                        | 通知渠道                 |
| -------- | --------------------------- | -------------------- |
| critical | 影响服务可用性的故障（如节点宕机、Ceph 集群异常） | 邮件 + PagerDuty（紧急工单） |
| warning  | 资源即将饱和或非核心异常（如磁盘使用率 > 80%）  | Slack（团队沟通群）         |
| info     | 非紧急状态变更（如 Pod 重启、进程启动）      | Grafana 面板展示（无推送）    |

## 访问与验证

### 1. 服务访问方式



| 服务名称       | 访问地址（默认 NodePort）           | 用途                  |
|------------|-----------------------------|---------------------|
| Grafana    | `http://节点IP:30093`         | 监控可视化与仪表盘管理         |
| Prometheus | `http://节点IP:30090`         | 指标查询与告警规则查看         |
| Alertmanager | `http://节点IP:30094`         | 告警状态与通知管理           |
| Node Exporter | `http://节点IP:30091/metrics` | 节点指标原始数据查看          |
| 告警中心       | `http://节点IP:30099`         | 告警中心管理平台，支持多个即时通讯平台 |
### 2. 部署验证

通过以下命令检查核心组件状态，确认部署成功：



```
 检查监控组件状态（monitoring 命名空间）

kubectl get pods -n monitoring

 预期结果：prometheus-server、grafana、alertmanager 等 Pod 均为 Running 状态

 检查 Ceph 组件状态（rook-ceph 命名空间）

kubectl get pods -n rook-ceph

 预期结果：rook-ceph-operator、ceph-mon、ceph-osd 等 Pod 均为 Running 状态
```

## 注意事项



1. **生产环境优化**：建议使用 Ingress 替代 NodePort 暴露 Grafana、Prometheus 等服务，结合 TLS 加密提升安全性；

2. **数据备份**：定期备份 Grafana 配置（`grafana.ini`）、Prometheus 时序数据（默认存储在 `emptyDir`，生产环境建议用持久化存储）；

3. **Ceph 高可用**：生产环境部署 Ceph 需至少 3 个节点，确保 Monitor 与 OSD 组件的高可用，避免单点故障；

4. **资源调整**：根据集群规模与负载，修改 Prometheus、Grafana、Ceph 等组件的 CPU / 内存请求与限制，避免资源竞争；

5. **告警优化**：合理配置告警阈值（如根据业务峰值调整 CPU 使用率阈值）与重复通知间隔（如 critical 级别间隔 15 分钟，避免告警风暴）。

> （注：文档部分内容可能由 AI 生成）