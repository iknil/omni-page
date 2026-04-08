请将灵感或归档沉淀为知识点。

用户输入：$ARGUMENTS

使用说明：
- 调用格式：`/distill --from inspirations/20260408-example.md --title "知识点标题" [--push]`
- 或：`/distill --from archive/ai-ml/20260408-example.md --title "知识点标题" [--push]`
- 输出文件写入 `knowledge/YYYYMMDD-slug.md`。
- 必须回链来源灵感或归档，并在需要时更新来源文件中的关联知识点字段。
- 具体结构与字段统一参考项目根目录 `AGENTS.md` 与 `CONTENT_STANDARDS.md`。
- 提交前执行 `scripts/verify_archive.sh`。
- 默认只执行 `git commit`，需要手动 push，或显式追加 `--push`。
