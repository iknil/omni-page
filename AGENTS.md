# Omni Page — Agent 说明

个人知识归档库，收录每天阅读的文章、博客和论文，结合个人思考。

## 唯一规范入口

归档规范、标题与图片命名、文章结构要求统一以 [CONTENT_STANDARDS.md](CONTENT_STANDARDS.md) 为准。
如需更新归档规则，优先修改本文件与 `CONTENT_STANDARDS.md`，`.claude/commands/archive.md` 仅保留调用格式。

## 目录结构

```
omni-page/
├── README.md              # 首页导航（自动维护）
├── CONTENT_STANDARDS.md   # 内容规范（唯一标准）
├── AGENTS.md              # 本文件（Codex 用）
├── CLAUDE.md              # Claude Code 用
├── assets/                # PDF 原文件和归档图片
├── scripts/               # 校验脚本
└── archive/
    ├── ai-ml/             # AI & 机器学习
    ├── technology/        # 技术 & 编程
    ├── science/           # 科学 & 研究
    ├── business/          # 商业 & 经济
    ├── design/            # 设计 & 产品
    ├── philosophy/        # 哲学 & 心理
    └── misc/              # 其他
```

每个分类目录下：
- `README.md`：该分类的文章索引
- `YYYYMMDD-title-slug.md`：每篇归档文章

## 归档任务说明

当用户要求归档一篇文章时，按以下步骤执行。

用户会提供以下参数（自然语言或命令行风格均可）：
- URL 或 PDF 路径
- 个人笔记 / 感悟（可选）
- 强制分类（可选）
- `--push`（可选，若需要归档后自动推送）

### 第一步：获取文章内容

#### URL 模式 — 依次尝试，成功即停

```bash
curl -sL \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
  -H "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8" \
  --max-time 30 \
  "<URL>" > /tmp/archive_fetch.html
wc -c /tmp/archive_fetch.html
```

```bash
curl -sL --max-time 30 \
  "https://r.jina.ai/<URL>" > /tmp/archive_fetch.html
```

提取正文和图片：

```bash
pandoc -f html -t plain /tmp/archive_fetch.html 2>/dev/null | head -500 \
|| python3 -c "
import re
html = open('/tmp/archive_fetch.html').read()
html = re.sub(r'<(script|style)[^>]*>.*?</\1>', '', html, flags=re.DOTALL|re.I)
text = re.sub(r'<[^>]+>', ' ', html)
print(re.sub(r'\s+', ' ', text).strip()[:8000])
"
```

```bash
python3 -c "
import re
html = open('/tmp/archive_fetch.html').read()
imgs = re.findall(r'<img[^>]+src=[\"\'](.*?)[\"\'][^>]*>', html, re.I)
alts = re.findall(r'<img[^>]+alt=[\"\'](.*?)[\"\'][^>]*>', html, re.I)
for i, src in enumerate(imgs):
    print(f'IMG: {src}  ALT: {alts[i] if i < len(alts) else ""}')
"
```

#### PDF 模式

```bash
python3 -c "
import sys
try:
    import pdfplumber
    with pdfplumber.open(sys.argv[1]) as pdf:
        for page in pdf.pages[:20]:
            print(page.extract_text() or '')
except ImportError:
    import subprocess
    subprocess.run(['pdftotext', sys.argv[1], '-'], check=True)
" "<PDF路径>"
```

### 第二步：分析内容

结合正文和用户笔记，按 [CONTENT_STANDARDS.md](CONTENT_STANDARDS.md) 生成：

- **标题**：优先保留原文标题；必要时补充中文副标题
- **摘要**：200 到 300 字，中文输出
- **关键要点**：3 到 6 条
- **重要图片**：记录与核心论点相关的图片 URL 及说明
- **分类**：从 `ai-ml`、`technology`、`science`、`business`、`design`、`philosophy`、`misc` 中选择
- **标签**：3 到 6 个关键词

### 第三步：确定文件路径

```
archive/<category>/<YYYYMMDD>-<title-slug>.md
```

- 日期：执行当天日期（`date +%Y%m%d`）
- slug：遵循 `CONTENT_STANDARDS.md`，优先使用中文检索词

### 第四步：写入文章文件

文章结构遵循 `CONTENT_STANDARDS.md` 的标准节顺序：元数据表、核心内容摘要、关键要点、重要图示（可选）、我的思考与感悟。

### 第五步：更新分类 README

在 `archive/<category>/README.md` 的 `<!-- ARTICLES_END -->` 行前插入：

```
| <YYYY-MM-DD> | [<标题>](<filename>.md) |
```

### 第六步：更新主 README

1. 在 `README.md` 的 `<!-- RECENT_START -->` 和 `<!-- RECENT_END -->` 之间，将新条目加到最前面，保留最多 20 条。
2. 运行 `scripts/verify_counts.sh`，确保主 README 分类计数与实际文章数一致。

### 第七步：处理 PDF

```bash
cp "<pdf-path>" assets/ 2>/dev/null || true
```

### 第八步：Git 提交

```bash
git add archive/ README.md assets/ CONTENT_STANDARDS.md scripts/verify_counts.sh AGENTS.md .claude/commands/archive.md
git commit -m "归档：<文章标题>

分类：<分类名>
来源：<URL 或文件名>
标签：<tag1>, <tag2>, ..."
```

注：默认只提交，不自动 `git push`。如需推送，请手动执行，或在调用时显式加 `--push`。

## 分类 README 维护规则

- `<!-- ARTICLES_END -->` 标记前插入新条目
- 格式：`| YYYY-MM-DD | [标题](文件名.md) |`

## 主 README 维护规则

- `<!-- RECENT_START -->` / `<!-- RECENT_END -->` 之间保存最近 20 篇，最新在最前
- 分类表格的文章数与实际文件数保持一致
- 提交前必须运行 `scripts/verify_counts.sh`
