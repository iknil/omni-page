# Omni Page — Agent 说明

个人知识归档库，收录每天阅读的文章、博客和论文，结合个人思考。

## 唯一规范入口

归档规范、标题规则、来源保真、标签、资源管理统一以 [CONTENT_STANDARDS.md](CONTENT_STANDARDS.md) 为准。
`.claude/commands/archive.md` 仅保留调用格式，避免重复维护正文规则。

## 目录结构

```text
omni-page/
├── README.md              # 首页导航（自动维护）
├── CONTENT_STANDARDS.md   # 内容规范（唯一标准）
├── AGENTS.md              # 本文件（Codex 用）
├── CLAUDE.md              # Claude Code 用
├── assets/                # 图片和 PDF 统一存放处
├── scripts/               # 校验脚本
└── archive/
    ├── ai-ml/
    ├── technology/
    ├── science/
    ├── business/
    ├── design/
    ├── philosophy/
    └── misc/
```

## 归档任务说明

- 标题保留英文原标题；中文副标题按需补充。
- 文件名统一为 `archive/<category>/YYYYMMDD-slug.md`。
- slug 使用检索友好的中文意译词或英文小写词，词间仅用连字符，不含空格。
- 元数据表必须包含原始标题、原始链接、原始发表日期（如有）。
- PDF 归档文件使用 `<YYYYMMDD>-<slug>.pdf`，放入 `assets/`。
- 校验脚本统一使用 `scripts/verify_archive.sh`。

## README 维护规则

- 主 `README.md` 的 `<!-- RECENT_START -->` / `<!-- RECENT_END -->` 之间最多保留 20 篇，最新在最前。
- 分类 `README.md` 在 `<!-- ARTICLES_END -->` 前追加索引行，格式为 `| YYYY-MM-DD | [标题](文件名.md) |`。
- 分类表格文章数必须与实际文件数一致。
