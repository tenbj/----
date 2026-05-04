---
name: 项目规范化
description: 项目结构与命名规范检查修正。按六项标准检查项目完整性，发现异常后修正：缺少补建、多余移入 .temp/规范化异常_{时间戳}/。标准定义在 output/09_项目检查标准_*/ 下。
---

# 项目规范化

## 何时使用

- 用户说"检查项目是否规范"、"规范化一下"、"检查结构"
- 框架体检发现结构问题后，需要修正
- 批量修改后，确认没有结构残留

## 两模式

| 参数 | 行为 |
|------|------|
| `--Check` | 逐项检查六项标准，报告 PASS/FAIL/WARN，不修改任何文件 |
| `--Fix` | 先检查，再对 FAIL/WARN 逐项修正 |

```powershell
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\项目规范化\scripts\normalize.ps1" --Check
powershell -ExecutionPolicy Bypass -File "e:\my_project\知识研究\.agents\skills\项目规范化\scripts\normalize.ps1" --Fix
```

## 六项检查

| # | 区域 | 检查内容 | 标准来源 |
|---|------|---------|---------|
| 1 | 根目录 | `.agents/` `.history/` `.memory/` `output/` `input/` `.temp/` 是否存在 | `06_.temp和input检查` + `01_根目录六文件夹` |
| 2 | .agents/ | 目录结构（rules/ + 6 个 skills/）+ 关键文件存在 | `02_.agents目录完整性` |
| 3 | output/ | 子项目文件夹命名 `{编号}_{主题}_v{版本}`，无零散文件 | `03_output结构命名规范` |
| 4 | .memory/ | 四区块完整、固定文件名、无 _v* 历史副本残留 | `04_.memory结构命名规范` |
| 5 | .history/ | 仅 `.agents/` `.memory/` `output/` 三子目录，快照含时间戳 | `05_.history结构命名规范` |
| 6 | .temp/ + input/ | 存在即可 | `06_.temp和input检查` |

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

修正项（缺少）直接创建。

## 边界

- 不调其他 Skill 的脚本，执行逻辑自包含
- 标准定义读取自 `output/09_项目检查标准_*/`，执行时不回写标准文件
- `--Fix` 前先跑 `--Check`，展示全景再修正
- 退出码 0 = 全 PASS，退出码 1 = 有 FAIL/WARN
