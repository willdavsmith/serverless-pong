terraform {
  required_version = ">= 1.5"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.37.1"
    }
  }
}

variable "context" {
  description = "This variable contains Radius recipe context."
  type        = any
}

# --- Deployment ---
resource "kubernetes_deployment" "deployment" {

  metadata {
    name = context.resource.name
    labels = {
      app = context.application.name
    }
  }

  spec {
    selector {
      match_labels = {
        app = context.application.name
      }
    }

    template {
      metadata {
        labels = {
          app = context.application.name
        }
      }

      spec {
        container {
          name  = context.resource.name
          image = context.resource.properties.image

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# --- Service ---
resource "kubernetes_service" "service" {
  metadata {
    name = context.resource.name
  }

  spec {
    selector = {
      app = context.resource.name
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# --- Outputs ---
output "result" {
  value = {
    resources = [
        "/planes/kubernetes/local/namespaces/${kubernetes_service.service.metadata.namespace}/providers/core/Service/${kubernetes_service.metadata.name}",
        "/planes/kubernetes/local/namespaces/${kubernetes_deployment.service.deployment.namespace}/providers/apps/Deployment/${kubernetes_deployment.deployment.metadata.name}"
    ]
    values = {
      url = "local"
    }
  }
}