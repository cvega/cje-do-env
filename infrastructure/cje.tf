# Set the variable value in *.tfvars file
# or using -var="key=value" CLI option
variable "do_token" {}
variable "image" {}
variable "region" {}
variable "size" {}
variable "private_key" {}
variable "public_key" {}
variable "nfs_export_dir" {}
variable "user" {}
variable "email" {}
variable "domain" {}
variable "scale" {
  type = "map"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_domain" "lb" {
  name       = "${var.domain}"
  ip_address = "${digitalocean_loadbalancer.public.ip}"
}

### cje required records

resource "digitalocean_record" "cje" {
  domain = "${digitalocean_domain.lb.name}"
  type   = "A"
  name   = "cje"
  value  = "${digitalocean_loadbalancer.public.ip}"
  ttl    = "60"
}

resource "digitalocean_record" "marathon" {
  domain = "${digitalocean_domain.lb.name}"
  type   = "CNAME"
  name   = "marathon-cje"
  value  = "${var.domain}."
  ttl    = "60"
}

resource "digitalocean_record" "mesos" {
  domain = "${digitalocean_domain.lb.name}"
  type   = "CNAME"
  name   = "mesos-cje"
  value  = "${var.domain}."
  ttl    = "60"
}

### cje communicable records

resource "digitalocean_record" "controller-records" {
  count  = "${var.scale["controller"]}"
  domain = "${digitalocean_domain.lb.name}"
  type   = "A"
  name   = "controller-${count.index}"
  value  = "${module.controller.ip-addresses[count.index]}"
  ttl    = "60"
}

resource "digitalocean_record" "master-worker-records" {
  count  = "${var.scale["master-worker"]}"
  domain = "${digitalocean_domain.lb.name}"
  type   = "A"
  name   = "master-worker-${count.index}"
  value  = "${module.master-worker.ip-addresses[count.index]}"
  ttl    = "60"
}

resource "digitalocean_record" "build-worker-records" {
  count  = "${var.scale["build-worker"]}"
  domain = "${digitalocean_domain.lb.name}"
  type   = "A"
  name   = "build-worker-${count.index}"
  value  = "${module.build-worker.ip-addresses[count.index]}"
  ttl    = "60"
}

resource "digitalocean_record" "elasticsearch-records" {
  count  = "${var.scale["elasticsearch"]}"
  domain = "${digitalocean_domain.lb.name}"
  type   = "A"
  name   = "elasticsearch-${count.index}"
  value  = "${module.elasticsearch.ip-addresses[count.index]}"
  ttl    = "60"
}

resource "digitalocean_record" "nfs-records" {
  domain = "${digitalocean_domain.lb.name}"
  type   = "A"
  name   = "nfs"
  value  = "${digitalocean_droplet.nfs.ipv4_address}"
  ttl    = "60"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

# Set up a registration using a private key from tls_private_key
resource "acme_registration" "reg" {
  server_url      = "https://acme-v01.api.letsencrypt.org/directory"
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.email}"
}

# Create a certificate
resource "acme_certificate" "certificate" {
  depends_on                = ["digitalocean_domain.lb",
                               "digitalocean_record.cje",
                               "digitalocean_record.mesos",
                               "digitalocean_record.marathon"]
  server_url                = "https://acme-v01.api.letsencrypt.org/directory"
  account_key_pem           = "${tls_private_key.private_key.private_key_pem}"
  common_name               = "${var.domain}"
  subject_alternative_names = ["cje.${var.domain}",
                               "mesos-cje.${var.domain}",
                               "marathon-cje.${var.domain}"]
  dns_challenge {
    provider = "digitalocean"
    config {
      DO_AUTH_TOKEN = "${var.do_token}"
    }
  }
  registration_url = "${acme_registration.reg.id}"
}

resource "digitalocean_certificate" "cert" {
  name              = "cert"
  private_key       = "${acme_certificate.certificate.private_key_pem}"
  leaf_certificate  = "${acme_certificate.certificate.certificate_pem}"
}

resource "digitalocean_loadbalancer" "public" {
  name      = "lb"
  region    = "ams3"
  algorithm = "least_connections"
  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"
    target_port     = 80
    target_protocol = "http"
  }
  healthcheck {
    port     = 22
    protocol = "tcp"
  }
  droplet_ids = ["${module.controller.all-ids}"]
}

resource "digitalocean_ssh_key" "default" {
  name       = "key"
  public_key = "${file(var.public_key)}"
}

module "controller" {
  source      = "../modules/droplets"
  name        = "controller"
  image       = "${var.image}"
  region      = "${var.region}"
  size        = "${var.size}"
  private_key = "${var.private_key}"
  public_key  = "${digitalocean_ssh_key.default.id}"
  user        = "${var.user}"
  scale       = "${var.scale["controller"]}"
  domain      = "${var.domain}"
}

module "master-worker" {
  source      = "../modules/droplets"
  name        = "master-worker"
  image       = "${var.image}"
  region      = "${var.region}"
  size        = "${var.size}"
  private_key = "${var.private_key}"
  public_key  = "${digitalocean_ssh_key.default.id}"
  user        = "${var.user}"
  scale       = "${var.scale["master-worker"]}"
  domain      = "${var.domain}"
}

module "build-worker" {
  source      = "../modules/droplets"
  name        = "build-worker"
  image       = "${var.image}"
  region      = "${var.region}"
  size        = "${var.size}"
  private_key = "${var.private_key}"
  public_key  = "${digitalocean_ssh_key.default.id}"
  user        = "${var.user}"
  scale       = "${var.scale["build-worker"]}"
  domain      = "${var.domain}"
}

module "elasticsearch" {
  source      = "../modules/droplets"
  name        = "elasticsearch"
  image       = "${var.image}"
  region      = "${var.region}"
  size        = "${var.size}"
  private_key = "${var.private_key}"
  public_key  = "${digitalocean_ssh_key.default.id}"
  user        = "${var.user}"
  scale       = "${var.scale["elasticsearch"]}"
  domain      = "${var.domain}"
}

# Create the NFS server
resource "digitalocean_droplet" "nfs" {
  name     = "nfs"
  image    = "${var.image}"
  region   = "${var.region}"
  size     = "${var.size}"
  ssh_keys = ["${digitalocean_ssh_key.default.id}"]
  connection {
    user        = "root"
    private_key = "${file("${var.private_key}")}"
    host        = "${self.ipv4_address}"
  }
  provisioner "file" {
    source = "./sources/create_user.sh"
    destination = "/tmp/create_user.sh"
  }
  provisioner "file" {
    source = "./sources/setup_nfs.sh"
    destination = "/tmp/setup_nfs.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_user.sh /tmp/setup_nfs.sh",
      "/tmp/create_user.sh ${var.user}"
    ]
  }
  connection {
    user        = "${var.user}"
    private_key = "${file("${var.private_key}")}"
    host        = "${self.ipv4_address}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /tmp/setup_nfs.sh '${var.nfs_export_dir}' '${
        module.controller.nfs-rule
      }' '${
        module.master-worker.nfs-rule
      }' '${
        module.build-worker.nfs-rule
      }' '${
        module.elasticsearch.nfs-rule
      }'"
    ]
  }
  provisioner "file" {
    source = "${var.private_key}"
    destination = "/home/${var.user}/.ssh/${basename(var.private_key)}"
  }
}

output "domain" {
  value = "${var.domain}"
}

output "ssh_identity_file" {
  value = "${var.private_key}"
}

output "user" {
  value = "${var.user}"
}

output "controller_count" {
  value = "${var.scale["controller"]}"
}

output "controllers_addresses" {
  value = "${module.controller.hostnames}"
}

output "master_worker_count" {
  value = "${var.scale["master-worker"]}"
}

output "master_workers_addresses" {
  value = "${module.master-worker.hostnames}"
}

output "build_worker_count" {
  value = "${var.scale["build-worker"]}"
}

output "build_workers_addresses" {
  value = "${module.build-worker.hostnames}"
}

output "elasticsearch_worker_count" {
  value = "${var.scale["elasticsearch"]}"
}

output "elasticsearch_workers_addresses" {
  value = "${module.elasticsearch.hostnames}"
}

output "nfs_server" {
  value = "nfs.${var.domain}"
}

output "nfs_export_dir" {
  value = "${var.nfs_export_dir}"
}
