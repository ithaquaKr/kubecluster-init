# Enable service compute
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

# Enable service container 
resource "google_project_service" "container" {
  service = "container.googleapis.com"
}

# VPC
resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  mtu                             = 1460
  delete_default_routes_on_create = false

  depends_on = [
    google_project_service.compute,
    google_project_service.container
  ]
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name                     = var.subnet_name
  ip_cidr_range            = "10.0.0.0/18"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "cluster-pod-range"
    ip_cidr_range = "10.48.0.0/14"
  }

  secondary_ip_range {
    range_name    = "cluster-service-range"
    ip_cidr_range = "10.52.0.0/20"
  }
}

# Router
resource "google_compute_router" "router" {
  name    = var.router_name
  region  = var.region
  network = google_compute_network.vpc.id
}

# NAT
resource "google_compute_router_nat" "router_nat" {
  name   = var.router_nat_name
  router = google_compute_router.router.name
  region = var.region

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  nat_ips = [google_compute_address.address.self_link]

}

# NAT Address
resource "google_compute_address" "address" {
  name         = var.address_name
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

  depends_on = [google_project_service.compute]
}

# Firewall
resource "google_compute_firewall" "firewall" {
  name    = var.firewall_name
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = var.firewall_allow_ports
  }
  source_ranges = ["0.0.0.0/0"]
}

# Cluster
resource "google_container_cluster" "cluster" {
  name                     = var.cluster_name
  location                 = var.region
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.vpc.self_link
  subnetwork               = google_compute_subnetwork.subnet.self_link
  logging_service          = "logging.googleapis.com/kubernetes"
  monitoring_service       = "monitoring.googleapis.com/kubernetes"
  networking_mode          = "VPC_NATIVE"

  # Optional, if you want multi-zonal cluster
  node_locations = [
    var.zone
  ]

  addons_config {
    http_load_balancing {
      disabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_name}.svc.id.goog"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "cluster-pod-range"
    services_secondary_range_name = "cluster-service-range"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
}

# Node-pool
resource "google_container_node_pool" "general" {
  name       = "general"
  cluster    = google_container_cluster.cluster.id
  node_count = 1

  management {
    auto_repair  = true
    auto_upgrade = true
  }
  node_config {
    preemptible  = false
    machine_type = var.node_machine_type

    labels = {
      role = "general"
    }

    service_account = google_service_account.kubernetes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_container_node_pool" "spot" {
  name    = "spot"
  cluster = google_container_cluster.cluster.id

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  autoscaling {
    min_node_count = 0
    max_node_count = 10

  }
  node_config {
    preemptible  = true
    machine_type = var.node_machine_type

    labels = {
      team = "devops"
    }
    taint {
      key    = "instance_type"
      value  = "spot"
      effect = "NO_SCHEDULE"
    }
    service_account = google_service_account.kubernetes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Service Account
resource "google_service_account" "kubernetes" {
  account_id = "kubernetes"
}
