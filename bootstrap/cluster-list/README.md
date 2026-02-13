# Cluster list (metadata only)

The YAML files in this directory are **not** deployed to any cluster. They are used only by the cluster-bootstrap ApplicationSet to decide which clusters get bootstrap Applications and to supply `name` and `server` for each.

- Add a cluster: create `<name>.yaml` here with `name` and `server`, and add manifests under `bootstrap/clusters/<name>/`.
- The cluster-bootstrap appset depends only on the `bootstrap/` directory.
