# 框架与 exe 一致性检查报告

> 检查时间：2026-05-05 14:55  
> exe 版本：`初始化工作区_v1.7.2.exe`  
> 子项目路径：`output/05_工作区初始化工具_v1.8.1/03_代码程序_v0.0.0/`  
> 检查方法：全量递归 MD5 比对 `templates/` vs live `.agents/`

---

## 零、工作区结构分层（不变 vs 可变）

exe 的职责是初始化/升级「工作区骨架」。骨架由两层组成：

### 不变层（exe 必须完整、一字不差地覆盖）

| 路径 | 说明 |
|------|------|
| `.agents/rules/*.md` | 4 个 Rule 文件，每次运行 exe 都会用模板覆盖（旧版先备份） |
| `.agents/skills/*/` | 8 个 Skill 文件夹，包括 SKILL.md + scripts/ + references/ + agents/ + assets/ 等全部子文件，每次运行 exe 都会用模板覆盖 |

### 骨架层（exe 只补缺，不覆盖已有内容）

| 路径 | 说明 |
|------|------|
| `.history/output/` | 空目录占位 |
| `.history/.agents/rules/` | 空目录占位 |
| `.history/.agents/skills/` | 空目录占位 |
| `.history/.memory/知识提炼/` | 空目录占位 |
| `.history/.memory/全局知识地图/` | 空目录占位 |
| `.memory/对话记录/` | 空目录占位 |
| `.memory/知识提炼/` | 空目录占位 |
| `.memory/系统记录/` | 补建 5 个记录文件（只在不存在时写入） |
| `.memory/全局知识地图.md` | 补建初始模板（只在不存在时写入） |
| `.temp/` | 空目录占位 |
| `input/` | 空目录占位 |
| `output/` | 空目录占位 |

### 可变层（exe 不接触，用户产出）

| 路径 | 说明 |
|------|------|
| `output/*/` | 子项目内容，用户和 AI 协作产出 |
| `.memory/对话记录/*.md` | 对话追加记忆 |
| `.memory/系统记录/*.md` | 已初始化的记录文件追加内容 |
| `.memory/知识提炼/*.md` | 知识沉淀 |
| `.history/` 下各备份 | 版本控制产物 |

---

## 一、骨架目录结构比对

exe 应创建 13 个骨架目录 + 6 个初始文件。与当前 live 比对：

| 路径 | 状态 |
|------|------|
| `.agents/rules/` | ✅ OK |
| `.agents/skills/` | ✅ OK |
| `.history/output/` | ✅ OK |
| `.history/.agents/rules/` | ✅ OK |
| `.history/.agents/skills/` | ✅ OK |
| `.history/.memory/知识提炼/` | ✅ OK |
| `.history/.memory/全局知识地图/` | ✅ OK |
| `.memory/对话记录/` | ✅ OK |
| `.memory/知识提炼/` | ✅ OK |
| `.memory/系统记录/` | ✅ OK |
| `.temp/` | ✅ OK |
| `input/` | ✅ OK |
| `output/` | ✅ OK |
| `.memory/全局知识地图.md` | ✅ OK |
| `.memory/系统记录/规则变更记录.md` | ✅ OK |
| `.memory/系统记录/技能变更记录.md` | ✅ OK |
| `.memory/系统记录/脚本治理记录.md` | ✅ OK |
| `.memory/系统记录/教训库.md` | ✅ OK |
| `.memory/系统记录/索引.md` | ✅ OK |

**结论：骨架目录结构 100% 匹配，无多余、无缺失。**

---

## 二、Rules 全量比对（4 文件）

| 文件 | MD5 匹配 |
|------|---------|
| `direction-rules.md` | ✅ MATCH |
| `filename-rules.md` | ✅ MATCH |
| `memory-rules.md` | ✅ MATCH |
| `version-control-rules.md` | ✅ MATCH |

**结论：4/4 完全一致。**

---

## 三、Skills 全量递归比对（46 文件）

对 `templates/skills/` 与 `.agents/skills/` 做全量递归 MD5 比对（已排除 `__pycache__`），总共 46 个文件。

### 文件集合比对

- **模板有、live 没有**：0 个
- **live 有、模板没有**：0 个

文件集合完全一致。

### 内容比对结果

| 文件 | 状态 |
|------|------|
| `创建技能/SKILL.md` | ✅ |
| `创建技能/agents/openai.yaml` | ✅ |
| `创建技能/assets/.gitkeep` | ✅ |
| `创建技能/references/openai_yaml.md` | ✅ |
| `创建技能/references/主控技能创建增量规则.md` | ✅ |
| `创建技能/references/技能创建完整流程.md` | ✅ |
| `创建技能/references/薄技能设计模式.md` | ✅ |
| `创建技能/references/通用技能设计原则.md` | ✅ |
| `创建技能/scripts/generate_openai_yaml.py` | ✅ |
| `创建技能/scripts/init_skill.py` | ✅ |
| `创建技能/scripts/quick_validate.py` | ✅ |
| `子项目管理/SKILL.md` | ✅ |
| `子项目管理/scripts/new_project.ps1` | ✅ |
| `子项目管理/scripts/next_number.ps1` | ✅ |
| `子项目管理/scripts/normalize_project.ps1` | ✅ |
| `安装技能/SKILL.md` | ✅ |
| `安装技能/agents/openai.yaml` | ✅ |
| `安装技能/assets/.gitkeep` | ✅ |
| `安装技能/references/主控适装评估与本地化规则.md` | ✅ |
| `安装技能/references/安装后本地化检查清单.md` | ✅ |
| `安装技能/references/远端抓取与降级策略.md` | ✅ |
| `安装技能/references/通用安装与适装流程.md` | ✅ |
| `安装技能/scripts/github_utils.py` | ✅ |
| `安装技能/scripts/install-skill-from-github.py` | ✅ |
| `安装技能/scripts/list-skills.py` | ✅ |
| `框架体检/SKILL.md` | ✅ |
| `框架体检/agents/openai.yaml` | ✅ |
| `框架体检/assets/.gitkeep` | ✅ |
| `框架体检/references/扩展说明.md` | ✅ |
| `框架体检/scripts/framework-check.ps1` | ✅ |
| `版本控制备份/SKILL.md` | ✅ |
| `版本控制备份/scripts/backup.ps1` | ✅ |
| `课题研究/SKILL.md` | ✅ |
| `课题研究/agents/openai.yaml` | ✅ |
| `课题研究/assets/.gitkeep` | ✅ |
| `课题研究/references/标注规范.md` | ✅ |
| `课题研究/references/研究方法论.md` | ✅ |
| `课题研究/scripts/.gitkeep` | ✅ |
| `记忆管理/scripts/remove.ps1` | ✅ |
| **`记忆管理/SKILL.md`** | **❌ DIFFER** |
| **`项目规范化/SKILL.md`** | **❌ DIFFER** |
| **`项目规范化/scripts/normalize.ps1`** | **❌ DIFFER** |

### 不匹配文件详解

#### 1. `记忆管理/SKILL.md`

| 方面 | exe 模板（旧） | live（新） |
|------|--------------|-----------|
| 系统记录架构 | `.memory/系统记录/rules-skills.md` 单文件聚合 | 拆分为 `规则变更记录.md` / `技能变更记录.md` / `脚本治理记录.md` / `教训库.md` + `索引.md` |
| 路由写入 | 系统治理统一追加到 `rules-skills.md` | 按内容维度写入对应分类正文文件 |
| 迁移策略 | 无 | 旧 `rules-skills.md` 只作为迁移源，发现时读取内容按分类追加到四个正文文件 |
| 目录结构示意 | 单文件 `rules-skills.md` | 五文件 + 迁移禁止规则 |

> **矛盾**：exe 源码 `init_workspace.py` 第 30-36 行已经正确地初始化 5 个分类文件（`规则变更记录.md` 等），但 exe 内置的 `记忆管理/SKILL.md` 模板仍描述旧的单文件架构。这会导致新工作区的 AI 按错误的 Skill 说明写入已不存在的 `rules-skills.md`。

#### 2. `项目规范化/SKILL.md` + `项目规范化/scripts/normalize.ps1`

| 能力 | exe 模板（旧） | live（新） |
|------|--------------|-----------|
| 旧 rules-skills.md 迁移 | ❌ 无 | ✅ `Migrate-LegacySystemRecord` 完整迁移函数 |
| 系统记录索引更新 | ❌ 无 | ✅ `Update-SystemRecordIndex` 自动统计条目计数 |
| 根目录散落文件归类 | ❌ 无 | ✅ `Move-RootPayloadFilesToSubFolders`（按扩展名+关键词自动分入 01/02/03） |
| 子文件夹管理 | ❌ 基础 | ✅ `Get-SubFolderSpecByPrefix` / `Get-ProjectSubFolderByPrefix` 等完整函数组 |
| 内部文件规范化 | ❌ 无 | ✅ `Remove-InternalVersionSuffix` / `Get-NormalizedContentFileName` |
| 必备 Skill 判定 | 缺少课题研究、项目规范化 | ✅ 8 个 Skill 全部列为必备 |

---

## 四、Bug 报告：`03_代码程序_v0.0.0` 版本号错误

### 现象

`output/05_工作区初始化工具_v1.8.1/03_代码程序_v0.0.0/` 内含有 `src/`、`dist/`、`build_tmp/` 等完整代码程序资产，但版本号仍为 `v0.0.0`（按规则应为 `v1.0.0` 起步）。

### 根因分析

| 环节 | 设计 | 实际 |
|------|------|------|
| `new_project.ps1` | 创建时固定为 `v0.0.0`（空占位） | ✅ 正确 |
| `子项目管理/SKILL.md` 第 129 行 | 「若目标子文件夹仍为 v0.0.0，首次落内容前改为 v1.0.0」 | ❌ AI 手动操作时未执行此步 |
| `backup.ps1` | 只 bump 子项目文件夹版本，不处理内部 01/02/03 子文件夹版本 | ✅ 设计如此（符合"互相独立"原则） |
| `normalize.ps1` 第 259-309 行 | 有 `Get-ExpectedSubFolderVersion`（有内容=v1.0.0，无内容=v0.0.0）+ `Ensure-StructuredSubFolders` 自动 rename | ✅ 逻辑正确，但只在显式调用 `--Fix` 时生效 |

### 结论

**责任归属**：这是 AI 执行时的操作遗漏。规则在 `子项目管理/SKILL.md` 第 129 行写得很清楚：「首次落内容前改为 v1.0.0」。但 AI 在往 `03_代码程序_v0.0.0` 迁入 src/dist 时没有执行此步。

**修复方式**：运行 `normalize.ps1 --Fix`，或手动 rename `03_代码程序_v0.0.0` → `03_代码程序_v1.0.0`。

**防范建议**：可以考虑在 `backup.ps1` 的 PROJECT 模式中加一步：备份后自动检查并 bump 内部子文件夹版本号（有内容但仍为 v0.0.0 的自动升为 v1.0.0）。

---

## 五、汇总

| 类别 | 总数 | 匹配 | 不匹配 |
|------|------|------|--------|
| 骨架目录 | 13 个 | 13 | 0 |
| 骨架初始文件 | 6 个 | 6 | 0 |
| Rules 文件 | 4 个 | 4 | 0 |
| Skills 文件（递归全量） | 46 个 | 43 | **3** |
| 子文件夹版本号 bug | — | — | **1**（`03_代码程序_v0.0.0`） |

---

## 六、建议动作

| 优先级 | 动作 |
|--------|------|
| 🔴 高 | 从 live 同步 3 个不匹配文件回 `templates/skills/`，重新 build exe |
| 🔴 高 | 修复 `03_代码程序_v0.0.0` → `v1.0.0` |
| 🟡 中 | 考虑在 backup.ps1 PROJECT 模式中自动 bump v0.0.0 的子文件夹 |
