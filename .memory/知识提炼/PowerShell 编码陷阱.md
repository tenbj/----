<!-- memory-version: 1.0.0 -->
# 知识提炼 · PowerShell 编码陷阱

> 本知识提炼属于系统治理范畴。记录在本项目中操作 PowerShell .ps1 脚本时反复踩过的编码坑，供 AI 后续操作前查阅。

---

## 2026-05-04 · BOM 丢失导致中文乱码

**核心观点**：
- Windows PowerShell 5.1 读取 `.ps1` 文件时，若文件无 BOM，按系统 ANSI 代码页（GBK）解析字节流，导致中文乱码
- Trae IDE 的 Write / SearchReplace 工具默认保存为 UTF-8 No BOM，会破坏 `[System.IO.File]::WriteAllText($path, $content, [System.Text.UTF8Encoding]::new($true))` 写入的 BOM
- `chcp 65001` 是运行时命令，无法解决 PowerShell 解析阶段的编码问题

**关键操作规则**：
1. 所有含中文的 `.ps1` 文件必须保持 UTF-8 with BOM
2. 不要用 Trae Write / SearchReplace 修改含中文的 `.ps1`
3. 应通过 ASCII-only 临时脚本或 RunCommand 调用 `[System.IO.File]` API 写入
4. `chcp 65001 > $null` 必须放在 `param()` 块之后
5. RunCommand 内联 PowerShell 中 `$null`/`$false`/`$true` 会被外层 shell 展开，需避免

**受影响文件**：
- `.agents/skills/版本控制备份/scripts/backup.ps1`
- `.agents/skills/子项目管理/scripts/new_project.ps1`

**与其他话题的关联**：
- → 版本控制备份：备份脚本本身受此约束
- → 子项目管理：子项目创建脚本本身受此约束
- → 记忆系统防漏机制：教训需要写入 AI 行动前能读取到的位置（Rule + Skill），而非仅事后记录

**嵌入位置**（防复现）：
- `version-control-rules.md`：新增「.ps1 脚本编码约束」章节（行动前必读）
- `版本控制备份/SKILL.md`：新增 `.ps1 脚本编码约束` 章节
- `子项目管理/SKILL.md`：新增 `.ps1 脚本编码约束` 章节
- `.memory/知识提炼/PowerShell 编码陷阱.md`：本文（知识沉淀）
- `.memory/系统记录/rules-skills.md`：2026-05-04 14:09 条目（操作日志）

---
