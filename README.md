# agent-conventions

三合一 agent 规范插件：**plain-zh**（平实中文写作规范）、**coding-conventions**（编码规范路由）、**industrial-impeccable**（工业视觉 HMI 设计规则）。一个仓库，全部主流 agent 可装。

三个技能均符合 [Agent Skills](https://agentskills.io) 开放标准；插件清单符合 [Agent Plugins 1.0](https://agent-plugins.org)（Codex / VS Code / Cursor 等）与 Claude Code 插件规范（`.claude-plugin/`）。

## 安装

| 你用的 agent | 命令 |
|---|---|
| 通用（79 家，含 Codex/Cursor/Gemini CLI/Copilot/OpenCode/Amp） | `npx skills add Gyanesh5/agent-conventions --skill '*'` |
| Claude Code（插件通道） | `/plugin marketplace add Gyanesh5/agent-conventions` → `/plugin install agent-conventions@agent-conventions` |
| Codex / ChatGPT（插件通道） | `codex plugin marketplace add Gyanesh5/agent-conventions` |
| Gemini CLI（原生） | `gemini skills install https://github.com/Gyanesh5/agent-conventions.git --path skills/<技能名>`（每个技能一条） |
| 软链自管（含 zcode + plain-zh 全局政策块） | `git clone https://github.com/Gyanesh5/agent-conventions && ./agent-conventions/install.sh` |

- `npx skills add` 按需加 `-g`（全局）、`-a <agent>`（指定目标）；一条装三技能后各 agent 任务匹配时自动加载。
- `install.sh` 会把 plain-zh 常驻政策幂等写入各 agent 的全局指令文件（CLAUDE.md / AGENTS.md / GEMINI.md），并软链三个技能到 `~/.agents/skills`、`~/.claude/skills`、`~/.zcode/skills`。
- 项目级编码规范接入（symlink + AGENTS.md 模板）：在项目根执行 `bash /path/to/agent-conventions/tools/conventions.sh link`。

## 三个技能

| 技能 | 作用 | 触发场景 |
|---|---|---|
| `plain-zh` | 平实中文输出规范：术语纪律、读者校准、结构信号、文体边界四层，生成/审阅双模式，规则按证据强度分级 | 中文技术写作、教学讲解、AI 回复的生成与审阅 |
| `coding-conventions` | 编码规范路由：按文件类型加载 Python / C++ / 前端 / 测试 / 安全 / 布局规范 | 写代码、改代码、写测试之前 |
| `industrial-impeccable` | 工业视觉 HMI 设计规则：设计 tokens、八个界面族规则、项目文件底稿、代理守则 | CNC 视觉 / 协作机器人产线的操作屏、看板、标注工具、报表的设计与审查 |

## 从旧仓库迁移

本仓库由三个独立仓库收编而来（唯一真源），旧仓库已归档、历史可查：

| 旧仓库 | 现位置 |
|---|---|
| `Gyanesh5/plain-zh` | `skills/plain-zh/` |
| `Gyanesh5/ai-coding-conventions` | `skills/coding-conventions/` + `tools/conventions.sh` |
| `Gyanesh5/industrial-impeccable` | `skills/industrial-impeccable/` |

旧 `~/.local/share/plain-zh` 部署位由 `~/.local/share/agent-conventions` 取代：重跑 `install.sh` 即完成迁移（自动清理旧 marker 块与旧软链）。

## 版本

插件整体版本见根 `plugin.json`（真源，同步投影到 `.claude-plugin/`）；各技能版本在各自 `SKILL.md` 的 `metadata.version`。MIT License。
