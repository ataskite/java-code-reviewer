---
description: Java 代码审查 — 启动交互式代码审查流程
---

Invoke the `java-code-reviewer` skill to start a Java code review session.

If the user provides arguments (e.g., project path, --mode, --type), pass them through as `$ARGUMENTS`. If no arguments are provided, the skill will guide the user through interactive configuration using AskUserQuestion.
