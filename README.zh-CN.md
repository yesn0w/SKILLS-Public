英文版本：[README.md](README.md)。

# SKILLS

这个仓库保存公开、可复用的 Codex 和 Claude Agent skills。

Skills 按 Codex 和 Claude 两套包并行维护。两边都使用 `SKILL.md` 元数据和相同的
小写 kebab-case 名称。Codex 包保留 Codex 专属的 `agents/openai.yaml` 界面元数据；
Claude 包不包含这类元数据，并使用 Claude 兼容的脚本引用方式，例如
`${CLAUDE_SKILL_DIR}`。辅助脚本保留在各自平台的 skill 包中，让安装后的 skill 保持自包含。

## 目录结构

- `codex/skills/`：可链接到 `~/.codex/skills` 的 Codex skill 包。
- `claude/skills/`：可链接到 `~/.claude/skills` 的 Claude skill 包。
- `common/`：说明和未来真正跨 Agent 的通用资产。
- `scripts/install-codex-skills.sh`：Codex 软链接安装脚本。
- `scripts/install-claude-skills.sh`：Claude 软链接安装脚本。
- `scripts/check.sh`：仓库校验脚本。

当前 skills，Codex 和 Claude 两边都可用：

- `bilingual-repo-docs`：维护英文和 `zh-CN` 仓库文档配对。
- `investigate-repo`：改代码前调查仓库行为和相关证据。
- `pr-prep`：检查仓库状态并准备干净的 PR 工作流。
- `latest-origin-main`：同步到干净的最新 `origin/main`。

## 命名规则

Codex 和 Claude skill 包目录以及 `SKILL.md` 的 `name` 值使用：

```text
<skill-name>
```

使用以字母开头的小写 kebab-case 名称，只包含小写字母、数字和用连字符分隔的词。
新增 skill 时选择适合公开使用的描述性名称，保持已有名称稳定，并同时添加两边的平台包：

```text
codex/skills/<skill-name>/
claude/skills/<skill-name>/
```

## 在其他电脑安装

先 clone 一次这个仓库：

```bash
git clone <repository-url> ~/agent-skills
cd ~/agent-skills
```

Codex：

```bash
bash scripts/install-codex-skills.sh
```

默认安装目标是：

```text
~/.codex/skills/
```

如果要安装到其他 Codex skills 目录，可以设置 `CODEX_SKILLS_DIR`：

```bash
CODEX_SKILLS_DIR=/path/to/skills bash scripts/install-codex-skills.sh
```

可以用 dry-run 模式预览改动：

```bash
bash scripts/install-codex-skills.sh --dry-run
```

安装后重启 Codex 或开启新会话，让 Codex 重新发现 skills。

Claude：

```bash
bash scripts/install-claude-skills.sh
```

默认安装目标是：

```text
~/.claude/skills/
```

如果要安装到其他 Claude skills 目录，可以设置 `CLAUDE_SKILLS_DIR`：

```bash
CLAUDE_SKILLS_DIR=/path/to/skills bash scripts/install-claude-skills.sh
```

可以用 dry-run 模式预览改动：

```bash
bash scripts/install-claude-skills.sh --dry-run
```

如果 Claude Code 没有自动发现这些 skills，重启 Claude Code 或开启新会话。

## 使用方式

显式触发最可靠。

Codex：

```text
Use $bilingual-repo-docs to check docs naming and links.
Use $investigate-repo to trace how authentication works before editing code.
Use $pr-prep to prepare this repo for a PR.
Use $latest-origin-main to sync this repo to the latest origin/main.
```

Claude Code：

```text
/bilingual-repo-docs check docs naming and links.
/investigate-repo trace how authentication works before editing code.
/pr-prep prepare this repo for a PR.
/latest-origin-main sync this repo to the latest origin/main.
```

当自然语言请求清楚匹配 skill 描述时，也可能自动触发。

## 校验

提交修改前运行仓库检查：

```bash
bash scripts/check.sh
```
