#!/usr/bin/env bash
# update_index.sh — Auto-update all README indices in omni-page
# Idempotent: safe to run multiple times, produces the same result.
# Uses only standard Unix tools (bash, awk, sort).

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TMPDIR="${TMPDIR:-/tmp}"
WORK=$(mktemp -d "$TMPDIR/update_index.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

# ── Category mapping ────────────────────────────────────────────────────────
declare -A CATEGORY_MAP=(
  [ai-ml]="AI & 机器学习"
  [technology]="技术 & 编程"
  [science]="科学 & 研究"
  [business]="商业 & 经济"
  [design]="设计 & 产品"
  [philosophy]="哲学 & 心理"
  [misc]="其他"
)
CATEGORY_ORDER=(ai-ml technology science business design philosophy misc)

# ── Helpers ─────────────────────────────────────────────────────────────────

extract_title() {
  local file="$1"
  local title
  title=$(awk '
    /^#/ && !done {
      sub(/^#+/, ""); sub(/^[ \t]+/, "");
      if (length > 0) { print; done=1 }
    }
    END { if (!done) exit 1 }
  ' "$file" 2>/dev/null) || title=""
  if [[ -z "$title" ]]; then
    title=$(basename "$file" .md | sed 's/^[0-9]\{8\}-//')
  fi
  printf '%s' "$title"
}

extract_type() {
  local file="$1"
  local type
  type=$(awk '
    /^#/ && !done {
      if (/类型[：:]/) {
        sub(/.*类型[：:]/, ""); sub(/\|.*/, ""); gsub(/^[ \t]+|[ \t]+$/, "");
        if (length > 0) { print; done=1 }
      }
    }
    /^#.*灵感$|^#.*灵感捕捉/ && !done { print "mixed"; done=1 }
    /^#.*架构图|^#.*图$|^#.*diagram/ && !done { print "image"; done=1 }
  ' "$file" 2>/dev/null)
  if [[ -z "$type" ]]; then
    type="mixed"
  fi
  printf '%s' "$type"
}

extract_status() {
  local file="$1"
  local status
  status=$(awk '
    /^#/ && !done {
      if (/状态[：:]/) {
        sub(/.*状态[：:]/, ""); sub(/\|.*/, ""); gsub(/^[ \t]+|[ \t]+$/, "");
        if (length > 0) { print; done=1 }
      }
    }
  ' "$file" 2>/dev/null)
  if [[ -z "$status" ]]; then
    status="seed"
  fi
  printf '%s' "$status"
}

get_file_date() {
  local file="$1"
  local date_part
  date_part=$(basename "$file" | cut -d'-' -f1)
  if ! [[ "$date_part" =~ ^[0-9]{8}$ ]]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      stat -f "%Sm" -t "%Y%m%d" "$file" 2>/dev/null || echo "19700101"
    else
      stat -c "%Y" "$file" 2>/dev/null | xargs -I{} date -d @{} +"%Y%m%d" 2>/dev/null || echo "19700101"
    fi
    return
  fi
  printf '%s' "$date_part"
}

format_date() {
  local d="$1"
  printf '%s-%s-%s' "${d:0:4}" "${d:4:2}" "${d:6:2}"
}

# Write formatted table rows to a temp file, one row per line.
# Usage: write_article_rows OUT_FILE CAT_DIR
#   Format written: date_raw|date_fmt|title|fname
write_article_rows() {
  local out="$1"
  local cat_dir="$2"
  > "$out"
  while IFS= read -r f; do
    local date_raw title fname
    date_raw=$(get_file_date "$f")
    title=$(extract_title "$f")
    fname=$(basename "$f")
    printf '%s|%s|%s|%s\n' "$date_raw" "$title" "$fname" >> "$out"
  done < <(find "$cat_dir" -maxdepth 1 -name "*.md" ! -name "README.md" -type f)
}

# ── Update archive category READMEs ─────────────────────────────────────────

echo "==> Updating archive category READMEs"

for cat in "${CATEGORY_ORDER[@]}"; do
  cat_dir="$PROJECT_DIR/archive/$cat"
  readme="$cat_dir/README.md"

  if [[ ! -f "$readme" ]]; then
    continue
  fi

  # Build and sort raw rows, then replace in README
  # Format: date_raw|title|fname
  write_article_rows "$WORK/cat_rows_${cat}.txt" "$cat_dir"
  sort -t'|' -k1,1 -rn "$WORK/cat_rows_${cat}.txt" > "$WORK/cat_rows_${cat}_sorted.txt" 2>/dev/null || \
    cp "$WORK/cat_rows_${cat}.txt" "$WORK/cat_rows_${cat}_sorted.txt"

  # Find header line number and ARTICLES_END line number
  hdr_linenum=$(awk '/^\| 日期 \| 文章 \|$/{print NR; exit}' "$readme")
  end_linenum=$(awk '/\-\- ARTICLES_END \-\-/{print NR; exit}' "$readme")
  if [[ -z "$hdr_linenum" ]] || [[ -z "$end_linenum" ]]; then
    echo "  WARNING: Missing markers in $readme, skipping"
    continue
  fi

  # Write formatted rows to temp file
  > "$WORK/cat_rows_formatted_${cat}.txt"
  while IFS='|' read -r date_raw title fname _; do
    date_fmt=$(format_date "$date_raw")
    printf '| %s | [%s](%s) |\n' "$date_fmt" "$title" "$fname"
  done < "$WORK/cat_rows_${cat}_sorted.txt" >> "$WORK/cat_rows_formatted_${cat}.txt"

  # Pure awk: print ONLY lines 1..hdr_linenum (header block).
  # ARTICLES_END and footer are handled by separate tail below.
  awk -v n="$hdr_linenum" '
    NR <= n { print; next }
    { next }
  ' "$readme" > "${readme}.pre"

  # Save ARTICLES_END and footer from original BEFORE awk modifies it
  tail -n +$((end_linenum)) "$readme" > "$WORK/cat_rows_end_${cat}.txt"

  # Concatenate: header block + new rows + (ARTICLES_END + blank + footer)
  { cat "${readme}.pre"; cat "$WORK/cat_rows_formatted_${cat}.txt"; cat "$WORK/cat_rows_end_${cat}.txt"; } > "${readme}.tmp" && \
    mv "${readme}.tmp" "$readme"
  rm -f "${readme}.pre" "$WORK/cat_rows_end_${cat}.txt"

  echo "  Updated $readme"
done

echo ""
echo "==> Updating main README.md"

main_readme="$PROJECT_DIR/README.md"

# ── 1. Update category table counts ─────────────────────────────────────────

for cat in "${CATEGORY_ORDER[@]}"; do
  cat_dir="$PROJECT_DIR/archive/$cat"
  display_name="${CATEGORY_MAP[$cat]:-}"
  if [[ -d "$cat_dir" ]]; then
    count=$(find "$cat_dir" -maxdepth 1 -name "*.md" ! -name "README.md" -type f | wc -l | tr -d ' ')
  else
    count=0
  fi
  awk -v dn="$display_name" -v cnt="$count" '
    index($0, dn) > 0 && /\]\(archive\// {
      sub(/[0-9]+[[:space:]]*\|$/, cnt " |")
      print; next
    }
    { print }
  ' "$main_readme" > "${main_readme}.tmp" && mv "${main_readme}.tmp" "$main_readme"
done

echo "  Updated category counts"

# ── 2. Build sorted all-articles list ────────────────────────────────────────

> "$WORK/all_articles.txt"
for cat in "${CATEGORY_ORDER[@]}"; do
  cat_dir="$PROJECT_DIR/archive/$cat"
  display_name="${CATEGORY_MAP[$cat]:-}"
  [[ -d "$cat_dir" ]] || continue
  while IFS= read -r f; do
    date_raw=$(get_file_date "$f")
    date_fmt=$(format_date "$date_raw")
    title=$(extract_title "$f")
    fname=$(basename "$f")
    # Fields: 1=date_raw, 2=date_fmt, 3=title, 4=fname, 5=display_name, 6=category_folder
    printf '%s|%s|%s|%s|%s|%s\n' "$date_raw" "$date_fmt" "$title" "$fname" "$display_name" "$cat" >> "$WORK/all_articles.txt"
  done < <(find "$cat_dir" -maxdepth 1 -name "*.md" ! -name "README.md" -type f)
done

# ── 3. Update "最近归档" section ─────────────────────────────────────────────

sort -t'|' -k1,1 -rn "$WORK/all_articles.txt" > "$WORK/all_articles_sorted.txt" 2>/dev/null

> "$WORK/recent_section.txt"
printf '| 日期 | 文章标题 | 分类 |\n' >> "$WORK/recent_section.txt"
printf '|------|----------|------|\n' >> "$WORK/recent_section.txt"
while IFS='|' read -r _ date_fmt title fname display_name cat2; do
  [[ -z "$date_fmt" ]] && continue
  printf '| %s | [%s](archive/%s/%s) | %s |\n' "$date_fmt" "$title" "$cat2" "$fname" "$display_name" >> "$WORK/recent_section.txt"
done < "$WORK/all_articles_sorted.txt"

awk '
  $0 == "<!-- RECENT_END -->" { print; skip=0; next }
  skip { next }
  $0 == "<!-- RECENT_START -->" {
    print
    while ((getline line < "'"$WORK/recent_section.txt"'") > 0) print line
    close("'"$WORK/recent_section.txt"'")
    skip=1; next
  }
  { print }
' "$main_readme" > "${main_readme}.tmp" && mv "${main_readme}.tmp" "$main_readme"

echo "  Updated 最近归档 section"

# ── 4. Build and update "最近灵感" ──────────────────────────────────────────

> "$WORK/insp_raw.txt"
while IFS= read -r f; do
  date_raw=$(get_file_date "$f")
  date_fmt=$(format_date "$date_raw")
  title=$(extract_title "$f")
  type=$(extract_type "$f")
  fname=$(basename "$f")
  printf '%s|%s|%s|%s|%s\n' "$date_raw" "$date_fmt" "$title" "$type" "$fname" >> "$WORK/insp_raw.txt"
done < <(find "$PROJECT_DIR/inspirations" -maxdepth 1 -name "*.md" ! -name "README.md" -type f)

sort -t'|' -k1,1 -rn "$WORK/insp_raw.txt" > "$WORK/insp_sorted.txt" 2>/dev/null

> "$WORK/insp_section.txt"
printf '| 日期 | 灵感标题 | 类型 |\n' >> "$WORK/insp_section.txt"
printf '|------|----------|------|\n' >> "$WORK/insp_section.txt"
while IFS='|' read -r _ date_fmt title type fname; do
  [[ -z "$date_fmt" ]] && continue
  printf '| %s | [%s](inspirations/%s) | %s |\n' "$date_fmt" "$title" "$fname" "$type" >> "$WORK/insp_section.txt"
done < "$WORK/insp_sorted.txt"

awk '
  $0 == "<!-- INSPIRATION_END -->" { print; skip=0; next }
  skip { next }
  $0 == "<!-- INSPIRATION_START -->" {
    print
    while ((getline line < "'"$WORK/insp_section.txt"'") > 0) print line
    close("'"$WORK/insp_section.txt"'")
    skip=1; next
  }
  { print }
' "$main_readme" > "${main_readme}.tmp" && mv "${main_readme}.tmp" "$main_readme"

echo "  Updated 最近灵感 section"

# ── 5. Build and update "最近知识点" ────────────────────────────────────────

> "$WORK/kno_raw.txt"
while IFS= read -r f; do
  date_raw=$(get_file_date "$f")
  date_fmt=$(format_date "$date_raw")
  title=$(extract_title "$f")
  status=$(extract_status "$f")
  fname=$(basename "$f")
  printf '%s|%s|%s|%s|%s\n' "$date_raw" "$date_fmt" "$title" "$status" "$fname" >> "$WORK/kno_raw.txt"
done < <(find "$PROJECT_DIR/knowledge" -maxdepth 1 -name "*.md" ! -name "README.md" -type f)

sort -t'|' -k1,1 -rn "$WORK/kno_raw.txt" > "$WORK/kno_sorted.txt" 2>/dev/null

> "$WORK/kno_section.txt"
printf '| 日期 | 知识点 | 状态 |\n' >> "$WORK/kno_section.txt"
printf '|------|--------|------|\n' >> "$WORK/kno_section.txt"
while IFS='|' read -r _ date_fmt title status fname; do
  [[ -z "$date_fmt" ]] && continue
  printf '| %s | [%s](knowledge/%s) | %s |\n' "$date_fmt" "$title" "$fname" "$status" >> "$WORK/kno_section.txt"
done < "$WORK/kno_sorted.txt"

awk '
  $0 == "<!-- KNOWLEDGE_END -->" { print; skip=0; next }
  skip { next }
  $0 == "<!-- KNOWLEDGE_START -->" {
    print
    while ((getline line < "'"$WORK/kno_section.txt"'") > 0) print line
    close("'"$WORK/kno_section.txt"'")
    skip=1; next
  }
  { print }
' "$main_readme" > "${main_readme}.tmp" && mv "${main_readme}.tmp" "$main_readme"

echo "  Updated 最近知识点 section"

# ── Update inspirations/README.md ──────────────────────────────────────────

insp_readme="$PROJECT_DIR/inspirations/README.md"
if [[ -f "$insp_readme" ]]; then
  > "$WORK/insp_index_rows.txt"
  while IFS= read -r f; do
    date_raw=$(get_file_date "$f")
    date_fmt=$(format_date "$date_raw")
    title=$(extract_title "$f")
    type=$(extract_type "$f")
    fname=$(basename "$f")
    printf '| %s | [%s](%s) | %s |\n' "$date_fmt" "$title" "$fname" "$type" >> "$WORK/insp_index_rows.txt"
  done < <(find "$PROJECT_DIR/inspirations" -maxdepth 1 -name "*.md" ! -name "README.md" -type f | sort)

  awk '
    /\-\- INSPIRATIONS_END \-\-/ {
      while ((getline line < "'"$WORK/insp_index_rows.txt"'") > 0) print line
      close("'"$WORK/insp_index_rows.txt"'")
    }
    { print }
  ' "$insp_readme" > "${insp_readme}.tmp" && mv "${insp_readme}.tmp" "$insp_readme"
  echo "  Updated inspirations/README.md"
fi

# ── Update knowledge/README.md ──────────────────────────────────────────────

kno_readme="$PROJECT_DIR/knowledge/README.md"
if [[ -f "$kno_readme" ]]; then
  > "$WORK/kno_index_rows.txt"
  while IFS= read -r f; do
    date_raw=$(get_file_date "$f")
    date_fmt=$(format_date "$date_raw")
    title=$(extract_title "$f")
    status=$(extract_status "$f")
    fname=$(basename "$f")
    printf '| %s | [%s](%s) | %s |\n' "$date_fmt" "$title" "$fname" "$status" >> "$WORK/kno_index_rows.txt"
  done < <(find "$PROJECT_DIR/knowledge" -maxdepth 1 -name "*.md" ! -name "README.md" -type f | sort)

  awk '
    /\-\- KNOWLEDGE_END \-\-/ {
      while ((getline line < "'"$WORK/kno_index_rows.txt"'") > 0) print line
      close("'"$WORK/kno_index_rows.txt"'")
    }
    { print }
  ' "$kno_readme" > "${kno_readme}.tmp" && mv "${kno_readme}.tmp" "$kno_readme"
  echo "  Updated knowledge/README.md"
fi

echo ""
echo "==> All indexes updated successfully."
