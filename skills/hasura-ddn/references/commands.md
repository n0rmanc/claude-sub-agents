# DDN CLI 命令參考

## 概述

`ddn` 是 Hasura DDN 的 CLI 工具，用於管理 supergraph、connectors、models 和 commands。

---

## 常用命令速查

| 任務 | 命令 |
|-----|------|
| Introspect connector | `ddn connector introspect <name>` |
| 新增所有 models | `ddn model add <connector> "*"` |
| 新增所有 commands | `ddn command add <connector> "*"` |
| 移除 model | `ddn model remove <ModelName>` |
| 本地建置 | `ddn supergraph build local` |
| 雲端部署 | `ddn supergraph build create` |
| 啟動服務 | `ddn run docker-start` |

---

## Connector 操作

### Introspect

從數據源重新生成 connector schema：

```bash
# OpenAPI connector（重新生成 api.ts, functions.ts）
ddn connector introspect <connector_name>

# MySQL connector（重新讀取數據庫 schema）
ddn connector introspect <db_connector>
```

**前置條件**（OpenAPI）：
```bash
# .env 中啟用檔案覆寫
APP_<API_CONNECTOR>_NDC_OAS_FILE_OVERWRITE="true"
```

### 升級 Connector 版本

```bash
ddn connector upgrade <connector_name>
```

---

## Model 操作

### 新增 Models

```bash
# 新增所有 models
ddn model add <db_connector> "*"

# 新增特定 model
ddn model add <db_connector> User

# 從 OpenAPI connector 新增（GET endpoints）
ddn model add <connector_name> "*"
```

### 移除 Models

```bash
# 移除單一 model（自動清理相關的 ObjectType、Permissions、BoolExp）
ddn model remove User

# 批量移除（按順序執行）
ddn model remove Admin && ddn model remove User && ddn model remove Post
```

**注意**：
- 使用 model 名稱（如 `User`），不是 connector 名稱
- 不支援萬用字元移除
- 移除後自動執行 PRUNE

---

## Command 操作

Commands 對應 GraphQL mutations（來自 OpenAPI 的 POST/PUT/DELETE）。

### 新增 Commands

```bash
# 新增所有 commands
ddn command add <connector_name> "*"

# 新增特定 command
ddn command add <connector_name> PostApiAuthLoginCreate
```

### 移除 Commands

```bash
ddn command remove PostApiAuthLoginCreate
```

---

## Supergraph 建置

### 本地建置

```bash
# 標準建置
ddn supergraph build local

# Watch 模式（變更時自動重建）
ddn supergraph build local --watch

# CI 模式（用於自動化部署）
ddn supergraph build local --ci
```

### 雲端部署

```bash
# 建置並部署到 Hasura DDN Cloud
ddn supergraph build create
```

---

## 服務運行

### 啟動服務

```bash
# 推薦方式（自動讀取 .env 並建置）
ddn run docker-start

# 等效於
docker compose up
```

### 停止服務

```bash
docker compose down

# 清理卷
docker compose down -v
```

### 重啟服務

修改 TypeScript 代碼後：
```bash
docker compose down
ddn run docker-start
```

**注意**：`docker compose restart` 不會重新編譯 TypeScript。

---

## 環境管理

### 查看當前環境

```bash
ddn context show
```

### 切換環境

```bash
# 設置默認 context
ddn context set-default <context_name>
```

---

## 常見工作流程

### 1. OpenAPI Schema 變更

```bash
# 1. 更新 swagger.json

# 2. Introspect
ddn connector introspect <connector_name>

# 3. 更新 commands
ddn command add <connector_name> "*"

# 4. 建置驗證
ddn supergraph build local

# 5. 重啟服務
docker compose down
ddn run docker-start
```

### 2. MySQL Schema 變更

```bash
# 1. 移除舊 models
ddn model remove User
ddn model remove Post
# ...

# 2. Introspect
ddn connector introspect <db_connector>

# 3. 新增 models
ddn model add <db_connector> "*"

# 4. 建置驗證
ddn supergraph build local
```

### 3. 完整重建

```bash
# 1. 清理
docker compose down -v

# 2. Introspect all connectors
ddn connector introspect <connector_name>
ddn connector introspect <db_connector>

# 3. 新增所有資源
ddn command add <connector_name> "*"
ddn model add <connector_name> "*"
ddn model add <db_connector> "*"

# 4. 建置
ddn supergraph build local

# 5. 啟動
ddn run docker-start
```

---

## 調試命令

### 查看服務日誌

```bash
# Engine 日誌
docker compose logs -f engine

# OpenAPI connector 日誌
docker compose logs -f app-<api_connector>-1

# MySQL connector 日誌
docker compose logs -f app-<db_connector>-1

# 所有服務
docker compose logs -f
```

### 檢查端口

```bash
lsof -i :3280  # Engine
lsof -i :7392  # <connector_name> connector
lsof -i :4064  # <db_connector> connector
```

### 健康檢查

```bash
# Engine
curl http://localhost:3280/health

# Connector
curl http://localhost:7392/health
curl http://localhost:4064/health
```

---

## 錯誤處理

### "file already exists"

```bash
# 設置環境變數
export APP_<API_CONNECTOR>_NDC_OAS_FILE_OVERWRITE="true"
```

### "unknown target column name"

metadata 引用了不存在的欄位。重新 introspect：

```bash
ddn connector introspect <connector_name>
ddn model add <connector_name> "*"
```

### Build 失敗

```bash
# 檢查 HML 語法
ddn supergraph build local

# 查看詳細錯誤
ddn supergraph build local --log-level debug
```

---

## 命令參數說明

### ddn connector introspect

```
ddn connector introspect <connector_name>

選項：
  --subgraph <name>    指定 subgraph（默認從 context 推斷）
```

### ddn model add

```
ddn model add <connector_name> <model_name|"*">

選項：
  --subgraph <name>    指定 subgraph
```

### ddn supergraph build

```
ddn supergraph build local [選項]

選項：
  --watch              Watch 模式
  --ci                 CI 模式（無交互）
  --log-level <level>  日誌級別（debug, info, warn, error）
```
