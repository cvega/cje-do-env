variable "name" {}
variable "image" {}
variable "region" {}
variable "size" {}
variable "private_key" {}
variable "public_key" {}
variable "user" {}
variable "scale" {}
variable "domain" {}

resource "digitalocean_droplet" "droplet" {
  count    = "${var.scale}"
  name     = "${var.name}-${count.index}"
  image    = "${var.image}"
  region   = "${var.region}"
  size     = "${var.size}"
  ssh_keys = ["${var.public_key}"]
  connection {
    user        = "root"
    private_key = "${file("${var.private_key}")}"
    host        = "${self.ipv4_address}"
  }
  provisioner "file" {
    source = "./sources/create_user.sh"
    destination = "/tmp/create_user.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create_user.sh",
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
      "sudo yum install -y nfs-utils nfs-utils-lib"
    ]
  }
  provisioner "file" {
    source = "${var.private_key}"
    destination = "/home/${var.user}/.ssh/${basename(var.private_key)}"
  }
}

output "ip-addresses" {
  value = ["${digitalocean_droplet.droplet.*.ipv4_address}"]
}

output "hostnames" {
  # doesn't work with 0 droplets
  value = "${join(".${var.domain}, ", digitalocean_droplet.droplet.*.name)}.${var.domain}"
}

output "nfs-rule" {
  value = "${
    join("(rw,sync,no_root_squash,no_subtree_check) ",
         digitalocean_droplet.droplet.*.ipv4_address)
  }"
}

output "all-ids" {
  value = ["${digitalocean_droplet.droplet.*.id}"]
}
