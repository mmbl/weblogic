################################################################################
# PROVIDERS
################################################################################
terraform {
  required_version = ">= 0.12"
}

# instance the provider
provider "libvirt" {
  uri = "qemu:///system"
}

################################################################################
# VAR
################################################################################

variable "ANSIBLE_USER" {
  default = "ansible"
  type    = string
}
variable "SSH_KEY_PATH" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

variable "LIBVIRT_POOL_DIR" {
  type    = string
  default = "/home/d/virtlab/vm_weblogic"
}

variable "RH81_IMG_URL_64" {
  type    = string
  default = "/home/d/repository/rhel-8.1-x86_64-kvm.qcow2"
}

resource "libvirt_pool" "weblogic_env" {
  name = "weblogic_env"
  type = "dir"
  path = abspath("${var.LIBVIRT_POOL_DIR}")
}

resource "libvirt_network" "weblogic_network" {
  name      = "weblogic_network"
  addresses = ["10.10.30.0/24"]

  dns {
    enabled    = true
    local_only = true
  }
}
################################################################################
# RESOURCES
################################################################################
data "template_file" "network_config" {
  template = file("${path.module}/network_config.yaml")
}

resource "libvirt_volume" "rh_disk" {
  name   = "rh_disk"
  pool   = libvirt_pool.weblogic_env.name
  source = var.RH81_IMG_URL_64
  format = "qcow2"
}
#################################################################
# VM
# Будет создано 2 виртуальных машины и отдельная сеть
#################################################################
data "template_file" "wls_user_data" {
  template = file("${path.module}/cloud_init.yaml")
  vars = {
    # пользователи из переменных выше - технический долг, при большом количестве добавляемых сущностей
    # реализовать циклический перебор или как-то вложить в одну переменную
    ANSIBLE_USER: var.ANSIBLE_USER
    SSH_KEY  = file(var.SSH_KEY_PATH)
    HOSTNAME = "wls"
  }
}

resource "libvirt_cloudinit_disk" "cloudinit" {
  name           = "wls_cloudinit.iso"
  user_data      = data.template_file.wls_user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.weblogic_env.name
}

resource "libvirt_volume" "wls_rh_disk" {
  name           = "wls_rh_disk_${count.index}"
  base_volume_id = libvirt_volume.rh_disk.id
  pool           = libvirt_pool.weblogic_env.name
  count          = 2
}

resource "libvirt_domain" "wls_rh_host" {
  name       = "wls_rh_host_${count.index}"
  memory     = "2048"
  vcpu       = 1
  autostart  = true
  qemu_agent = true

  count = 2

  cloudinit = libvirt_cloudinit_disk.cloudinit.id

  network_interface {
    network_name   = libvirt_network.weblogic_network.name
    hostname       = "wls-${count.index}"
    wait_for_lease = true
  }

  disk {
    volume_id = element(libvirt_volume.wls_rh_disk.*.id, count.index)
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

}
output "vm_weblogic" {
  value = libvirt_domain.wls_rh_host.*.network_interface.0.addresses
}