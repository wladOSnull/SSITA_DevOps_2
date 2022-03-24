### SSH
##################################################

variable "ssh_ip" {
  type = list(string)
  default = ["35.226.240.92/32", "34.132.230.113/32"]
  description = "1: GCP VM Jenkins IP; 2: GCP VM AWX IP"
}

variable "ssh_admin" {
  description = "OS user"
  default  = "wlad1324"
}

data "google_storage_bucket_object_content" "key_db" {

  bucket = "ssita"
  name   = "ssh/id_rsa_db.pub"
}

data "google_storage_bucket_object_content" "key_server" {

  bucket = "ssita"
  name   = "ssh/id_rsa_server.pub"
}