# Connector 操作指南

## 概述

Hasura DDN Connectors 是連接外部數據源的橋樑。主要類型：

- **OpenAPI Connector** - 連接 REST APIs
- **MySQL/PostgreSQL Connector** - 連接關係型數據庫
- **MongoDB Connector** - 連接 NoSQL 數據庫

---

## 目錄結構

```
app/
├── connector/
│   ├── <api_connector>/          # OpenAPI connector
│   │   ├── connector.yaml         # Connector 配置
│   │   ├── swagger.json           # OpenAPI spec（真實來源）
│   │   ├── api.ts                 # 生成的 TypeScript API client
│   │   └── functions.ts           # 生成的 connector functions
│   │
│   └── <db_connector>/            # MySQL connector
│       └── connector.yaml
│
└── metadata/
    ├── <api_connector>.hml       # DataConnectorLink + schema
    ├── <api_connector>-types.hml # ObjectTypes from connector
    ├── <db_connector>.hml         # DataConnectorLink
    └── <db_connector>-types.hml   # ObjectTypes from connector
```

---

## OpenAPI Connector

### connector.yaml 配置

```yaml
kind: Connector
version: v2
definition:
  name: <api_connector>
  subgraph: app
  source: hasura/openapi:v1.7.1    # Connector 版本
  context: .
  envMapping:
    HASURA_CONNECTOR_PORT:
      fromEnv: APP_<API_CONNECTOR>_HASURA_CONNECTOR_PORT
    HASURA_SERVICE_TOKEN_SECRET:
      fromEnv: APP_<API_CONNECTOR>_HASURA_SERVICE_TOKEN_SECRET
    NDC_OAS_BASE_URL:
      fromEnv: APP_<API_CONNECTOR>_NDC_OAS_BASE_URL
    NDC_OAS_DOCUMENT_URI:
      fromEnv: APP_<API_CONNECTOR>_NDC_OAS_DOCUMENT_URI
    NDC_OAS_FILE_OVERWRITE:
      fromEnv: APP_<API_CONNECTOR>_NDC_OAS_FILE_OVERWRITE
    NDC_OAS_LAMBDA_PRETTY_LOGS:
      fromEnv: APP_<API_CONNECTOR>_NDC_OAS_LAMBDA_PRETTY_LOGS
    OTEL_EXPORTER_OTLP_ENDPOINT:
      fromEnv: APP_<API_CONNECTOR>_OTEL_EXPORTER_OTLP_ENDPOINT
```

### 環境變數

```bash
# .env
APP_<API_CONNECTOR>_NDC_OAS_BASE_URL="https://your-backend.com"  # 注意：無末尾斜線！
APP_<API_CONNECTOR>_NDC_OAS_DOCUMENT_URI="./swagger.json"
APP_<API_CONNECTOR>_NDC_OAS_FILE_OVERWRITE="true"    # 開發時啟用
APP_<API_CONNECTOR>_NDC_OAS_LAMBDA_PRETTY_LOGS="true"
APP_<API_CONNECTOR>_HASURA_SERVICE_TOKEN_SECRET="your-secret"
APP_<API_CONNECTOR>_AUTHORIZATION_HEADER="Bearer your-secret"
```

**重要**：`BASE_URL` 不能有末尾斜線，否則會產生雙斜線 (`//api/...`)。

### swagger.json 最佳實踐

#### 1. 定義明確的 Response Schema

避免生成 `Json!` 類型：

```json
{
  "paths": {
    "/api/auth/login": {
      "post": {
        "responses": {
          "200": {
            "description": "Login successful",
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "success": { "type": "boolean" },
                    "accessToken": { "type": "string" },
                    "refreshToken": { "type": "string" }
                  },
                  "required": ["success", "accessToken", "refreshToken"]
                }
              }
            }
          }
        }
      }
    }
  }
}
```

#### 2. 提取共享類型到 components

避免重複的內聯類型定義：

```json
{
  "components": {
    "schemas": {
      "FileListItem": {
        "type": "object",
        "properties": {
          "id": { "type": "integer" },
          "fileName": { "type": "string" },
          "type": { "type": "string" }
        },
        "required": ["id", "fileName", "type"]
      }
    }
  },
  "paths": {
    "/api/file/list": {
      "post": {
        "responses": {
          "200": {
            "content": {
              "application/json": {
                "schema": {
                  "type": "object",
                  "properties": {
                    "files": {
                      "type": "array",
                      "items": { "$ref": "#/components/schemas/FileListItem" }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```

#### 3. 公開 Endpoints 配置

對不需要認證的 endpoints，覆蓋全域 security：

```json
{
  "security": [{ "bearerAuth": [] }],  // 全域認證
  "paths": {
    "/api/auth/register": {
      "post": {
        "security": [],  // 覆蓋：無需認證
        "description": "Public registration endpoint"
      }
    },
    "/api/auth/login": {
      "post": {
        "security": []  // 覆蓋：無需認證
      }
    }
  }
}
```

### Introspect 工作流程

```bash
# 1. 確保環境變數正確設置
export APP_<API_CONNECTOR>_NDC_OAS_FILE_OVERWRITE="true"

# 2. 更新 swagger.json（如有變更）

# 3. Introspect（重新生成 api.ts, functions.ts）
ddn connector introspect <api_connector>

# 4. 新增/更新 commands
ddn command add <api_connector> "*"

# 5. 新增/更新 models（如果有 GET endpoints）
ddn model add <api_connector> "*"

# 6. 建置驗證
ddn supergraph build local
```

---

## MySQL Connector

### connector.yaml 配置

```yaml
kind: Connector
version: v2
definition:
  name: <db_connector>
  subgraph: app
  source: hasura/mysql:v1.1.0
  context: .
  envMapping:
    HASURA_CONNECTOR_PORT:
      fromEnv: APP_<DB_CONNECTOR>_HASURA_CONNECTOR_PORT
    HASURA_SERVICE_TOKEN_SECRET:
      fromEnv: APP_<DB_CONNECTOR>_HASURA_SERVICE_TOKEN_SECRET
    JDBC_URL:
      fromEnv: APP_<DB_CONNECTOR>_JDBC_URL
```

### 環境變數

```bash
# .env
APP_<DB_CONNECTOR>_JDBC_URL="jdbc:mysql://host:3306/dbname?user=username&password=password"
APP_<DB_CONNECTOR>_FULLY_QUALIFY_NAMES="false"
APP_<DB_CONNECTOR>_HASURA_SERVICE_TOKEN_SECRET="your-secret"
```

### Introspect 工作流程

```bash
# 1. Introspect 數據庫 schema
ddn connector introspect <db_connector>

# 2. 新增所有 models
ddn model add <db_connector> "*"

# 3. 建置驗證
ddn supergraph build local
```

---

## DataConnectorLink (HML)

Connector 在 metadata 中的表示：

```yaml
kind: DataConnectorLink
version: v1
definition:
  name: <api_connector>
  url:
    readWriteUrls:
      read:
        valueFromEnv: APP_<API_CONNECTOR>_READ_URL
      write:
        valueFromEnv: APP_<API_CONNECTOR>_WRITE_URL
  headers:
    Authorization:
      valueFromEnv: APP_<API_CONNECTOR>_AUTHORIZATION_HEADER
  schema:
    version: v0.1
    schema:
      collections: []
      functions:
        - name: getApiUserProfile
          arguments: { ... }
          result_type: { ... }
      procedures:
        - name: postApiAuthLogin
          arguments: { ... }
          result_type: { ... }
      object_types: { ... }
      scalar_types: { ... }
    capabilities:
      capabilities:
        mutation: {}
        query:
          nested_fields: {}
          variables: {}
      version: 0.1.6
```

---

## Schema 變更工作流程

當上游 schema 變更時（如數據庫遷移）：

### MySQL Schema 變更

```bash
# 1. 移除所有舊 models（逐一執行）
ddn model remove User
ddn model remove Post
ddn model remove Comment
# ... 其他 models

# 2. 重新 introspect
ddn connector introspect <db_connector>

# 3. 重新新增 models
ddn model add <db_connector> "*"

# 4. 建置驗證
ddn supergraph build local
```

### OpenAPI Schema 變更

```bash
# 1. 更新 swagger.json

# 2. 重新 introspect
ddn connector introspect <api_connector>

# 3. 重新新增 commands/models
ddn command add <api_connector> "*"
ddn model add <api_connector> "*"

# 4. 建置驗證
ddn supergraph build local
```

---

## 命名映射

### OpenAPI → TypeScript → HML → GraphQL

| OpenAPI Endpoint | TypeScript Function | HML ObjectType | GraphQL |
|-----------------|---------------------|----------------|---------|
| `POST /api/auth/login` | `postApiAuthLoginCreate` | `PostApiAuthLoginCreate` | `postApiAuthLoginCreate` |
| `GET /api/user/profile` | `getApiUserProfileList` | `GetApiUserProfileList` | `getApiUserProfileList` |
| Response body | `*_output` | `*CreateOutput` | 同 HML |
| Request body | `*_data` | `*CreateData` | 同 HML |

### MySQL → HML → GraphQL

| MySQL Table | HML ObjectType/Model | GraphQL Query |
|-------------|---------------------|---------------|
| `user` | `User` | `user`, `userById` |
| `post` | `Post` | `post`, `postById` |

---

## 服務啟動

### 推薦方式

```bash
# 停止現有服務
docker compose down

# 使用 ddn 啟動（自動讀取 .env）
ddn run docker-start
```

### 手動方式

```bash
docker compose up
```

### 查看服務狀態

```bash
# 所有服務
docker compose ps

# 特定服務日誌
docker compose logs -f app-<api_connector>-1
docker compose logs -f app-<db_connector>-1
docker compose logs -f engine
```

---

## 常見問題

### Q: Introspect 失敗 "file already exists"

設置環境變數：
```bash
APP_<API_CONNECTOR>_NDC_OAS_FILE_OVERWRITE="true"
```

### Q: Response 類型顯示為 `Json!`

swagger.json 缺少 response schema 定義。添加明確的 `responses.200.content.application/json.schema`。

### Q: Connector 無法連接

1. 檢查 Docker 服務狀態：`docker compose ps`
2. 驗證環境變數正確性
3. 確認 BASE_URL 無末尾斜線
4. 檢查網絡連接（對於外部服務）

### Q: 修改 TypeScript 後服務未更新

單純 `docker compose restart` 不會重新編譯。使用：

```bash
docker compose down
ddn run docker-start
```
