# 進階 Kustomize 模式

## 1. 多目標 Patch

對多個資源應用同一個 patch：

```yaml
patches:
  - patch: |-
      - op: add
        path: /metadata/labels/team
        value: platform
    target:
      kind: Deployment
      # 不指定 name，套用到所有 Deployment

  - patch: |-
      - op: add
        path: /spec/template/spec/tolerations
        value:
          - key: "dedicated"
            operator: "Equal"
            value: "myproject"
            effect: "NoSchedule"
    target:
      kind: Deployment
      labelSelector: "app.kubernetes.io/component=web"
```

### Target 選擇器

| 欄位 | 說明 | 範例 |
|------|------|------|
| `kind` | 資源類型 | `Deployment`, `Service` |
| `name` | 資源名稱（支持正則） | `myapp`, `.*-web` |
| `namespace` | 命名空間 | `production` |
| `group` | API group | `apps`, `networking.k8s.io` |
| `version` | API version | `v1`, `v1beta1` |
| `labelSelector` | 標籤選擇 | `app=myapp` |
| `annotationSelector` | 註解選擇 | `team=platform` |

---

## 2. 命名規範

### namePrefix 和 nameSuffix

```yaml
namePrefix: prod-
nameSuffix: -v2

# myapp → prod-myapp-v2
```

### commonLabels 和 commonAnnotations

```yaml
commonLabels:
  app.kubernetes.io/part-of: myplatform
  app.kubernetes.io/managed-by: kustomize
  environment: production

commonAnnotations:
  team: platform
  oncall: platform-oncall@company.com
```

**注意**：`commonLabels` 會自動加到 selector，可能影響現有 Deployment。如果只想加 labels 不影響 selector，用 patch。

---

## 3. 資源排序

Kustomize 默認按 Kind 排序輸出。自定義排序：

```yaml
sortOptions:
  order: fifo  # 按文件順序
  # 或 legacy（按 Kind 排序）
```

---

## 4. 變數替換（vars - 已廢棄）

> **警告**：vars 已被廢棄，使用 replacements 替代。

### Replacements（推薦）

```yaml
replacements:
  - source:
      kind: Service
      name: myapp
      fieldPath: metadata.name
    targets:
      - select:
          kind: Deployment
          name: myapp
        fieldPaths:
          - spec.template.spec.containers.[name=myapp].env.[name=SERVICE_NAME].value
```

---

## 5. 大型項目結構

### 多應用 Monorepo

```
k8s/
├── base/
│   ├── common/              # 跨應用共用
│   │   ├── namespace.yaml
│   │   └── networkpolicy.yaml
│   ├── app-a/
│   │   ├── kustomization.yaml
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── app-b/
│       └── ...
│
├── components/
│   ├── istio-sidecar/
│   ├── prometheus-annotations/
│   └── resource-limits/
│
└── overlays/
    ├── development/
    │   ├── kustomization.yaml  # 引用所有 base
    │   ├── app-a/
    │   └── app-b/
    ├── staging/
    └── production/
```

### Overlay kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/common
  - app-a
  - app-b

# 每個 app 子目錄有自己的 kustomization.yaml
# overlays/production/app-a/kustomization.yaml
```

---

## 6. Helm Chart 整合

Kustomize 可以對 Helm 輸出做 post-processing：

```yaml
helmCharts:
  - name: nginx-ingress
    repo: https://kubernetes.github.io/ingress-nginx
    version: 4.0.0
    releaseName: nginx
    namespace: ingress
    valuesFile: values.yaml

# 然後可以用 patches 修改 Helm 輸出
patches:
  - patch: |-
      - op: add
        path: /metadata/annotations/custom
        value: "true"
    target:
      kind: Deployment
      name: nginx-ingress-controller
```

---

## 7. 最佳實踐 Checklist

### 結構設計

- [ ] Base 只包含環境無關的配置
- [ ] 每個 overlay 只定義環境差異
- [ ] Components 用於可選功能
- [ ] 避免深層嵌套（最多 base → overlay）

### Patches

- [ ] 優先使用 Strategic Merge Patch
- [ ] JSON 6902 只用於刪除或精確操作
- [ ] Patch 文件命名清晰（如 `deployment-resources.yaml`）

### 命名

- [ ] 使用 namePrefix/nameSuffix 區分環境
- [ ] commonLabels 包含必要的識別標籤
- [ ] 避免 commonLabels 破壞 selector

### 安全

- [ ] Secrets 不直接存在 Git（用 External Secrets）
- [ ] 敏感配置用 secretGenerator + 外部 secrets 管理

### 維護

- [ ] 定期執行 `kustomize build` 驗證
- [ ] 使用 CI 檢查 kustomization 語法
- [ ] 文檔化每個 component 的用途

---

## 8. 常見反模式

### ❌ 在 base 放環境特定配置

```yaml
# base/deployment.yaml - 錯誤
spec:
  replicas: 3  # 這是生產配置，不應在 base
```

### ❌ Overlay 重複 base 內容

```yaml
# overlays/prod/deployment.yaml - 錯誤
# 完整複製 base 的 deployment 再修改
```

應該只用 patch 修改差異。

### ❌ 過度使用 Components

Components 適合可選功能，不適合環境差異。環境差異用 overlay。

### ❌ 忽略 hash suffix

```yaml
configMapGenerator:
  - name: config
    options:
      disableNameSuffixHash: true  # 危險！ConfigMap 變更不會觸發 Pod 重啟
```
