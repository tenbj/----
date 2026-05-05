# SSOT 标准架构设计

> 创建时间：2026-05-05  
> 状态：已实施（.system/standards/ 已创建）

---

## 一、问题根因

框架体检（`framework-check.ps1`）、项目规范化（`normalize.ps1`）、初始化工具（`init_workspace.py`）三者各自硬编码检查/修正/创建逻辑，同一个标准散落在四个地方：

```
09_项目检查标准/   ← 7 个人读 .md 文件
framework-check.ps1  ← 硬编码检查列表
normalize.ps1        ← 硬编码修正逻辑
init_workspace.py    ← 硬编码骨架定义
```

**改其中任何一个，其他三个不会自动知道 → 永远有同步遗漏。**

---

## 二、解决方案：Single Source of Truth

### 核心设计

```
.system/standards/
├── workspace-spec.json    ← 机器可读 SSOT（唯一事实源）
└── 工作区骨架规格.md       ← 人类可读版本
```

### 消费关系

| 消费者 | 读取方式 | 原来 |
|--------|---------|------|
| `framework-check.ps1` | 运行时解析 JSON | 硬编码检查列表 |
| `normalize.ps1` | 运行时解析 JSON | 硬编码修正规则 |
| `init_workspace.py` | 构建时/运行时读取 JSON | 硬编码 skeleton_dirs |
| AI（通过 SKILL.md） | 读取人读 .md | 读 09 子项目散落文档 |

### 改动工作流（改后）

```
改标准 → 只改 workspace-spec.json + 工作区骨架规格.md
       → 三个脚本自动适配（运行时读 JSON）
       → 重新 build exe（把新 JSON 打进去）
       → 完毕
```

不再需要分别修改 framework-check.ps1 和 normalize.ps1 的检查逻辑。

---

## 三、路径选择：为什么是 `.system/`

| 方案 | 路径 | 结论 |
|------|------|------|
| A | `.agents/standards/` | ❌ `.agents` 是 IDE 自动加载目录，放非 AI 配置会乱 |
| B | `.standards/` | ○ 可行但太窄，扩展性差 |
| C | `.system/standards/` | ✅ 采纳。概念纯粹（项目基础设施），天然可扩展 |
| D | `input/standards/` | ❌ `input/` 定义是用户参考资料 |

### 语义分工

| 目录 | 职责 |
|------|------|
| `.agents/` | AI 行为配置（IDE 加载 rules + skills） |
| `.system/` | 项目基础设施（标准数据、未来可扩展） |

---

## 四、workspace-spec.json 结构概览

```json
{
  "version": "1.0.0",
  "rootDirectories": [...],          // 7 个根目录
  "overwriteLayer": {                // 覆盖层
    "rules": [...],                  // 4 个 Rule
    "skills": [...]                  // 8 个 Skill
  },
  "requiredLayer": {                 // 必备层
    "directories": [...],            // 16 个必备目录
    "files": {...},                  // 6+1 个必备文件
    "coreSubproject": {...}          // 00_系统治理
  },
  "variableLayer": {...},            // 可变层
  "naming": {                        // 命名规范
    "subproject": {...},
    "subfolder": {...},
    "contentFile": {...},
    ...
  },
  "bomCheck": {...},                 // BOM 检查清单
  "memoryCleanRules": {...}          // .memory 洁净度规则
}
```

详见 `.system/standards/workspace-spec.json`。

---

## 五、与 09_项目检查标准 旧文档的关系

| 旧文档 | 新归属 |
|--------|--------|
| `01_根目录六文件夹` | JSON `rootDirectories`（已从 6 → 7） |
| `02_.agents目录完整性` | JSON `overwriteLayer` |
| `03_output结构命名规范` | JSON `naming.subproject` + `naming.subfolder` |
| `04_.memory结构命名规范` | JSON `naming.systemRecord` + `memoryCleanRules` |
| `05_.history结构命名规范` | JSON `naming.historySnapshot` + `requiredLayer.directories` |
| `06_.temp和input检查` | JSON `rootDirectories` |

旧文档保留作为设计决策的历史记录，实际标准以 JSON 为准。

---

## 六、待执行项

| # | 动作 | 状态 |
|---|------|------|
| 1 | 创建 `.system/standards/workspace-spec.json` | ✅ 完成 |
| 2 | 创建 `.system/standards/工作区骨架规格.md` | ✅ 完成 |
| 3 | 改造 `framework-check.ps1` 读取 JSON | 🔲 待执行 |
| 4 | 改造 `normalize.ps1` 读取 JSON | 🔲 待执行 |
| 5 | 改造 `init_workspace.py` 读取 JSON | 🔲 待执行 |
| 6 | 同步 3 个不匹配模板文件到 exe | 🔲 待执行 |
| 7 | 重新 build exe | 🔲 待执行 |
| 8 | 更新 `direction-rules.md` 引用 `.system/` | 🔲 待执行 |
