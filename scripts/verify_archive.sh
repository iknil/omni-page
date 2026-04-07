#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
readme="$repo_root/README.md"
status=0

categories=(ai-ml technology science business design philosophy misc)
labels=("AI & 机器学习" "技术 & 编程" "科学 & 研究" "商业 & 经济" "设计 & 产品" "哲学 & 心理" "其他")

echo_err() {
  echo "$1" >&2
  status=1
}

trim() {
  sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

recent_tmp=$(mktemp)
expected_recent_tmp=$(mktemp)
all_articles_tmp=$(mktemp)
find "$repo_root/archive" -mindepth 2 -maxdepth 2 -type f -name '*.md' ! -name 'README.md' | sed "s#^$repo_root/##" | sort > "$all_articles_tmp"
awk '/<!-- RECENT_START -->/{flag=1;next}/<!-- RECENT_END -->/{flag=0}flag && /^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \| \[.*\]\(archive\/.*\.md\) \| /{line=$0; sub(/^.*\]\(/, "", line); sub(/\) \| .*$/, "", line); print line}' "$readme" > "$recent_tmp"
recent_count=$(wc -l < "$recent_tmp" | tr -d ' ')
if [ "$recent_count" -gt 20 ]; then
  echo_err "主 README 最近归档条目超过 20 条: $recent_count"
fi
head -n 20 "$all_articles_tmp" > /dev/null
if [ "$(wc -l < "$all_articles_tmp" | tr -d ' ')" -le 20 ]; then
  cp "$all_articles_tmp" "$expected_recent_tmp"
else
  tail -n 20 "$all_articles_tmp" > "$expected_recent_tmp"
fi
sort "$recent_tmp" -o "$recent_tmp"
sort "$expected_recent_tmp" -o "$expected_recent_tmp"
if ! diff -u "$recent_tmp" "$expected_recent_tmp" >/dev/null 2>&1; then
  echo_err "主 README 最近归档区块与实际文章文件不同步"
fi
rm -f "$recent_tmp" "$expected_recent_tmp" "$all_articles_tmp"

for i in "${!categories[@]}"; do
  category=${categories[$i]}
  label=${labels[$i]}
  category_dir="$repo_root/archive/$category"
  category_readme="$category_dir/README.md"

  actual_count=$(find "$category_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
  readme_line=$(grep -F "archive/$category/README.md" "$readme" || true)
  if [ -z "$readme_line" ]; then
    echo_err "主 README 缺少分类行: $category"
  else
    declared_count=$(printf '%s\n' "$readme_line" | awk -F'|' '{print $4}' | trim)
    if [ "$declared_count" != "$actual_count" ]; then
      echo_err "主 README 分类计数不一致: $label，README=$declared_count，实际=$actual_count"
    fi
  fi

  tmp_expected=$(mktemp)
  tmp_actual=$(mktemp)
  find "$category_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' -print | sed "s#^$category_dir/##" | sort > "$tmp_expected"
  awk '/^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \| \[.*\]\(.*\.md\) \|$/{line=$0; sub(/^.*\]\(/, "", line); sub(/\) \|$/, "", line); print line}' "$category_readme" | sort > "$tmp_actual"
  if ! diff -u "$tmp_actual" "$tmp_expected" >/dev/null 2>&1; then
    echo_err "分类 README 与 archive/$category/ 下文件不同步"
  fi
  rm -f "$tmp_expected" "$tmp_actual"
done

all_assets_tmp=$(mktemp)
used_assets_tmp=$(mktemp)
find "$repo_root/assets" -type f | sed "s#^$repo_root/##" | sort -u > "$all_assets_tmp"
: > "$used_assets_tmp"

while IFS= read -r article; do
  article_rel=${article#$repo_root/}
  filename=$(basename "$article")
  base=${filename%.md}
  if ! printf '%s\n' "$filename" | grep -Eq '^[0-9]{8}-.+\.md$'; then
    echo_err "文件名不符合 YYYYMMDD-slug.md: $article_rel"
  fi
  slug=${base#????????-}
  if [ -z "$slug" ] || printf '%s\n' "$slug" | grep -Eq '[[:space:]]|[A-Z]'; then
    echo_err "slug 含空格或大写字母: $article_rel"
  fi
  if printf '%s\n' "$slug" | grep -Eq '[_]'; then
    echo_err "slug 不得包含下划线: $article_rel"
  fi

  if ! grep -q '^| \*\*原始标题\*\* | ' "$article"; then
    echo_err "缺少原始标题元数据: $article_rel"
  fi
  if ! grep -q '^| \*\*原始链接\*\* | ' "$article"; then
    echo_err "缺少原始链接元数据: $article_rel"
  fi
  if ! grep -q '^| \*\*原始发表日期\*\* | ' "$article"; then
    echo_err "缺少原始发表日期元数据: $article_rel"
  fi
  if ! grep -q '^|---|---|' "$article"; then
    echo_err "缺少元数据表: $article_rel"
  fi
  if ! grep -q '^## 核心内容摘要$' "$article"; then
    echo_err "缺少核心内容摘要: $article_rel"
  fi
  if ! grep -q '^## 关键要点$' "$article"; then
    echo_err "缺少关键要点: $article_rel"
  else
    keypoint_count=$(awk 'found && /^## /{exit} found && /^- /{count++} END{print count+0} /^## 关键要点$/{found=1}' "$article")
    if [ "$keypoint_count" -lt 3 ] || [ "$keypoint_count" -gt 6 ]; then
      echo_err "关键要点数量不在 3-6 条之间: $article_rel"
    fi
  fi
  if ! grep -q '^## 我的思考与感悟$' "$article"; then
    echo_err "缺少我的思考与感悟: $article_rel"
  fi

  while IFS= read -r asset_ref; do
    [ -z "$asset_ref" ] && continue
    asset_path=${asset_ref#../../}
    if [ ! -f "$repo_root/$asset_path" ]; then
      echo_err "文章引用的资源不存在: $article_rel -> $asset_ref"
    else
      printf '%s\n' "$asset_path" >> "$used_assets_tmp"
    fi
  done < <(grep -o '\.\./\.\./assets/[^)]*' "$article" || true)
done < <(find "$repo_root/archive" -type f -name '*.md' ! -name 'README.md' | sort)

sort -u "$used_assets_tmp" -o "$used_assets_tmp"
while IFS= read -r asset; do
  [ -z "$asset" ] && continue
  if ! grep -Fxq "$asset" "$used_assets_tmp"; then
    echo_err "存在孤儿资源文件: $asset"
  fi
done < "$all_assets_tmp"

rm -f "$all_assets_tmp" "$used_assets_tmp"

if [ "$status" -ne 0 ]; then
  exit 1
fi

echo "归档校验通过"
