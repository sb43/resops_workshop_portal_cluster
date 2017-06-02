resource "openstack_networking_floatingip_v2" "openlava_floatip" {
  region = ""
  pool   = "${var.floating_pool}"
}
