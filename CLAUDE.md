# Omni Page

个人知识归档库，收录每天阅读的文章、博客和论文，结合个人思考。

详细归档规范、标题规则、来源保真、资源管理统一以 [CONTENT_STANDARDS.md](CONTENT_STANDARDS.md) 为准。

## 目录结构

```text
omni-page/
├── README.md
├── CONTENT_STANDARDS.md
├── CLAUDE.md
├── assets/
├── archive/
└── scripts/
```

## 调用命令

```bash
/archive --url https://example.com/post --notes "我的感悟"
/archive --pdf paper.pdf --notes "这篇论文的核心"
/archive --url https://example.com/post --notes "..." --category ai-ml
```
