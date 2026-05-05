---
name: 项目规范化
description: 项目结构与命名规范检查修正。按 .system/standards/workspace-spec.json 检查项目完整性，发现异常后修正：缺少补建、多余移入 .temp/规范化异常_{时间戳}/。不得修改标准文件。
---

# 项目规范化

## 何时使用

- 用户说"检查项目是否规范"、"规范化一下"、"检查结构"
- 框架体检发现结构问题后，需要修正
- 批量修改后，确认没有结构残留

## 两模式

| 参数 | 行为 |
|------|------|
| `--Check` | 逐项检查工作区标准，报告 PASS/FAIL/WARN，不修改任何文件 |
| `--Fix` | 先检查，再对 FAIL/WARN 逐项修正 |

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\项目规范化\scripts\normalize.ps1" --Check
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\项目规范化\scripts\normalize.ps1" --Fix
```

## 检查项目

| # | 区域 | 检查内容 | 标准来源 |
|---|------|---------|---------|
| 1 | 根目录 | `.agents/` `.history/` `.memory/` `.system/` `.temp/` `input/` `output/` 是否存在 | `.system/standards/workspace-spec.json` 的 `rootDirectories` |
| 2 | .agents/ | 目录结构（rules/ + 8 个 skills/）+ 关键文件存在 | `overwriteLayer.rules` + `overwriteLayer.skills` |
| 3 | output/ | 子项目文件夹命名 `{编号}_{主题}_v{版本}`，无零散文件；新结构子项目补查三类子文件夹、`目录.md`、`版本记录.md`、内部文件 `{NN}_` 编号和无 `_v*` 后缀 | `naming.subproject` + `naming.subfolder` + `naming.contentFile` |
| 4 | .memory/ | 四区块完整、固定文件名、无 _v* 历史副本残留；全局知识地图无乱码且与 `output/` 对齐 | `requiredLayer` + `memoryCleanRules` + `naming.systemRecord` |
| 5 | .history/ | 仅 `.agents/` `.memory/` `.system/` `output/` 四子目录，快照含时间戳 | `requiredLayer` + `naming.historySnapshot` |
| 6 | .system/ | `.system/standards/` 与三个标准文件存在；只补缺，不反向改标准内容 | `requiredLayer.files` + `systemCore` |
| 7 | .temp/ + input/ | 存在即可 | `rootDirectories` |

`.agents/skills/` 的 8 个必备 Skill 固定为：`创建技能`、`子项目管理`、`安装技能`、`框架体检`、`版本控制备份`、`记忆管理`、`项目规范化`、`课题研究`。其中 `课题研究/` 是项目标准能力，不得判为多余项。

## 异常修正规则

所有异常项不删除，移入 `.temp/规范化异常_{yyyyMMddHHmmss}/`，保留原路径结构：

```
.temp/规范化异常_20260504233000/
├── output/
│   └── 多余文件.md
├── .memory/
│   └── 知识提炼/
│       └── 某话题_v1.0.0.md
└── .history/
    └── .agents/
        └── skills/
            └── 无时间戳副本/
```

修正项（缺少）直接创建。对 `output/` 子项目内部做补齐或重命名之前，脚本会先把该子项目快照到 `.history/output/{子项目文件夹名}_{yyyyMMddHHmmss}/`。新结构子项目会补建三类子文件夹、按三节重建 `目录.md`、补建 `版本记录.md`，并按内容是否为空校正子文件夹版本；仍是平铺内容的老项目保持旧式检查，不自动搬迁到三子文件夹。全局知识地图修复会先把旧文件保存到 `.history/.memory/全局知识地图/`，再按当前 `output/` 重建。

`.memory/系统记录/rules-skills.md` 属于旧版聚合记忆文件，不按“多余项”直接搬走。`--Fix` 必须先读取旧文件内容，按 Rule、Skill、脚本治理、教训四类拆分追加到 `规则变更记录.md`、`技能变更记录.md`、`脚本治理记录.md`、`教训库.md`，更新 `索引.md` 后，再把原 `rules-skills.md` 归档到 `.temp/规范化迁移_{yyyyMMddHHmmss}/.memory/系统记录/`。

> 老项目迁移顺序：必须先运行最新版初始化 EXE 注入最新 `.agents` 模板，再执行本 Skill。若缺失完整 Rule/Skill 文件，`--Fix` 不会伪造空 Skill，只会提示先注入模板。

## 边界

- 不调其他 Skill 的脚本，执行逻辑自包含
- 标准定义读取自 `.system/standards/workspace-spec.json`，执行时不回写标准文件
- `--Fix` 前先跑 `--Check`，展示全景再修正
- 退出码 0 = 全 PASS，退出码 1 = 有 FAIL/WARN
