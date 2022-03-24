data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}
# "${chomp(data.http.myip.body)}/32"

module myip {
  source  = "4ops/myip/http"
  version = "1.0.0"
}
# module.myip.address

variable "host_ip" {
  type = list(string)
  default = ["172.31.45.27/32",]
}

variable "mint_ip" {
  type = list(string)
  default = ["193.178.190.134/32",]
}