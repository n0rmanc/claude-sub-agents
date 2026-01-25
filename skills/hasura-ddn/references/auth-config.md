# AuthConfig 認證配置指南

## 概述

AuthConfig 定義 Hasura DDN 如何驗證和授權 GraphQL 請求。支援三種主要認證模式：
- **Webhook** - 外部服務驗證（推薦用於生產環境）
- **JWT** - JSON Web Token 驗證
- **noAuth** - 無認證（僅用於開發/測試）

## HML 結構

```yaml
kind: AuthConfig
version: v4
definition:
  mode:
    # 選擇以下其一：webhook / jwt / noAuth
  alternativeModes:  # 可選：支援多重認證模式
```

---

## 認證模式詳解

### 1. Webhook 認證（推薦）

外部 HTTP 服務驗證請求並返回 session variables。

```yaml
kind: AuthConfig
version: v4
definition:
  mode:
    webhook:
      url:
        valueFromEnv: HASURA_AUTH_WEBHOOK_URL
      method: GET  # 或 POST
      customHeadersConfig:
        headers:
          forward:
            - Authorization      # 轉發客戶端 header 到 webhook
            - X-Custom-Header
          additional:
            user-agent: hasura-ddn  # 添加固定 header
```

**Webhook 響應格式**：
```json
{
  "X-Hasura-User-Id": "123",
  "X-Hasura-Role": "user",
  "X-Hasura-Organization-Id": "456"
}
```

**環境變數**：
```bash
HASURA_AUTH_WEBHOOK_URL=https://your-backend.com/api/hasura/auth
```

### 2. JWT 認證

驗證 JWT token 並從 claims 提取 session variables。

```yaml
kind: AuthConfig
version: v4
definition:
  mode:
    jwt:
      tokenLocation:
        header:
          name: Authorization
          prefix: "Bearer "
      key:
        # 方式 1: 固定密鑰
        fixed:
          algorithm: HS256
          key:
            valueFromEnv: HASURA_JWT_SECRET

        # 方式 2: JWKs URL（推薦）
        jwkFromUrl: https://your-auth.com/.well-known/jwks.json
      claimsConfig:
        namespace:
          claimsFormat: Json
          location: /https:~1~1hasura.io~1jwt~1claims
      claimsMappings:
        sessionVariableMappings:
          x-hasura-user-id: $.user_id
          x-hasura-role: $.role
```

**JWT Claims 結構範例**：
```json
{
  "https://hasura.io/jwt/claims": {
    "x-hasura-user-id": "123",
    "x-hasura-role": "user",
    "x-hasura-default-role": "user",
    "x-hasura-allowed-roles": ["user", "admin"]
  }
}
```

### 3. NoAuth 模式

無需認證，直接指派角色。**僅用於開發環境**。

```yaml
kind: AuthConfig
version: v4
definition:
  mode:
    noAuth:
      role: admin
      sessionVariables:
        x-hasura-user-id: "1"
        x-hasura-organization-id: "1"
```

---

## 多重認證模式 (alternativeModes)

支援在單一 supergraph 中使用多種認證方式。

### 使用場景
- **主模式 (mode)**: 生產環境 Webhook 認證
- **備選模式 (alternativeModes)**: 開發工具用 noAuth

```yaml
kind: AuthConfig
version: v4
definition:
  mode:
    webhook:
      url:
        valueFromEnv: HASURA_AUTH_WEBHOOK_URL
      method: GET
      customHeadersConfig:
        headers:
          forward:
            - Authorization
          additional:
            user-agent: hasura-ddn

  alternativeModes:
    - identifier: "codegen"
      config:
        noAuth:
          role: admin
          sessionVariables: {}

    - identifier: "api-key"
      config:
        jwt:
          tokenLocation:
            header:
              name: X-API-Key
              prefix: ""
          key:
            fixed:
              algorithm: HS256
              key:
                valueFromEnv: HASURA_API_KEY_SECRET
```

### 切換認證模式

在 GraphQL 請求中使用 `x-hasura-auth-mode` header：

```bash
# 使用主模式（默認）
curl -H "Authorization: Bearer <jwt>" ...

# 使用 codegen 模式
curl -H "x-hasura-auth-mode: codegen" ...

# 使用 api-key 模式
curl -H "x-hasura-auth-mode: api-key" -H "X-API-Key: <key>" ...
```

---

## 文件組織

### 本地與雲端配置分離

```
globals/
└── metadata/
    ├── auth-config.local.hml   # 本地開發（含 alternativeModes）
    └── auth-config.cloud.hml   # 雲端生產（僅 webhook）
```

**supergraph.yaml 配置**：
```yaml
# 本地開發
include:
  - path: globals

# 雲端部署
include:
  - path: globals
    exclude:
      - "**/auth-config.local.hml"
```

---

## 常見問題

### Q: 如何支援 anonymous 用戶？

在 Webhook 返回未認證時指定默認角色：

```json
{
  "X-Hasura-Role": "anonymous"
}
```

然後在 HML 中為 anonymous 角色配置權限：

```yaml
kind: TypePermissions
version: v1
definition:
  typeName: PostApiAuthLoginCreateOutput
  permissions:
    - role: admin
      output:
        allowedFields: [accessToken, refreshToken, success]
    - role: anonymous
      output:
        allowedFields: [accessToken, refreshToken, success]
```

### Q: Engine 和 Connector 之間的認證如何工作？

Engine 使用 `HASURA_SERVICE_TOKEN_SECRET` 與 Connector 通信：

```yaml
# connector.yaml
envMapping:
  HASURA_SERVICE_TOKEN_SECRET:
    fromEnv: APP_<API_CONNECTOR>_HASURA_SERVICE_TOKEN_SECRET

# <api_connector>.hml (DataConnectorLink)
headers:
  Authorization:
    valueFromEnv: APP_<API_CONNECTOR>_AUTHORIZATION_HEADER
    # 值為 "Bearer <HASURA_SERVICE_TOKEN_SECRET>"
```

**重要**：不要在 `argumentPresets` 中使用 `httpHeaders.forward: [Authorization]`，這會覆蓋服務認證 token。

### Q: 如何傳遞用戶身份到 Backend API？

使用不同的 header 名稱：

```yaml
argumentPresets:
  - argument: headers
    value:
      httpHeaders:
        forward:
          - X-User-Token  # 用不同名稱傳遞用戶 JWT
        additional: {}
```

或使用 Hasura session variables（推薦）：
- `x-hasura-user-id`
- `x-hasura-role`
- `x-hasura-organization-id`
