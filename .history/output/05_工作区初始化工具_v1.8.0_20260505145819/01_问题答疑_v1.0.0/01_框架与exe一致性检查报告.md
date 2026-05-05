# 框架与 exe 一致性检查报告

> 检查时间：2026-05-05 14:42  
> 检查对象：`05_工作区初始化工具_v1.8.0`（exe 版本 v1.7.2）  
> 检查方法：对 templates/ 与 .agents/ 各类文件做 MD5 哈希比对

---

## 一、检查范围

| 层次 | 检查项 |
|------|--------|
| Rules | direction-rules.md / filename-rules.md / memory-rules.md / version-control-rules.md |
| Skills SKILL.md | 8 个 skill 的 SKILL.md 主体文件 |
| Skills Scripts | backup.ps1 / new_project.ps1 / next_number.ps1 / normalize_project.ps1 / framework-check.ps1 / normalize.ps1 / remove.ps1 |

---

## 二、检查结论

### ✅ 完全匹配项

| 类型 | 文件 |
|------|------|
| Rule | direction-rules.md |
| Rule | filename-rules.md |
| Rule | memory-rules.md |
| Rule | version-control-rules.md |
| Skill SKILL.md | 安装技能 |
| Skill SKILL.md | 版本控制备份 |
| Skill SKILL.md | 创建技能 |
| Skill SKILL.md | 课题研究 |
| Skill SKILL.md | 框架体检 |
| Skill SKILL.md | 子项目管理 |
| Script | 版本控制备份/scripts/backup.ps1 |
| Script | 子项目管理/scripts/new_project.ps1 |
| Script | 子项目管理/scripts/next_number.ps1 |
| Script | 子项目管理/scripts/normalize_project.ps1 |
| Script | 框架体检/scripts/framework-check.ps1 |
| Script | 记忆管理/scripts/remove.ps1 |

**全部 4 个 Rule 文件完全匹配。**

---

### ❌ 不匹配项（exe 模板落后于 live）

#### 1. `记忆管理/SKILL.md`

**差异根因**：exe 模板中使用旧的「单文件聚合」架构（`rules-skills.md`），live 版本已升级为「四分类文件」架构（`规则变更记录.md` / `技能变更记录.md` / `脚本治理记录.md` / `教训库.md` + `索引.md`）。

| 方向 | 内容 |
|------|------|
| exe 模板（旧） | `.memory/系统记录/rules-skills.md` 单文件聚合，第一阶段默认聚合到此文件 |
| live（新） | 拆分为四个分类正文文件 + `索引.md`；旧 `rules-skills.md` 仅作迁移源 |

影响：用 exe 初始化的新工作区，记忆管理 SKILL.md 描述的是旧架构，与实际运作机制不一致。

---

#### 2. `项目规范化/SKILL.md` + `项目规范化/scripts/normalize.ps1`

**差异根因**：`normalize.ps1` 是 live 最近大幅重构版本，exe 模板为旧版本。核心差异：

| 功能点 | exe 模板（旧） | live（新） |
|--------|--------------|-----------|
| 系统记录架构 | 单文件 `rules-skills.md` | 四分类文件 + 索引 |
| 旧文件迁移 | 不含迁移逻辑 | 含 `Migrate-LegacySystemRecord` 完整迁移函数 |
| 根目录内容文件归类 | 不含 | 含 `Move-RootPayloadFilesToSubFolders`（按扩展名+关键词自动归类到 01/02/03） |
| 子文件夹操作 | 基础 | 含 `Get-SubFolderSpecByPrefix` / `Get-ProjectSubFolderByPrefix` 等完整函数组 |

影响：用 exe 初始化的新工作区运行 `normalize.ps1`，缺少以下能力：
- 无法自动迁移旧 `rules-skills.md` 到四分类结构
- 无法自动将子项目根目录下散落的内容文件归类到三分类子文件夹

---

## 三、汇总

| 类别 | 总数 | 匹配 | 不匹配 |
|------|------|------|--------|
| Rules | 4 | 4 | 0 |
| Skills SKILL.md | 8 | 6 | **2**（记忆管理、项目规范化） |
| Scripts | 7 | 6 | **1**（normalize.ps1） |

---

## 四、建议动作

| 优先级 | 动作 |
|--------|------|
| 🔴 高 | 将 live `.agents/skills/记忆管理/SKILL.md` 同步回 `03_代码程序/src/templates/skills/记忆管理/SKILL.md` |
| 🔴 高 | 将 live `.agents/skills/项目规范化/SKILL.md` 同步回 `03_代码程序/src/templates/skills/项目规范化/SKILL.md` |
| 🔴 高 | 将 live `.agents/skills/项目规范化/scripts/normalize.ps1` 同步回 `03_代码程序/src/templates/skills/项目规范化/scripts/normalize.ps1` |
| 🟡 中 | 重新 build exe（运行 `build.ps1`），生成与当前 live 框架一致的新版 exe |
| 🟡 中 | 更新 `03_代码程序` 子文件夹版本号（当前 `v0.0.0` → 首次有实质修改后升为 `v1.0.0`） |
