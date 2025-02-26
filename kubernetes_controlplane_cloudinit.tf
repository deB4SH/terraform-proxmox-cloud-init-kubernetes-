resource "proxmox_virtual_environment_file" "cloud-init-kubernetes-controlplane" {
  for_each = {for each in var.kubernetes_controlplanes: each.name => each}
  node_name    = coalesce(each.value.node, var.pve_default_node)
  content_type = "snippets"
  datastore_id = var.pve_default_snippet_datastore_id

  source_raw {
    data = templatefile("${path.module}/templates/kubernetes_controlplane.yaml.tftpl", {
      #defaults
      hostname      = each.value.name
      user          = var.vm_user
      user_password = var.vm_user_password
      user_pub_key  = var.vm_user_public_key
      timezone      = var.pve_default_timezone
      arch = var.kubernetes_vm_controlplane_arch
      #apt related
      debian_primary_mirror  = var.debian_primary_mirror
      debian_primary_security_mirror = var.debian_primary_security_mirror
      #kubernetes related
      kubernetes_version = var.kubernetes_version
      kubernetes_version_semantic = var.kubernetes_version_semantic
      kine_version = var.kubernetes_controlplane_kine_version
      ip = element(split("/", each.value.ip),0)
      #kine related
      postgres_username = "kine"
      postgres_password = var.postgres_conf_kine_pw
      postgres_ip = element(split("/",var.postgres_vm_ipv4),0)
    })
    file_name = format("%s-%s.yaml", "${var.kubernetes_vm_controlplane_startid + each.value.id_offset}", each.value.name)
  }
}