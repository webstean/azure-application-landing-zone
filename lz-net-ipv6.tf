
# 40-bit Global ID (5 bytes)
resource "random_id" "ula_global_id" {
  byte_length = 5
}

# Format the ULA prefix: https://en.wikipedia.org/wiki/Unique_local_address
locals {
  hex = lower(random_id.ula_global_id.hex)

  # Split the 40-bit hex into 3 chunks for IPv6 format
  ula_prefix = format(
    "fd%02s:%04s:%04s::/48",
    substr(local.hex, 0, 2), # 8 bits
    substr(local.hex, 2, 4), # 16 bits
    substr(local.hex, 6, 4)  # 16 bits
  )
}

## ULA prefix: local.ula_prefix

locals {
  ula_subnets = {
    "core"        = cidrsubnet(local.ula_prefix, 16, 1)     # fd12:34ab:cd56:0001::/64
    "management"  = cidrsubnet(local.ula_prefix, 16, 2)     # fd12:34ab:cd56:0002::/64
    "siteA_users" = cidrsubnet(local.ula_prefix, 16, 100)   # fd12:34ab:cd56:0064::/64
    "siteA_srv"   = cidrsubnet(local.ula_prefix, 16, 101)   # fd12:34ab:cd56:0065::/64
    "p2p_links"   = cidrsubnet(local.ula_prefix, 16, 65534) # fd12:34ab:cd56:fffe::/64
  }
}