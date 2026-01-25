---
name: playwright-e2e-test
description: |
  编写和调试 Playwright E2E 测试。自动检测包管理器（npm/pnpm/bun），使用 fixture 模式管理测试数据。

  当用户提到以下时触发：
  - "playwright test", "e2e test", "写测试", "端到端测试"
  - "写 playwright", "run e2e", "调试测试"
  - "test fixture", "测试数据清理"
user-invocable: true
---

# Playwright E2E Test Skill

编写、执行和调试 Playwright E2E 测试的通用指南。

## 项目环境检测

在执行任何命令前，自动检测当前专案的包管理器：

### 检测逻辑
1. 检查 `package.json` 中的 `packageManager` 字段
2. 检查 lock files：
   - `pnpm-lock.yaml` → pnpm
   - `bun.lockb` → bun
   - `package-lock.json` → npm
   - `yarn.lock` → yarn
3. 默认使用 pnpm

### 命令映射
| 操作 | npm | pnpm | bun |
|------|-----|------|-----|
| 运行测试 | `npm run test` | `pnpm test` | `bun test` |
| 运行单个测试 | `npm run test -- path/to/test.spec.ts` | `pnpm test path/to/test.spec.ts` | `bun test path/to/test.spec.ts` |

## 核心原则

### 1. 不做纯 UI 测试

**只测试业务逻辑，不测试 UI 渲染：**

```typescript
// ❌ 纯 UI 测试 - 不做
test('should display page title', async ({ page }) => {
  await expect(page.getByRole('heading')).toBeVisible();
});

// ✅ 业务逻辑测试 - 做
test('should create record and verify in database', async ({ page }) => {
  // ... 操作
  const { data } = await supabaseAdmin.from('records').select().eq('id', id);
  expect(data).toBeTruthy();
});
```

### 2. 使用语义化选择器 + Exact Match

**模拟真实用户行为，不依赖 `data-testid`，并使用精确匹配：**

```typescript
// ✅ 推荐 - 语义化选择器 + exact match
page.getByRole('button', { name: 'Create', exact: true })
page.getByRole('menuitem', { name: 'Edit', exact: true })
page.getByLabel('Priority', { exact: true })
page.getByText('Upload Complete', { exact: true })

// ❌ 避免 - 正则表达式（测试不够精确）
page.getByRole('button', { name: /create/i })      // 可能匹配 "Create New" 或 "Recreate"
page.getByRole('menuitem', { name: /edit/i })      // 可能匹配 "Edit" 或 "Credit"
page.getByLabel(/priority/i)                        // 可能匹配 "Priority" 或 "High Priority"

// ⚠️ 次选 - 只在无法用语义化时
page.getByTestId('data-table')

// ❌ 避免
page.locator('.btn-primary')
page.locator('#submit-btn')
```

**为什么要用 exact match：**
- **精确性**：避免误匹配相似文字（如 "Edit" vs "Credit"）
- **可靠性**：测试结果更稳定，不会因为文字变化而失败
- **可读性**：测试代码清楚表达期望的精确文字

**为什么不用 `data-testid`：**
- 与真实用户行为脱节
- 如果 testid 改了或忘记加，测试就挂
- 无法验证可访问性

## 测试文件结构

```
e2e/
├── playwright.config.ts
├── fixtures/
│   ├── auth.fixture.ts       # 认证 fixtures
│   └── supabase-client.ts    # Supabase 测试客户端（或其他 DB client）
└── tests/
    ├── admin/
    │   └── feature-a.spec.ts
    ├── user/
    └── guest/
```

## 测试数据隔离原则（核心）

**每个测试必须是独立的：**
- ✅ 测试前：创建所需的测试数据
- ✅ 测试后：删除所有创建的数据
- ❌ 禁止：依赖 seed.sql 中的固定数据
- ❌ 禁止：依赖其他测试创建的数据

### 为什么要测试隔离？

```typescript
// ❌ 错误 - 依赖固定数据
test('should edit record', async ({ adminPage }) => {
  // 假设 seed.sql 有 id=123 的记录
  await adminPage.goto('/admin/records/123/edit');
  // 如果 seed 数据变了，测试就挂
});

// ✅ 正确 - 使用 fixture 创建独立数据
test('should edit record', async ({ adminPage, testRecord }) => {
  await adminPage.goto(`/admin/records/${testRecord.id}/edit`);
  // testRecord 是 fixture 创建的，测试后自动清理
});
```

### Fixture 生命周期

```
test('my test', async ({ testRecord }) => {
  // 1. Playwright 调用 fixture
  // 2. fixture 执行 SETUP（await use 之前的代码）
  //    - createTestRecord() 在数据库创建数据
  // 3. fixture 执行 await use(record)
  //    - 测试代码开始执行
  // 4. 测试代码执行完毕
  // 5. fixture 执行 TEARDOWN（await use 之后的代码）
  //    - deleteTestRecord() 清理数据
});
```

## Fixture 模式

### db-client.ts（示例）

```typescript
import { createClient } from '@supabase/supabase-js';
import type { Database } from '../../src/types/database.generated';

// Service role key 绕过 RLS - 可以直接操作数据库
const DB_URL = process.env.SUPABASE_URL || 'http://localhost:55321';
const DB_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || '...';

export const dbAdmin = createClient<Database>(
  DB_URL,
  DB_SERVICE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } }
);

// 唯一前缀生成器 - 确保测试数据不会冲突
export function generateTestPrefix(): string {
  return `e2e-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
}

export const TEST_CREDENTIALS = {
  admin: { email: 'admin@test.com', password: 'testpass123' },
  user: { email: 'user@test.com', password: 'testpass123' },
};

// ========== 数据创建函数 ==========

export async function createTestRecord(data: {
  name: string;
  // ... 其他字段
}) {
  const { data: record, error } = await dbAdmin
    .from('your_table')
    .insert(data)
    .select()
    .single();

  if (error) throw new Error(`Failed to create record: ${error.message}`);
  return record;
}

// ========== 数据清理函数 ==========

export async function deleteTestRecord(id: string) {
  // CASCADE 会自动删除关联数据
  const { error } = await dbAdmin
    .from('your_table')
    .delete()
    .eq('id', id);

  if (error) {
    console.warn(`Failed to delete record ${id}: ${error.message}`);
  }
}
```

### auth.fixture.ts

```typescript
/* eslint-disable no-empty-pattern */
import { expect, type Page, test as base } from '@playwright/test';
import {
  createTestRecord,
  deleteTestRecord,
  generateTestPrefix,
  dbAdmin,
  TEST_CREDENTIALS,
} from './db-client';

interface AuthFixtures {
  adminPage: Page;
  /** 自动创建和清理的测试记录 */
  testRecord: Awaited<ReturnType<typeof createTestRecord>>;
  /** 手动追踪需要清理的资源 */
  recordCleanup: { add: (id: string) => void };
}

async function loginAs(page: Page, credentials: { email: string; password: string }) {
  await page.goto('/login');
  await page.getByRole('textbox', { name: /email/i }).fill(credentials.email);
  await page.locator('input[type="password"]').fill(credentials.password);
  await page.getByRole('button', { name: /login/i }).click();
  await page.waitForURL(/\/(admin|dashboard)/);
}

export const test = base.extend<AuthFixtures>({
  adminPage: async ({ page }, use) => {
    await loginAs(page, TEST_CREDENTIALS.admin);
    await use(page);
  },

  /**
   * 自动创建测试记录
   * - SETUP: 创建唯一命名的记录
   * - TEARDOWN: 自动删除（包括关联数据）
   */
  testRecord: async ({}, use) => {
    // === SETUP ===
    const record = await createTestRecord({
      name: `${generateTestPrefix()}-Test Record`,
      // ... 其他字段
    });

    await use(record);

    // === TEARDOWN ===
    await deleteTestRecord(record.id);
  },

  /**
   * 手动清理追踪器
   * 用于测试中动态创建的资源
   */
  recordCleanup: async ({}, use) => {
    const ids: string[] = [];
    const cleanup = {
      add: (id: string) => ids.push(id),
    };

    await use(cleanup);

    // TEARDOWN - 清理所有追踪的资源
    for (const id of ids) {
      await deleteTestRecord(id);
    }
  },
});

export { expect, dbAdmin };
```

## 使用 Fixture 的三种模式

### 模式 1：直接使用预定义 fixture

```typescript
import { test, expect } from '../fixtures/auth.fixture';

test('should display record details', async ({ adminPage, testRecord }) => {
  // testRecord 已经创建好了，测试后自动清理
  await adminPage.goto(`/admin/records/${testRecord.id}`);
  await expect(adminPage.getByText(testRecord.name)).toBeVisible();
});
```

### 模式 2：使用 cleanup 追踪器（测试中创建数据）

```typescript
import { test, expect, dbAdmin } from '../fixtures/auth.fixture';

test('should create new record', async ({ adminPage, recordCleanup }) => {
  // 通过 UI 创建记录
  await adminPage.goto('/admin/records/create');
  await adminPage.getByLabel('Name').fill('New Test Record');
  await adminPage.getByRole('button', { name: 'Create' }).click();

  // 从 URL 获取新创建的 ID
  const url = adminPage.url();
  const id = url.match(/records\/([^/]+)/)?.[1];

  // 追踪 ID 以便自动清理
  if (id) recordCleanup.add(id);

  // 验证数据库
  const { data } = await dbAdmin
    .from('your_table')
    .select()
    .eq('id', id)
    .single();
  expect(data?.name).toBe('New Test Record');
});
```

### 模式 3：创建自定义 fixture（复杂场景）

```typescript
import { test as base } from '../fixtures/auth.fixture';
import { createTestRecord, deleteTestRecord, generateTestPrefix } from '../fixtures/db-client';

// 扩展 fixture，添加带有关联数据的记录
const test = base.extend<{
  recordWithItems: { record: any; items: any[] };
}>({
  recordWithItems: async ({}, use) => {
    // === SETUP ===
    const record = await createTestRecord({
      name: `${generateTestPrefix()}-With Items`,
      // ... 其他字段
    });

    const items = await createTestItems(record.id, 5);

    await use({ record, items });

    // === TEARDOWN ===
    // items 会通过 CASCADE 自动删除
    await deleteTestRecord(record.id);
  },
});

test('should display items count', async ({ adminPage, recordWithItems }) => {
  await adminPage.goto(`/admin/records/${recordWithItems.record.id}`);
  await expect(adminPage.getByText('5 items')).toBeVisible();
});
```

## 清理策略

### CASCADE 删除（推荐）

数据库设计时使用 `ON DELETE CASCADE`：

```sql
-- 子表自动跟随父表删除
ALTER TABLE child_table
ADD CONSTRAINT fk_parent
FOREIGN KEY (parent_id)
REFERENCES parent_table(id)
ON DELETE CASCADE;
```

删除父记录即可清理所有关联数据：

```typescript
await deleteTestRecord(record.id);
// 所有关联的子表记录自动删除
```

### 手动清理顺序（无 CASCADE 时）

按依赖关系**反向**删除：

```typescript
async function cleanupRecordComplete(recordId: string) {
  // 1. 先删子表
  await dbAdmin.from('child_table_c').delete().eq('record_id', recordId);
  await dbAdmin.from('child_table_b').delete().eq('record_id', recordId);
  await dbAdmin.from('child_table_a').delete().eq('record_id', recordId);
  // 2. 最后删父表
  await dbAdmin.from('parent_table').delete().eq('id', recordId);
}
```

## 测试质量检查清单

- [ ] **业务逻辑验证** - 通过数据库查询验证操作结果
- [ ] **使用语义化选择器** - `getByRole`、`getByLabel`、`getByText`
- [ ] **使用 Locator 断言** - `toBeVisible()`、`toHaveCount()` 等（有 auto-wait）
- [ ] **禁止 waitForTimeout** - 使用 `waitForLoadState('networkidle')`
- [ ] **Fixture 正确清理** - teardown 删除测试数据
- [ ] **测试隔离** - 不依赖其他测试状态

### Locator 断言（重要）

```typescript
// ✅ 正确 - Locator 断言有 auto-wait
await expect(page.getByRole('row')).toHaveCount(3);
await expect(page.getByText('Success')).toBeVisible();

// ❌ 错误 - 提取值后断言，没有 auto-wait
expect(await page.locator('tr').count()).toBe(3);  // flaky!
```

## 执行命令

**注意**：以下命令会根据检测到的包管理器自动调整。

```bash
# 运行所有测试（list reporter，人类可读输出）
{pm} run test

# 运行特定测试文件
{pm} run test -- e2e/tests/path/to/test.spec.ts

# 运行特定测试用例（按行号）
{pm} run test -- e2e/tests/path/to/test.spec.ts:行号
```

## 测试前提条件

1. **开发服务器**: 运行中（通常 port 5173 或 3000）
2. **数据库**: 运行中（如 Supabase: `supabase start`）
3. **后端服务**: 运行中（如 Edge Functions）
4. **测试账户存在**: 确保测试用的账户已在数据库中

## 调试失败的测试

**调试优先级（遇到错误时按此顺序检查）：**

1. **截图** - 快速了解页面状态
2. **error-context.md** - 查看可用的元素和选择器
3. **trace** - 深度调试（如果前两步无法解决）

### 1. 查看截图（最快速）

**测试输出会显示截图路径：**

```
attachment #1: screenshot (image/png)
test-results/tests-admin-xxx/test-failed-1.png
```

```bash
# 直接打开截图
open test-results/tests-admin-xxx/test-failed-1.png
```

**从截图可以看到：**
- ✅ 页面是否正确加载
- ✅ 是否有错误提示
- ✅ 元素是否可见（可能在视窗外）
- ✅ 页面停留在哪个 URL

### 2. 查看 error-context.md（找选择器）

**测试输出会显示 error-context 路径：**

```
Error Context: test-results/tests-admin-xxx/error-context.md
```

```bash
# 查看内容
cat test-results/tests-admin-xxx/error-context.md
```

**error-context.md 的价值：**

```markdown
<!-- error-context.md 示例 -->

## Accessible elements in viewport:

- group [ref=e45]:
  - textbox "PinInput" [ref=e47]:
    - /placeholder: ○
  - textbox "PinInput" [ref=e49]:
    - /placeholder: ○
  - button "Verify and Continue" [ref=e59]:
    - /type: submit
```

从这个文件你可以看到：
- ✅ **元素的 role**（button, textbox, link 等）
- ✅ **元素的 accessible name**（"PinInput", "Verify and Continue" 等）
- ✅ **元素的层级关系**（哪些元素在哪个容器内）
- ✅ **元素的属性**（placeholder, type 等）

**使用 error-context.md 修正选择器：**

```typescript
// ❌ 错误 - 使用了错误的选择器
await page.locator('input[type="number"]').fill(code);
// 失败：找不到元素

// 👀 查看 error-context.md 发现：
// - textbox "PinInput" [ref=e47]

// ✅ 正确 - 使用从 error-context.md 看到的语义化选择器
await page.getByRole('textbox', { name: 'PinInput' }).first().fill(code);
// 成功！
```

### 3. 使用 trace（深度调试）

**只在前两步无法解决时使用：**

```bash
# 运行测试并启用 trace
{pm} run test -- path/to/test.spec.ts --trace on

# 查看 trace（交互式调试界面）
npx playwright show-trace test-results/*/trace.zip
```

## 调试流程示例

```bash
# 1. 运行测试
{pm} run test -- e2e/tests/admin/feature.spec.ts

# 测试失败，输出显示：
# attachment #1: screenshot (image/png) ──────
# test-results/tests-admin-xxx/test-failed-1.png
# Error Context: test-results/tests-admin-xxx/error-context.md

# 2. 先看截图（最快）
open test-results/tests-admin-xxx/test-failed-1.png
# 发现页面显示某个错误

# 3. 查看 error-context.md（找元素）
cat test-results/tests-admin-xxx/error-context.md
# 看到可用的元素和选择器

# 4. 修正代码后重新运行
{pm} run test -- e2e/tests/admin/feature.spec.ts
```

## 工作流程

1. **理解测试范围** - 确定业务逻辑测试点
2. **创建 fixtures** - 数据创建/清理/认证
3. **编写 spec.ts** - 使用语义化选择器
4. **数据库验证** - 通过 dbAdmin 查询验证
5. **运行测试** - 使用 list reporter（默认）
6. **调试失败** - **优先级：截图 → error-context.md → trace**
