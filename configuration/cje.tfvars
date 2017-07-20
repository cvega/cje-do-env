# how many of each resource to create
scale = {
  controller    = 1,
  master-worker = 1,
  build-worker  = 1,
  elasticsearch = 3
}

# resource attributes
image    = "centos-7-x64"
region   = "ams3"
size     = "8gb"

# path to jenkins root
nfs_export_dir = "/home/cje"

# name of new user
user = "cje"

# path to public ssh key
public_key = "/Users/jbert/.ssh/id_rsa.pub"

# domain name
domain = "jimmyjam5000.com"
