# Single-repo example: clusters from Git

This folder implements an improved layout compared to `single-repo-example-git-generator`:

1. **Cluster list from Git** — Adding a cluster = adding a directory and a small manifest (`clusters/<name>/cluster.yaml`). No ApplicationSet list edit.
2. **Centralized repo URL/revision** — The repo URL and target revision for generated Applications are defined in one place in the ApplicationSet template (see below). The app-of-apps has its own `repoURL`/`targetRevision` for bootstrapping.
3. **Split ApplicationSets** — Main workload apps use `all-components-appset.yaml`; optional `cluster-bootstrap-appset.yaml` is for cluster bootstrap with a different project/sync policy. See `apps/appsets/README.md` for per-team or per-concern splits.

## Behavior

- **Clusters:** Each `clusters/<name>/cluster.yaml` defines a cluster. The file must contain at least `server` (cluster API URL); optional `name` defaults to the directory name.
- **Components per cluster:** Directories under `clusters/<name>/*` (e.g. `clusters/cluster1/headlamp/`, `clusters/cluster1/gen-dashboard/`) are the components deployed on that cluster. Each should contain at least a `values.yaml` for Helm overrides.
- **Example:** cluster1 has `headlamp/` and `gen-dashboard/`; cluster2 has only `gen-dashboard/`; cluster3 has both. Same as the git-generator example, but the cluster list comes from Git.

## How to use

1. **Set Git repo URL**  
   - In `apps/app-of-apps.yaml`: set `spec.source.repoURL` (and `targetRevision` if needed) for the bootstrap Application.  
   - In `apps/appsets/all-components-appset.yaml`: set `repoURL` and `revision` in both Git generator blocks, and the same `repoURL`/`targetRevision` in the template’s three source blocks. This is the single place for generated Applications.  
   - In `apps/appsets/cluster-bootstrap-appset.yaml` (if used): set `repoURL` and `revision` in the generator and in the template source.

2. **Bootstrap**  
   Apply the app-of-apps Application once (e.g. `kubectl apply -f apps/app-of-apps.yaml` or via your GitOps flow). It syncs all ApplicationSets from `apps/appsets/`.

3. **Add a cluster**  
   - Create `clusters/<newName>/cluster.yaml` with `name` and `server`.  
   - Create `clusters/<newName>/<component>/values.yaml` for each component you want on that cluster.  
   No change to any ApplicationSet YAML.

4. **Add or remove a component on a cluster**  
   Add or remove the directory `clusters/<cluster>/<component>/` (e.g. add a `values.yaml`). No ApplicationSet edit.

## Optional: cluster bootstrap

The ApplicationSet `cluster-bootstrap-appset.yaml` creates one Application per cluster, pointing at `bootstrap/clusters/<name>/`. Use it for namespaces, RBAC, or other bootstrap resources. You can set a different `project` and `syncPolicy` than for workload apps. Add manifests under `bootstrap/clusters/<name>/` as needed. See `apps/appsets/README.md` for details.

## Repo URL and revision

- **App-of-apps:** Uses its own `repoURL` and `targetRevision` in `apps/app-of-apps.yaml` (one place for bootstrap).
- **Generated Applications:** All use the repo URL and target revision defined in the template of `apps/appsets/all-components-appset.yaml`. Change them in the template’s source blocks (and in the Git generator blocks so the ApplicationSet controller can read the repo). Argo CD ApplicationSet matrix supports only two child generators, so the cluster list and component list are driven by Git; the repo for generated apps is kept in the template as the single place to update.

## Directory layout

```
apps/
  app-of-apps.yaml
  appsets/
    all-components-appset.yaml
    cluster-bootstrap-appset.yaml   # optional
    README.md
bootstrap/
  clusters/
    <name>/                         # optional bootstrap manifests
clusters/
  <name>/
    cluster.yaml                    # required: name, server
    <component>/
      values.yaml
components/
  <component>/                      # Helm chart
```

Replace `https://git.example.com/org/gitops-repo.git` with your repo URL in the files above.
