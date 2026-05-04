---
name: 版本控制备份
description: 文件版本控制备份技能。AI 每次修改文件之前，必须先执行此技能：根据目标类型把旧状态备份到 .history。output 文件会切换到新版本文件；.memory 的版本化文件保持稳定文件名，历史版本只进入 .history/.memory。
---

# 版本控制备份技能（File Version Control Backup）

## 何时使用此技能

**每次修改任何文件之前，无一例外**，必须执行此技能。包括但不限于：
- 修改文档内容
- 调整文件结构
- 补充或删除任何内容

---

## 核心流程（每次修改文件前必须完整执行）

### 第 1 步：判断目标类型，选择对应模式

根据要修改的文件/文件夹路径，确定备份模式：

| 目标路径 | 备份模式 | `-Mode` 参数 | 原文件处理 |
|---------|---------|-------------|-----------|
| `output/` 下的内容文件 | FILE | 省略（AUTO 自动识别） | 旧版本进 `.history`，工作文件**切换**到新版本号 |
| `.agents/rules/` 下的配置文件 | CONFIG | `-Mode CONFIG` | **保持不变** |
| `.agents/skills/` 下的 Skill 文件夹 | FOLDER | `-Mode FOLDER` | **保持不变** |
| `.memory/知识提炼/*.md`、`.memory/全局知识地图.md` | MEMORY | `-Mode MEMORY` 或 AUTO 自动识别 | **保持稳定文件名**，旧版本写入 `.history/.memory/` |

> **MEMORY 模式目标必须是当前态稳定文件**：文件名不能带 `_v*`。例如应操作 `.memory/知识提炼/版本管理.md`，不得操作 `.memory/知识提炼/版本管理_v1.0.0.md`；应操作 `.memory/全局知识地图.md`，不得操作 `.memory/全局知识地图_v1.2.0.md`。

> **不使用备份脚本的路径**：
>
> - `.memory/对话记录/`
> - `.memory/系统记录/`
> - `.memory/` 下任何 `*_v*.md` 历史副本
>
> 这两类文件是追加型记忆，直接原地追加，不做版本备份。
> 带 `_v*` 的 `.memory` 文件若出现在当前区，是待整理的历史副本，不是可继续编辑的 live 文件。

> **FILE 模式额外需要 `-ChangeType`**，根据本次修改幅度选择：
>
> | 变更类型 | 参数值 | 使用场景 |
> |--------|--------|---------| 
> | 大版本 | `MAJOR` | 内容结构、框架的不兼容重大修改 |
> | 小版本 | `MINOR` | 新增内容、新增章节，向下兼容 |
> | 补丁版本 | `PATCH` | 修复错误、微调描述、轻微补充 |

### 第 2 步：调用备份脚本

使用 `run_command` 工具执行 PowerShell 命令，根据模式选择对应示例：

---

#### 📄 FILE 模式 — output/ 内容文件（最常用）

旧文件会**连同原版本号一起**备份到 `.history/`，然后当前工作文件切换到新版本号。最终子项目目录中只保留最新版本文件。

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "<output/ 下文件的绝对路径>" `
    -ChangeType <MAJOR|MINOR|PATCH>
```

**示例**（微调描述，PATCH）：
```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "e:\my_project\知识研究\output\减肥第一性原理_202605031505\核心理论_v1.0.0.md" `
    -ChangeType PATCH
```

执行结果：原文件切换为 `核心理论_v1.0.1.md`，备份 `核心理论_v1.0.0.md` 到 `.history/`。

---

#### ⚙️ CONFIG 模式 — .agents/rules/ 配置文件

原文件**保持不变**，仅在 `.history/` 复制一份带时间戳的备份。

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "<.agents/rules/ 下文件的绝对路径>" `
    -Mode CONFIG
```

**示例**（备份 version-control-rules.md）：
```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "e:\my_project\知识研究\.agents\rules\version-control-rules.md" `
    -Mode CONFIG
```

执行结果：备份 `version-control-rules_202605031718.md` 到 `.history/.agents/rules/`，原文件不动。

---

#### 📁 FOLDER 模式 — .agents/skills/ Skill 文件夹

整个 Skill 文件夹被**快照**到 `.history/`（带时间戳），原文件夹**保持不变**。

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "<.agents/skills/ 下 Skill 文件夹的绝对路径>" `
    -Mode FOLDER
```

**示例**（备份整个"版本控制备份" Skill）：
```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "e:\my_project\知识研究\.agents\skills\版本控制备份" `
    -Mode FOLDER
```

执行结果：整个文件夹快照到 `.history/.agents/skills/版本控制备份_202605031718/`，原文件夹不动。

---

#### 🧠 MEMORY 模式 — .memory 的版本化文件

适用于：

- `.memory/知识提炼/{话题名}.md`
- `.memory/全局知识地图.md`

当前文件名**保持不变**，旧版本写入 `.history/.memory/`。这样 `.memory/` 只保留当前态，不再堆多个 `v*` 文件。

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "<.memory/ 下版本化文件的绝对路径>" `
    -Mode MEMORY `
    -ChangeType <MAJOR|MINOR|PATCH>
```

**示例**（更新全局知识地图，MINOR）：
```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "e:\my_project\知识研究\.memory\全局知识地图.md" `
    -Mode MEMORY `
    -ChangeType MINOR
```

执行结果：

- 当前文件仍然是 `.memory\全局知识地图.md`
- 旧版本被写入 `.history\.memory\全局知识地图\全局知识地图_v1.2.0.md`
- 文件头隐藏版本号自动从 `1.2.0` 升到 `1.3.0`

---

### 第 3 步：读取脚本输出，确认备份结果

脚本执行成功后，输出示例如下：

**FILE 模式输出示例：**
```
[OK] Backed up to: ...\核心理论_v1.0.0.md
[OK] Renamed to:   ...\核心理论_v1.0.1.md
==========================================
  File Version Backup Complete
==========================================
  Source   : ...\核心理论_v1.0.0.md
  Backup   : .history\...\核心理论_v1.0.0.md
  New File : ...\核心理论_v1.0.1.md
  Version  : v1.0.0 --> v1.0.1 (PATCH)
==========================================
```

**CONFIG 模式输出示例：**
```
[OK] Config file backed up: .history\.agents\rules\version-control-rules_202605031718.md
==========================================
  Config Backup Complete
==========================================
  Source : .agents\rules\version-control-rules.md
  Backup : .history\.agents\rules\version-control-rules_202605031718.md
==========================================
```

**FOLDER 模式输出示例：**
```
[OK] Skill folder snapshot created: .history\.agents\skills\版本控制备份_202605031718
==========================================
  Folder Snapshot Complete
==========================================
  Source   : .agents\skills\版本控制备份
  Snapshot : .history\.agents\skills\版本控制备份_202605031718
==========================================
```

**MEMORY 模式输出示例：**
```
[OK] Memory snapshot created: .history\.memory\全局知识地图\全局知识地图_v1.2.0.md
[OK] Live memory file kept stable: .memory\全局知识地图.md
==========================================
  Memory Backup Complete
==========================================
  Source    : .memory\全局知识地图.md
  Snapshot  : .history\.memory\全局知识地图\全局知识地图_v1.2.0.md
  Live File : .memory\全局知识地图.md
  Version   : v1.2.0 --> v1.3.0 (MINOR)
==========================================
```

### 第 4 步：在正确的目标文件上进行修改

| 模式 | 备份后在哪里修改 |
|------|---------------|
| FILE | 新版本文件（如 `核心理论_v1.0.1.md`） |
| CONFIG | 原文件（如 `version-control-rules.md`，名称不变） |
| FOLDER | 原 Skill 文件夹内的文件（文件夹名称不变） |
| MEMORY | 原文件（如 `.memory/全局知识地图.md`，名称不变） |

⚠️ 不得修改 `.history` 目录中的任何备份文件。

### 第 5 步：更新版本记录

- `FILE` 模式：在新版本文件底部追加版本更新记录
- `MEMORY` 模式：在当前稳定文件中继续修改内容，并同步更新文末版本记录或相关说明
`FILE` 模式示例：

```markdown
---

## 版本更新记录

| 版本 | 日期 | 变更类型 | 变更描述 |
|------|------|--------|---------| 
| v1.0.1 | 2026-05-03 | PATCH | 修复了... |
```

---

## 目录结构说明

```
e:\my_project\知识研究\
├── output\                              ← 当前工作文件（带版本号）
│   └── 减肥第一性原理_202605031505\
│       ├── 核心理论_v1.0.1.md           ← FILE 模式：子项目中只保留最新版本
│       └── ...
├── .agents\
│   ├── rules\
│   │   └── version-control-rules.md    ← CONFIG 模式：原文件名不变
│   └── skills\
│       └── 版本控制备份\                ← FOLDER 模式：原文件夹不变
├── .memory\
│   ├── 知识提炼\
│   │   └── 版本管理.md                  ← MEMORY 模式：当前态稳定文件名
│   └── 全局知识地图.md                  ← MEMORY 模式：当前态稳定文件名
└── .history\                            ← 备份目录（镜像结构）
    ├── output\
    │   └── 减肥第一性原理_202605031505\
    │       └── 核心理论_v1.0.0.md       ← FILE 历史版本（保留原版本号）
    ├── .agents\
    │   ├── rules\
    │   │   └── version-control-rules_202605031718.md  ← CONFIG 备份（时间戳）
    │   └── skills\
    │       └── 版本控制备份_202605031718\             ← FOLDER 快照（时间戳）
    └── .memory\
        ├── 知识提炼\
        │   └── 版本管理_v1.0.0.md                     ← MEMORY 历史版本
        └── 全局知识地图\
            └── 全局知识地图_v1.2.0.md                 ← MEMORY 历史版本
```

---

## 文件命名规则

- 格式：`{中文名称}_v{MAJOR}.{MINOR}.{PATCH}.{扩展名}`
- 示例：`减肥核心理论_v2.1.0.md`
- `output` 的历史备份文件保留原版本号，例如 `核心理论_v1.0.0.md`
- `.agents/rules/` 与 `.agents/skills/` 的备份仍使用时间戳
- `.memory` 当前态文件不带版本号，版本号只保留在文件头隐藏注释和 `.history/.memory/` 的历史文件名中
- `.memory` 当前区若出现 `*_v*.md`，先整理到 `.history/.memory/` 或删除已确认重复副本，不得继续对它执行备份或编辑

---

## 错误处理

| 错误信息 | 原因 | 解决方法 |
|---------|------|---------| 
| `Target not found` | 文件/文件夹路径有误 | 检查路径是否正确 |
| `Workspace root not found` | 项目根目录没有 `.history` 文件夹 | 在项目根目录手动创建 `.history` 文件夹 |

---

## 禁止行为

- ❌ 在未执行备份脚本的情况下直接修改文件
- ❌ 修改 `.history` 目录中的备份文件
- ❌ 跳过版本号判断，任意指定版本类型
- ❌ 让 `output` 子项目中同时保留多个旧版本工作文件
- ❌ 对 `.agents/rules/` 或 `.agents/skills/` 使用 FILE 模式（会错误地给文件名加版本号）
- ❌ 对 `.memory/对话记录/` 或 `.memory/系统记录/` 使用备份脚本
- ❌ 对 `.memory/` 当前区中带 `_v*` 的历史副本使用 MEMORY 模式
- ❌ 对 `.memory/` 目录做整目录快照
