# Omni Page — 项目说明

个人知识归档库，收录每天阅读的文章、博客和论文，结合个人思考。

## 目录结构

```
omni-page/
├── README.md              # 首页导航（自动维护）
├── CLAUDE.md              # 本文件
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

## 如何归档文章

在此项目目录内使用 Claude Code，执行 slash command：

```
/archive --url https://example.com/post --notes "我的感悟"
/archive --pdf paper.pdf --notes "这篇论文的核心..."
/archive --url https://... --notes "..." --category ai-ml
```

Claude 会自动完成：抓取内容 → 分析生成摘要/要点/标签 → 创建 Markdown → 更新导航 → 提交。

## 文章文件命名规范

`archive/<category>/YYYYMMDD-title-slug.md`

示例：`archive/ai-ml/20260407-attention-is-all-you-need.md`

## 分类说明

| key | 名称 | 适用内容 |
|-----|------|---------|
| `ai-ml` | AI & 机器学习 | 人工智能、机器学习、大模型 |
| `technology` | 技术 & 编程 | 软件工程、编程、系统设计 |
| `science` | 科学 & 研究 | 学术论文、自然科学 |
| `business` | 商业 & 经济 | 商业、经济、管理、创业 |
| `design` | 设计 & 产品 | 产品设计、UX |
| `philosophy` | 哲学 & 心理 | 哲学、心理学、认知 |
| `misc` | 其他 | 其他内容 |

## README 维护规则

### 主 README.md

- 分类表格中的文章数需与实际文件数一致
- `<!-- RECENT_START -->` 到 `<!-- RECENT_END -->` 之间保存最近 20 篇文章，最新的在最前

### 分类 README.md

- `<!-- ARTICLES_END -->` 标记前插入新条目
- 新条目格式：`| YYYY-MM-DD | [标题](文件名.md) |`
