#!/bin/bash


#if [ ! -f "ceph/quay.io-rook-ceph-v1.18.2.tar" ]; then
#  cat $PWD/ceph.zip.001 $PWD/ceph.zip.002 $PWD/ceph.zip.003 $PWD/ceph.zip.004 $PWD/ceph.zip.005 \
#      $PWD/ceph.zip.006 $PWD/ceph.zip.007 $PWD/ceph.zip.008 $PWD/ceph.zip.009 $PWD/ceph.zip.010 \
#      $PWD/ceph.zip.011 $PWD/ceph.zip.012 $PWD/ceph.zip.013 $PWD/ceph.zip.014 $PWD/ceph.zip.015 \
#      $PWD/ceph.zip.016 $PWD/ceph.zip.017 $PWD/ceph.zip.018 $PWD/ceph.zip.019 $PWD/ceph.zip.020 \
#      $PWD/ceph.zip.021 $PWD/ceph.zip.022 $PWD/ceph.zip.023 > $PWD/ceph.zip
#  unzip $PWD/ceph.zip -d $PWD/
#  rm -fr $PWD/ceph.zip
#fi

#ansible-playbook -i hosts.ini install.yml -k
ansible-playbook -i hosts.ini install.yml



