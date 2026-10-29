# meaningfool-writing

Content for https://meaningfool.net: articles, activity logs and images. The site code lives in [meaningfool.github.io](https://github.com/meaningfool/meaningfool.github.io), which includes this repository as a git submodule at `src/content/writing/`.

## What gets published

- `articles/*.md` and `daily-logs/*.md` are published. Nothing else is: not `_draft/`, `_research/`, `_daily-notes/`, `_temp/`, files at the root, or dot-folders.
- `images/` holds the images and videos the articles use.
- Pushing a change under `articles/`, `daily-logs/` or `images/` to `main` deploys the site within a few minutes, through `.github/workflows/deploy-site.yml`. Other pushes deploy nothing.

## Article files

- Name files `YYYY-MM-DD-slug.md`. An article's URL is `/articles/slug/`, without the date. Activity logs keep it: `daily-logs/2025-11-14-daily-log.md` is served at `/articles/2025-11-14-daily-log/`. Renaming a published file changes its URL.
- Frontmatter is required, or the site build fails:

  ```yaml
  ---
  title: "Article title"
  date: 2026-01-05
  updated: 2026-03-01
  description: "Optional one-sentence summary"
  tags: ["optional"]
  ---
  ```

  `title` is a quoted string. `date` and `updated` are `YYYY-MM-DD`, unquoted. `date` is the publish date and never changes; when a published post changes meaningfully, set `updated` to that day (search engines read it). `updated`, `description` and `tags` are optional, and other fields are ignored by the site.
- Start the body with `# Title`, matching `title`; the site drops that heading and shows `title` instead. Use `##` and deeper for sections: the site currently hides any other `#` heading in the body (see meaningfool/meaningfool.github.io#8).
- Images: `![What the image shows](../images/file.png)`. Videos: `<video src="/images/file.mp4" controls width="100%"></video>`.

## Publishing a draft

Publishing is public, so confirm with the owner first unless they explicitly asked you to publish.

1. The draft is in `_draft/`. Its title is its first `# ` heading.
2. Move it to `articles/YYYY-MM-DD-slug.md` with today's date (`git mv` if it is tracked). The slug is the draft's file name without any leading number prefix.
3. Set the frontmatter: `title` from the heading, `date` to today. Keep any other fields already there.
4. Point images at `../images/…`, and report any image file that doesn't exist.
5. Commit as `Publish: <title>` and push to `main`. The push deploys the site; follow the run in meaningfool.github.io's Actions, for example with `gh run watch -R meaningfool/meaningfool.github.io`.

If a deploy fails, the live site keeps its previous version. The build log names the file at fault, usually because of bad frontmatter.

The repository is public: keep secrets and personal data out of it, including tracking parameters in links.
