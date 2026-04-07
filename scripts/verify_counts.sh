#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
readme="$repo_root/README.md"

categories=(ai-ml technology science business design philosophy misc)
labels=("AI & 机器学习" "技术 & 编程" "科学 & 研究" "商业 & 经济" "设计 & 产品" "哲学 & 心理" "其他")

status=0

for i in "${!categories[@]}"; do
  category=${categories[$i]}
  label=${labels[$i]}

  actual=$(find "$repo_root/archive/$category" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')

  line=$(grep -F "archive/$category/README.md" "$readme" || true)
  if [ -z "$line" ]; then
    echo "缺少 README 分类行: $category" >&2
    status=1
    continue
  fi

  declared=$(printf '%s\n' "$line" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $4); print $4}')

  if [ "$actual" != "$declared" ]; then
    echo "分类计数不一致: $label，README=$declared，实际=$actual" >&2
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  exit 1
fi

echo "README 分类计数校验通过"
