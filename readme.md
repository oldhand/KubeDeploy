# KubeDeploy 部署指南

## 项目概述
KubeDeploy 是一个用于在 Kubernetes 集群上部署一系列组件的项目，包括Prometheus、Grafana、Ceph 等，旨在提供完整的基础设施管理和监控能力。

## 组件说明
项目主要包含以下组件：
- **Prometheus**：开源的系统监控和告警工具包
- **Grafana**：开源的数据可视化和监控平台
- **cAdvisor**：用于容器监控的工具

## 前置要求
- Kubernetes 集群，最低版本 `v1.29.0+`
- Helm，最低版本 `v3.0.0+`
- Ansible（用于执行部署脚本）

## 部署步骤

1. **准备环境**
   确保已满足上述前置要求，并且 Kubernetes 集群处于可用状态。

2. **获取项目代码**
   克隆或下载 KubeDeploy 项目代码到本地。

3. **执行部署**
   在项目根目录下运行以下命令启动部署：
   ```bash
   ansible-playbook -i inventory install.yml
   ```
   其中 `inventory` 是包含 Kubernetes 集群节点信息的 Ansible  inventory 文件。





### Prometheus 和 Grafana
- Prometheus 用于 metrics 数据收集，默认暴露在 30090 端口
- Grafana 用于数据可视化，默认暴露在 30093 端口，初始管理员密码为 `admin`
- 包含 Node Exporter（30091 端口）和 Kube State Metrics（30092 端口）


## 许可证
项目中各组件遵循各自的许可证，其中 Crossplane 遵循 Apache License 2.0，详情参见各组件的 LICENSE 文件。