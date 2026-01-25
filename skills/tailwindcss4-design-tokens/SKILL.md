---
name: tailwindcss4-design-tokens
description: |
  Tailwind CSS 4 design tokens 最佳实践指南。使用此 skill 当：
  (1) 需要将 arbitrary values (如 `bg-[#FFFDFA]`, `text-[14px]`) 转换为 design tokens
  (2) 配置 `@theme inline` 自定义 CSS 变量
  (3) 需要了解 Tailwind CSS 4 的命名空间规则
  (4) 修复 eslint-plugin-tailwindcss 的 `no-arbitrary-value` 错误
  触发词：tailwind tokens, design tokens, @theme inline, arbitrary value, no-arbitrary-value
---

# Tailwind CSS 4 Design Tokens 最佳实践

## 核心概念

Tailwind CSS 4 使用 `@theme` 指令定义 design tokens（CSS 变量），这些变量会自动生成对应的 utility classes。

```css
@import "tailwindcss";

@theme inline {
  --color-page: #FFFDFA;        /* 生成 bg-page, text-page 等 */
  --text-size-sm: 14px;         /* 生成 text-size-sm */
  --spacing-section: 60px;      /* 生成 p-section, m-section, gap-section 等 */
}
```

## 命名空间规则

| 命名空间 | 生成的 Utilities | 示例 |
|---------|-----------------|------|
| `--color-*` | `bg-*`, `text-*`, `border-*`, `fill-*` | `--color-page` → `bg-page` |
| `--text-*` | `text-*` (字体大小) | `--text-size-sm` → `text-size-sm` |
| `--font-weight-*` | `font-*` | `--font-weight-light` → `font-light` |
| `--tracking-*` | `tracking-*` | `--tracking-wide` → `tracking-wide` |
| `--leading-*` | `leading-*` | `--leading-tight` → `leading-tight` |
| `--spacing-*` | `p-*`, `m-*`, `gap-*`, `left-*`, `right-*`, `top-*`, `bottom-*`, `w-*`, `h-*` | `--spacing-section` → `py-section` |
| `--width-*` | 需使用 `w-(--width-*)` 语法 | 见下文 |
| `--height-*` | 需使用 `h-(--height-*)` 语法 | 见下文 |
| `--aspect-*` | `aspect-*` | `--aspect-video` → `aspect-video` |
| `--radius-*` | `rounded-*` | `--radius-lg` → `rounded-lg` |

## 关键语法：CSS 变量引用

对于 `width`, `height`, `max-width` 等尺寸属性，需要使用括号语法引用 CSS 变量：

```html
<!-- ✅ 正确：使用括号语法 -->
<div class="max-w-(--width-content)">...</div>
<div class="h-(--height-hero)">...</div>
<div class="w-(--width-card)">...</div>

<!-- ❌ 错误：直接使用 token 名 -->
<div class="max-w-content">...</div>  <!-- 不会工作 -->
```

对于 `--spacing-*` 命名空间，可以直接使用：

```html
<!-- ✅ spacing 命名空间可直接使用 -->
<div class="py-section gap-section left-inset-hero">...</div>
```

## 转换映射表

### 颜色
```
bg-[#FFFDFA]     → --color-page: #FFFDFA;        → bg-page
text-[#443C3C]   → --color-text-primary: #443C3C; → text-text-primary
text-[#666]      → --color-text-muted: #666666;   → text-text-muted
border-[#E5E5E5] → --color-border: #E5E5E5;       → border-border
```

### 字体大小
```
text-[13px] → --text-size-xs: 13px;  → text-size-xs
text-[14px] → --text-size-sm: 14px;  → text-size-sm
text-[16px] → --text-size-base: 16px; → text-size-base
text-[18px] → --text-size-lg: 18px;  → text-size-lg
text-[36px] → --text-size-4xl: 36px; → text-size-4xl
```

### 字重
```
font-[300] → --font-weight-light: 300;  → font-light
font-[400] → --font-weight-normal: 400; → font-normal
font-[500] → --font-weight-medium: 500; → font-medium
```

### 字间距
```
tracking-[0.03em] → --tracking-tight: 0.03em;   → tracking-tight
tracking-[0.05em] → --tracking-normal: 0.05em;  → tracking-normal
tracking-[0.1em]  → --tracking-wide: 0.1em;     → tracking-wide
```

### 行高
```
leading-[1.3] → --leading-tight: 1.3;    → leading-tight
leading-[1.8] → --leading-relaxed: 1.8;  → leading-relaxed
leading-[2]   → --leading-loose: 2;      → leading-loose
```

### 间距（使用 --spacing-* 命名空间）
```
py-[60px]      → --spacing-section: 60px;     → py-section
left-[100px]   → --spacing-inset-hero: 100px; → left-inset-hero
right-[40px]   → --spacing-inset-social: 40px; → right-inset-social
space-y-[80px] → --spacing-section-lg: 80px;  → space-y-section-lg
```

### 尺寸（需要括号语法）
```
max-w-[900px]  → --width-content: 900px;   → max-w-(--width-content)
max-w-[1100px] → --width-wide: 1100px;     → max-w-(--width-wide)
max-w-[1200px] → --width-container: 1200px; → max-w-(--width-container)
h-[500px]      → --height-hero: 500px;     → h-(--height-hero)
w-[300px]      → --width-card: 300px;      → w-(--width-card)
```

### 比例
```
aspect-[16/9] → --aspect-video: 16 / 9;     → aspect-video
aspect-[3/4]  → --aspect-portrait: 3 / 4;   → aspect-portrait
```

## 完整示例

### globals.css
```css
@import "tailwindcss";

@theme inline {
  /* 颜色 */
  --color-page: #FFFDFA;
  --color-section-alt: #FAF8F6;
  --color-muted: #F5F5F5;
  --color-border: #E5E5E5;
  --color-text-primary: #443C3C;
  --color-text-muted: #666666;
  --color-text-subtle: #999999;

  /* 字体大小 */
  --text-size-xs: 13px;
  --text-size-sm: 14px;
  --text-size-base: 16px;
  --text-size-lg: 18px;
  --text-size-4xl: 36px;

  /* 字重 */
  --font-weight-light: 300;
  --font-weight-normal: 400;

  /* 字间距 */
  --tracking-normal: 0.05em;
  --tracking-wide: 0.1em;

  /* 行高 */
  --leading-tight: 1.3;
  --leading-relaxed: 1.8;
  --leading-loose: 2;

  /* 间距 */
  --spacing-section: 60px;
  --spacing-section-lg: 80px;
  --spacing-inset-hero: 100px;

  /* 尺寸 */
  --width-content: 900px;
  --height-hero: 500px;

  /* 比例 */
  --aspect-video: 16 / 9;
}
```

### 组件使用
```tsx
// Before (arbitrary values)
<div className="min-h-screen bg-[#FFFDFA]">
  <section className="h-[500px] py-[60px]">
    <div className="max-w-[900px]">
      <h1 className="text-[36px] leading-[1.3] font-[400] tracking-[0.05em] text-[#443C3C]">
        Title
      </h1>
    </div>
  </section>
</div>

// After (design tokens)
<div className="min-h-screen bg-page">
  <section className="h-(--height-hero) py-section">
    <div className="max-w-(--width-content)">
      <h1 className="text-size-4xl leading-tight font-normal tracking-normal text-text-primary">
        Title
      </h1>
    </div>
  </section>
</div>
```

## ESLint 注意事项

使用 `eslint-plugin-tailwindcss` 4.0.0-beta 版本时：
- 自定义 token 类名可能显示 warning（如 `max-w-(--width-content)` 不被识别）
- 这是 beta 版限制，**0 errors** 即为成功
- Warnings 可忽略，不影响功能

## 工作流程

1. **识别 arbitrary value** - 如 `bg-[#FFFDFA]`
2. **确定命名空间** - 颜色用 `--color-*`
3. **添加 token 到 globals.css** - `--color-page: #FFFDFA;`
4. **替换类名** - `bg-[#FFFDFA]` → `bg-page`
5. **运行 ESLint 验证** - 确认 0 errors
6. **运行视觉测试** - 确认无回归

## 常见陷阱

1. **尺寸属性必须用括号语法** - `max-w-(--width-content)` 而非 `max-w-content`
2. **颜色值大小写** - `#666666` 与 `#666` 等价，但建议统一用完整格式
3. **spacing 与 width/height 的区别** - `--spacing-*` 自动映射，`--width-*` 需括号语法
4. **一次只改一个值** - 便于定位问题，配合视觉测试
5. **避免与内置 utility 命名冲突** - `--width-full` 会覆盖内置 `w-full`（100%），应使用 `--width-container` 代替。同理避免 `--width-screen`、`--height-full`、`--height-screen` 等
