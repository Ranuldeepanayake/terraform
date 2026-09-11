resource "kubernetes_manifest" "ebs_sc" {
  manifest = {
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"

    metadata = {
      name = "ebs-sc"
    }

    provisioner       = "ebs.csi.aws.com"
    volumeBindingMode = "WaitForFirstConsumer"

    allowVolumeExpansion = true

    parameters = {
      type       = "gp3"
      iops       = "3000"
      throughput = "125"
    }

    reclaimPolicy = "Delete"
  }

  depends_on = [
    data.terraform_remote_state.eks_platform
  ]
}