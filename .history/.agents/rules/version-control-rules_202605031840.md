---
trigger: always_on
---

所有 output/ 下的文件在每次修改前，必须先执行版本控制备份。
具体执行步骤参考并调用 Skill：版本控制备份

例外：.agent/rules/ 和 .agent/skills/ 下的配置文件，只做 .history 备份，文件名不带版本号。