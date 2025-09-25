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
     cat $PWD/ceph/images/x86_64/images.zip.001 $PWD/ceph/images/x86_64/images.zip.002 $PWD/ceph/images/x86_64/images.zip.003 $PWD/ceph/images/x86_64/images.zip.004 $PWD/ceph/images/x86_64/images.zip.005 \
         $PWD/ceph/images/x86_64/images.zip.006 $PWD/ceph/images/x86_64/images.zip.007 $PWD/ceph/images/x86_64/images.zip.008 $PWD/ceph/images/x86_64/images.zip.009 $PWD/ceph/images/x86_64/images.zip.010 \
         $PWD/ceph/images/x86_64/images.zip.011 $PWD/ceph/images/x86_64/images.zip.012 $PWD/ceph/images/x86_64/images.zip.013 $PWD/ceph/images/x86_64/images.zip.014 $PWD/ceph/images/x86_64/images.zip.015 \
         $PWD/ceph/images/x86_64/images.zip.016 $PWD/ceph/images/x86_64/images.zip.017 $PWD/ceph/images/x86_64/images.zip.017 $PWD/ceph/images/x86_64/images.zip.019 $PWD/ceph/images/x86_64/images.zip.020 \
         $PWD/ceph/images/x86_64/images.zip.021 $PWD/ceph/images/x86_64/images.zip.022 $PWD/ceph/images/x86_64/images.zip.023 > $PWD/ceph/images/x86_64/images.zip
     unzip $PWD/ceph/images/x86_64/images.zip -d $PWD/ceph/images/x86_64/
     rm -fr $PWD/ceph/images/x86_64/images.zip
   fi
   if [ ! -f "images/prometheus/x86_64/prom_prometheus_v3.6.0.tar" ]; then
      cat $PWD/prometheus/images/x86_64/images.zip.001 $PWD/prometheus/images/x86_64/images.zip.002 $PWD/prometheus/images/x86_64/images.zip.003 $PWD/prometheus/images/x86_64/images.zip.004 > $PWD/prometheus/images/x86_64/images.zip
      unzip $PWD/prometheus/images/x86_64/images.zip -d $PWD/prometheus/images/x86_64/
      rm -fr $PWD/prometheus/images/x86_64/images.zip
   fi
elif [ "$cpu_arch" = "aarch64" ]; then
   if [ ! -f "images/ceph/aarch64/quay.io_ceph_ceph_v19.2.3.tar" ]; then
     cat $PWD/ceph/images/aarch64/images.zip.001 $PWD/ceph/images/aarch64/images.zip.002 $PWD/ceph/images/aarch64/images.zip.003 $PWD/ceph/images/aarch64/images.zip.004 $PWD/ceph/images/aarch64/images.zip.005 \
         $PWD/ceph/images/aarch64/images.zip.006 $PWD/ceph/images/aarch64/images.zip.007 $PWD/ceph/images/aarch64/images.zip.008 $PWD/ceph/images/aarch64/images.zip.009 $PWD/ceph/images/aarch64/images.zip.010 \
         $PWD/ceph/images/aarch64/images.zip.011 $PWD/ceph/images/aarch64/images.zip.012 $PWD/ceph/images/aarch64/images.zip.013 $PWD/ceph/images/aarch64/images.zip.014 $PWD/ceph/images/aarch64/images.zip.015 \
         $PWD/ceph/images/aarch64/images.zip.016 $PWD/ceph/images/aarch64/images.zip.017 $PWD/ceph/images/aarch64/images.zip.017 $PWD/ceph/images/aarch64/images.zip.019 $PWD/ceph/images/aarch64/images.zip.020 \
         $PWD/ceph/images/aarch64/images.zip.021 $PWD/ceph/images/aarch64/images.zip.022 $PWD/ceph/images/aarch64/images.zip.023 > $PWD/ceph/images/aarch64/images.zip
     unzip $PWD/ceph/images/aarch64/images.zip -d $PWD/ceph/images/aarch64/
     rm -fr $PWD/ceph/images/aarch64/images.zip
   fi
   if [ ! -f "images/prometheus/aarch64/prom_prometheus_v3.6.0.tar" ]; then
      cat $PWD/prometheus/images/aarch64/images.zip.001 $PWD/prometheus/images/aarch64/images.zip.002 $PWD/prometheus/images/aarch64/images.zip.003 $PWD/prometheus/images/aarch64/images.zip.004 > $PWD/prometheus/images/aarch64/images.zip
      unzip $PWD/prometheus/images/aarch64/images.zip -d $PWD/prometheus/images/aarch64/
      rm -fr $PWD/prometheus/images/aarch64/images.zip
   fi
fi

#ansible-playbook -i hosts.ini install.yml -k
ansible-playbook -i hosts.ini install.yml



