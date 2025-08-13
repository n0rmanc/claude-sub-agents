# AI Agent 和 MCP Tool 文件編寫規範

編寫 AI Agent 或 MCP Tool 使用指南和 CLAUDE.md 文件時，請遵守以下規範：

## 格式要求
- 一行一個操作指令
- 使用檢查清單風格
- 設計成易於快速掃描和執行
- 專有名詞保持英文

## 文件結構（4個主要部分）

### 1. 任務前準備 (Before Starting Any Task)
- **Always search first:** 使用相關工具先搜尋現有知識
- **Check requirements:** 確認所有必要條件
- **準備環境:** 設定所需的開發環境

### 2. 保存資訊 (Always Save New Information)
- **即時記錄:** 發現新資訊立即保存
- **分類清楚:** 使用適當的標籤分類
- **更新既有知識:** 標記是新增還是更新

### 3. 執行期間 (During Your Work)
- **遵循流程:** 按步驟執行已定義的程序
- **保持一致性:** 與既有規範保持一致
- **記錄問題:** 遇到問題時記錄解決方案

### 4. 最佳實踐 (Best Practices)
- **簡潔明瞭:** 指令保持簡短易懂
- **可執行性:** 每個指令都能直接執行
- **持續改進:** 根據使用經驗更新文件

## 範例格式

```markdown
### Before Starting Any Task
- **Always search first:** Use `search_nodes` to look for relevant preferences
- **Search across all groups:** Don't specify `group_ids` unless needed
- **Filter by entity type:** Specify `Preference`, `Procedure`, or `Requirement`

### Always Save New Information
- **Choose the right group:** Use `default` for general knowledge
- **Capture immediately:** Use `add_memory` right away
- **Label clearly:** Use categories in source_description

### During Your Work
- **Respect preferences:** Align work with discovered preferences
- **Follow procedures:** Execute procedures step-by-step
- **Stay consistent:** Maintain consistency with previous knowledge

### Best Practices
- **Search before suggesting:** Check established knowledge first
- **Combine searches:** Search both nodes and facts
- **Be proactive:** Store patterns as preferences or procedures
```