# syntax-docker/dockerfile:experimental
ARG OS_VERSION=22.04
FROM ubuntu:$OS_VERSION as baseline

## Package updates and Python 3 installation
RUN apt update && apt upgrade -y \
  && apt install -y python3 python3-dev python3-pip \
  && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
  && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

## Add-on packages
RUN apt install -y gnupg software-properties-common curl wget git git-lfs sshpass unzip gzip jq tar rsync skopeo 

# Builds

## Terraform
FROM baseline as terraform_builder
ARG TERRAFORM_VERSION=1.3.7

WORKDIR /build

RUN curl -sLO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

## Kubernetes tooling
FROM baseline as tool_builder
ARG KUSTOMIZE_VERSION=4.5.2
ARG KUBECTL_VERSION=1.23.12

WORKDIR /build

RUN curl -sLO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && chmod 755 ./kubectl \
  && curl -sLO https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz && gunzip -c ./kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | tar xvf - && chmod 755 ./kustomize

# Installation
FROM baseline
ARG TIMESTAMP
ARG IAC_BRANCH=main
ARG DAC_BRANCH=main
ARG HELM_VERSION=3.11.0

# Move build items
COPY --from=terraform_builder /build/terraform /usr/local/bin/terraform
COPY --from=tool_builder /build/kubectl /usr/local/bin/kubectl
COPY --from=tool_builder /build/kustomize /usr/local/bin/kustomize

# Add extra packages
RUN curl -ksLO https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod 755 get-helm-3 \
  && ./get-helm-3 --version v$HELM_VERSION --no-sudo \
  && helm plugin install https://github.com/databus23/helm-diff

WORKDIR /sas-marketplace

RUN git clone --single-branch --branch $IAC_BRANCH "https://github.com/sassoftware/viya4-iac-aws.git" viya4-iac-aws \
  && git clone --single-branch --branch $DAC_BRANCH "https://github.com/sassoftware/viya4-deployment.git" viya4-deployment

COPY requirements.* ./viya4-deployment/

ENV HOME=/sas-marketplace

RUN pip install -r /sas-marketplace/viya4-deployment/requirements.txt \
  && ansible-galaxy install -r /sas-marketplace/viya4-deployment/requirements.yaml \
  && chmod -R g=u /etc/passwd /etc/group /sas-marketplace \
  && git config --system --add safe.directory /sas-marketplace/viya4-iac-aws \
  && git config --system --add safe.directory /sas-marketplace/viay4-deployment \
  && git config --global --add safe.directory /sas-marketplace/viya4-iac-aws \
  && git config --global --add safe.directory /sas-marketplace/viya4-deployment \
  && cd /sas-marketplace/viya4-iac-aws \
  && terraform init

ENV PLAYBOOK=playbook.yaml
ENV VIYA4_DEPLOYMENT_TOOLING=docker
ENV ANSIBLE_CONFIG=/viya4-deployment/ansible.cfg

VOLUME ["/config", "/data", "/workspace"]
ENTRYPOINT ["/workspace/docker-entrypoint.sh"]
