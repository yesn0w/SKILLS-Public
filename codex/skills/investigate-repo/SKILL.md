---
name: investigate-repo
description: Investigate an unfamiliar repository, feature, bug, behavior, architecture question, or code path before editing. Use when Codex is asked to understand how something works, locate an implementation, trace data or control flow, explain why behavior occurs, assess impact, find related tests or configs, or report evidence-backed findings without immediately changing code.
---

# Investigate Repo

## Principles

- Investigate before editing. Keep commands read-only unless the user asks for implementation or validation requires a harmless local run.
- Follow the active repository's instructions first, especially `AGENTS.md`, README files, test docs, and task-specific notes.
- Prefer `rg` and `rg --files` for file and text search. Use language-aware tools, package scripts, and framework conventions when they are clearer than raw search.
- Trace behavior through entry points, call sites, data models, configuration, tests, generated types, and runtime wiring before forming a conclusion.
- Separate facts from inferences. State uncertainty when evidence is incomplete.
- Do not treat one failed search as proof of absence. Search related identifiers, user-facing strings, route names, config keys, and test names.

## Workflow

1. Clarify the investigation target:
   - restate the behavior, subsystem, bug, or question in concrete terms.
   - identify whether the user wants read-only findings or an implementation after investigation.
2. Read the local operating context:
   - inspect `AGENTS.md` or equivalent instructions.
   - skim project layout, package manifests, scripts, and top-level docs.
   - check `git status --short` when edits may follow, so unrelated changes are not confused with evidence.
3. Find likely entry points:
   - search for exact names, visible text, API paths, component names, command names, environment variables, schema fields, and error messages.
   - inspect routing, dependency injection, command registration, job scheduling, migrations, or framework-specific conventions when relevant.
4. Trace the path:
   - follow definitions to call sites and callers.
   - include tests, fixtures, mocks, config, and generated code when they affect behavior.
   - note cross-cutting concerns such as permissions, feature flags, caching, async jobs, persistence, validation, and serialization.
5. Validate the understanding:
   - run focused read-only or low-risk commands when useful, such as type checks, targeted tests, grep counts, or framework introspection.
   - explain when validation is skipped because dependencies, credentials, network access, or runtime services are unavailable.
6. Report findings:
   - answer the user's question first.
   - cite the key files and line references.
   - summarize the evidence chain and any important alternatives ruled out.
   - list open questions, assumptions, and suggested next actions only when they materially affect the answer.

## Output Shape

Use this structure for non-trivial investigations:

- **Answer**: concise conclusion.
- **Evidence**: files, symbols, configs, tests, and commands that support the conclusion.
- **Impact**: affected flows or risk areas.
- **Gaps**: missing evidence or validation that could change the conclusion.
- **Next Step**: the smallest useful follow-up, such as implementing a fix, adding a test, or checking a runtime environment.

For small investigations, use a shorter prose answer with the same evidence discipline.
