#!/usr/bin/env bash
set -e

# setup container user
echo "sas-marketplace:*:$(id -u):$(id -g):,,,:/sas-marketplace:/bin/bash" >> /etc/passwd
echo "sas-marketplace:*:$(id -G | cut -d' ' -f 2)" >> /etc/group

# Marketplace tasks

## Global

##
## Tooling here is very simple, it either creates or destroys the cluster
##

help() {
  echo ""
  echo "Usage: $0 [create|destroy]"
  echo ""
  echo "  Actions           - Items and their meanings"
  echo ""
  echo "    create          - Create SAS Viya Platform infrastrucure, baseline, and Viya deployment"
  echo "    destroy         - Destroy SAS Viya Platform deployment, baseline, and infrastrucutre"
  echo ""
  exit 1
}

## Check if one has passed in arguments
if [ "$#" -eq 0 ]; then
  help
fi

## Create
if [[ "$1" == "create" ]]; then
  echo "Creating SAS Viya Platform"
  ## IAC
  cd /sas-marketplace/viya4-iac-aws
  /usr/local/bin/terraform apply -var-file /workspace/terraform.tfvars -state /workspace/terraform.tfstate -auto-approve
  cp /sas-marketplace/viya4-iac-aws/*-kubeconfig.conf /workspace

  ## DAC
  cd /sas-marketplace/viya4-deployment
  /usr/local/bin/ansible-playbook \
    -e BASE_DIR=/sas-marketplace/viya4-deployment \
    -e CONFIG=/workspace/ansible-vars.yaml \
    -e TFSTATE=/workspace/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=/sas-marketplace/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,install"
fi

## Destroy
if [[ "$1" == "destroy" ]]; then
  echo "Destroying SAS Viya Platform"
  ## DAC
  cd /sas-marketplace/viya4-deployment
  /usr/local/bin/ansible-playbook \
    -e BASE_DIR=/sas-marketplace/viya4-deployment \
    -e CONFIG=/workspace/ansible-vars.yaml \
    -e TFSTATE=/workspace/terraform.tfstate \
    -e JUMP_SVR_PRIVATE_KEY=/sas-marketplace/.ssh/id_rsa \
    playbooks/playbook.yaml --tags "baseline,viya,uninstall"
    
  ## IAC
  cd /sas-marketplace/viya4-iac-aws
  /usr/local/bin/terraform destroy -var-file /workspace/terraform.tfvars -state /workspace/terraform.tfstate -auto-approve

  ## Cleann up artifacts
  rm -rf /workspace/terraform.tfstate*
  rm -rf /workspace/*-kubeconfig.conf
fi
