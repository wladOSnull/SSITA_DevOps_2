terraform {

  backend "gcs" {

    credentials = "/home/wlados/.gcp/terraform.json"

    bucket = "ssita"
    prefix = "terraform/terraform.tfstate"
  }
}

provider "google" {

  credentials = "/home/wlados/.gcp/terraform.json"

  project = "helical-history-342218"
  region  = "us-central1"
  zone    = "us-central1-a"
}

### Tomcat
##################################################

resource "google_compute_address" "static_ip" {
  name = "ipv4-address"
}

resource "google_compute_instance" "instance_server" {

  tags = ["serv"]

  name         = "server"
  machine_type = "g1-small"

  boot_disk {
    initialize_params {
      image = "ubuntu-2004-focal-v20220204"
    }
  }

  network_interface {

    network = "default"

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  metadata = {
    #ssh-keys = "${var.ssh_admin}:${file(var.ssh_server_file_pub)}"
    ssh-keys = "${var.ssh_admin}:${data.google_storage_bucket_object_content.key_server.content}"
  }
}

resource "google_compute_firewall" "firewall_server" {

  target_tags   = ["serv"]
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  name    = "firewall-server-ingress"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
}

### DB
##################################################

resource "google_compute_instance" "instance_db" {

  tags = ["db"]

  name         = "db"
  machine_type = "g1-small"

  boot_disk {
    initialize_params {
      image = "centos-7-v20220126"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    #ssh-keys = "${var.ssh_admin}:${file(var.ssh_db_file_pub)}"
    ssh-keys = "${var.ssh_admin}:${data.google_storage_bucket_object_content.key_db.content}"
  }
}

resource "google_compute_firewall" "firewall_db" {

  target_tags   = ["db"]
  direction     = "INGRESS"
  source_ranges = ["${google_compute_instance.instance_server.network_interface.0.network_ip}/32", ]

  name    = "firewall-db-ingress"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }
}

### Common
##################################################

resource "google_compute_firewall" "firewall_server_db" {

  target_tags   = ["serv", "db"]
  direction     = "INGRESS"
  source_ranges = var.ssh_ip

  name    = "firewall-geo-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

### Values
##################################################

### IPs
output "server-external-ip" {
  value = google_compute_instance.instance_server.network_interface.0.access_config.0.nat_ip
}

output "server-internal-ip" {
  value = google_compute_instance.instance_server.network_interface.0.network_ip
}

output "db-external-ip" {
  value = google_compute_instance.instance_db.network_interface.0.access_config.0.nat_ip
}

output "db-internal-ip" {
  value = google_compute_instance.instance_db.network_interface.0.network_ip
}
