# ArgoCD + Kustomize 整合指南

## 1. Application 使用 Kustomize Source

### 基本配置

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/k8s-config.git
    targetRevision: main
    path: overlays/production  # 指向 kustomization.yaml 所在目錄
  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Kustomize 選項

在 Application 中覆蓋 Kustomize 配置：

```yaml
spec:
  source:
    path: overlays/production
    kustomize:
      # 覆蓋 images（常用於 Image Updater）
      images:
        - myapp=123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp@sha256:abc123

      # 添加 namePrefix
      namePrefix: prod-

      # 添加 commonLabels
      commonLabels:
        app.kubernetes.io/instance: myapp-prod

      # 添加 commonAnnotations
      commonAnnotations:
        team: platform

      # 覆蓋 replicas
      replicas:
        - name: myapp
          count: 5
```

---

## 2. App-of-Apps 模式

### 根 Application

```yaml
# k8s/argocd/app-of-apps.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/k8s-config.git
    targetRevision: main
    path: k8s/applications  # 包含所有子 Application
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 子 Application 結構

```
k8s/applications/
├── kustomization.yaml
├── myapp-a.yaml
├── myapp-b.yaml
└── myapp-c.yaml
```

```yaml
# k8s/applications/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - myapp-a.yaml
  - myapp-b.yaml
  - myapp-c.yaml
```

---

## 3. ApplicationSet + Git Generator

自動從目錄結構生成 Application：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: apps
  namespace: argocd
spec:
  generators:
    - git:
        repoURL: https://github.com/org/k8s-config.git
        revision: main
        directories:
          - path: overlays/production/*  # 每個子目錄生成一個 Application

  template:
    metadata:
      name: '{{path.basename}}'  # 目錄名作為 Application 名
    spec:
      project: default
      source:
        repoURL: https://github.com/org/k8s-config.git
        targetRevision: main
        path: '{{path}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: '{{path.basename}}'
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

### 目錄結構範例

```
overlays/production/
├── myapp-a/
│   └── kustomization.yaml  → 生成 Application: myapp-a
├── myapp-b/
│   └── kustomization.yaml  → 生成 Application: myapp-b
└── myapp-c/
    └── kustomization.yaml  → 生成 Application: myapp-c
```

---

## 4. Sync Waves

控制資源部署順序：

```yaml
# 在資源中添加 annotation
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"  # 數字越小越先部署
```

### 常見順序

| Wave | 資源類型 |
|------|----------|
| -5 | Namespace, CRD |
| -3 | PersistentVolumeClaim |
| 0 | ConfigMap, Secret |
| 1 | Service |
| 2 | Deployment, StatefulSet |
| 5 | Job, CronJob |
| 10 | Ingress |

### 在 Kustomize 中應用

```yaml
# base/kustomization.yaml
commonAnnotations:
  argocd.argoproj.io/sync-wave: "0"

# 或用 patch 單獨設定
patches:
  - patch: |-
      - op: add
        path: /metadata/annotations/argocd.argoproj.io~1sync-wave
        value: "-1"
    target:
      kind: ConfigMap
```

**注意**：annotation 中的 `/` 需要轉義為 `~1`。

---

## 5. Sync Options

### 常用選項

```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true       # 自動創建 namespace
    - PrunePropagationPolicy=foreground  # 刪除時等待子資源
    - ApplyOutOfSyncOnly=true    # 只同步變更的資源
    - ServerSideApply=true       # 使用 server-side apply
    - RespectIgnoreDifferences=true  # 尊重 ignoreDifferences
```

### Ignore Differences

忽略某些欄位的差異（避免無限 sync loop）：

```yaml
spec:
  ignoreDifferences:
    - group: apps
      kind: Deployment
      jsonPointers:
        - /spec/replicas  # 忽略 HPA 管理的 replicas

    - group: ""
      kind: Service
      jqPathExpressions:
        - .spec.clusterIP  # 忽略自動分配的 ClusterIP
```

---

## 6. 多 Source Application

從多個來源組合：

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  sources:
    # Source 1: Helm chart
    - repoURL: https://charts.bitnami.com/bitnami
      chart: nginx
      targetRevision: 13.2.0
      helm:
        valueFiles:
          - $values/overlays/production/values.yaml

    # Source 2: 自定義配置（提供 values 文件）
    - repoURL: https://github.com/org/k8s-config.git
      targetRevision: main
      ref: values  # 引用名稱

  destination:
    server: https://kubernetes.default.svc
    namespace: myapp
```

---

## 7. Finalizer 保護

防止意外刪除時清空 namespace：

```yaml
metadata:
  finalizers:
    - resources-finalizer.argocd.argoproj.io
```

移除 finalizer 允許刪除 Application 但保留資源：

```yaml
metadata:
  finalizers: []  # 空數組
```

---

## 8. 常見問題

### Application 狀態一直 OutOfSync

1. 檢查 `ignoreDifferences` 是否需要添加
2. 檢查是否有其他控制器修改資源（如 HPA 修改 replicas）
3. 檢查資源是否有 immutable 欄位

### Kustomize 變更沒有同步

1. 確認 `targetRevision` 是否正確
2. 檢查 ArgoCD 是否有讀取 repo 的權限
3. 手動刷新：`argocd app refresh myapp`

### 資源順序問題

使用 Sync Waves 控制順序，確保依賴資源先部署。
