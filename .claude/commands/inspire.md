请将以下个人灵感记录到知识库。

用户输入：$ARGUMENTS

使用说明：
- 调用格式：`/inspire --text "灵感内容" --scene "触发场景" [--tags "..."] [--push]`
- 或：`/inspire --image <图片路径> --scene "触发场景" [--tags "..."] [--push]`
- 或：`/inspire --text "..." --image <图片路径> --scene "触发场景" [--tags "..."] [--push]`
- 输出文件写入 `inspirations/YYYYMMDD-slug.md`。
- 图片统一放入 `assets/inspirations/<slug>/`，并在灵感文件中用相对路径引用。
- 具体结构与字段统一参考项目根目录 `AGENTS.md` 与 `CONTENT_STANDARDS.md`。
- 提交前执行 `scripts/verify_archive.sh`。
- 默认只执行 `git commit`，需要手动 push，或显式追加 `--push`。
