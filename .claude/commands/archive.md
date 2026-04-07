请将以下文章归档到知识库。

用户输入：$ARGUMENTS

---

## 操作步骤

### 第一步：解析参数

从用户输入中提取：
- `--url <url>` 或 `--pdf <文件路径>`
- `--notes "..."` 用户的个人笔记和感悟（可选）
- `--category <分类>` 强制指定分类（可选）

### 第二步：获取文章内容

#### 2-A：URL 模式

用 Bash 执行以下命令抓取网页正文，**依次尝试**，成功即停：

```bash
# 尝试 1：带浏览器 UA 的 curl（应对大多数 403）
curl -sL \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36" \
  -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
  -H "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8" \
  --max-time 30 \
  "<URL>" -o /tmp/archive_fetch.html

# 检查是否成功（文件非空且含 HTML 内容）
wc -c /tmp/archive_fetch.html
```

```bash
# 尝试 2：通过 Jina Reader 代理
curl -sL \
  -H "User-Agent: Mozilla/5.0 (compatible)" \
  --max-time 30 \
  "https://r.jina.ai/<URL>" -o /tmp/archive_fetch.html
```

```bash
# 尝试 3：通过 Google AMP Cache（适合部分博客）
# 将 https://example.com/path 转换为
# https://example-com.cdn.ampproject.org/v/s/example.com/path
```

拿到 HTML 后，用以下命令提取可读正文（过滤掉导航、广告、脚注等噪声）：

```bash
# 如果安装了 pandoc
pandoc -f html -t plain /tmp/archive_fetch.html 2>/dev/null | head -500

# 如果没有 pandoc，用 python
python3 -c "
import re, sys
html = open('/tmp/archive_fetch.html').read()
# 去除 script/style
html = re.sub(r'<(script|style)[^>]*>.*?</\1>', '', html, flags=re.DOTALL|re.I)
# 去除所有标签
text = re.sub(r'<[^>]+>', ' ', html)
# 压缩空白
text = re.sub(r'\s+', ' ', text).strip()
print(text[:8000])
"

# 同时提取所有图片 URL（用于后续嵌入）
python3 -c "
import re
html = open('/tmp/archive_fetch.html').read()
imgs = re.findall(r'<img[^>]+src=[\"\'](.*?)[\"\'|][^>]*>', html, re.I)
alts = re.findall(r'<img[^>]+alt=[\"\'](.*?)[\"\'|][^>]*>', html, re.I)
for i, src in enumerate(imgs):
    alt = alts[i] if i < len(alts) else ''
    print(f'IMG: {src}  ALT: {alt}')
"
```

**同时**提取页面中所有 `<img>` 的 `src` 和 `alt`，以便后续在文章里引用重要图片。

#### 2-B：PDF 模式

用 Read 工具读取 PDF 文件内容。

### 第三步：分析文章

结合文章内容和用户笔记，得出以下信息（全部以中文输出）：

**标题**：文章的准确标题

**摘要**：200~300 字，概括文章核心观点和价值

**关键要点**：3~6 条，提炼最重要的信息点

**图片**：列出页面中与内容强相关的图片（尤其是用户笔记中提到的图），记录：
- 图片原始 URL（绝对路径；若是相对路径则补全域名）
- 图片的 alt 文字或推断出的说明

**分类**（从下列选一个最合适的）：
| key | 适用范围 |
|-----|---------|
| `ai-ml` | 人工智能、机器学习、深度学习、大模型、AI 应用 |
| `technology` | 软件工程、编程语言、系统设计、开发工具、计算机科学 |
| `science` | 学术论文、自然科学、物理、生物、化学 |
| `business` | 商业、经济学、金融、管理、创业、产品 |
| `design` | 产品设计、用户体验、交互设计、视觉 |
| `philosophy` | 哲学、心理学、认知科学、伦理、社会学 |
| `misc` | 以上均不适合时选此 |

**标签**：3~6 个，简洁的内容关键词

### 第四步：创建文章文件

文件路径：`archive/<category>/<YYYYMMDD>-<title-slug>.md`
- 日期用今天的日期
- slug：将标题转为小写、空格换成连字符、去掉特殊字符，限 60 字符

文件内容格式：

```markdown
# <标题>

| | |
|---|---|
| **来源** | [<URL或文件名>](<链接>) |
| **归档日期** | <YYYY-MM-DD> |
| **分类** | [<分类名>](../../<category>/README.md) |
| **标签** | `标签1`  `标签2`  `标签3` |

## 核心内容摘要

<摘要>

## 关键要点

- <要点1>
- <要点2>
- <要点3>

## 重要图示

<!-- 若用户笔记中提到了特定图，或页面有与核心论点直接相关的图，在此嵌入 -->
<!-- 格式：![说明文字](<图片绝对URL>) -->
<!-- 若无相关图片则删除本节 -->

## 我的思考与感悟

<用户笔记，若无则写"（暂无笔记）">

---

*[← 返回分类](../../<category>/README.md) · [← 返回首页](../../README.md)*
```

### 第五步：更新分类 README

在 `archive/<category>/README.md` 的 `<!-- ARTICLES_END -->` 标记**前**插入一行：

```
| <YYYY-MM-DD> | [<标题>](<filename>.md) |
```

### 第六步：更新主 README

在 `README.md` 的 `<!-- RECENT_START -->` 和 `<!-- RECENT_END -->` 之间，将新条目插入**最前面**（保留最多 20 条）：

```
| <YYYY-MM-DD> | [<标题>](archive/<category>/<filename>.md) | <分类名> |
```

同时将主 README 中对应分类行的文章计数加 1（格式：`| 0 |` → `| 1 |`）。

### 第七步：处理 PDF 文件

如果是 PDF，用 Bash 将文件复制到 `assets/` 目录：

```bash
cp "<pdf-path>" assets/ 2>/dev/null || true   # 已存在时跳过
```

### 第八步：Git 提交并推送

```bash
git add archive/ README.md assets/
git commit -m "$(cat <<'COMMITMSG'
归档：<文章标题>

分类：<分类名>
来源：<URL 或文件名>
标签：<tag1>, <tag2>, ...
COMMITMSG
)"
git push -u origin "$(git branch --show-current)"
```
