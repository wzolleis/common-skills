#!/usr/bin/env bash
# Verlinkt jeden Skill-Ordner dieses Repos (<name>/SKILL.md) nach ~/.claude/skills/<name>.
# Bestehende echte Ordner gleichen Namens werden nicht angefasst.
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)"
target="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$target"

for d in "$repo"/*/; do
  [ -d "$d" ] || continue
  n="$(basename "$d")"
  [ -f "$d/SKILL.md" ] || continue
  if [ -e "$target/$n" ] && [ ! -L "$target/$n" ]; then
    echo "übersprungen, existiert schon: $n"
    continue
  fi
  ln -sfn "${d%/}" "$target/$n"
  echo "verlinkt: $n"
done

# Verwaiste Links entfernen, die auf gelöschte Skills dieses Repos zeigen
for l in "$target"/*; do
  [ -L "$l" ] || continue
  case "$(readlink "$l")" in
    "$repo"/*) [ -e "$l" ] || { rm "$l"; echo "entfernt: $(basename "$l")"; } ;;
  esac
done
