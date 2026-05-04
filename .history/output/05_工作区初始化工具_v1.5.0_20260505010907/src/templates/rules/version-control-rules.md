---
trigger: always_on
---

所有 output/ 下的文件在每次修改前，必须先执行版本控制备份。
具体执行步骤参考并调用 Skill：版本控制备份

例外与补充：

- output/ 下的子项目文件夹使用 PROJECT 模式：
  - 文件夹命名：`{编号}_{主题}_v{x.y.z}`
  - 备份：整个文件夹快照到 `.history/output/{文件夹名}_{yyyyMMddHHmmss}/`，live 文件夹 bump 版本号
  - 每个子项目内含 `版本记录.md`，记录整体版本变更历史和子文件变更明细
  - 子项目版本号与子文件版本号互相独立
  - **备份脚本会自动同步 `.memory/对话记录/{子项目文件夹名}.md` 的文件名**（与子项目文件夹版本号保持一致）
- `.agents/rules/` 下的配置文件，只做 `.history` 备份，文件名不带版本号
- `.agents/skills/` 下的 Skill 文件夹，只做 `.history` 快照，原文件夹名称不变
- `.memory/对话记录/` 与 `.memory/系统记录/` 是追加型记忆，不做版本备份
- `.memory/知识提炼/` 与 `.memory/全局知识地图.md` 使用 `MEMORY` 模式：
  - 当前文件名保持稳定，不在 `.memory/` 中堆多个 `v*` 文件
  - 历史版本统一写入 `.history/.memory/`
- 禁止对 `.memory/` 目录本身做整目录快照
- 禁止对 output/ 下的单个文件使用 FILE 模式（已废弃）
