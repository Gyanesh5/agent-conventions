#!/usr/bin/env bash
# agent-conventions 一键安装（三技能：plain-zh / coding-conventions / industrial-impeccable）
# - 技能：软链 skills/<name> 到各 agent 的 skills 目录（--copy 改为复制）
#   ~/.agents/skills  vendor-neutral 标准位：Codex/Cursor/Copilot/VS Code/Gemini CLI/OpenCode/goose/Amp 官方路径
#   ~/.claude/skills  Claude Code 专属位（它不读 ~/.agents/skills）
#   ~/.zcode/skills   zcode 专属位
# - 政策：plain-zh 常驻政策带标记幂等写入各 agent 的全局指令文件
# - Claude Code 插件通道（可选，替代软链）：/plugin marketplace add Gyanesh5/agent-conventions
# 用法：
#   ./install.sh               # 常规安装/刷新
#   ./install.sh --update      # 先 git pull 再刷新
#   ./install.sh --remove      # 撤销软链与政策块（canonical 副本保留）
set -euo pipefail

CANONICAL="${AGENT_CONVENTIONS_HOME:-$HOME/.local/share/agent-conventions}"
REPO_URL="https://github.com/Gyanesh5/agent-conventions.git"
OLD_CANONICAL="$HOME/.local/share/plain-zh"   # plain-zh 独立仓库时代的部署位，仅提示
BEGIN="<!-- agent-conventions:begin (auto-managed) -->"
END="<!-- agent-conventions:end -->"
OLD_BEGIN="<!-- plain-zh:begin (auto-managed) -->"
OLD_END="<!-- plain-zh:end -->"

SKILLS=(plain-zh coding-conventions industrial-impeccable)

REMOVE=0; UPDATE=0; ALL=0; COPY=0
for a in "$@"; do
  case "$a" in
    --remove) REMOVE=1 ;; --update) UPDATE=1 ;; --all) ALL=1 ;; --copy) COPY=1 ;;
    *) echo "未知参数: $a（可用: --update --all --copy --remove）"; exit 1 ;;
  esac
done

# skills 软链位 : 检测目录（always = 无条件，vendor-neutral 自留地多链无害）
LINKS=(
  "$HOME/.agents/skills:always"
  "$HOME/.claude/skills:$HOME/.claude"
  "$HOME/.zcode/skills:$HOME/.zcode"
)
LEGACY_LINKS=( # plain-zh v0.4 及以前的写入位，现统一收敛到 ~/.agents/skills
  "$HOME/.codex/skills/plain-zh"
  "$HOME/.config/opencode/skills/plain-zh"
  "$HOME/.gemini/skills/plain-zh"
)

# agent 名 : 根目录 : 全局指令文件（政策载体，各家路径不同，与技能软链无关）
AGENTS=(
  "claude-code:$HOME/.claude:$HOME/.claude/CLAUDE.md"
  "codex:$HOME/.codex:$HOME/.codex/AGENTS.md"
  "opencode:$HOME/.config/opencode:$HOME/.config/opencode/AGENTS.md"
  "zcode:$HOME/.zcode:$HOME/.zcode/AGENTS.md"
  "gemini:$HOME/.gemini:$HOME/.gemini/GEMINI.md"
)

strip_blocks() { # 删新旧 marker 块 + 遗留的旧版 plain-zh 段（幂等基础）
  local f="$1"
  awk -v b="$BEGIN" -v e="$END" 'index($0,b),index($0,e){next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  awk -v b="$OLD_BEGIN" -v e="$OLD_END" 'index($0,b),index($0,e){next} {print}' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  awk '/^## plain-zh/{skip=1;next} skip && /^## /{skip=0} !skip' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
}

remove_skill_links() {
  local row sdir detect skill p
  for row in "${LINKS[@]}"; do
    sdir="${row%%:*}"
    for skill in "${SKILLS[@]}"; do
      if [ -L "$sdir/$skill" ] || { [ "$COPY" = 1 ] && [ -d "$sdir/$skill" ]; }; then
        rm -rf "$sdir/$skill"; echo "removed $sdir/$skill"
      fi
    done
  done
  for p in "${LEGACY_LINKS[@]}"; do
    if [ -L "$p" ] || [ -d "$p" ]; then rm -rf "$p"; echo "removed $p（旧位置）"; fi
  done
}

if [ "$REMOVE" = 1 ]; then
  remove_skill_links
  for row in "${AGENTS[@]}"; do
    IFS=':' read -r name root gfile <<< "$row"
    if [ -f "$gfile" ]; then strip_blocks "$gfile"; echo "cleaned $gfile"; fi
  done
  echo "撤销完成。canonical 副本保留在 $CANONICAL（彻底删除: rm -rf $CANONICAL）"
  exit 0
fi

# 1) canonical 副本
if [ ! -f "$CANONICAL/plugin.json" ]; then
  SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  if [ -f "$SRC_DIR/plugin.json" ] && [ "$SRC_DIR" != "$CANONICAL" ]; then
    mkdir -p "$CANONICAL"; cp -a "$SRC_DIR"/. "$CANONICAL"/
    echo "[1/3] canonical <- 本地检出 ($CANONICAL)"
  else
    git clone --depth 1 "$REPO_URL" "$CANONICAL"
    echo "[1/3] canonical <- $REPO_URL"
  fi
elif [ "$UPDATE" = 1 ] && [ -d "$CANONICAL/.git" ]; then
  git -C "$CANONICAL" pull --ff-only >/dev/null 2>&1 || echo "  (git pull 失败，沿用当前版本)"
  echo "[1/3] canonical 已更新"
else
  echo "[1/1] canonical 已存在: $CANONICAL（--update 可拉新版）"
fi

POLICY="$(cat "$CANONICAL/skills/plain-zh/POLICY.md")"

echo "[2/3] 链接技能目录:"
for p in "${LEGACY_LINKS[@]}"; do
  if [ -L "$p" ] || [ -d "$p" ]; then rm -rf "$p"; echo "  clean  $p（旧位置）"; fi
done
linked_any=0
for row in "${LINKS[@]}"; do
  sdir="${row%%:*}"; detect="${row#*:}"
  if [ "$ALL" = 0 ] && [ "$detect" != "always" ] && [ ! -d "$detect" ]; then continue; fi
  linked_any=1
  mkdir -p "$sdir"
  for skill in "${SKILLS[@]}"; do
    if [ "$COPY" = 1 ]; then rm -rf "$sdir/$skill"; cp -r "$CANONICAL/skills/$skill" "$sdir/$skill"; echo "  copy  $sdir/$skill"
    else rm -rf "$sdir/$skill"; ln -sfn "$CANONICAL/skills/$skill" "$sdir/$skill"; echo "  link  $sdir/$skill"; fi
  done
done

echo "[3/3] 写入 plain-zh 全局政策块（幂等，可重复执行）:"
policy_any=0
for row in "${AGENTS[@]}"; do
  IFS=':' read -r name root gfile <<< "$row"
  if [ "$ALL" = 0 ] && [ ! -d "$root" ]; then continue; fi
  policy_any=1
  mkdir -p "$(dirname "$gfile")"; touch "$gfile"
  strip_blocks "$gfile"
  printf '\n%s\n\n%s\n%s\n' "$BEGIN" "$POLICY" "$END" >> "$gfile"
  echo "  $name -> $gfile"
done

if [ "$linked_any" = 0 ] && [ "$policy_any" = 0 ]; then
  echo "未检测到已安装的 agent。重跑加 --all 可预写全部兼容位（之后装任何 agent 即生效）。"
fi

[ -d "$OLD_CANONICAL" ] && echo "提示: 检测到旧部署位 $OLD_CANONICAL（plain-zh 独立仓库时代），确认无引用后可删除。"
echo "完成。以后更新: cd $CANONICAL && ./install.sh --update"
echo "（Claude Code 也可走插件通道: /plugin marketplace add Gyanesh5/agent-conventions）"
echo "（项目级编码规范接入: 在项目根执行 bash $CANONICAL/tools/conventions.sh link）"
