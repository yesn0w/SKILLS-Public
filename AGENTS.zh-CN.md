英文版本：[AGENTS.md](AGENTS.md)。

# 仓库说明

这个仓库保存 Codex 和 Claude skill 包。

## 结构

- 完整 Codex skill 包放在 `codex/skills/44-NN-<skill-name>/`。
- 完整 Claude skill 包放在 `claude/skills/44-NN-<skill-name>/`。
- 每个 skill 都必须同时有 Codex 和 Claude 包，并使用相同的
  `44-NN-<skill-name>` 目录名和 `SKILL.md` 的 `name` 值。
- 只有真正跨 Agent 的通用资产才放在 `common/`。
- 仓库自动化脚本放在 `scripts/`。

## Skill 包规则

- 每个 Codex 和 Claude skill 包都必须包含 `SKILL.md`。
- skill 目录名和 `SKILL.md` 的 `name` 值必须匹配 `44-NN-<skill-name>`。
- 使用从 `01` 开始的两位数序号；新增 skill 使用下一个未占用序号，并保持已有序号稳定。
- 当 `agents/openai.yaml` 提供 Codex 界面元数据时，保留在对应 skill 内。
- Claude 包不要包含 `agents/openai.yaml`。
- Claude 包中引用随包辅助脚本时，使用 `${CLAUDE_SKILL_DIR}`，这样无论安装在个人、
  项目还是插件级 skills 目录都能工作。
- 当 `SKILL.md` 使用相对路径引用辅助脚本时，脚本保留在对应 skill 包内。
- 不要因为脚本看起来通用就移动到 `common/`，除非同一次修改也更新 skill 文档和安装逻辑。

## 文档规则

- 英文 Markdown 文件不加语言后缀，例如 `README.md`。
- 中文 Markdown 文件使用 `zh-CN` 后缀，例如 `README.zh-CN.md`。
- 面向用户的仓库文档应尽量成对维护。
- 每个成对文件顶部附近添加对应语言版本链接。
- 英文和中文文档保持行为等价。

## 校验

提交前运行：

```bash
bash scripts/check.sh
```
