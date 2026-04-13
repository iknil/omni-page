# Omni Page — 个人知识与灵感库

> 统一管理外部文章归档、个人灵感捕获，以及沉淀后的知识点。

## 内容空间

| 空间 | 说明 | 数量 |
|------|------|:----:|
| [文章归档](archive/ai-ml/README.md) | 来自文章、博客、论文的结构化归档 | 6 |
| [个人灵感](inspirations/README.md) | 一段话、一张图、或图文混合的低摩擦记录 | 2 |
| [知识点](knowledge/README.md) | 从灵感或归档提炼出的可复用结论 | 1 |

## 知识分类

| 分类 | 描述 | 文章数 |
|------|------|:------:|
| [AI & 机器学习](archive/ai-ml/README.md) | 人工智能、深度学习、大模型、AI 应用 | 5 |
| [技术 & 编程](archive/technology/README.md) | 软件工程、系统设计、编程语言、开发工具 | 0 |
| [科学 & 研究](archive/science/README.md) | 科学研究、学术论文、自然科学 | 0 |
| [商业 & 经济](archive/business/README.md) | 商业分析、经济学、产品、管理 | 0 |
| [设计 & 产品](archive/design/README.md) | 产品设计、用户体验、交互设计 | 0 |
| [哲学 & 心理](archive/philosophy/README.md) | 哲学思考、心理学、认知科学 | 0 |
| [其他](archive/misc/README.md) | 其他感兴趣的内容 | 0 |

## 最近归档

<!-- RECENT_START -->
| 日期 | 文章标题 | 分类 |
|------|----------|------|
| 2026-04-13 | [Post-training Core Technologies Explained: From SFT to RLHF, GRPO, and Agentic RL](archive/ai-ml/20260413-rlhf-grpo-agentic-rl.md) | AI & 机器学习 |
| 2026-04-08 | [大语言模型生成控制参数详解：温度、Top-K与Top-P](archive/ai-ml/20260408-llm-decoding-parameters.md) | AI & 机器学习 |
| 2026-04-08 | [Context Window](archive/ai-ml/20260408-context-window.md) | AI & 机器学习 |
| 2026-04-08 | [A Guide to Context Engineering for LLMs](archive/ai-ml/20260408-context-engineering-for-llms.md) | AI & 机器学习 |
| 2026-04-07 | [Continual Learning for AI Agents](archive/ai-ml/20260407-continual-learning-for-ai-agents.md) | AI & 机器学习 |
| 2026-04-07 | [A Taxonomy of RL Environments for LLM Agents](archive/ai-ml/20260407-llm-agent-强化学习环境分类.md) | AI & 机器学习 |
<!-- RECENT_END -->

## 最近灵感

<!-- INSPIRATION_START -->
| 日期 | 灵感标题 | 类型 |
|------|----------|------|
| 2026-04-08 | [harness 架构图](inspirations/20260408-harness-architecture-diagram.md) | image |
| 2026-04-08 | [上下文卡片化捕获流程](inspirations/20260408-context-card-capture.md) | mixed |
<!-- INSPIRATION_END -->

## 最近知识点

<!-- KNOWLEDGE_START -->
| 日期 | 知识点 | 状态 |
|------|--------|------|
| 2026-04-08 | [上下文先卡片化，再知识化](knowledge/20260408-context-card-knowledge-loop.md) | seed |
<!-- KNOWLEDGE_END -->

## 推荐流程

1. 用 `/inspire` 快速捕获灵感，不强迫自己一次写成完整文章。
2. 用 `/distill` 把成熟灵感沉淀为知识点，并回链来源。
3. 用 `/archive` 继续归档外部资料，把它们接入已有知识点。

## 使用方法

在此项目目录内打开 Claude Code，按内容类型选择命令：

```bash
/archive --url https://example.com/article --notes "我的感悟和评论"
/archive --pdf paper.pdf --notes "这篇论文的核心贡献是..."
/archive --url https://example.com/article --notes "..." --category technology
/archive --url https://example.com/article --notes "..." --push
/inspire --text "突然想到的判断" --scene "复盘时"
/inspire --text "..." --image assets/inspirations/sketch.svg --scene "白板草图"
/distill --from inspirations/20260408-example.md --title "可复用知识点"
```

详细的标题规则、文章结构、标签、来源保真、资源与校验规范统一见 [CONTENT_STANDARDS.md](CONTENT_STANDARDS.md)。
