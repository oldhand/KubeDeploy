#!/bin/bash



# 获取操作系统名称
os_name=$(cat /etc/os-release | grep NAME | head -n1 | cut -d= -f2 | sed 's/"//g' | cut -d' ' -f1)

# 获取CPU架构
cpu_arch=$(uname -m)

# 输出结果
echo "操作系统: $os_name"
echo "CPU架构: $cpu_arch"


if [ "$cpu_arch" = "x86_64" ]; then
   if [ ! -f "images/ceph/x86_64/quay.io_ceph_ceph_v19.2.3.tar" ]; then
     cat $PWD/images/ceph/x86_64/images.zip.001 $PWD/images/ceph/x86_64/images.zip.002 $PWD/images/ceph/x86_64/images.zip.003 $PWD/images/ceph/x86_64/images.zip.004 $PWD/images/ceph/x86_64/images.zip.005 \
         $PWD/images/ceph/x86_64/images.zip.006 $PWD/images/ceph/x86_64/images.zip.007 $PWD/images/ceph/x86_64/images.zip.008 $PWD/images/ceph/x86_64/images.zip.009 $PWD/images/ceph/x86_64/images.zip.010 \
         $PWD/images/ceph/x86_64/images.zip.011 $PWD/images/ceph/x86_64/images.zip.012 $PWD/images/ceph/x86_64/images.zip.013 $PWD/images/ceph/x86_64/images.zip.014 $PWD/images/ceph/x86_64/images.zip.015 \
         $PWD/images/ceph/x86_64/images.zip.016 $PWD/images/ceph/x86_64/images.zip.017 $PWD/images/ceph/x86_64/images.zip.018 $PWD/images/ceph/x86_64/images.zip.019 $PWD/images/ceph/x86_64/images.zip.020 \
         $PWD/images/ceph/x86_64/images.zip.021 $PWD/images/ceph/x86_64/images.zip.022 $PWD/images/ceph/x86_64/images.zip.023 > $PWD/images/ceph/x86_64/images.zip
     unzip $PWD/images/ceph/x86_64/images.zip -d $PWD/images/ceph/x86_64/
     rm -fr $PWD/images/ceph/x86_64/images.zip
   fi
   if [ ! -f "images/prometheus/x86_64/prom_prometheus_v3.6.0.tar" ]; then
      cat $PWD/images/prometheus/x86_64/images.zip.001 $PWD/images/prometheus/x86_64/images.zip.002 $PWD/images/prometheus/x86_64/images.zip.003 $PWD/images/prometheus/x86_64/images.zip.004 > $PWD/images/prometheus/x86_64/images.zip
      unzip $PWD/images/prometheus/x86_64/images.zip -d $PWD/images/prometheus/x86_64/
      rm -fr $PWD/images/prometheus/x86_64/images.zip
   fi
elif [ "$cpu_arch" = "aarch64" ]; then
   if [ ! -f "images/ceph/aarch64/quay.io_ceph_ceph_v19.2.3.tar" ]; then
     cat $PWD/images/ceph/aarch64/images.zip.001 $PWD/images/ceph/aarch64/images.zip.002 $PWD/images/ceph/aarch64/images.zip.003 $PWD/images/ceph/aarch64/images.zip.004 $PWD/images/ceph/aarch64/images.zip.005 \
         $PWD/images/ceph/aarch64/images.zip.006 $PWD/images/ceph/aarch64/images.zip.007 $PWD/images/ceph/aarch64/images.zip.008 $PWD/images/ceph/aarch64/images.zip.009 $PWD/images/ceph/aarch64/images.zip.010 \
         $PWD/images/ceph/aarch64/images.zip.011 $PWD/images/ceph/aarch64/images.zip.012 $PWD/images/ceph/aarch64/images.zip.013 $PWD/images/ceph/aarch64/images.zip.014 $PWD/images/ceph/aarch64/images.zip.015 \
         $PWD/images/ceph/aarch64/images.zip.016 $PWD/images/ceph/aarch64/images.zip.017 $PWD/images/ceph/aarch64/images.zip.018 $PWD/images/ceph/aarch64/images.zip.019 $PWD/images/ceph/aarch64/images.zip.020 \
         $PWD/images/ceph/aarch64/images.zip.021 $PWD/images/ceph/aarch64/images.zip.022 $PWD/images/ceph/aarch64/images.zip.023 > $PWD/images/ceph/aarch64/images.zip
     unzip $PWD/images/ceph/aarch64/images.zip -d $PWD/images/ceph/aarch64/
     rm -fr $PWD/images/ceph/aarch64/images.zip
   fi
   if [ ! -f "images/prometheus/aarch64/prom_prometheus_v3.6.0.tar" ]; then
      cat $PWD/images/prometheus/aarch64/images.zip.001 $PWD/images/prometheus/aarch64/images.zip.002 $PWD/images/prometheus/aarch64/images.zip.003 $PWD/images/prometheus/aarch64/images.zip.004 > $PWD/images/prometheus/aarch64/images.zip
      unzip $PWD/images/prometheus/aarch64/images.zip -d $PWD/images/prometheus/aarch64/
      rm -fr $PWD/images/prometheus/aarch64/images.zip
   fi
fi

ansible-playbook -i hosts.ini install.yml -k




