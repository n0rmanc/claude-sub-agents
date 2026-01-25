---
name: shadcn-ui-guide
description: |
  shadcn/ui 元件庫使用指南與最佳實踐。使用此 skill 當：
  (1) 需要新增或修改 shadcn/ui 元件時
  (2) 建立表單並需要了解 Field 系統 vs Form 系統的選擇
  (3) 需要了解 react-hook-form + zod 整合模式
  (4) 需要自訂元件樣式或主題配置
  (5) 需要確保無障礙 (accessibility) 支援
  觸發詞：shadcn, form, field, 表單驗證, ui component
---

# shadcn/ui 使用指南

## 快速參考

### 安裝元件
```bash
bun run shadcn add <component>
```

### 專案配置
- 配置檔：`components.json`
- CSS 變數：`app/globals.css` 或 `styles/globals.css`
- 元件目錄：`components/ui/`

## 表單系統選擇

### Field 系統（v4 推薦）

**使用時機**：所有新表單開發

```tsx
import { Controller, useForm } from "react-hook-form";
import { Field, FieldError, FieldLabel, FieldDescription } from "@/components/ui/field";

<Controller
  name="email"
  control={form.control}
  render={({ field, fieldState }) => (
    <Field data-invalid={fieldState.invalid}>
      <FieldLabel htmlFor={field.name}>Email</FieldLabel>
      <Input
        {...field}
        id={field.name}
        aria-invalid={fieldState.invalid}
      />
      <FieldDescription>輸入你的電子郵件</FieldDescription>
      {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
    </Field>
  )}
/>
```

**必要屬性**：
- `data-invalid={fieldState.invalid}` 在 `<Field>` 上
- `aria-invalid={fieldState.invalid}` 在輸入元件上
- `htmlFor={field.name}` 連結 label 和 input
- `id={field.name}` 在輸入元件上

### Form 系統（舊版）

**狀態**：不再積極開發，僅維護現有代碼

詳見 `references/form-patterns.md`

## useForm 配置

```tsx
const form = useForm<FormData>({
  resolver: zodResolver(schema),
  mode: "onBlur",  // 推薦：失焦時驗證
  defaultValues: {
    email: "",
    password: "",
  },
});
```

**驗證時機選項**：
- `onBlur`：失焦時驗證（推薦用於文字欄位）
- `onChange`：每次輸入變化時驗證（用於即時反饋）
- `onSubmit`：僅提交時驗證（用於複雜驗證）

## 樣式規範

### 禁止使用
```tsx
// ❌ 任意值顏色
className="bg-[#316ff6]"

// ❌ 任意值 shadow
className="shadow-[0_0_20px_...]"

// ❌ 字串拼接
className={`base ${condition}`}
```

### 正確做法
```tsx
// ✅ 使用 design tokens
className="bg-brand-accent-lime text-brand-accent-pink"

// ✅ 使用 cn() 合併
className={cn("base", condition && "active")}

// ✅ 使用預定義 shadow
className="shadow-brand-glow"
```

## 元件參考

| 元件 | 用途 | 安裝 |
|------|------|------|
| Field | 表單欄位容器（v4） | `bun run shadcn add field` |
| Button | 按鈕 | `bun run shadcn add button` |
| Input | 文字輸入 | `bun run shadcn add input` |
| Select | 下拉選單 | `bun run shadcn add select` |
| Checkbox | 核取方塊 | `bun run shadcn add checkbox` |
| Card | 卡片容器 | `bun run shadcn add card` |
| Tabs | 分頁標籤 | `bun run shadcn add tabs` |
| Dialog | 對話框 | `bun run shadcn add dialog` |

## 參考資源

- 完整表單模式：`references/form-patterns.md`
- [shadcn/ui 官方文檔](https://ui.shadcn.com)
- [React Hook Form 整合](https://ui.shadcn.com/docs/forms/react-hook-form)
- [Field 元件文檔](https://ui.shadcn.com/docs/components/field)
