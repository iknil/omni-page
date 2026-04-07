请将以下文章归档到知识库。

用户输入：$ARGUMENTS

使用说明：
- 调用格式：`/archive --url <url> [--notes "..."] [--category <分类>] [--push]`
- 或：`/archive --pdf <文件路径> [--notes "..."] [--category <分类>] [--push]`
- 具体归档规范、标题规则、图片命名、来源保真、README 更新规则统一参考项目根目录 `AGENTS.md` 与 `CONTENT_STANDARDS.md`。
- 提交前执行 `scripts/verify_archive.sh`。
- 默认只执行 `git commit`，需要手动 push，或显式追加 `--push`。
