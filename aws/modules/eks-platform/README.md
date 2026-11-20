# EKS platform module

This module installs Kubernetes platform components into an existing EKS
cluster using Helm. The cluster infrastructure is managed separately by the
`eks-cluster` module; this module reads its Terraform Cloud state and uses the
Helm provider configured by the root caller.

## Add-on controls and versions

Each add-on has an `enabled` switch and an optional Helm chart `version`.
Metrics Server, NGINX Ingress, cert-manager, and Argo CD remain enabled by
default to preserve existing behavior. Istio is disabled by default. When
`version` is omitted or `null`, Helm installs the latest chart available from
that chart's repository at install time. To pin the installation version, set
it explicitly:

```hcl
addons = {
  metrics_server = {
    enabled = true
  }
  nginx_ingress = {
    enabled = true
  }
  cert_manager = {
    enabled = true
  }
  argocd = {
    enabled = true
  }
  istio = {
    enabled   = true
    version   = "1.32.0"
    namespace = "istio-system"
  }
}
```

For any add-on, set `version` to an available version from that chart's
repository to pin the initial installation; the example pins Istio.

The available entries are `metrics_server`, `nginx_ingress`, `cert_manager`,
`argocd`, and `istio`. Istio is installed as two Helm releases (`base` and
`istiod`) that share one version and enablement setting.

For every release, Terraform ignores changes to the chart `version` after
installation. This means an upgrade performed outside Terraform is not rolled
back by a later plan/apply, and changing the configured version alone will not
upgrade an existing release. The configured version selects the version for a
new installation; if omitted, the chart repository's latest version is selected.
Manage subsequent upgrades using your established Helm upgrade process, or
explicitly plan a controlled release replacement. Terraform still manages the
other chart settings and the enabled/disabled state.

Disabling an add-on uninstalls its Helm release and may interrupt workloads or
services that depend on it. Review the plan before disabling. Istio CRDs are
retained on uninstall; keep them while Istio custom resources exist.

## Istio service mesh

When `addons.istio.enabled` is true, the module installs the Istio `base` chart
first, which provides the Istio custom resource definitions, then installs
`istiod`, the mesh control plane. Both charts use the same selected version.
The root caller's Helm identity must
be authorized for the cluster and allowed to install cluster-scoped CRDs and
Istio resources. This is Kubernetes authorization in addition to the AWS
permissions used to obtain the EKS token.

Keep Istio disabled while initially creating a new EKS cluster. After the
cluster is ready and the platform workspace has cluster access, enable Istio
in a later apply.

Installing Istio does not automatically enroll application workloads. To opt
in an application namespace, label it `istio-injection=enabled` and roll its
Pods so the admission webhook can inject an Envoy sidecar. Do this deliberately
for the namespaces containing `s3-app-backend` and `s3-app-frontend`; each
Pod will then use additional CPU and memory. No application code changes are
normally required, but restrictive mTLS policies, ingress routing, health
probes, and resource requests may need adjustment. This module does not manage
application namespace labels or install an Istio ingress gateway.

Istio provides consistent service-to-service encryption, traffic management
(for example retries and canary routing), and service-level telemetry. It also
adds network hops and operational overhead, so enable it when those capabilities
are useful for the workloads.

Helm does not remove CRDs installed by a chart on uninstall; retain them while
any Istio custom resources exist. See the [Istio Helm guide](https://istio.io/latest/docs/setup/install/helm/)
and [supported releases](https://istio.io/latest/docs/releases/supported-releases/)
for installation, upgrade, and compatibility details.
