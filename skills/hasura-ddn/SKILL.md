---
name: hasura-ddn
description: |
  Hasura DDN v3 supergraph 開發完整工作流程指南。使用此 skill 當：
  - 需要配置 AuthConfig（webhook/JWT/noAuth 認證）
  - 新增或管理 Models、Commands、Relationships
  - Introspect OpenAPI 或 MySQL connectors
  - 建置和部署 supergraph
  - 解決 HML metadata 錯誤
---

# Hasura DDN 工作流程指南

## 快速決策樹

```
用戶需求
    │
    ├─ "新增 relationship" ──→ 參考 references/relationships.md
    │
    ├─ "配置認證" ──────────→ 參考 references/auth-config.md
    │
    ├─ "Introspect connector" → 參考 references/connectors.md
    │
    ├─ "新增 model/command" ─→ 參考 references/commands.md
    │
    ├─ "Schema 變更後更新" ──→ 見下方「Schema 變更工作流程」
    │
    └─ "部署/建置問題" ─────→ 見下方「建置與部署」
```

---

## 核心概念

### Supergraph 結構

```
project/
├── supergraph.yaml          # 根配置
├── globals/                 # 全域配置（AuthConfig 等）
│   └── metadata/
│       └── auth-config.hml
├── app/                     # 主 subgraph
│   ├── subgraph.yaml
│   ├── metadata/            # HML 文件
│   │   ├── *.hml           # Models, Commands, Types
│   │   └── *Relationships.hml
│   └── connector/
│       ├── openapi_connector/
│       │   ├── connector.yaml
│       │   └── swagger.json
│       └── mysql_connector/
│           └── connector.yaml
└── engine/                  # 本地 engine 配置
```

### HML 文件類型

| Kind | 用途 | 來源 |
|------|------|------|
| `ObjectType` | 數據類型定義 | 自動生成 |
| `Model` | GraphQL queries | `ddn model add` |
| `Command` | GraphQL mutations | `ddn command add` |
| `Relationship` | 類型間關聯 | **手動編寫** |
| `TypePermissions` | 字段權限 | 自動生成，可編輯 |
| `CommandPermissions` | 執行權限 | 自動生成，可編輯 |
| `AuthConfig` | 認證配置 | **手動編寫** |

---

## 常用工作流程

### 1. 新增 Backend API Endpoint

當 backend 新增 REST endpoint 時：

```bash
# 1. 更新 swagger.json（複製或編輯）

# 2. Introspect（重新生成 TypeScript）
ddn connector introspect <api_connector>

# 3. 新增 commands
ddn command add <api_connector> "*"

# 4. 建置驗證
ddn supergraph build local

# 5. 重啟服務
docker compose down && ddn run docker-start
```

### 2. 新增 Relationship

Relationships 需要**手動編寫** HML。

**Object Relationship** (Many-to-One)：
```yaml
kind: Relationship
version: v1
definition:
  name: author              # GraphQL 字段名
  sourceType: Post
  target:
    model:
      name: Author
      relationshipType: Object
  mapping:
    - source:
        fieldPath:
          - fieldName: authorId
      target:
        modelField:
          - fieldName: id
```

**Array Relationship** (One-to-Many)：
```yaml
kind: Relationship
version: v1
definition:
  name: posts               # GraphQL 字段名（複數）
  sourceType: Author
  target:
    model:
      name: Post
      relationshipType: Array
  mapping:
    - source:
        fieldPath:
          - fieldName: id
      target:
        modelField:
          - fieldName: authorId
```

詳見 `references/relationships.md`。

### 3. Schema 變更工作流程

**MySQL 數據庫變更後**：
```bash
# 移除舊 models
ddn model remove User
ddn model remove Post
# ...

# 重新 introspect
ddn connector introspect <db_connector>

# 重新新增
ddn model add <db_connector> "*"

# 驗證
ddn supergraph build local
```

### 4. 配置認證

**Webhook 認證**（推薦）：
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
```

**多重認證模式**：
```yaml
kind: AuthConfig
version: v4
definition:
  mode:
    webhook: { ... }
  alternativeModes:
    - identifier: "codegen"
      config:
        noAuth:
          role: admin
          sessionVariables: {}
```

詳見 `references/auth-config.md`。

---

## 建置與部署

### 本地開發

```bash
# 建置 supergraph
ddn supergraph build local

# 啟動服務
ddn run docker-start

# 訪問
# - GraphQL: http://localhost:3280/graphql
# - Console: http://localhost:3280/console
```

### 雲端部署

```bash
# 建置並部署到 DDN Cloud
ddn supergraph build create
```

### CI/CD 模式

```bash
# 用於自動化流程
ddn supergraph build local --ci
```

---

## 常見錯誤處理

### "unknown target column name xxx"

metadata 引用了不存在的欄位。

**解決**：
```bash
ddn connector introspect <connector>
ddn model add <connector> "*"
```

### "file already exists"

**解決**：設置環境變數
```bash
APP_<API_CONNECTOR>_NDC_OAS_FILE_OVERWRITE="true"
```

### Response 類型顯示為 `Json!`

swagger.json 缺少 response schema。

**解決**：在 swagger.json 中添加明確的 schema 定義：
```json
"responses": {
  "200": {
    "content": {
      "application/json": {
        "schema": {
          "type": "object",
          "properties": { ... }
        }
      }
    }
  }
}
```

### Connector 連接失敗

1. 檢查 `docker compose ps`
2. 驗證 `.env` 中的 `BASE_URL`（無末尾斜線）
3. 查看日誌：`docker compose logs -f app-<connector>-1`

---

## 環境變數速查

```bash
# OpenAPI Connector
APP_<API_CONNECTOR>_NDC_OAS_BASE_URL="https://api.example.com"  # 無末尾斜線！
APP_<API_CONNECTOR>_NDC_OAS_FILE_OVERWRITE="true"
APP_<API_CONNECTOR>_HASURA_SERVICE_TOKEN_SECRET="secret"
APP_<API_CONNECTOR>_AUTHORIZATION_HEADER="Bearer secret"

# MySQL Connector
APP_<DB_CONNECTOR>_JDBC_URL="jdbc:mysql://host:3306/db?user=u&password=p"

# Auth
HASURA_AUTH_WEBHOOK_URL="https://api.example.com/hasura/auth"
```

---

## 參考資料

- `references/auth-config.md` - AuthConfig 完整配置指南
- `references/relationships.md` - Relationship HML 格式和範例
- `references/connectors.md` - Connector introspect 和配置
- `references/commands.md` - DDN CLI 常用命令
