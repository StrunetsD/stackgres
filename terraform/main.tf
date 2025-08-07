provider "kubernetes" {
  config_path = "~/.kube/config"
}


locals {

  cluster_prereq_files = [
    "../backup.yaml",
    "../pgconfig.yaml",
    "../poolconfig.yaml",
    "../secret.yaml"
  ]
}


resource "helm_release" "stackgres_operator" {
  name             = "stackgres-operator"
  repository       = "https://stackgres.io/helm" 
  chart            = "stackgres-operator"
  version          = "1.17.0" 
  namespace        = "stackgres" 
  create_namespace = true
  values           = [file("../stackgres-operator/values.yaml")]
}

resource "kubernetes_manifest" "cluster_configs" {

  for_each = toset(local.cluster_prereq_files)

  manifest = yamldecode(file(each.value))

 
  depends_on = [helm_release.stackgres_operator]
}

resource "kubernetes_manifest" "postgres_cluster" {
  manifest = yamldecode(file("../postgres.yaml"))

  
  depends_on = [kubernetes_manifest.cluster_configs]
}