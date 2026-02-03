---
name: kustomize-gitops
description: |
  Kustomize + ArgoCD GitOps 最佳實踐指南。使用此 skill 當：
  - 設計 Kustomize 目錄結構 (base/overlays)
  - 使用 patches、configMapGenerator、secretGenerator
  - 配置 ArgoCD Application 使用 Kustomize source
  - 配置 Image Updater 自動更新鏡像
  - 理解 GitOps 工作流中 Kustomize 的角色
  觸發詞：kustomize, gitops, argocd kustomize, image updater, overlay, patches
---

# Kustomize + GitOps 最佳實踐

## 快速決策樹

```
用戶需求
    │
    ├─ "設計目錄結構" ─────→ 見「Base/Overlays 結構」
    │
    ├─ "覆蓋配置" ──────────→ 見「Patches 三種方式」
    │
    ├─ "生成 ConfigMap" ───→ 見「Generators」
    │
    ├─ "鏡像版本管理" ─────→ 見「Images Transformer」
    │
    ├─ "ArgoCD 整合" ──────→ 參考 references/argocd-integration.md
    │
    └─ "鏡像自動更新" ─────→ 參考 references/image-updater.md
```

---

## 1. Base/Overlays 標準結構

```
project/
├── base/                    # 通用配置（所有環境共用）
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── configmap.yaml
│
├── components/              # 可選功能模塊（按需引入）
│   ├── monitoring/
│   │   ├── kustomization.yaml
│   │   └── servicemonitor.yaml
│   └── security/
│       ├── kustomization.yaml
│       └── networkpolicy.yaml
│
└── overlays/                # 環境覆蓋
    ├── development/
    │   ├── kustomization.yaml
    │   └── patches/
    ├── staging/
    │   ├── kustomization.yaml
    │   └── patches/
    └── production/
        ├── kustomization.yaml
        └── patches/
```

### 核心原則

| 原則 | 說明 |
|------|------|
| Base 只放通用配置 | 不含任何環境特定值 |
| Overlay 定義差異 | 通過 patches 和 generators |
| 無 if-else 邏輯 | 結構即配置 |
| 單一數據源 | 每個值只在一處定義 |

### Base kustomization.yaml 範例

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml

commonLabels:
  app.kubernetes.io/managed-by: kustomize
```

### Overlay kustomization.yaml 範例

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

namespace: myapp-production

commonLabels:
  environment: production

patches:
  - path: patches/deployment.yaml

images:
  - name: myapp
    newName: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp
    digest: sha256:abc123...

configMapGenerator:
  - name: app-config
    behavior: merge
    literals:
      - LOG_LEVEL=warn
```

---

## 2. Patches 三種方式

### 對比表

| 類型 | 適用場景 | 語法複雜度 |
|------|----------|------------|
| Strategic Merge Patch | 合併式修改（最常用） | 低 |
| JSON 6902 Patch | 精確操作（刪除、替換） | 中 |
| Inline Patch | 簡單修改 | 最低 |

### Strategic Merge Patch（推薦）

最直觀的方式，像寫 YAML 覆蓋一樣：

```yaml
# patches/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp  # 必須匹配 base 中的 name
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: myapp  # 必須匹配容器 name
          resources:
            limits:
              memory: 512Mi
              cpu: 500m
```

在 kustomization.yaml 中引用：

```yaml
patches:
  - path: patches/deployment.yaml
```

### JSON 6902 Patch

用於精確操作（刪除欄位、條件替換）：

```yaml
# patches/remove-probes.yaml
- op: remove
  path: /spec/template/spec/containers/0/livenessProbe
- op: remove
  path: /spec/template/spec/containers/0/readinessProbe
```

在 kustomization.yaml 中引用（需要 target）：

```yaml
patches:
  - path: patches/remove-probes.yaml
    target:
      kind: Deployment
      name: myapp
```

### Inline Patch

簡單修改直接寫在 kustomization.yaml：

```yaml
patches:
  - patch: |-
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: myapp
      spec:
        replicas: 5
```

或用 JSON 6902 語法：

```yaml
patches:
  - target:
      kind: Deployment
      name: myapp
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 5
```

---

## 3. Generators

### configMapGenerator

```yaml
configMapGenerator:
  # 從 literals
  - name: app-config
    literals:
      - DB_HOST=postgres.svc.cluster.local
      - LOG_LEVEL=info
    options:
      disableNameSuffixHash: false  # 預設 false，自動加 hash

  # 從文件
  - name: nginx-config
    files:
      - nginx.conf
      - configs/app.json

  # 從 env 文件
  - name: env-config
    envs:
      - .env.production
```

### secretGenerator

```yaml
secretGenerator:
  - name: db-credentials
    type: Opaque
    literals:
      - username=admin
      - password=supersecret

  - name: tls-cert
    type: kubernetes.io/tls
    files:
      - tls.crt
      - tls.key
```

### Hash Suffix 機制

預設 Kustomize 會在 ConfigMap/Secret 名稱後加 hash（如 `app-config-8h2c9`）。

**優點**：ConfigMap 變更時自動觸發 Pod 重啟
**停用**：設定 `disableNameSuffixHash: true`（不推薦）

---

## 4. Images Transformer

### 基本用法

```yaml
images:
  # 更換 registry 和 tag
  - name: nginx
    newName: my-registry.com/nginx
    newTag: "1.21.0"

  # 使用 digest（生產環境推薦）
  - name: myapp
    newName: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp
    digest: sha256:abc123def456...
```

### 黃金規則

`name` 必須與 deployment.yaml 中的 image 完全匹配：

```yaml
# deployment.yaml
containers:
  - name: myapp
    image: myapp:latest  # ← images.name 必須是 "myapp"

# kustomization.yaml
images:
  - name: myapp          # ✅ 匹配
    newName: ecr.../myapp
    newTag: v1.0.0
```

**常見錯誤**：

```yaml
# deployment.yaml
image: my-registry.com/myapp:latest

# kustomization.yaml - 錯誤！
images:
  - name: myapp  # ❌ 不匹配，應該是 my-registry.com/myapp
```

---

## 5. Components（可選功能模塊）

用於跨環境共享的可選功能：

```yaml
# components/monitoring/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - servicemonitor.yaml

patches:
  - patch: |-
      - op: add
        path: /metadata/annotations/prometheus.io~1scrape
        value: "true"
    target:
      kind: Deployment
```

在 overlay 中引用：

```yaml
# overlays/production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base

components:
  - ../../components/monitoring
  - ../../components/security
```

---

## 6. 常見問題速查

| 症狀 | 原因 | 解決 |
|------|------|------|
| ConfigMap 變更但 Pod 沒重啟 | `disableNameSuffixHash: true` | 移除此選項，讓 hash 生效 |
| Patch 不生效 | target 不匹配 | 檢查 name/kind/apiVersion |
| Image 沒替換 | name 不匹配 | 確保與 deployment 中 image 完全一致 |
| 資源重複 | resources 重複引用 | 檢查 base 和 overlay 的 resources |
| Namespace 沒套用 | 資源已有 namespace | 使用 patch 覆蓋或移除原有 namespace |

---

## 7. 驗證命令

```bash
# 預覽生成的 YAML
kustomize build overlays/production

# 預覽並檢查特定資源
kustomize build overlays/production | kubectl diff -f -

# 驗證語法
kustomize build overlays/production > /dev/null && echo "Valid"

# 查看 images 替換結果
kustomize build overlays/production | grep "image:"
```

---

## 延伸閱讀

- [ArgoCD 整合](references/argocd-integration.md) - Application 配置、Sync Waves
- [Image Updater](references/image-updater.md) - 自動鏡像更新、故障排查
- [進階 Kustomize 模式](references/kustomize-patterns.md) - 多目標 patch、大型項目結構
