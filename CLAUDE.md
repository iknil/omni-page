# Omni Page

个人知识库，既归档外部文章，也记录个人灵感，并把灵感沉淀成知识点。

详细归档规范、标题规则、来源保真、资源管理统一以 [CONTENT_STANDARDS.md](CONTENT_STANDARDS.md) 为准。

## 目录结构

```text
omni-page/
├── README.md
├── CONTENT_STANDARDS.md
├── CLAUDE.md
├── assets/
├── inspirations/
├── knowledge/
├── archive/
└── scripts/
```

## 调用命令

```bash
/archive --url https://example.com/post --notes "我的感悟"
/archive --pdf paper.pdf --notes "这篇论文的核心"
/archive --url https://example.com/post --notes "..." --category ai-ml
/inspire --text "今天想到一个点子" --scene "散步时"
/inspire --image assets/inspirations/sketch.svg --scene "白板草图"
/inspire --text "..." --image assets/inspirations/sketch.svg --scene "图文混合灵感"
/distill --from inspirations/20260408-example.md --title "可复用的知识点"
```
