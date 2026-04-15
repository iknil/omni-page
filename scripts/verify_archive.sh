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

check_home_count() {
  local label=$1
  local expected=$2
  local line
  line=$(grep -F "| [$label]" "$readme" | head -n 1 || true)
  if [ -z "$line" ]; then
    echo_err "主 README 缺少内容空间行: $label"
    return
  fi

  local declared
  declared=$(printf '%s\n' "$line" | awk -F'|' '{print $4}' | trim)
  if [ "$declared" != "$expected" ]; then
    echo_err "主 README 内容空间计数不一致: ${label}，README=${declared}，实际=${expected}"
  fi
}

check_main_recent_section() {
  local start_marker=$1
  local end_marker=$2
  local pattern=$3
  local source_dir=$4
  local tmp_actual
  local tmp_expected

  tmp_actual=$(mktemp)
  tmp_expected=$(mktemp)

  awk "/$start_marker/{flag=1;next}/$end_marker/{flag=0}flag" "$readme" | \
    awk "$pattern" | sort > "$tmp_actual"
  find "$repo_root/$source_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | \
    sed "s#^$repo_root/##" | sort > "$tmp_expected"

  if ! diff -u "$tmp_actual" "$tmp_expected" >/dev/null 2>&1; then
    echo_err "主 README 区块 $start_marker 与 $source_dir 不同步"
  fi

  rm -f "$tmp_actual" "$tmp_expected"
}

check_index_readme() {
  local readme_path=$1
  local marker_name=$2
  local dir_path=$3
  local pattern=$4
  local tmp_actual
  local tmp_expected

  tmp_actual=$(mktemp)
  tmp_expected=$(mktemp)

  awk "$pattern" "$readme_path" | sort > "$tmp_actual"
  find "$dir_path" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' -print | \
    sed "s#^$dir_path/##" | sort > "$tmp_expected"

  if ! diff -u "$tmp_actual" "$tmp_expected" >/dev/null 2>&1; then
    echo_err "$marker_name 与 $(basename "$dir_path")/ 下文件不同步"
  fi

  rm -f "$tmp_actual" "$tmp_expected"
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

inspiration_count=$(find "$repo_root/inspirations" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
knowledge_count=$(find "$repo_root/knowledge" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
archive_count=$(find "$repo_root/archive" -mindepth 2 -maxdepth 2 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')

check_home_count "文章归档" "$archive_count"
check_home_count "个人灵感" "$inspiration_count"
check_home_count "知识点" "$knowledge_count"

check_main_recent_section '<!-- INSPIRATION_START -->' '<!-- INSPIRATION_END -->' '/^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \| \[.*\]\(inspirations\/.*\.md\) \| /{line=$0; sub(/^.*\]\(/, "", line); sub(/\) \| .*$/, "", line); print line}' "inspirations"
check_main_recent_section '<!-- KNOWLEDGE_START -->' '<!-- KNOWLEDGE_END -->' '/^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \| \[.*\]\(knowledge\/.*\.md\) \| /{line=$0; sub(/^.*\]\(/, "", line); sub(/\) \| .*$/, "", line); print line}' "knowledge"

for i in "${!categories[@]}"; do
  category=${categories[$i]}
  label=${labels[$i]}
  category_dir="$repo_root/archive/$category"
  category_readme="$category_dir/README.md"

  actual_count=$(find "$category_dir" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | wc -l | tr -d ' ')
  readme_line=$(grep -F "| [$label](archive/$category/README.md) |" "$readme" | head -n 1 || true)
  if [ -z "$readme_line" ]; then
    echo_err "主 README 缺少分类行: $category"
  else
    declared_count=$(printf '%s\n' "$readme_line" | awk -F'|' '{print $4}' | trim)
    if [ "$declared_count" != "$actual_count" ]; then
      echo_err "主 README 分类计数不一致: ${label}，README=${declared_count}，实际=${actual_count}"
    fi
  fi

  check_index_readme \
    "$category_readme" \
    "分类 README archive/$category/README.md" \
    "$category_dir" \
    '/^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \| \[.*\]\(.*\.md\) \|$/{line=$0; sub(/^.*\]\(/, "", line); sub(/\) \|$/, "", line); print line}'

  if ! grep -qE '^\| ---- \| ---- \|$' "$category_readme"; then
    echo_err "分类 README 缺少表格分隔行: archive/$category/README.md"
  fi
done

check_index_readme \
  "$repo_root/inspirations/README.md" \
  "灵感索引 inspirations/README.md" \
  "$repo_root/inspirations" \
  '/^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \| \[.*\]\(.*\.md\) \| .* \|$/{line=$0; sub(/^.*\]\(/, "", line); sub(/\) \| .*$/, "", line); print line}'

check_index_readme \
  "$repo_root/knowledge/README.md" \
  "知识点索引 knowledge/README.md" \
  "$repo_root/knowledge" \
  '/^\| [0-9]{4}-[0-9]{2}-[0-9]{2} \| \[.*\]\(.*\.md\) \| .* \|$/{line=$0; sub(/^.*\]\(/, "", line); sub(/\) \| .*$/, "", line); print line}'

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

while IFS= read -r inspiration; do
  inspiration_rel=${inspiration#$repo_root/}
  if ! grep -q '^| \*\*记录时间\*\* | ' "$inspiration"; then
    echo_err "缺少记录时间元数据: $inspiration_rel"
  fi
  if ! grep -q '^| \*\*灵感类型\*\* | ' "$inspiration"; then
    echo_err "缺少灵感类型元数据: $inspiration_rel"
  fi
  if ! grep -q '^| \*\*来源场景\*\* | ' "$inspiration"; then
    echo_err "缺少来源场景元数据: $inspiration_rel"
  fi
  if ! grep -q '^| \*\*状态\*\* | ' "$inspiration"; then
    echo_err "缺少状态元数据: $inspiration_rel"
  fi
  if ! grep -q '^| \*\*关联知识点\*\* | ' "$inspiration"; then
    echo_err "缺少关联知识点元数据: $inspiration_rel"
  fi
  if ! grep -q '^## 灵感内容$' "$inspiration"; then
    echo_err "缺少灵感内容: $inspiration_rel"
  fi
  if ! grep -q '^## 可沉淀方向$' "$inspiration"; then
    echo_err "缺少可沉淀方向: $inspiration_rel"
  fi
  if ! grep -q '^## 后续动作$' "$inspiration"; then
    echo_err "缺少后续动作: $inspiration_rel"
  fi

  while IFS= read -r asset_ref; do
    [ -z "$asset_ref" ] && continue
    asset_path=${asset_ref#../}
    if [ ! -f "$repo_root/$asset_path" ]; then
      echo_err "灵感引用的资源不存在: $inspiration_rel -> $asset_ref"
    else
      printf '%s\n' "$asset_path" >> "$used_assets_tmp"
    fi
  done < <(grep -o '\.\./assets/[^)]*' "$inspiration" || true)
done < <(find "$repo_root/inspirations" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort)

while IFS= read -r knowledge; do
  knowledge_rel=${knowledge#$repo_root/}
  if ! grep -q '^| \*\*知识点\*\* | ' "$knowledge"; then
    echo_err "缺少知识点元数据: $knowledge_rel"
  fi
  if ! grep -q '^| \*\*沉淀日期\*\* | ' "$knowledge"; then
    echo_err "缺少沉淀日期元数据: $knowledge_rel"
  fi
  if ! grep -q '^| \*\*来源灵感\*\* | ' "$knowledge"; then
    echo_err "缺少来源灵感元数据: $knowledge_rel"
  fi
  if ! grep -q '^| \*\*关联归档\*\* | ' "$knowledge"; then
    echo_err "缺少关联归档元数据: $knowledge_rel"
  fi
  if ! grep -q '^| \*\*状态\*\* | ' "$knowledge"; then
    echo_err "缺少状态元数据: $knowledge_rel"
  fi
  if ! grep -q '^## 核心结论$' "$knowledge"; then
    echo_err "缺少核心结论: $knowledge_rel"
  fi
  if ! grep -q '^## 论证与展开$' "$knowledge"; then
    echo_err "缺少论证与展开: $knowledge_rel"
  fi
  if ! grep -q '^## 可复用方法$' "$knowledge"; then
    echo_err "缺少可复用方法: $knowledge_rel"
  fi
  if ! grep -q '^## 关联来源$' "$knowledge"; then
    echo_err "缺少关联来源: $knowledge_rel"
  fi
  if ! grep -Eq '\.\./inspirations/.*\.md' "$knowledge"; then
    echo_err "知识点缺少来源灵感链接: $knowledge_rel"
  fi

  while IFS= read -r asset_ref; do
    [ -z "$asset_ref" ] && continue
    asset_path=${asset_ref#../}
    if [ ! -f "$repo_root/$asset_path" ]; then
      echo_err "知识点引用的资源不存在: $knowledge_rel -> $asset_ref"
    else
      printf '%s\n' "$asset_path" >> "$used_assets_tmp"
    fi
  done < <(grep -o '\.\./assets/[^)]*' "$knowledge" || true)
done < <(find "$repo_root/knowledge" -maxdepth 1 -type f -name '*.md' ! -name 'README.md' | sort)

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
