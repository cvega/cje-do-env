# cje-do-environment

## Configuration

This is a configurable CJE environment that's hosted on DigitalOcean. The following options can be set:

```HCL
do_token = "<authentication-token>" # string

scale = {
  controller = <num-controllers>,       # integer (e.g. 3)
  master = <num-master-workers>,        # integer (e.g. 2)
  build = <num-build-workers>,          # integer (e.g. 3)
  elasticsearch = <num-elasticsearches> # integer (e.g. 3)
}

image    = <OS>     # string (e.g. "centos-7-x64")
region   = <region> # string (e.g. "ams3")
size     = <size>   # string (ends with unit; e.g. "8gb")

# private ssh key path
private_key = <path-to-private-key> # string (e.g. "/Users/user/.ssh/id_rsa")
# public ssh key path
public_key = <path-to-public-key> # string (e.g. /Users/user/.ssh/id_rsa.pub)

# exported nfs directory
nfs_export_dir = <path-to-nfs-dir> # string (e.g. "/home/cje")

# name of new user
user = <username> # string (e.g. "cje")

```

If you're using a .tfvars file, you'll want to put `do_token` and `private_key` into a separate `configuration/secret.tfvars`. Then include it as such: `terraform apply --var-file="configuration/secret.tfvars" ...`


## Install

After creating a `configuration/secret.tfvars`, you're ready to spin up the droplets and install CJE. Just run `./apply.sh`. It'll take care of parsing the output from terraform and filling in the `cluster-init.config` generated by `cje`. Run `./destroy.sh` to bring down the droplets and remove the current cje project.