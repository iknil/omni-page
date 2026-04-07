# Omni Page — 个人知识阅读归档

> 每天阅读的文章、博客和论文的整理归档，结合个人思考与笔记。

## 知识分类

| 分类 | 描述 | 文章数 |
|------|------|:------:|
| [AI & 机器学习](archive/ai-ml/README.md) | 人工智能、深度学习、大模型、AI 应用 | 2 |
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
| 2026-04-07 | [AI Agent 的持续学习：模型、运行框架与上下文三层](archive/ai-ml/20260407-continual-learning-for-ai-agents.md) | AI & 机器学习 |
| 2026-04-07 | [A Taxonomy of RL Environments for LLM Agents](archive/ai-ml/20260407-a-taxonomy-of-rl-environments-for-llm-agents.md) | AI & 机器学习 |
<!-- RECENT_END -->

## 使用方法

在此项目目录内打开 Claude Code，使用 `/archive` 命令：

### 归档网页文章 / 博客

```
/archive --url https://example.com/article --notes "我的感悟和评论"
```

### 归档 PDF / 论文

```
/archive --pdf paper.pdf --notes "这篇论文的核心贡献是..."
```

### 可选参数

| 参数 | 说明 |
|------|------|
| `--url` | 文章 URL（与 `--pdf` 二选一） |
| `--pdf` | PDF 文件路径（与 `--url` 二选一） |
| `--notes` | 你的个人笔记和感悟 |
| `--category` | 强制指定分类（覆盖自动分类） |

### 示例

```
# 归档一篇技术博客
/archive --url https://blog.example.com/system-design --notes "对分布式一致性分析很有启发"

# 归档 ArXiv 论文
/archive --pdf attention_is_all_you_need.pdf --notes "Transformer 架构的开山之作"

# 强制指定分类
/archive --url https://example.com/article --notes "..." --category technology
```

Claude 会自动完成：抓取/读取内容 → 分析生成摘要和标签 → 创建 Markdown → 更新导航 → 提交。
