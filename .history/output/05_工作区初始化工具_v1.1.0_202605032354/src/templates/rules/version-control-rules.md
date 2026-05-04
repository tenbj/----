---
trigger: always_on
---

所有 output/ 下的文件在每次修改前，必须先执行版本控制备份。
具体执行步骤参考并调用 Skill：版本控制备份

例外与补充：

- `.agents/rules/` 下的配置文件，只做 `.history` 备份，文件名不带版本号
- `.agents/skills/` 下的 Skill 文件夹，只做 `.history` 快照，原文件夹名称不变
- `output/` 下的内容文件，旧文件必须连同原版本号一起进入 `.history/output/`，子项目目录中只保留最新版本文件
- `.memory/对话记录/` 与 `.memory/系统记录/` 是追加型记忆，不做版本备份
- `.memory/知识提炼/` 与 `.memory/全局知识地图.md` 使用 `MEMORY` 模式：
  - 当前文件名保持稳定，不在 `.memory/` 中堆多个 `v*` 文件
  - 历史版本统一写入 `.history/.memory/`
- 禁止对 `.memory/` 目录本身做整目录快照，避免再次产生 `.history/.memory_*` 这类重复语义
