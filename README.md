# aws-marketplace

## Getting started

### Clone the repo

```bash
git clone 
```

## Usage

### Building the docker image

#### Using defaults

```bash
cd ./aws-marketplace
docker build --file ./Dockerfile --build-arg TIMESTAMP=$(date +%s) --tag aws-marketplace . 
```

#### Using specific IAC and DAC branches

```bash
cd ./aws-marketplace
docker build --file ./Dockerfile --build-arg TIMESTAMP=$(date +%s) --build-arg IAC_BRANCH=5.4.0 --build-arg DAC_BRANCH=6.1.0 --tag aws-marketplace .
```

### Running

You must first have these files in your current working directory:

- `terraform.tfvars` - IaC terraform tfvars file. Reference [here](https://github.com/sassoftware/viya4-iac-aws)
- `ansible-vars.yaml` - DaC ansible vars file. Reference [here](https://github.com/sassoftware/viya4-deployment)
- `requirements.txt` (Optional - Only needed if you have overrides)
- `requirements.yaml` (Optional - Only needed if you have overrides)
- `docker-entrypoint.sh`

You also need access to your AWS credentials in a file in the form of environmental variables and access to your public ssh key.

#### Creating the cluster

```bash
docker run --rm -it \
  --group-add root \
  --user $(id -u):$(id -g) \
  --env-file $HOME/.aws_docker_creds.env \
  --volume $HOME/.ssh:/sas-marketplace/.ssh \
  --volume $(pwd):/workspace \
  registry.unx.sas.com/props/marketplace-aws:0.1.0 create   
```

#### Destroying the cluster

```bash
docker run --rm -it \
  --group-add root \
  --user $(id -u):$(id -g) \
  --env-file $HOME/.aws_docker_creds.env \
  --volume $HOME/.ssh:/sas-marketplace/.ssh \
  --volume $(pwd):/workspace \
  registry.unx.sas.com/props/marketplace-aws:0.1.0 
```

## License

The license is [here](./LICENSE)
