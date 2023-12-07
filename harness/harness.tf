provider "harness" {
  endpoint         = "https://app.harness.io/gateway"
  account_id       = var.accountid
  platform_api_key = var.apikey
}



resource "harness_platform_gitops_cluster" "gitopscluster" {

  identifier = var.agentname
  account_id = var.accountid 
  project_id = "CANVA"
  org_id     = "default"
  agent_id   = var.agentname

  request {
    upsert = false

    cluster {
      server = "https://kubernetes.default.svc"
      name   = var.agentname

      config {
        tls_client_config {
          insecure = true
        }
        cluster_connection_type = "IN_CLUSTER"
      }
    }
  }

  lifecycle {
    ignore_changes = [
      request.0.upsert,
      request.0.cluster.0.config.0.bearer_token,
    ]
  }
}

resource "harness_platform_gitops_repository" "gitrepo" {
  depends_on = [
    harness_platform_gitops_cluster.gitopscluster
  ]

  identifier = "gitrepo"
  project_id = "CANVA"
  org_id     = "default"
  agent_id   = var.agentname
  account_id = var.accountid

  repo {
    repo            = "https://github.com/argoproj/argocd-example-apps"
    name            = "gitrepo"
    insecure        = true
    connection_type = "HTTPS_ANONYMOUS"
  }

  upsert = true
}

resource "harness_platform_gitops_applications" "gitopsapplication" {
  depends_on = [
    harness_platform_gitops_repository.gitrepo
  ]

  application {
    metadata {
      annotations = {}
      labels = {
        "harness.io/serviceRef" = "guestbook"
        "harness.io/envRef"     = "dev"
      }
      name = "guestbook"
    }

    spec {
      sync_policy {
        sync_options = [
          "PrunePropagationPolicy=undefined",
          "CreateNamespace=false",
          "Validate=false",
          "skipSchemaValidations=false",
          "autoCreateNamespace=false",
          "pruneLast=false",
          "applyOutofSyncOnly=false",
          "Replace=false",
          "retry=false"
        ]

      }

      source {
        target_revision = "master"
        repo_url        = "https://github.com/argoproj/argocd-example-apps"
        path            = "helm-guestbook"

        helm {
          value_files = ["values.yaml"]
        }
      }

      destination {
        namespace = "default"
        server    = "https://kubernetes.default.svc"
      }
    }
  }

  name       = "guestbook"
  project_id = "CANVA"
  org_id     = "default"
  cluster_id  = var.agentname
  repo_id     = "gitrepo"
  agent_id    = var.agentname
  account_id = var.accountid
}
