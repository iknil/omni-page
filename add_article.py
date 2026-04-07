#!/usr/bin/env python3
"""
Omni Page - 文章归档脚本

用法:
  python add_article.py --url <url> [--notes "你的感悟"]
  python add_article.py --pdf <path> [--notes "你的感悟"]
  python add_article.py --url <url> --notes "..." --category technology
"""

import os
import sys
import json
import argparse
import re
import base64
import shutil
from datetime import date
from pathlib import Path

import anthropic

CATEGORIES = {
    "ai-ml":       "AI & 机器学习",
    "technology":  "技术 & 编程",
    "science":     "科学 & 研究",
    "business":    "商业 & 经济",
    "design":      "设计 & 产品",
    "philosophy":  "哲学 & 心理",
    "misc":        "其他",
}

REPO_ROOT   = Path(__file__).parent.resolve()
ARCHIVE_DIR = REPO_ROOT / "archive"
ASSETS_DIR  = REPO_ROOT / "assets"


# ──────────────────────────────────────────────
# 内容获取
# ──────────────────────────────────────────────

def fetch_url_content(url: str) -> str:
    """抓取 URL 页面并提取正文文本。"""
    try:
        import requests
        from bs4 import BeautifulSoup
    except ImportError:
        print("错误：请先安装依赖：pip install requests beautifulsoup4")
        sys.exit(1)

    headers = {"User-Agent": "Mozilla/5.0 (compatible; OmniPage/1.0)"}
    try:
        resp = requests.get(url, headers=headers, timeout=30)
        resp.raise_for_status()
    except Exception as e:
        print(f"警告：无法抓取 URL 内容（{e}），将仅基于 URL 和笔记进行分析。")
        return ""

    from bs4 import BeautifulSoup
    soup = BeautifulSoup(resp.text, "html.parser")

    for tag in soup(["script", "style", "nav", "footer", "header", "aside"]):
        tag.decompose()

    main = (
        soup.find("article")
        or soup.find("main")
        or soup.find(class_=re.compile(r"content|post|article", re.I))
        or soup.find("body")
    )
    text = main.get_text(separator="\n", strip=True) if main else soup.get_text("\n", strip=True)

    # 去除多余空行
    lines = [l for l in text.splitlines() if l.strip()]
    return "\n".join(lines)[:60000]  # 最多 60k 字符


# ──────────────────────────────────────────────
# Claude 分析
# ──────────────────────────────────────────────

ANALYSIS_SCHEMA = {
    "type": "object",
    "properties": {
        "title":      {"type": "string",  "description": "文章标题"},
        "summary":    {"type": "string",  "description": "200~300字的核心内容总结"},
        "key_points": {"type": "array",   "items": {"type": "string"}, "description": "3~6个关键要点"},
        "category":   {"type": "string",  "enum": list(CATEGORIES.keys())},
        "tags":       {"type": "array",   "items": {"type": "string"}, "description": "3~6个内容标签"},
    },
    "required": ["title", "summary", "key_points", "category", "tags"],
    "additionalProperties": False,
}

SYSTEM_PROMPT = """\
你是一个专业的文章分析和知识归档助手。
用户会提供文章内容（或 PDF）以及他们的个人笔记和感悟。
请仔细阅读后，输出一份结构化的归档分析，帮助用户整理知识。

分类选项（只能选其一）：
- ai-ml：人工智能、机器学习、深度学习、大模型
- technology：软件工程、编程、系统设计、开发工具、计算机科学
- science：科学研究、学术论文、物理、生物、化学等自然科学
- business：商业、经济学、金融、管理、创业、产品
- design：产品设计、用户体验、视觉设计、交互设计
- philosophy：哲学、心理学、认知科学、伦理、社会学
- misc：以上均不适合时选此项
"""


def build_messages_for_url(content: str, url: str, notes: str) -> list:
    prompt = f"""请分析以下文章，结合我的笔记，生成归档信息。

文章来源：{url}

文章内容：
{content if content else "（无法抓取正文，请基于 URL 和我的笔记进行推断）"}

我的笔记和感悟：
{notes.strip() if notes else "（无）"}
"""
    return [{"role": "user", "content": prompt}]


def build_messages_for_pdf(pdf_path: str, notes: str) -> list:
    with open(pdf_path, "rb") as f:
        pdf_b64 = base64.standard_b64encode(f.read()).decode("utf-8")

    return [{
        "role": "user",
        "content": [
            {
                "type": "document",
                "source": {
                    "type": "base64",
                    "media_type": "application/pdf",
                    "data": pdf_b64,
                },
                "title": Path(pdf_path).name,
            },
            {
                "type": "text",
                "text": f"""请分析这份 PDF 文档，结合我的笔记，生成归档信息。

我的笔记和感悟：
{notes.strip() if notes else "（无）"}
""",
            },
        ],
    }]


def analyze_with_claude(
    client: anthropic.Anthropic,
    messages: list,
    forced_category: str | None = None,
) -> dict:
    """调用 Claude 分析文章，返回结构化数据。"""
    schema = ANALYSIS_SCHEMA.copy()
    if forced_category:
        schema["properties"]["category"] = {"type": "string", "const": forced_category}

    response = client.messages.create(
        model="claude-opus-4-6",
        max_tokens=2048,
        system=SYSTEM_PROMPT,
        messages=messages,
        output_config={
            "format": {
                "type": "json_schema",
                "schema": schema,
            }
        },
    )

    text = next(b.text for b in response.content if b.type == "text")
    return json.loads(text)


# ──────────────────────────────────────────────
# 文件生成
# ──────────────────────────────────────────────

def slugify(text: str) -> str:
    """生成 URL 友好的文件名。"""
    text = text.lower()
    # 保留中文、英文、数字
    text = re.sub(r"[^\w\u4e00-\u9fff\s-]", "", text)
    text = re.sub(r"[\s_]+", "-", text).strip("-")
    return text[:60] or "article"


def render_article_md(
    data: dict,
    source: str,
    notes: str,
    asset_rel_path: str | None = None,
) -> str:
    """渲染文章 Markdown 文件内容。"""
    today = date.today().strftime("%Y-%m-%d")
    tags_md = "  ".join(f"`{t}`" for t in data.get("tags", []))
    key_points_md = "\n".join(f"- {p}" for p in data.get("key_points", []))
    category = data.get("category", "misc")
    category_name = CATEGORIES.get(category, category)

    if asset_rel_path:
        source_link = f"[{Path(source).name}]({asset_rel_path})"
    elif source.startswith("http"):
        source_link = f"[{source}]({source})"
    else:
        source_link = source

    return f"""# {data['title']}

| | |
|---|---|
| **来源** | {source_link} |
| **归档日期** | {today} |
| **分类** | [{category_name}](../../{category}/README.md) |
| **标签** | {tags_md} |

## 核心内容摘要

{data['summary']}

## 关键要点

{key_points_md}

## 我的思考与感悟

{notes.strip() if notes.strip() else "*（暂无笔记）*"}

---

*[← 返回分类](../../{category}/README.md) · [← 返回首页](../../README.md)*
"""


# ──────────────────────────────────────────────
# README 更新
# ──────────────────────────────────────────────

def update_category_readme(category: str, title: str, filename: str) -> None:
    """在分类 README 中添加文章条目。"""
    today = date.today().strftime("%Y-%m-%d")
    cat_readme = ARCHIVE_DIR / category / "README.md"

    entry = f"| {today} | [{title}]({filename}) |"

    content = cat_readme.read_text(encoding="utf-8")
    if "<!-- ARTICLES_END -->" in content:
        content = content.replace("<!-- ARTICLES_END -->", f"{entry}\n<!-- ARTICLES_END -->")
    else:
        content += f"\n{entry}\n"
    cat_readme.write_text(content, encoding="utf-8")

    # 更新文章计数（分类 README 里的计数仅供参考，主 README 中的也要更新）
    _update_main_readme_count(category)


def _update_main_readme_count(category: str) -> None:
    """更新主 README 中对应分类的文章数。"""
    cat_dir = ARCHIVE_DIR / category
    # 统计该分类下 .md 文件数（排除 README.md）
    count = len([f for f in cat_dir.glob("*.md") if f.name != "README.md"])
    category_name = CATEGORIES.get(category, category)

    readme_path = REPO_ROOT / "README.md"
    content = readme_path.read_text(encoding="utf-8")

    # 匹配该分类行并更新数字
    pattern = rf"(\| \[{re.escape(category_name)}\][^\|]+\| )(\d+)( \|)"
    content = re.sub(pattern, rf"\g<1>{count}\g<3>", content)
    readme_path.write_text(content, encoding="utf-8")


def update_main_readme_recent(data: dict, article_rel_path: str) -> None:
    """在主 README 最近归档表格中插入新条目（最多保留 20 条）。"""
    today = date.today().strftime("%Y-%m-%d")
    category_name = CATEGORIES.get(data["category"], data["category"])
    entry = f"| {today} | [{data['title']}]({article_rel_path}) | {category_name} |"

    readme_path = REPO_ROOT / "README.md"
    content = readme_path.read_text(encoding="utf-8")

    if "<!-- RECENT_START -->" not in content:
        return

    # 提取现有条目
    between = re.search(
        r"<!-- RECENT_START -->(.*?)<!-- RECENT_END -->", content, re.DOTALL
    )
    existing = between.group(1).strip().splitlines() if between else []

    # 新条目插入最前面，最多保留 20 条
    rows = [entry] + [r for r in existing if r.strip()]
    rows = rows[:20]

    new_block = "<!-- RECENT_START -->\n" + "\n".join(rows) + "\n<!-- RECENT_END -->"
    content = re.sub(
        r"<!-- RECENT_START -->.*?<!-- RECENT_END -->",
        new_block,
        content,
        flags=re.DOTALL,
    )
    readme_path.write_text(content, encoding="utf-8")


# ──────────────────────────────────────────────
# 入口
# ──────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description="将文章归档到 Omni Page 知识库",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    src = parser.add_mutually_exclusive_group(required=True)
    src.add_argument("--url", help="文章网页地址")
    src.add_argument("--pdf", help="本地 PDF 文件路径")
    parser.add_argument("--notes", default="", help="你的个人笔记和感悟")
    parser.add_argument(
        "--category",
        choices=list(CATEGORIES.keys()),
        help="强制指定分类（可选，默认由 AI 自动判断）",
    )
    args = parser.parse_args()

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("错误：请设置环境变量 ANTHROPIC_API_KEY")
        sys.exit(1)

    client = anthropic.Anthropic(api_key=api_key)

    # 准备消息
    asset_rel_path = None
    if args.url:
        print(f"正在抓取文章内容：{args.url}")
        content = fetch_url_content(args.url)
        messages = build_messages_for_url(content, args.url, args.notes)
        source = args.url
    else:
        pdf_path = Path(args.pdf).resolve()
        if not pdf_path.exists():
            print(f"错误：文件不存在：{pdf_path}")
            sys.exit(1)
        if pdf_path.stat().st_size > 30 * 1024 * 1024:  # 30 MB
            print("错误：PDF 文件过大（>30 MB），请压缩后再试。")
            sys.exit(1)

        # 复制 PDF 到 assets/
        ASSETS_DIR.mkdir(exist_ok=True)
        dest = ASSETS_DIR / pdf_path.name
        if not dest.exists():
            shutil.copy2(pdf_path, dest)
        asset_rel_path = f"../../assets/{pdf_path.name}"

        print(f"正在解析 PDF：{pdf_path.name}")
        messages = build_messages_for_pdf(str(pdf_path), args.notes)
        source = str(pdf_path)

    # Claude 分析
    print("正在分析文章...")
    data = analyze_with_claude(client, messages, forced_category=args.category)

    # 确定存储路径
    category = data.get("category", "misc")
    cat_dir = ARCHIVE_DIR / category
    cat_dir.mkdir(parents=True, exist_ok=True)

    today_str = date.today().strftime("%Y%m%d")
    slug = slugify(data["title"])
    filename = f"{today_str}-{slug}.md"
    filepath = cat_dir / filename

    # 避免同名覆盖
    counter = 1
    while filepath.exists():
        filename = f"{today_str}-{slug}-{counter}.md"
        filepath = cat_dir / filename
        counter += 1

    # 写文章文件
    md = render_article_md(data, source, args.notes, asset_rel_path)
    filepath.write_text(md, encoding="utf-8")

    # 更新各 README
    update_category_readme(category, data["title"], filename)
    article_rel = str(filepath.relative_to(REPO_ROOT))
    update_main_readme_recent(data, article_rel)

    # 输出摘要
    print()
    print("✅ 归档完成！")
    print(f"   文件路径 : {article_rel}")
    print(f"   标题     : {data['title']}")
    print(f"   分类     : {CATEGORIES.get(category, category)}")
    print(f"   标签     : {', '.join(data.get('tags', []))}")
    print()
    print(f"摘要：{data['summary'][:120]}...")


if __name__ == "__main__":
    main()
