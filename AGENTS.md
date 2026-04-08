# Omni Page — Agent 说明

个人知识库，包含外部文章归档、个人灵感捕获，以及从灵感沉淀出来的知识点。

## 唯一规范入口

内容规范、标题规则、来源保真、标签、资源管理统一以 [CONTENT_STANDARDS.md](CONTENT_STANDARDS.md) 为准。
`.claude/commands/` 只保留调用格式，避免重复维护正文规则。

## 目录结构

```text
omni-page/
├── README.md              # 首页导航（自动维护）
├── CONTENT_STANDARDS.md   # 内容规范（唯一标准）
├── AGENTS.md              # 本文件（Codex 用）
├── CLAUDE.md              # Claude Code 用
├── assets/                # 图片和 PDF 统一存放处
├── inspirations/          # 个人灵感速记与素材卡片
├── knowledge/             # 从灵感或文章沉淀出的知识点
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

## 内容流说明

- `archive/`：外部文章、博客、论文的结构化归档。
- `inspirations/`：随手记录的一段话、一张图，或图文混合灵感。
- `knowledge/`：从 `inspirations/` 或 `archive/` 提炼出的可复用知识点。

推荐流程：

1. 先用 `/inspire` 捕获灵感，不要求一次写全。
2. 当灵感成熟后，用 `/distill` 将其沉淀为 `knowledge/` 下的知识点。
3. 遇到外部资料时继续用 `/archive` 归档，并在需要时关联到知识点。

## 文章归档任务说明

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
- `inspirations/README.md` 与 `knowledge/README.md` 也需要维护最新索引，最新在最前。
