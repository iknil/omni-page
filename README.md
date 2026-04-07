# Omni Page — 个人知识阅读归档

> 每天阅读的文章、博客和论文的整理归档，结合个人思考与笔记。

## 知识分类

| 分类 | 描述 | 文章数 |
|------|------|:------:|
| [AI & 机器学习](archive/ai-ml/README.md) | 人工智能、深度学习、大模型、AI 应用 | 0 |
| [技术 & 编程](archive/technology/README.md) | 软件工程、系统设计、编程语言、开发工具 | 0 |
| [科学 & 研究](archive/science/README.md) | 科学研究、学术论文、自然科学 | 0 |
| [商业 & 经济](archive/business/README.md) | 商业分析、经济学、产品、管理 | 0 |
| [设计 & 产品](archive/design/README.md) | 产品设计、用户体验、交互设计 | 0 |
| [哲学 & 心理](archive/philosophy/README.md) | 哲学思考、心理学、认知科学 | 0 |
| [其他](archive/misc/README.md) | 其他感兴趣的内容 | 0 |

## 最近归档

| 日期 | 文章标题 | 分类 |
|------|----------|------|
<!-- RECENT_START -->
<!-- RECENT_END -->

## 使用方法

### 环境准备

```bash
pip install -r requirements.txt
export ANTHROPIC_API_KEY=your_key_here
```

### 归档网页文章 / 博客

```bash
python add_article.py --url https://example.com/article --notes "我的感悟和评论"
```

### 归档 PDF / 论文

```bash
python add_article.py --pdf paper.pdf --notes "这篇论文的核心贡献是..."
```

### 可选参数

| 参数 | 说明 |
|------|------|
| `--url` | 文章 URL（与 `--pdf` 二选一） |
| `--pdf` | PDF 文件路径（与 `--url` 二选一） |
| `--notes` | 你的个人笔记和感悟 |
| `--category` | 强制指定分类（覆盖 AI 自动分类） |

### 示例

```bash
# 归档一篇技术博客
python add_article.py \
  --url https://blog.example.com/system-design \
  --notes "这篇文章对分布式系统的一致性分析很有启发"

# 归档 ArXiv 论文
python add_article.py \
  --pdf attention_is_all_you_need.pdf \
  --notes "Transformer 架构的开山之作，Self-Attention 机制彻底改变了 NLP"

# 强制指定分类
python add_article.py \
  --url https://example.com/article \
  --notes "..." \
  --category technology
```
