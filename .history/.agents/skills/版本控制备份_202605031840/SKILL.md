---
name: 版本控制备份
description: 文件版本控制备份技能。AI 每次修改文件之前，必须先执行此技能：将文件备份到 .history 目录，再将原文件重命名为带新版本号的文件，最后在新版本文件上进行修改。
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
| `output/` 下的内容文件 | FILE | 省略（AUTO 自动识别） | **重命名**为新版本号 |
| `.agent/rules/` 下的配置文件 | CONFIG | `-Mode CONFIG` | **保持不变** |
| `.agent/skills/` 下的 Skill 文件夹 | FOLDER | `-Mode FOLDER` | **保持不变** |

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

原文件会被**重命名为新版本号**，备份无版本号原件到 `.history/`。

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agent\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "<output/ 下文件的绝对路径>" `
    -ChangeType <MAJOR|MINOR|PATCH>
```

**示例**（微调描述，PATCH）：
```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agent\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "e:\my_project\知识研究\output\减肥第一性原理_202605031505\核心理论_v1.0.0.md" `
    -ChangeType PATCH
```

执行结果：原文件重命名为 `核心理论_v1.0.1.md`，备份 `核心理论.md` 到 `.history/`。

---

#### ⚙️ CONFIG 模式 — .agent/rules/ 配置文件

原文件**保持不变**，仅在 `.history/` 复制一份带时间戳的备份。

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agent\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "<.agent/rules/ 下文件的绝对路径>" `
    -Mode CONFIG
```

**示例**（备份 version-control-rules.md）：
```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agent\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "e:\my_project\知识研究\.agent\rules\version-control-rules.md" `
    -Mode CONFIG
```

执行结果：备份 `version-control-rules_202605031718.md` 到 `.history/.agent/rules/`，原文件不动。

---

#### 📁 FOLDER 模式 — .agent/skills/ Skill 文件夹

整个 Skill 文件夹被**快照**到 `.history/`（带时间戳），原文件夹**保持不变**。

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agent\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "<.agent/skills/ 下 Skill 文件夹的绝对路径>" `
    -Mode FOLDER
```

**示例**（备份整个"版本控制备份" Skill）：
```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agent\skills\版本控制备份\scripts\backup.ps1" `
    -TargetPath "e:\my_project\知识研究\.agent\skills\版本控制备份" `
    -Mode FOLDER
```

执行结果：整个文件夹快照到 `.history/.agent/skills/版本控制备份_202605031718/`，原文件夹不动。

---

### 第 3 步：读取脚本输出，确认备份结果

脚本执行成功后，输出示例如下：

**FILE 模式输出示例：**
```
[OK] Backed up to: ...\核心理论.md
[OK] Renamed to:   ...\核心理论_v1.0.1.md
==========================================
  File Version Backup Complete
==========================================
  Source   : ...\核心理论_v1.0.0.md
  Backup   : .history\...\核心理论.md
  New File : ...\核心理论_v1.0.1.md
  Version  : v1.0.0 --> v1.0.1 (PATCH)
==========================================
```

**CONFIG 模式输出示例：**
```
[OK] Config file backed up: .history\.agent\rules\version-control-rules_202605031718.md
==========================================
  Config Backup Complete
==========================================
  Source : .agent\rules\version-control-rules.md
  Backup : .history\.agent\rules\version-control-rules_202605031718.md
==========================================
```

**FOLDER 模式输出示例：**
```
[OK] Skill folder snapshot created: .history\.agent\skills\版本控制备份_202605031718
==========================================
  Folder Snapshot Complete
==========================================
  Source   : .agent\skills\版本控制备份
  Snapshot : .history\.agent\skills\版本控制备份_202605031718
==========================================
```

### 第 4 步：在正确的目标文件上进行修改

| 模式 | 备份后在哪里修改 |
|------|---------------|
| FILE | 新版本文件（如 `核心理论_v1.0.1.md`） |
| CONFIG | 原文件（如 `version-control-rules.md`，名称不变） |
| FOLDER | 原 Skill 文件夹内的文件（文件夹名称不变） |

⚠️ 不得修改 `.history` 目录中的任何备份文件。

### 第 5 步：在文件底部追加版本更新记录（仅 FILE 模式）

修改完成后，在文件内容底部追加版本记录（如文件中尚无此章节则新增）：

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
│       ├── 核心理论_v1.0.1.md           ← FILE 模式：AI 修改的目标文件
│       └── ...
├── .agent\
│   ├── rules\
│   │   └── version-control-rules.md    ← CONFIG 模式：原文件名不变
│   └── skills\
│       └── 版本控制备份\                ← FOLDER 模式：原文件夹不变
└── .history\                            ← 备份目录（镜像结构）
    ├── output\
    │   └── 减肥第一性原理_202605031505\
    │       └── 核心理论.md              ← FILE 备份（无版本号）
    ├── .agent\
    │   ├── rules\
    │   │   └── version-control-rules_202605031718.md  ← CONFIG 备份（时间戳）
    │   └── skills\
    │       └── 版本控制备份_202605031718\             ← FOLDER 快照（时间戳）
    └── ...
```

---

## 文件命名规则

- 格式：`{中文名称}_v{MAJOR}.{MINOR}.{PATCH}.{扩展名}`
- 示例：`减肥核心理论_v2.1.0.md`
- `.history` 中的备份文件**不带**版本号，保留原始文件名（FILE 模式）或加时间戳（CONFIG/FOLDER 模式）

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
- ❌ 直接覆盖原文件（必须先重命名）
- ❌ 对 `.agent/rules/` 或 `.agent/skills/` 使用 FILE 模式（会错误地给文件名加版本号）
