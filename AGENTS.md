# Omni Page — Agent 说明

个人知识归档库，收录每天阅读的文章、博客和论文，结合个人思考。

## 目录结构

```
omni-page/
├── README.md              # 首页导航（自动维护）
├── AGENTS.md              # 本文件（Codex 用）
├── CLAUDE.md              # Claude Code 用
├── assets/                # PDF 原文件存放处
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

---

## 归档任务说明

当用户要求归档一篇文章时，按以下步骤执行。

用户会提供以下参数（自然语言或命令行风格均可）：
- URL 或 PDF 路径
- 个人笔记 / 感悟（可选）
- 强制分类（可选）

---

### 第一步：获取文章内容

#### URL 模式 — 依次尝试，成功即停

```bash
# 尝试 1：带浏览器 UA 的 curl
curl -sL \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
  -H "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8" \
  --max-time 30 \
  "<URL>" > /tmp/archive_fetch.html
wc -c /tmp/archive_fetch.html   # 确认非空
```

```bash
# 尝试 2：Jina Reader 代理
curl -sL --max-time 30 \
  "https://r.jina.ai/<URL>" > /tmp/archive_fetch.html
```

提取正文和图片：

```bash
# 提取正文（优先 pandoc，否则用 python）
pandoc -f html -t plain /tmp/archive_fetch.html 2>/dev/null | head -500 \
|| python3 -c "
import re
html = open('/tmp/archive_fetch.html').read()
html = re.sub(r'<(script|style)[^>]*>.*?</\1>', '', html, flags=re.DOTALL|re.I)
text = re.sub(r'<[^>]+>', ' ', html)
print(re.sub(r'\s+', ' ', text).strip()[:8000])
"

# 提取所有图片 URL 和 alt
python3 -c "
import re
html = open('/tmp/archive_fetch.html').read()
imgs = re.findall(r'<img[^>]+src=[\"\'](.*?)[\"\'][^>]*>', html, re.I)
alts = re.findall(r'<img[^>]+alt=[\"\'](.*?)[\"\'][^>]*>', html, re.I)
for i, src in enumerate(imgs):
    print(f'IMG: {src}  ALT: {alts[i] if i < len(alts) else \"\"}')
"
```

#### PDF 模式

```bash
# 读取 PDF 文本
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

---

### 第二步：分析内容

结合正文和用户笔记，提炼（中文输出）：

- **标题**：文章准确标题
- **摘要**：200~300 字，核心观点和价值
- **关键要点**：3~6 条
- **重要图片**：记录与核心论点相关的图片 URL（补全为绝对路径）及说明
- **分类**：

| key | 适用范围 |
|-----|---------|
| `ai-ml` | 人工智能、机器学习、深度学习、大模型 |
| `technology` | 软件工程、编程语言、系统设计、开发工具 |
| `science` | 学术论文、自然科学 |
| `business` | 商业、经济学、管理、创业 |
| `design` | 产品设计、UX |
| `philosophy` | 哲学、心理学、认知科学 |
| `misc` | 以上均不适合 |

- **标签**：3~6 个关键词

---

### 第三步：确定文件路径

```
archive/<category>/<YYYYMMDD>-<title-slug>.md
```

- 日期：执行当天日期（`date +%Y%m%d`）
- slug：标题转小写、空格换连字符、去特殊字符，限 60 字符

```bash
date +%Y%m%d
```

---

### 第四步：写入文章文件

```bash
cat > archive/<category>/<filename>.md << 'EOF'
# <标题>

| | |
|---|---|
| **来源** | [<URL或文件名>](<链接>) |
| **归档日期** | <YYYY-MM-DD> |
| **分类** | [<分类名>](../../archive/<category>/README.md) |
| **标签** | `标签1`  `标签2`  `标签3` |

## 核心内容摘要

<摘要>

## 关键要点

- <要点1>
- <要点2>
- <要点3>

## 重要图示

![<说明>](<图片绝对URL>)

## 我的思考与感悟

<用户笔记，若无则写"（暂无笔记）">

---

*[← 返回分类](README.md) · [← 返回首页](../../README.md)*
EOF
```

> 若无相关图片，删除"重要图示"节。

---

### 第五步：更新分类 README

在 `archive/<category>/README.md` 的 `<!-- ARTICLES_END -->` 行**前**插入：

```
| <YYYY-MM-DD> | [<标题>](<filename>.md) |
```

---

### 第六步：更新主 README

1. 在 `README.md` 的 `<!-- RECENT_START -->` 和 `<!-- RECENT_END -->` 之间，将新条目加到**最前面**（保留最多 20 条）：

```
| <YYYY-MM-DD> | [<标题>](archive/<category>/<filename>.md) | <分类名> |
```

2. 将对应分类行的文章计数 +1（`| N |` → `| N+1 |`）。

---

### 第七步：处理 PDF

```bash
cp "<pdf-path>" assets/ 2>/dev/null || true
```

---

### 第八步：Git 提交并推送

```bash
git add archive/ README.md assets/
git commit -m "归档：<文章标题>

分类：<分类名>
来源：<URL 或文件名>
标签：<tag1>, <tag2>, ..."
git push -u origin "$(git branch --show-current)"
```

---

## 分类 README 维护规则

- `<!-- ARTICLES_END -->` 标记前插入新条目
- 格式：`| YYYY-MM-DD | [标题](文件名.md) |`

## 主 README 维护规则

- `<!-- RECENT_START -->` / `<!-- RECENT_END -->` 之间保存最近 20 篇，最新在最前
- 分类表格的文章数与实际文件数保持一致
