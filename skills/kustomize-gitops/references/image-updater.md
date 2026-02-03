# ArgoCD Image Updater 配置指南

## 1. 核心概念

ArgoCD Image Updater 監控容器鏡像 registry，自動更新 Application 中的鏡像版本。

### 工作流程

```
1. Image Updater 輪詢 ECR/DockerHub
2. 發現新鏡像（tag 或 digest）
3. 更新 Application 的 kustomize.images
4. ArgoCD 檢測變更，執行 sync
5. Pod 使用新鏡像重啟
```

### 兩種模式

| 模式 | 說明 | 適用場景 |
|------|------|----------|
| `argocd` | 直接更新 Application annotation | 快速驗證 |
| `git` | 提交到 Git 倉庫 | **生產推薦** |

---

## 2. ImageUpdater CRD 配置

### 基本配置（git 模式）

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ImageUpdater
metadata:
  name: myapp
  namespace: argocd
spec:
  application:
    name: myapp
    namespace: argocd

  gitCommit:
    author:
      name: ArgoCD Image Updater
      email: image-updater@argocd.io
    message: "chore: update image to {{.NewImage}}"

  images:
    - alias: myapp
      imageName: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp
      updateStrategy: digest
      allowTags: /^latest$/
      manifestTargets:
        kustomize:
          name: myapp  # ⚠️ 黃金三角：必須與 deployment 中的 image name 匹配
```

### 黃金三角規則

```
                    Deployment.yaml
                    image: myapp:latest
                           ↑
                           │ 必須匹配
                           │
    ImageUpdater ─────────────────────→ Kustomize
    manifestTargets.                   images:
    kustomize.name: myapp              - name: myapp
```

**三者必須一致**：
1. `deployment.yaml` 中的 `image: <name>:tag`
2. `ImageUpdater` 的 `manifestTargets.kustomize.name`
3. `kustomization.yaml` 的 `images[].name`

---

## 3. Update Strategy

### digest（生產推薦）

```yaml
images:
  - alias: myapp
    imageName: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp
    updateStrategy: digest
    allowTags: /^latest$/  # 監控 latest tag 的 digest 變化
```

生成的 `.argocd-source-myapp.yaml`：

```yaml
kustomize:
  images:
    - myapp=123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp@sha256:abc123...
```

### semver

```yaml
images:
  - alias: myapp
    imageName: my-registry.com/myapp
    updateStrategy: semver
    constraints: ">=1.0.0 <2.0.0"  # 只更新 1.x 版本
```

### latest

```yaml
images:
  - alias: myapp
    imageName: my-registry.com/myapp
    updateStrategy: latest
    allowTags: /^v[0-9]+\.[0-9]+\.[0-9]+$/  # 只匹配 v1.2.3 格式
```

---

## 4. 多鏡像應用

```yaml
images:
  - alias: frontend
    imageName: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp-frontend
    updateStrategy: digest
    allowTags: /^latest$/
    manifestTargets:
      kustomize:
        name: frontend

  - alias: backend
    imageName: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp-backend
    updateStrategy: digest
    allowTags: /^latest$/
    manifestTargets:
      kustomize:
        name: backend
```

對應 `deployment.yaml`：

```yaml
containers:
  - name: frontend
    image: frontend:latest

  - name: backend
    image: backend:latest
```

---

## 5. ECR 認證配置

### 創建 ECR Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ecr-credentials
  namespace: argocd
type: Opaque
stringData:
  creds: |
    registries:
      - name: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com
        api_url: https://123456789.dkr.ecr.ap-northeast-1.amazonaws.com
        credentials: ext:/scripts/ecr-login.sh
        default: true
        ping: false
```

### ECR Login Script

```bash
#!/bin/sh
# /scripts/ecr-login.sh
aws ecr get-login-password --region ap-northeast-1
```

### 使用 IRSA（推薦）

```yaml
# ServiceAccount for Image Updater
apiVersion: v1
kind: ServiceAccount
metadata:
  name: argocd-image-updater
  namespace: argocd
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/argocd-image-updater
```

---

## 6. Git 認證配置

### SSH Key

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: git-creds
  namespace: argocd
type: Opaque
stringData:
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
```

### GitHub App

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: github-app-creds
  namespace: argocd
type: Opaque
stringData:
  githubAppID: "123456"
  githubAppInstallationID: "12345678"
  githubAppPrivateKey: |
    -----BEGIN RSA PRIVATE KEY-----
    ...
    -----END RSA PRIVATE KEY-----
```

---

## 7. 生成的文件格式

Image Updater 在 git 模式下會創建 `.argocd-source-<app-name>.yaml`：

### 正確格式

```yaml
# .argocd-source-myapp.yaml
kustomize:
  images:
    - myapp=123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp@sha256:abc123def456
```

### 常見錯誤格式

```yaml
# ❌ 錯誤：缺少 kustomize.name 導致格式錯誤
kustomize:
  images:
    - 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp@sha256:abc123def456

# ❌ 錯誤：完整 URL 作為 name
kustomize:
  images:
    - 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp=123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp@sha256:abc123
```

---

## 8. 故障排查

### 檢查 Image Updater 日誌

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-image-updater --tail=100
```

### 常見問題

| 症狀 | 原因 | 解決 |
|------|------|------|
| 鏡像沒更新 | ECR 認證失敗 | 檢查 IRSA 和 Secret |
| Git push 失敗 | SSH key 無效 | 檢查 deploy key 權限 |
| `.argocd-source` 格式錯誤 | 缺少 `manifestTargets.kustomize.name` | 添加正確的 name 配置 |
| Application OutOfSync 但不更新 | `allowTags` 不匹配 | 檢查 regex 是否正確 |
| Deployment 沒重啟 | Kustomize images.name 不匹配 | 確保黃金三角一致 |

### 驗證 ECR 認證

```bash
# 在 Image Updater Pod 中測試
kubectl exec -it -n argocd deploy/argocd-image-updater -- \
  argocd-image-updater test \
  123456789.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:latest
```

### 手動觸發更新

```bash
kubectl annotate imageupdater -n argocd myapp \
  argocd-image-updater.argoproj.io/force-update=true
```

---

## 9. 完整配置範例

### ImageUpdater CRD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ImageUpdater
metadata:
  name: shih-chuan-web
  namespace: argocd
spec:
  application:
    name: shih-chuan-web
    namespace: argocd

  gitCommit:
    author:
      name: ArgoCD Image Updater
      email: image-updater@argocd.io
    message: "chore(shih-chuan-web): update image to {{.NewImage}}"
    branch: main

  images:
    - alias: shih-chuan-web
      imageName: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/shih-chuan-web
      updateStrategy: digest
      allowTags: /^latest$/
      manifestTargets:
        kustomize:
          name: shih-chuan-web
```

### 對應的 deployment.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shih-chuan-web
spec:
  template:
    spec:
      containers:
        - name: shih-chuan-web
          image: shih-chuan-web:latest  # ← name 必須與 ImageUpdater 的 kustomize.name 匹配
```

### 對應的 kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml

images:
  - name: shih-chuan-web  # ← 與 deployment 中的 image name 匹配
    newName: 123456789.dkr.ecr.ap-northeast-1.amazonaws.com/shih-chuan-web
    newTag: latest
```
