#!/usr/bin/env bash

set -e

if [[ -d .terraform ]];
then
  terraform destroy --var-file="configuration/secret.tfvars" --var-file="configuration/cje.tfvars" infrastructure;
  rm -rf .terraform *.tfstate*
fi
rm -rf cluster-init* .tiger-project .dna operations logs
