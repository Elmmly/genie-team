---
type: discovery-analysis
parent-contract: docs/backlog/P0-multi-agent-provider-framework.md
status: completed
created: 2025-12-15
---

# Discovery Analysis: Gemini CLI Conventions

> This document answers the open questions from the research spike defined in the "Multi-CLI Provider Framework" work contract. The findings are synthesized from provided code snippets representative of the Gemini CLI's internal architecture.

## Executive Summary

The Gemini CLI architecture is fundamentally different from the file-based conventions of the Claude Code host. It is a distributed, asynchronous, Python-native framework for executing complex, stateful tasks with a hierarchical agent model.

A simple "lift and shift" of `genie-team`'s markdown files is not feasible. Integration will require creating a Python-native adapter or rewriting the `genie-team` orchestration logic in Python to act as a proper `Task` within the Gemini ecosystem. The core `genie` personas and prompts, however, remain valuable and can be reused.

---

### 1. How are commands registered?

**Answer:** Commands are not registered via markdown files. They are defined as Python classes.

*   **Evidence A (`TaskHandler`):** The `TaskHandler.get_handler(task_name)` static method implies a system where a given task name is mapped to a specific Python handler class (e.g., `DCG`, `HH`, `OS`). This is a code-based routing system.
*   **Evidence B (`create_agent_structure`):** This function shows that agents themselves are defined as Python modules or packages, with a `root_agent` object serving as the entry point. The system loads these Python files, not markdown descriptions.
*   **Conclusion:** To add a `genie-team` command like `/discover` to the Gemini CLI, one would need to create a corresponding `DiscoverTask` class and a `TaskHandler` for it in Python.

---

### 2. How is the execution model different?

**Answer:** The Gemini CLI uses a distributed, asynchronous microservices architecture for task execution, built on `asyncio` and `FastAPI`.

*   **Evidence A (`TaskController`, `TaskWorker`):** The system comprises a central `TaskController` that schedules work and one or more `TaskWorker`s that execute it. Workers are separate services that register with the controller via an HTTP API and send heartbeats to signal their availability.
*   **Evidence B (`TaskClient`):** When a task is initiated, the client calls the `TaskController`, which then finds an available `TaskWorker` and forwards the request (`/start_sample`).
*   **Conclusion:** This is far more complex than `genie-team`'s model of a single host process reading a file and executing a command. It is built for resilience, scalability, and long-running, stateful operations.

---

### 3. Is there an equivalent to `Task(subagent_type=...)`?

**Answer:** Yes, the Gemini CLI has a first-class, programmatic model for hierarchical sub-agents that is more advanced than the `genie-team`'s tool-based approach.

*   **Evidence A (`BaseAgent`, `find_sub_agent`):** The code defines a `BaseAgent` with explicit `sub_agents` and `parent_agent` attributes. There are methods for traversing this agent hierarchy.
*   **Evidence B (`_build_target_agents_instructions`):** This function generates a prompt that instructs an agent on how to use a specific function (`_TRANSFER_TO_AGENT_FUNCTION_NAME`) to delegate a task to one of its sub-agents. This is a core feature of the framework.
*   **Evidence C (`_create_branch_ctx_for_sub_agent`):** The system programmatically creates a unique, isolated `InvocationContext` for each sub-agent, preventing context collision.
*   **Conclusion:** A `genie` like "Architect" would be a `BaseAgent` in Python. Its "tools" or sub-tasks would be implemented as concrete `sub_agents` (e.g., `CodeAnalysisAgent`, `FeasibilityStudyAgent`). The parent Architect agent would decide when to *transfer* control to these sub-agents, rather than an LLM deciding to use a generic "Task" tool.

---

### 4. How is context managed?

**Answer:** Context is managed programmatically through a dedicated `InvocationContext` object, not by auto-loading a single large file.

*   **Evidence A (`_create_branch_ctx_for_sub_agent`):** This function creates a *copy* of the context for each sub-agent call, creating an isolated branch for that operation. This is granular and explicit.
*   **Evidence B (`_create_empty_state`):** This function shows that initial state can be populated by parsing an agent's instruction string for `{placeholders}` and creating an empty state dictionary.
*   **Conclusion:** The reliance on a monolithic `CLAUDE.md` file is incompatible. To integrate, `genie-team`'s context would need to be broken down and injected programmatically into the `InvocationContext` when a task begins.

---

### 5. What is the security model?

**Answer:** The snippets do not reveal a declarative permissions model similar to `claude-code`'s `settings.json`. Security appears to be implicit and imperative.

*   **Evidence:** The provided snippets are all Python code. An agent's capabilities are defined by the Python code it can import and execute. For example, to access the file system, an agent would `import os`. To make a network call, it would use a library like `requests` or `aiohttp`.
*   **Conclusion:** Security is managed by the permissions of the process running the `TaskWorker`. Unlike `genie-team` where an agent *declares* the commands it needs (e.g., `Bash(git status:*)`), a Gemini agent's permissions are inherent to its code. Any integration would need to consider the security implications of the Python code being executed.
