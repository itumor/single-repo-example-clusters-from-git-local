# GitOps Strategy Diagrams — Clusters-from-Git

This document uses a **multi-layered** approach to visualize the relationship between the **Git folder structure**, **ApplicationSet logic**, and **physical clusters** in the Clusters-from-Git strategy.

---

## 1. The Strategy: "The Matrix Generator"

In the Clusters-from-Git model we use a **Matrix Generator**. This is a two-dimensional grid:

| Axis | Meaning | Driven by |
|------|---------|-----------|
| **Where** | Cluster | Git file generator over `clusters/*/cluster.yaml` |
| **What** | Component | Git directory generator over `clusters/{{.clusterPath.basename}}/*` |

- **Cluster list:** Git file generator over `clusters/*/cluster.yaml` — each file defines `name` and `server`.
- **Component list:** Git directory generator over `clusters/{{.clusterPath.basename}}/*` — directories under each cluster = components to deploy.
- **Matrix:** Git (cluster.yaml files) × Git (directories per cluster). No cluster or component list is hard-coded in the ApplicationSet YAML.
- **Optional:** A separate `cluster-bootstrap-appset.yaml` for bootstrap (namespaces, RBAC) with its own sync policy.

---

## 2. Repository Structure (The "Drawing" Blueprint)

Directory tree that drives the GitOps flow in this repo:

```text
.
├── apps/
│   ├── app-of-apps.yaml              ← Bootstrap: syncs all ApplicationSets
│   └── appsets/
│       ├── all-components-appset.yaml   ← Matrix: (cluster × component) → Applications
│       ├── cluster-bootstrap-appset.yaml ← Optional: one Application per cluster (bootstrap)
│       └── README.md
├── bootstrap/
│   └── clusters/
│       ├── cluster1/                    ← Bootstrap manifests for cluster1
│       ├── cluster2/
│       └── cluster3/
├── clusters/
│   ├── cluster1/
│   │   ├── cluster.yaml                 ← (name: cluster1, server: https://...)
│   │   ├── gen-dashboard/               ← Component 1 (values.yaml)
│   │   └── headlamp/                    ← Component 2 (values.yaml)
│   ├── cluster2/
│   │   ├── cluster.yaml
│   │   └── gen-dashboard/
│   └── cluster3/
│       ├── cluster.yaml
│       ├── gen-dashboard/
│       └── headlamp/
└── components/
    ├── gen-dashboard/                   ← Helm chart (shared)
    │   ├── Chart.yaml
    │   └── templates/
    └── headlamp/
        ├── Chart.yaml
        └── templates/
```

**Flow in words:** The ApplicationSet reads `clusters/*/cluster.yaml` to get the cluster list, then for each cluster reads `clusters/<name>/*` to get the component list. It generates one Argo CD Application per (cluster, component) pair, deploying the shared chart from `components/<component>` with overrides from `clusters/<name>/<component>/values.yaml`.

---

## 3. ApplicationSet Logic (Central "Brain")

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     ApplicationSet: all-components                          │
│                         (Matrix Generator)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  Generator 1 (Git file)          Generator 2 (Git directory)                │
│  path: clusters/*/cluster.yaml   path: clusters/{{.clusterPath.basename}}/*  │
│  → cluster1, cluster2, cluster3  → per cluster: gen-dashboard, headlamp…   │
│                                                                             │
│  Matrix = (cluster1×gen-dashboard), (cluster1×headlamp),                    │
│           (cluster2×gen-dashboard), (cluster3×gen-dashboard),                │
│           (cluster3×headlamp)  → 5 Applications (example)                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

Optional bootstrap ApplicationSet:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     ApplicationSet: cluster-bootstrap                        │
│                     (Git file generator only)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  path: clusters/*/cluster.yaml  →  one Application per cluster              │
│  destination: bootstrap/clusters/{{.clusterPath.basename}}                  │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Pros & Cons (Comparison Table)

| Strategy Aspect   | Status     | Why |
|-------------------|------------|-----|
| **Scalability**   | ✅ **High** | Adding a cluster = adding a folder + `cluster.yaml`; no YAML edits in Argo CD. |
| **Drift detection** | ✅ **Direct** | Changes in Git are reflected via the Git generator. |
| **Single source of truth** | ✅ **Git** | Cluster list and component-per-cluster list both live in the repo. |
| **Complexity**    | ⚠️ **Medium** | Debugging matrix (cluster × component) logic can be harder than simple lists. |
| **Security**      | 🛡️ **Strong** | RBAC can be applied at the folder level in the Git repo. |

---

## 5. High-Level Flow (Mermaid)

**Git → ApplicationSet (Matrix) → Clusters**

```mermaid
graph LR
    subgraph Git_Repository["Git Repository"]
        A1[clusters/cluster1/cluster.yaml]
        A2[clusters/cluster2/cluster.yaml]
        A3[clusters/cluster3/cluster.yaml]
        B1[clusters/cluster1/gen-dashboard]
        B2[clusters/cluster1/headlamp]
        B3[clusters/cluster2/gen-dashboard]
        B4[clusters/cluster3/gen-dashboard]
        B5[clusters/cluster3/headlamp]
    end

    subgraph ArgoCD["Argo CD"]
        D{ApplicationSet<br/>Matrix Generator}
    end

    subgraph Target_Clusters["Target Clusters"]
        E[cluster1]
        F[cluster2]
        G[cluster3]
    end

    A1 --> D
    A2 --> D
    A3 --> D
    B1 --> D
    B2 --> D
    B3 --> D
    B4 --> D
    B5 --> D
    D -- "gen-dashboard, headlamp" --> E
    D -- "gen-dashboard" --> F
    D -- "gen-dashboard, headlamp" --> G
```

---

## 6. Full Bootstrap Layer (App-of-Apps → ApplicationSets → Clusters)

```mermaid
graph TB
    subgraph Git["Git Repository"]
        APP[apps/app-of-apps.yaml]
        ASETS[apps/appsets/]
        CL[clusters/*/cluster.yaml]
        COMP[clusters/*/component dirs]
        BOOT[bootstrap/clusters/*]
    end

    subgraph ArgoCD["Argo CD"]
        AOA[App-of-Apps<br/>Application]
        AS1[ApplicationSet:<br/>all-components]
        AS2[ApplicationSet:<br/>cluster-bootstrap]
    end

    subgraph Generated["Generated Applications"]
        APPS[gen-dashboard-cluster1, headlamp-cluster1,<br/>gen-dashboard-cluster2, ...]
        BOOT_APPS[bootstrap-cluster1,<br/>bootstrap-cluster2,<br/>bootstrap-cluster3]
    end

    subgraph Clusters["Physical Clusters"]
        C1[cluster1]
        C2[cluster2]
        C3[cluster3]
    end

    APP --> AOA
    ASETS --> AOA
    AOA --> AS1
    AOA --> AS2
    CL --> AS1
    COMP --> AS1
    AS1 --> APPS
    CL --> AS2
    BOOT --> AS2
    AS2 --> BOOT_APPS
    APPS --> C1
    APPS --> C2
    APPS --> C3
    BOOT_APPS --> C1
    BOOT_APPS --> C2
    BOOT_APPS --> C3
```

---

## 7. Matrix Generator Detail (Two Generators)

```mermaid
flowchart LR
    subgraph Gen1["Generator 1: Git file"]
        F1[cluster1/cluster.yaml]
        F2[cluster2/cluster.yaml]
        F3[cluster3/cluster.yaml]
    end

    subgraph Gen2["Generator 2: Git directory"]
        D1[cluster1/gen-dashboard]
        D2[cluster1/headlamp]
        D3[cluster2/gen-dashboard]
        D4[cluster3/gen-dashboard]
        D5[cluster3/headlamp]
    end

    subgraph Matrix["Matrix"]
        M[cluster × component]
    end

    subgraph Apps["Generated Applications"]
        A1[gen-dashboard-cluster1]
        A2[headlamp-cluster1]
        A3[gen-dashboard-cluster2]
        A4[gen-dashboard-cluster3]
        A5[headlamp-cluster3]
    end

    F1 --> M
    F2 --> M
    F3 --> M
    D1 --> M
    D2 --> M
    D3 --> M
    D4 --> M
    D5 --> M
    M --> A1
    M --> A2
    M --> A3
    M --> A4
    M --> A5
```

---

## 8. Prompt for External Diagram Tools

Use this prompt with a Mermaid-compatible or diagram tool (e.g. GPT-based visualizer) for a professional architecture diagram:

> **Prompt:** "Create a technical architecture diagram for an Argo CD GitOps workflow using the Clusters-from-Git strategy. On the left, show a Git repository with a folder structure: `clusters/cluster1/cluster.yaml`, `clusters/cluster1/gen-dashboard/`, `clusters/cluster1/headlamp/`, and similar for cluster2 and cluster3. In the center, show an 'Argo CD ApplicationSet' using a Matrix Generator (Git file generator on `clusters/*/cluster.yaml` and Git directory generator on `clusters/<name>/*`). On the right, show three Kubernetes clusters (cluster1, cluster2, cluster3). Draw arrows: (1) from the Git tree to the ApplicationSet (discovery), (2) from the ApplicationSet to each cluster (deploy). Optionally add a top layer: one 'App-of-Apps' Application syncing `apps/appsets/`, which contains the ApplicationSet manifests and an optional cluster-bootstrap ApplicationSet. Use a clean style: blue for Git, orange for Argo CD, green for clusters."

---

## 9. Summary

| Layer            | What it is |
|------------------|------------|
| **Git folder**   | `clusters/<name>/cluster.yaml` + `clusters/<name>/<component>/` define where and what. |
| **ApplicationSet** | Matrix Generator: cluster list from Git files, component list from Git directories; no hard-coded cluster or component list. |
| **Physical clusters** | Target `server` from each `cluster.yaml`; one Application per (cluster, component) for workloads; optional one Application per cluster for bootstrap. |

Adding a cluster = add `clusters/<name>/cluster.yaml` and `clusters/<name>/<component>/` (e.g. `values.yaml`). No change to ApplicationSet YAML.
