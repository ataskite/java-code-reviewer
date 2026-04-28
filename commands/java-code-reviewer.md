---
description: Java 代码审查 — 启动交互式代码审查流程
---

Invoke the `java-code-reviewer` skill to start a Java code review session.

MUST follow this execution order strictly. Do not improvise, reorder, skip, or compress the workflow.

Run the skill in this exact sequence:

1. First: execute the four pre-scan scripts defined by the skill.
2. Then: output the pre-scan summary to the user before any parameter confirmation.
3. Then: if not in fast-start mode, use AskUserQuestion for exactly one interaction step at a time until review parameters are confirmed.
4. Then: if in fast-start mode (`--mode` present), skip AskUserQuestion entirely and perform only parameter validation.
5. Finally: start the review subagent only after the required pre-scan and confirmation/validation path is complete.

If the user provides arguments (e.g., project path, --mode, --type), pass them through as `$ARGUMENTS`.
If no arguments are provided, the skill must still pre-scan first, show the pre-scan summary, and only then guide the user through interactive configuration using AskUserQuestion.
