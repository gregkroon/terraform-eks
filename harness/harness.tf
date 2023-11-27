terraform {
  required_providers {
    harness = {
      source = "harness/harness"
    }
  }
}



provider "harness" {
  endpoint         = "https://app.harness.io/gateway"
  account_id       = var.accountid
  platform_api_key = var.apikey
}

resource "harness_platform_gitops_agent" "gitopseks" {
  identifier = "gitopseks"
  account_id = "Ke-E1FX2SO2ZAL2TXqpLjg"
  project_id = "CANVA"
  org_id     = "default"
  name       = "gitopseks"
  type       = "MANAGED_ARGO_PROVIDER"
  metadata {
    namespace         = "default"
    high_availability = true
  }
}

resource "harness_platform_gitops_cluster" "gitopscluster" {


  identifier = "argocluster"
  account_id = "Ke-E1FX2SO2ZAL2TXqpLjg"
  project_id = "CANVA"
  org_id     = "default"
  agent_id   = "gitopseks"


  request {
    upsert = false
    cluster {
      server = "https://kubernetes.default.svc"
      name   = "argocluster"
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
      request.0.upsert, request.0.cluster.0.config.0.bearer_token,
    ]
  }
}


resource "harness_platform_gitops_repository" "gitrepo" {

  depends_on = [
    harness_platform_gitops_cluster.gitopscluster
  ]
  identifier = "gitrepo"
  account_id = "Ke-E1FX2SO2ZAL2TXqpLjg"
  project_id = "CANVA"
  org_id     = "default"
  agent_id   = "gitopseks"
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
  account_id = "Ke-E1FX2SO2ZAL2TXqpLjg"
  cluster_id  = "argocluster"
  repo_id     = "gitrepo"
  agent_id    = "gitopseks"
}


