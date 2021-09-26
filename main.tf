terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "host" { type = string }
variable "client_certificate" { type = string }
variable "client_key" { type = string }
variable "cluster_ca_certificate" { type = string }
variable "k8s_insecure" { type = bool }
variable "rstudio_password" { type = string }

provider "kubernetes" {
  host = var.host

  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

  insecure = var.k8s_insecure
}

##########################################################################################
# Persistent Volumes
##########################################################################################
resource "kubernetes_persistent_volume" "rstudio" {
  metadata {
    name = "rstudio-pv"
  }
  spec {
    capacity = {
      storage = "20Gi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      local {
        path = "/run/desktop/mnt/host/d/Kubernetes/RStudio/"
      }
    }
    storage_class_name = "manual"
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key = "kubernetes.io/hostname"
            operator = "In"
            values = ["docker-desktop"]
          }
        }
      }
    }
  }
}

##########################################################################################
# Persistent Volume Claims
##########################################################################################
resource "kubernetes_persistent_volume_claim" "rstudio" {
  metadata {
    name = "rstudio-pvc"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "20Gi"
      }
    }
    volume_name = "${kubernetes_persistent_volume.rstudio.metadata.0.name}"
    storage_class_name = "manual"
  }
}

##########################################################################################
# Kubernetes Deployments
##########################################################################################
resource "kubernetes_deployment" "rstudio" {
  metadata {
    name = "rstudio"
    labels = {
      App = "RStudio"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        App = "RStudio"
      }
    }
    template {
      metadata {
        labels = {
          App = "RStudio"
        }
      }
      spec {
        container {
          image = "rocker/rstudio"
          name  = "rstudio"

          port {
            container_port = 8787
          }
          volume_mount {
            mount_path = "/home/rstudio"
            name = "rstudio-home"
          }

          env {
            name = "PASSWORD"
            value = var.rstudio_password
          }
        }
        volume {
          name = "rstudio-home"
          persistent_volume_claim {
            claim_name = "${kubernetes_persistent_volume_claim.rstudio.metadata.0.name}"
          }
        }
      }
    }
  }
}

##########################################################################################
# Kubernetes Services
##########################################################################################
resource "kubernetes_service" "rstudio" {
  metadata {
    name = "rstudio"
  }
  spec {
    selector = {
      App = kubernetes_deployment.rstudio.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 8787
      target_port = 8787
      node_port = 30001
    }
    type = "NodePort"
  }
}
