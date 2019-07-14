variable name_prefix {
  default = ""
}

variable dev_mode {
  default = true
}

locals {
  name_prefix = "${var.name_prefix != "" ? var.name_prefix : "entropic"}"
}
