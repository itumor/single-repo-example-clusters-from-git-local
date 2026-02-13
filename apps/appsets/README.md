# ApplicationSets in this repo

## all-components-appset.yaml

**Purpose:** Generates one Argo CD Application per (cluster, component) pair. Which components run where is driven by the filesystem:

- **Cluster list:** From Git. Each directory `clusters/<name>/` that contains a `cluster.yaml` file is a cluster. The file must define `server` (cluster API URL) and optionally `name`.
- **Component list per cluster:** Directories under `clusters/<name>/*` (e.g. `clusters/cluster1/headlamp/`, `clusters/cluster1/gen-dashboard/`) are the components to deploy on that cluster.

**Add a cluster:** Create `clusters/<name>/cluster.yaml` with `name` and `server`, then add `clusters/<name>/<component>/` (with at least a `values.yaml`) for each component. No change to the ApplicationSet YAML.

**Repo URL:** The repo URL and target revision for generated Applications are set in the template of this file. Change them in the three `sources`/`source` blocks (and in the two Git generator blocks if the ApplicationSet controller must read from a different repo).

---

## cluster-bootstrap-appset.yaml (optional)

**Purpose:** One Application per cluster for bootstrap resources (e.g. namespaces, RBAC, cluster-scoped resources). Uses the same cluster list from Git (`clusters/*/cluster.yaml`).

**When to use:** When you want bootstrap resources to have a different Argo CD project and/or sync policy than workload apps (e.g. `project: cluster-admin`, manual sync).

**How to enable:** Keep this file under `apps/appsets/` so the app-of-apps syncs it. Add manifests under `bootstrap/clusters/<name>/` (e.g. Kustomize or plain YAML). Empty directories are valid; add resources when needed.

**Customization:** Edit the ApplicationSet to set `spec.template.spec.project` to a different project and/or change `syncPolicy` (e.g. remove `automated` for manual sync).

---

## Splitting ApplicationSets by concern

### By team

To give a team its own set of apps with a different Argo CD project:

1. Copy the matrix pattern from `all-components-appset.yaml` into a new file (e.g. `team-a-appset.yaml`).
2. Set `metadata.name` to something unique (e.g. `team-a-components`).
3. Set `spec.template.spec.project` to the team’s project (e.g. `team-a`).
4. Optionally restrict which components are included (e.g. use a different Git path or a directory layout like `components/team-a-*` and point the Git directory generator there).

The same cluster list (Git file generator on `clusters/*/cluster.yaml`) and repo can be reused.

### By sync policy

To use a different sync policy (e.g. manual approval) for a subset of apps:

- Duplicate the ApplicationSet and change only `spec.template.spec.syncPolicy` (e.g. remove `automated` or set `automated: false`).
- Optionally restrict clusters or components via generator paths or a separate ApplicationSet that targets a different path.

### Summary

| ApplicationSet              | Use case                          |
|----------------------------|-----------------------------------|
| all-components             | Main workload apps (all clusters) |
| cluster-bootstrap          | Optional bootstrap per cluster    |
| (your) team-a-appset       | Per-team apps, different project  |
