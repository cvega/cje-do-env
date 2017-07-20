#!/usr/bin/env bash

set -e

if ! type "jq" &> /dev/null ;
then
  echo "error: jq must be installed"
  exit 1
fi

# run infrastructure
terraform get infrastructure;
terraform apply --var-file="configuration/secret.tfvars" --var-file="configuration/cje.tfvars" infrastructure;

# initiate cje project
if [[ ! -f .tiger-project ]];
then
  cje init-project anywhere
  cje prepare cluster-init
fi

# fill in config file
./configure.sh

# apply
cje verify
