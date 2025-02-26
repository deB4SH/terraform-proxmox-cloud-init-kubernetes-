/**
* Generate a fresh mac.
* Mostly used in selfhosted environments for dhcp ip reservation purposes.
*/
resource "macaddress" "mac-vm-postgresql" {} 

/**
* VM for postgresql
* 
*/
resource "proxmox_virtual_environment_vm" "vm-k8s-postgresql" {
  depends_on    = [macaddress.mac-vm-postgresql]
  node_name     = var.pve_default_node
  name          = var.postgres_vm_name
  description   = var.postgres_vm_description
  tags          = var.postgresql_vm_tags.tags
  on_boot       = true
  vm_id         = var.postgres_vm_id
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"
  bios          = "ovmf"

  cpu {
    cores = var.postgres_vm_cpu_core_count
    type  = "host"
  }

  memory {
    dedicated = var.postgres_vm_memory_count
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = macaddress.mac-vm-postgresql.address
  }

  efi_disk {
    datastore_id = coalesce(var.postgres_vm_disk_efi_datastore_id ,var.pve_default_datastore_id)
    file_format  = "raw" // To support qcow2 format
    type         = "4m"
  }

  disk {
    datastore_id = coalesce(var.postgres_vm_disk_efi_datastore_id ,var.pve_default_datastore_id)
    file_id      = proxmox_virtual_environment_download_file.image[var.postgres_vm_arch].id
    interface    = "scsi0"
    cache        = "writethrough"
    discard      = "on"
    ssd          = true
    size         = coalesce(var.postgres_vm_disk_size, 32)
  }

  /**
  * FIX: seems to be requiered by debain 12 as is requests a serial_device on socket 0
  * REF: https://www.reddit.com/r/Proxmox/comments/1gujajr/comment/lxvzbk6/
  */
  serial_device {
    device = "socket"
  }

  boot_order = ["scsi0"]

  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  initialization {
    dns {
      domain  = var.dns_configuration.domain
      servers = var.dns_configuration.servers
    }
    ip_config {
      ipv4 {
        address = var.postgres_vm_ipv4
        gateway = coalesce(var.postgres_vm_network_gateway, var.pve_network_default_gateway)
      }
    }

    datastore_id      = var.postgres_vm_disk_datastore_id
    user_data_file_id = proxmox_virtual_environment_file.cloud-init-kubernetes-postgres.id
  }
}