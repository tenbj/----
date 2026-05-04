"""
初始化工作区.py
──────────────────────────────────────────────────────────────────────
将本脚本（或由其编译出的 EXE）放到任意目录，双击运行后，
会在该目录下自动创建完整的「知识研究工作区」骨架：
  .agent/rules/       ← 4 条 Rule 文件
  .agent/skills/      ← 5 个 Skill 完整文件夹
  .memory/            ← 初始化记忆目录
  .history/           ← 历史归档目录（空）
  input/
  output/

完成后弹出提示窗口，告知初始化结果。
"""

import os
import sys
import shutil
import tkinter as tk
from tkinter import messagebox
from datetime import datetime
from pathlib import Path


# ──────────────────────────────────────────────────────────────────────
# 工具函数
# ──────────────────────────────────────────────────────────────────────

def get_templates_dir() -> Path:
    """
    PyInstaller 打包后，附加数据会解压到 sys._MEIPASS；
    开发调试时，templates/ 就在脚本同级目录。
    """
    if getattr(sys, "frozen", False):
        base = Path(sys._MEIPASS)
    else:
        base = Path(__file__).parent
    return base / "templates"


def get_workspace_root() -> Path:
    """EXE 所在目录即目标工作区根目录。"""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).parent
    else:
        return Path(__file__).parent


def ensure_dir(path: Path):
    path.mkdir(parents=True, exist_ok=True)


def copy_tree_no_pycache(src: Path, dst: Path):
    """递归复制目录，自动跳过 __pycache__。"""
    ensure_dir(dst)
    for item in src.iterdir():
        if item.name == "__pycache__":
            continue
        target = dst / item.name
        if item.is_dir():
            copy_tree_no_pycache(item, target)
        else:
            shutil.copy2(item, target)


# ──────────────────────────────────────────────────────────────────────
# 初始化记忆文件内容
# ──────────────────────────────────────────────────────────────────────

def memory_global_map_content() -> str:
    return """\
<!-- memory-version: 1.0.0 -->
# 全局知识地图

> 所有研究子项目的总索引，新建子项目时自动更新。

| 话题 | 子项目文件夹 | 创建时间 | 状态 | 核心结论（一句话） |
|------|------------|---------|------|----------------|
"""


def memory_system_record_content() -> str:
    now = datetime.now().strftime("%Y-%m-%d %H:%M")
    return f"""\
# 系统记录 · rules-skills

> 记录 Rule、Skill、脚本、备份流程、Memory 机制等系统治理相关对话，按时间追加。

---

## {now}

**用户操作**：运行「初始化工作区」工具，从零创建新的知识研究工作区骨架
**AI做了**：通过工具写入目录结构、Rules、Skills、空记忆区和历史区

---
"""


def write_if_missing(path: Path, content: str):
    if not path.exists():
        ensure_dir(path.parent)
        path.write_text(content, encoding="utf-8")


# ──────────────────────────────────────────────────────────────────────
# 主初始化逻辑
# ──────────────────────────────────────────────────────────────────────

def initialize_workspace(workspace: Path, templates: Path) -> dict:
    """
    在 workspace 下创建完整骨架。
    返回统计信息字典，用于弹窗展示。
    """
    stats = {
        "rules": 0,
        "skills": [],
        "errors": [],
    }

    # 1. 必须创建的空目录
    skeleton_dirs = [
        ".agent/rules",
        ".agent/skills",
        ".history/output",
        ".history/.agent/rules",
        ".history/.agent/skills",
        ".history/.memory/知识提炼",
        ".history/.memory/全局知识地图",
        ".memory/对话记录",
        ".memory/知识提炼",
        ".memory/系统记录",
        "input",
        "output",
    ]
    for d in skeleton_dirs:
        ensure_dir(workspace / d)

    # 2. 复制 rules
    rules_src = templates / "rules"
    rules_dst = workspace / ".agent" / "rules"
    if rules_src.exists():
        for f in rules_src.iterdir():
            if f.is_file():
                shutil.copy2(f, rules_dst / f.name)
                stats["rules"] += 1
    else:
        stats["errors"].append("模板 rules/ 目录不存在")

    # 3. 复制 skills
    skills_src = templates / "skills"
    skills_dst = workspace / ".agent" / "skills"
    if skills_src.exists():
        for skill_dir in sorted(skills_src.iterdir()):
            if skill_dir.is_dir():
                copy_tree_no_pycache(skill_dir, skills_dst / skill_dir.name)
                stats["skills"].append(skill_dir.name)
    else:
        stats["errors"].append("模板 skills/ 目录不存在")

    # 4. 初始化 .memory 文件（仅当文件不存在时写入）
    write_if_missing(
        workspace / ".memory" / "全局知识地图.md",
        memory_global_map_content(),
    )
    write_if_missing(
        workspace / ".memory" / "系统记录" / "rules-skills.md",
        memory_system_record_content(),
    )

    return stats


# ──────────────────────────────────────────────────────────────────────
# 弹窗
# ──────────────────────────────────────────────────────────────────────

def show_result_dialog(workspace: Path, stats: dict):
    """弹出自定义结果窗口，展示初始化详情。"""
    root = tk.Tk()
    root.withdraw()  # 先隐藏主窗口

    if stats["errors"]:
        error_text = "\n".join(f"  ⚠ {e}" for e in stats["errors"])
        message = (
            f"工作区初始化完成（部分警告）\n\n"
            f"路径：{workspace}\n\n"
            f"警告：\n{error_text}"
        )
        messagebox.showwarning("初始化完成（有警告）", message)
    else:
        skills_text = "\n".join(f"    · {s}" for s in stats["skills"])
        message = (
            f"✅  工作区初始化成功！\n\n"
            f"路径：{workspace}\n\n"
            f"已创建：\n"
            f"  · .agent/rules       （{stats['rules']} 个 Rule 文件）\n"
            f"  · .agent/skills      （{len(stats['skills'])} 个 Skill 文件夹）\n"
            f"{skills_text}\n"
            f"  · .memory/           （已初始化记忆文件）\n"
            f"  · .history/          （空的历史归档目录）\n"
            f"  · input/  output/\n\n"
            f"现在可以开始使用这个工作区了。"
        )
        messagebox.showinfo("🎉 初始化完成", message)

    root.destroy()


# ──────────────────────────────────────────────────────────────────────
# 入口
# ──────────────────────────────────────────────────────────────────────

def main():
    workspace = get_workspace_root()
    templates = get_templates_dir()

    # 安全检查：防止在模板源目录下运行覆盖自己
    agent_dir = workspace / ".agent"
    if agent_dir.exists() and any(agent_dir.iterdir()):
        root = tk.Tk()
        root.withdraw()
        answer = messagebox.askyesno(
            "目录已存在内容",
            f"目标目录已存在 .agent/ 内容：\n{workspace}\n\n是否继续（可能覆盖已有 Rules/Skills）？",
        )
        root.destroy()
        if not answer:
            return

    stats = initialize_workspace(workspace, templates)
    show_result_dialog(workspace, stats)


if __name__ == "__main__":
    main()
