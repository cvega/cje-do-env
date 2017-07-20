#!/usr/bin/env bash

for var in "$@"
do
  SHARED=$SHARED" $var"
  if [[ $SHARED =~ [0-9]+$ ]];
  then
    SHARED=$SHARED'(rw,sync,no_root_squash,no_subtree_check)';
  fi
done
yum install -y nfs-utils nfs-utils-lib
chkconfig nfs on
service rpcbind start
service nfs start
echo $SHARED | tee -a /etc/exports
exportfs -a
