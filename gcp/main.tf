#-----------------------------------
# Certificate
#-----------------------------------
resource "google_compute_ssl_certificate" "main" {
    name_prefix = var.project_name
    description = "${var.project_name}-cluster-k8s"
    private_key = file(var.key_path_priv)
    certificate = file(var.key_path_pub)

    lifecycle {
        create_before_destroy = true
    }
}
#-----------------------------------
# Backend Services
#-----------------------------------
resource "google_compute_backend_service" "main" {
    project               = var.project
    name                  = "${var.project_name}-backend-service"
    protocol              = "HTTP"
    port_name             = "${var.project_name}-port-backend-service"

    health_checks         = [google_compute_health_check.main.id]
    load_balancing_scheme = "EXTERNAL"
    backend {
        group = google_compute_instance_group_manager.main.instance_group
    }
}
#-----------------------------------
# Health Checks
#-----------------------------------
resource "google_compute_health_check" "main" {
    project  = var.project
    name     = "${var.project_name}-hc"

    check_interval_sec  = try(var.health_check_config.check_interval_sec, 30)
    unhealthy_threshold = try(var.health_check_config.unhealthy_threshold, 2)
    timeout_sec         = try(var.health_check_config.timeout_sec, 1)

    http_health_check {
      port              = try(var.health_check_config.http_health_check_port, "80")
      request_path      = try(var.health_check_config.request_path, "/")
    }
}
#-----------------------------------
# Regional instance group manager
#-----------------------------------
resource "google_compute_instance_group_manager" "main" {
    name               = "${var.project_name}-rmig"
    base_instance_name = "${var.project_name}-base-cigm"
    zone               = "${var.region}-${var.zone}"
    target_size        = 1

    dynamic "named_port" {
        for_each = var.instance_group_manager_port

        content {
            name = named_port.value.name
            port = named_port.value.port
        }
    }

    auto_healing_policies {
        health_check      = google_compute_health_check.main.id
        initial_delay_sec = try(var.health_check_config.healing_policies_initial_delay_sec, 300)
    }

    version {
        instance_template = google_compute_instance_template.main.id
    }
}
#-----------------------------------
# Instance template
#-----------------------------------
resource "google_compute_instance_template" "main" {
    name_prefix          = try(var.compute_instance_template.name_prefix, "tpl-")
    description          = try(var.compute_instance_template.description, "description template")
    project              = var.project
    tags                 = var.tags
    instance_description = try(var.compute_instance_template.desc_inst, "description instance")
    machine_type         = var.machine_type
    can_ip_forward       = false // Whether to allow sending and receiving of packets with non-matching source or destination IPs. This defaults to false.

    scheduling {
        automatic_restart   = true
        on_host_maintenance = "MIGRATE"
    }

    // Create a new boot disk from an image (Lets use one created by Packer)
    disk {
        source_image = var.source_image
        auto_delete  = true
        boot         = true
    }

    metadata_startup_script = file(var.startup_script)

    network_interface {
        network = var.network
    }

    service_account {
        scopes = ["userinfo-email", "compute-ro", "storage-ro"]
    }

    lifecycle {
        create_before_destroy = true
    }
    depends_on = [google_compute_router_nat.nat]
}
#-----------------------------------
# AutoScaler
#-----------------------------------
resource "google_compute_autoscaler" "main" {
    name   = "${var.project_name}-config-autoscaler"
    zone   = "${var.region}-${var.zone}"
    target = google_compute_instance_group_manager.main.id

    autoscaling_policy {
        min_replicas    = try(var.compute_autoscaler.min_replicas, 1)
        max_replicas    = try(var.compute_autoscaler.max_replicas, 2)
        cooldown_period = try(var.compute_autoscaler.cooldown_period, 60)

        cpu_utilization {
        target = try(var.compute_autoscaler.cpu_utilization, 0.6)
        }
    }
}
#-----------------------------------
# Firewall
#-----------------------------------
resource "google_compute_firewall" "main" {
    for_each    = local.compute_firewall_map

    project     = var.project
    name        = "${var.network}-${each.value.name}"
    network     = var.network

    allow {
        protocol = each.value.protocol
        ports    = each.value.ports
    }
}
#-----------------------------------
# Static IP
#-----------------------------------
resource "google_compute_address" "static" {
  name    = "${var.project_name}-ip-address"
  region  = var.region
}
#-----------------------------------
# Global IP
#-----------------------------------
resource "google_compute_global_address" "default" {
  name = "${var.project_name}-ip-global"
}
#-----------------------------------
# VPC
#-----------------------------------
data "google_compute_network" "network" {
  name    = var.network
  project = var.project
}
#-----------------------------------
# Cloud Routers
#-----------------------------------
resource "google_compute_router" "router" {
  name    = "${var.project_name}-router"
  region  = var.region
  network = data.google_compute_network.network.id
}
#-----------------------------------
# NAT
#-----------------------------------
resource "google_compute_router_nat" "nat" {
  name   = "${var.project_name}-nat-router"
  router = google_compute_router.router.name
  region = google_compute_router.router.region

  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.static.*.self_link

  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
#-----------------------------------
# DNS
#-----------------------------------
data "google_dns_managed_zone" "main" {
  name = var.project_name
}
#-----------------------------------
# Record Set
#-----------------------------------
resource "google_dns_record_set" "main" {
  name         = "*.${data.google_dns_managed_zone.main.dns_name}"
  type         = "A"
  ttl          = 30
  managed_zone = data.google_dns_managed_zone.main.name
  rrdatas      = [google_compute_global_forwarding_rule.https.ip_address]
}
#-----------------------------------
# HTTPS Forwarding rule
#-----------------------------------
resource "google_compute_global_forwarding_rule" "https" {
  project    = var.project
  name       = "${var.project_name}-https"
  target     = google_compute_target_https_proxy.main.id
  ip_address = google_compute_global_address.default.address
  port_range = "443"
}
#-----------------------------------
# HTTPS Proxy
#-----------------------------------
resource "google_compute_target_https_proxy" "main" {
  project = var.project
  name    = "${var.project_name}-https-proxy"
  url_map = google_compute_url_map.main.id
  ssl_certificates = [google_compute_ssl_certificate.main.id]
  ssl_policy       = null
}
#-----------------------------------
# URL Map
#-----------------------------------
resource "google_compute_url_map" "main" {
  name            = "${var.project_name}-url-map-target-proxy"
  default_service = google_compute_backend_service.main.id

  host_rule {
    hosts        = ["*.${var.domain_name}"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.main.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.main.id
    }
  }
}
#-----------------------------------
# HTTP TO HTTPS
#-----------------------------------
resource "google_compute_url_map" "http-redirect" {
  name = "${var.project_name}-http-redirect-https"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"  // 301 redirect
    strip_query            = false
    https_redirect         = true  // this is the magic
  }
}

resource "google_compute_target_http_proxy" "http-redirect" {
  name    = "http-redirect"
  url_map = google_compute_url_map.http-redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http-redirect" {
  name       = "${var.project_name}-http-redirect"
  target     = google_compute_target_http_proxy.http-redirect.self_link
  ip_address = google_compute_global_address.default.address
  port_range = "80"
}