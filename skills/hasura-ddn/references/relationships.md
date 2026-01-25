# Relationship 定義指南

## 概述

Relationships 定義 GraphQL types 之間的關聯，讓你可以在單一查詢中跨越多個 models 獲取數據。Hasura DDN 支援兩種主要類型：

- **Object Relationship** (Many-to-One) - 返回單一對象
- **Array Relationship** (One-to-Many) - 返回對象數組

---

## HML 結構

```yaml
kind: Relationship
version: v1
definition:
  name: <relationship_name>        # GraphQL 中使用的字段名
  sourceType: <SourceTypeName>     # 起始 ObjectType
  target:
    model:
      name: <TargetModelName>      # 目標 Model
      relationshipType: Object     # 或 Array
  mapping:
    - source:
        fieldPath:
          - fieldName: <sourceField>   # 源類型的外鍵字段
      target:
        modelField:
          - fieldName: <targetField>   # 目標模型的主鍵字段
```

---

## Object Relationship (Many-to-One)

**場景**：多個子記錄指向一個父記錄。

### 範例：OrderItem -> Order

每個 OrderItem 屬於一個 Order：

```yaml
kind: Relationship
version: v1
definition:
  name: order                 # 在 OrderItem 上訪問 .order
  sourceType: OrderItem
  target:
    model:
      name: Order
      relationshipType: Object  # 返回單一 Order
  mapping:
    - source:
        fieldPath:
          - fieldName: orderId
      target:
        modelField:
          - fieldName: id
```

**GraphQL 查詢**：
```graphql
query {
  orderItem {
    id
    productName
    order {    # Object relationship
      id
      status
    }
  }
}
```

### 範例：Post -> 多個父級

Post 可以關聯到多個不同的父類型：

```yaml
---
# Post -> Author
kind: Relationship
version: v1
definition:
  name: author
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

---
# Post -> Category
kind: Relationship
version: v1
definition:
  name: category
  sourceType: Post
  target:
    model:
      name: Category
      relationshipType: Object
  mapping:
    - source:
        fieldPath:
          - fieldName: categoryId
      target:
        modelField:
          - fieldName: id

---
# Post -> Tag (Many-to-One via PostTag)
kind: Relationship
version: v1
definition:
  name: tag
  sourceType: PostTag
  target:
    model:
      name: Tag
      relationshipType: Object
  mapping:
    - source:
        fieldPath:
          - fieldName: tagId
      target:
        modelField:
          - fieldName: id
```

---

## Array Relationship (One-to-Many)

**場景**：一個父記錄有多個子記錄。

### 範例：Author -> Post[]

一個 Author 可以有多個 Post 記錄：

```yaml
kind: Relationship
version: v1
definition:
  name: posts                 # 在 Author 上訪問 .posts
  sourceType: Author
  target:
    model:
      name: Post
      relationshipType: Array   # 返回 Post 數組
  mapping:
    - source:
        fieldPath:
          - fieldName: id
      target:
        modelField:
          - fieldName: authorId
```

**GraphQL 查詢**：
```graphql
query {
  author {
    id
    name
    posts {    # Array relationship
      id
      title
    }
    comments {
      id
      content
    }
  }
}
```

---

## 文件組織最佳實踐

### 方式 1：獨立 Relationships 文件（推薦）

將所有相關的 relationships 放在一個專用文件中：

```
app/metadata/
├── Author.hml                 # Model + ObjectType + Permissions
├── Post.hml
├── Comment.hml
├── Category.hml
├── Tag.hml
└── AuthorRelationships.hml    # 所有 Author 相關的 relationships
```

**AuthorRelationships.hml** 結構：
```yaml
---
# Object Relationships (Many-to-One)

# Post -> Author
kind: Relationship
version: v1
definition:
  name: author
  sourceType: Post
  # ...

---
# Comment -> Author
kind: Relationship
version: v1
definition:
  name: author
  sourceType: Comment
  # ...

---
# Array Relationships (One-to-Many)

# Author -> Post[]
kind: Relationship
version: v1
definition:
  name: posts
  sourceType: Author
  # ...
```

### 方式 2：內聯在 Model 文件中

將 relationships 放在對應的 model 文件末尾：

```yaml
# Author.hml
---
kind: ObjectType
# ...

---
kind: Model
# ...

---
# Relationships
kind: Relationship
version: v1
definition:
  name: posts
  sourceType: Author
  # ...
```

---

## 雙向關係設計模式

為了完整的 GraphQL 查詢能力，通常需要定義雙向關係：

```yaml
# 正向: Author -> Post[] (One-to-Many)
kind: Relationship
version: v1
definition:
  name: posts
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

---
# 反向: Post -> Author (Many-to-One)
kind: Relationship
version: v1
definition:
  name: author
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

這樣可以支援兩種查詢方向：

```graphql
# 從 Author 查 posts
query {
  author {
    name
    posts { title }
  }
}

# 從 Post 查 author
query {
  post {
    title
    author { name }
  }
}
```

---

## 複合外鍵

當關係基於多個字段時：

```yaml
kind: Relationship
version: v1
definition:
  name: relatedModel
  sourceType: SourceType
  target:
    model:
      name: TargetModel
      relationshipType: Object
  mapping:
    - source:
        fieldPath:
          - fieldName: organizationId
      target:
        modelField:
          - fieldName: organizationId
    - source:
        fieldPath:
          - fieldName: userId
      target:
        modelField:
          - fieldName: userId
```

---

## 跨 Connector 關係

Relationships 可以跨越不同的 data connectors：

```yaml
# MySQL User -> OpenAPI Backend
kind: Relationship
version: v1
definition:
  name: backendData
  sourceType: User              # 來自 <db_connector>
  target:
    model:
      name: GetApiUserProfile   # 來自 <api_connector>
      relationshipType: Object
  mapping:
    - source:
        fieldPath:
          - fieldName: id
      target:
        modelField:
          - fieldName: userId
```

**注意**：跨 connector 關係會產生額外的網絡調用，可能影響性能。

---

## 命名約定

| 關係類型 | 命名建議 | 範例 |
|---------|---------|------|
| Object (Many-to-One) | 單數名詞 | `author`, `organization`, `user` |
| Array (One-to-Many) | 複數名詞 | `posts`, `comments`, `orders` |

---

## 常見錯誤

### 1. 字段名不存在

```
Error: unknown target column name xxx
```

**解決**：確認 `fieldName` 在對應的 ObjectType 中存在。使用 `ddn connector introspect` 重新生成 schema。

### 2. 關係類型錯誤

- 使用 `Object` 當預期返回數組
- 使用 `Array` 當預期返回單一對象

**診斷**：檢查外鍵方向。外鍵所在的表是「多」端（使用 Object 指向「一」端）。

### 3. 循環依賴

確保不會創建無限循環的 eager loading：

```graphql
# 避免這種情況
query {
  author {
    posts {
      author {        # 循環回去
        posts {       # 又循環
          # ...
        }
      }
    }
  }
}
```
