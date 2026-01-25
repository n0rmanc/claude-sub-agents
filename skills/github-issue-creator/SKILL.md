---
name: github-issue-creator
description: Create well-structured GitHub issues from symptom descriptions. Use when user says "create issue", "建立 issue", "help me create github issue", or describes a bug/feature without solution. Follows best practice of describing symptoms, not prescribing solutions.
allowed-tools: Bash, Read, Grep, Glob, WebFetch
---

# GitHub Issue Creator

Automatically creates well-structured GitHub issues that describe symptoms clearly, following the principle of "describe problems, not solutions".

## When to use

- User says "create issue", "建立 issue", "create github issue"
- User describes a bug or feature request
- User says "only describe symptom, don't provide solution"
- User wants to track a problem for later

## Core principles

### 1. Symptoms over Solutions

**Good issue**:
```markdown
## Problem
商品列表頁面在載入超過 100 筆商品時，畫面會卡頓約 3 秒

## Steps to Reproduce
1. 前往 /admin/products
2. 確保資料庫有 100+ 商品
3. 重新載入頁面
4. 觀察載入時間

## Expected Behavior
頁面應在 1 秒內載入完成

## Current Behavior
載入時間約 3-5 秒，期間 UI 無響應
```

**Bad issue** (prescribes solution):
```markdown
## Problem
需要加入虛擬滾動來優化商品列表

## Solution
使用 react-virtual 或 @tanstack/virtual
```

### 2. Issue Structure

```markdown
## Problem / 問題描述
[清楚描述問題現象]

## Steps to Reproduce / 重現步驟
1. [步驟 1]
2. [步驟 2]
3. ...

## Expected Behavior / 期望行為
[應該發生什麼]

## Current Behavior / 實際行為
[實際發生什麼]

## Environment / 環境資訊 (if applicable)
- Browser: Chrome 120
- OS: macOS 14
- Node: 20.x

## Screenshots / 截圖 (if applicable)
[附上截圖或錯誤訊息]

## Additional Context / 額外資訊
[其他相關資訊]
```

## Instructions

### Step 1: Gather information

Ask user for:
1. What is the problem? (symptom, not solution)
2. How to reproduce?
3. What should happen vs what actually happens?
4. Any error messages or screenshots?

### Step 2: Check for duplicates

```bash
gh issue list --state open --search "keyword"
```

### Step 3: Determine labels

Common labels:
- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Documentation improvement
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `priority:high` / `priority:low`
- `type:ui` / `type:api` / `type:database`

### Step 4: Create issue

```bash
gh issue create \
  --title "簡短但描述性的標題" \
  --body "$(cat <<'EOF'
## Problem / 問題描述
[問題描述]

## Steps to Reproduce / 重現步驟
1. 步驟 1
2. 步驟 2

## Expected Behavior / 期望行為
[期望行為]

## Current Behavior / 實際行為
[實際行為]

## Additional Context / 額外資訊
[額外資訊]
EOF
)" \
  --label "bug"
```

### Step 5: Return issue URL

Always provide the created issue URL to user.

## Examples

### Example 1: UI Bug

**User says**: "商品圖片在手機上顯示不正確，幫我建立 issue"

**Created issue**:
```markdown
Title: [UI] 商品圖片在行動裝置上顯示異常

## Problem / 問題描述
商品詳情頁的商品圖片在行動裝置上顯示比例不正確

## Steps to Reproduce / 重現步驟
1. 使用手機瀏覽器訪問 /products/[id]
2. 查看商品主圖

## Expected Behavior / 期望行為
圖片應維持正確比例並填滿容器

## Current Behavior / 實際行為
圖片被拉伸變形

## Environment / 環境資訊
- Device: iPhone 14 Pro
- Browser: Safari
- Screen width: 390px
```

### Example 2: Feature Request

**User says**: "As admin I can view call records"

**Clarifying questions**:
1. 要查看哪些通話記錄？所有品牌還是特定品牌？
2. 要顯示哪些資訊？基本資料、詳細內容、統計數據？
3. 需要搜尋/篩選功能嗎？
4. 需要匯出功能嗎？

**Created issue** (after clarification):
```markdown
Title: [Feature] Admin Call Records View

## Feature Request / 功能需求
管理員需要查看所有品牌的通話記錄

## User Story
As an admin
I want to view call records from all brands
So that I can monitor call quality and track customer interactions

## Acceptance Criteria / 驗收條件
- [ ] Table view with pagination
- [ ] Filter by: date range, brand, caller
- [ ] Search by phone number
- [ ] Click to view details
- [ ] Show: caller, customer, time, status, duration

## UI Reference
類似現有的 Order Management 頁面設計
```

### Example 3: Bug from Error Message

**User says**:
```
現在一進入 call records 頁面就會顯示錯誤
{
  "code": "PGRST200",
  "message": "Could not find a relationship between 'call_records' and 'call_list_items'"
}
```

**Created issue**:
```markdown
Title: [Bug] Call Records 頁面載入失敗 - 資料庫關聯錯誤

## Problem / 問題描述
進入 Call Records 頁面時出現 PGRST200 錯誤

## Error Message / 錯誤訊息
```json
{
  "code": "PGRST200",
  "details": "Searched for a foreign key relationship between 'call_records' and 'call_list_items' in the schema 'public', but no matches were found.",
  "message": "Could not find a relationship between 'call_records' and 'call_list_items' in the schema cache"
}
```

## Steps to Reproduce / 重現步驟
1. 登入系統
2. 前往 /admin/call-records
3. 頁面顯示錯誤

## Expected Behavior / 期望行為
頁面應正常載入通話記錄列表

## Current Behavior / 實際行為
頁面顯示錯誤，無法查看任何資料
```

## Title conventions

Format: `[Type] Brief description`

Types:
- `[Bug]` - 錯誤修復
- `[Feature]` - 新功能
- `[UI]` - 介面相關
- `[API]` - API 相關
- `[DB]` - 資料庫相關
- `[Perf]` - 效能問題
- `[Docs]` - 文件更新
- `[Refactor]` - 重構

## Best practices

1. **Never prescribe solutions in issues** - Let developers decide implementation
2. **Use clear, searchable titles** - Include key terms
3. **Include reproduction steps** - Make it easy to verify
4. **Add context** - Environment, user role, affected areas
5. **Link related issues** - If this is related to existing issues
6. **Use labels consistently** - Follow project conventions

## Verification

After creating issue:
1. ✅ Title is descriptive and includes type tag
2. ✅ Problem is clearly described (not solution)
3. ✅ Reproduction steps are complete
4. ✅ Expected vs actual behavior is clear
5. ✅ Labels are appropriate
6. ✅ Issue URL is provided to user
