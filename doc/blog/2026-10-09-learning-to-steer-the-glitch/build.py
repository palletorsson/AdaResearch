"""Publish the illustrated progress essay using unchanged native museum captures."""
from pathlib import Path
from html import escape
import hashlib
import json
import re
import shutil

import markdown

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SITE = REPO.parent / "ada_encyclopedia"
SLUG = HERE.name
IMAGES = {
    "01-in-the-hall.png": "2026-10-09-glitch-dials/museum/new-gallery.png",
    "02-uncertain-surface.png": "2026-10-09-geometry-noise-test/museum/comparison.png",
    "03-curl-the-view.png": "2026-10-09-camera-image-becomes-body/museum/mode-05.png",
    "04-wrap-the-room.png": "2026-10-09-camera-image-becomes-body/museum/mode-10.png",
    "05-wrong-row-width.png": "2026-10-09-cut-the-image-pixels/museum/pixels-02.png",
    "06-exchanged-blocks.png": "2026-10-09-cut-the-image-pixels/museum/pixels-04.png",
    "07-dials.png": "2026-10-09-glitch-dials/museum/new-console.png",
}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    site_images = SITE / "public/blog-images" / SLUG
    local_images = HERE / "images"
    site_images.mkdir(parents=True, exist_ok=True)
    local_images.mkdir(exist_ok=True)
    evidence = []
    for name, source in IMAGES.items():
        original = REPO / "doc/book/iterations" / source
        for target in (local_images / name, site_images / name):
            shutil.copy2(original, target)
            assert digest(target) == digest(original)
        evidence.append({"image": name, "source": original.relative_to(REPO).as_posix(),
                         "sha256": digest(original)})

    raw = (HERE / "post.md").read_text(encoding="utf-8")
    _, frontmatter, body = raw.split("---", 2)
    meta = dict(re.findall(r'^(\w+): "(.*)"$', frontmatter, re.M))
    local_targets = re.findall(r'\]\(([^)]+)\)', body)
    for target in local_targets:
        assert (HERE / target).resolve().is_file(), target
    html_body = markdown.markdown(body, extensions=["extra"])
    html_body = re.sub(r'<p><img ([^>]+) /></p>\s*<p><em>(.*?)</em></p>',
                      r'<figure><img loading="lazy" \1><figcaption>\2</figcaption></figure>',
                      html_body, flags=re.S)
    css = """
    *{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#242d30;font:20px/1.75 Georgia,serif}
    main{max-width:1160px;margin:auto;padding:48px 28px 85px}header,p{max-width:760px;margin:0 auto 1.4em}
    h1{font-size:clamp(40px,6vw,76px);line-height:1.04;letter-spacing:-.035em;margin:.4em 0}
    .subtitle{font-size:24px;line-height:1.45;color:#5c6263}.date,nav,figcaption{font-family:system-ui,sans-serif}
    .date{font-size:12px;text-transform:uppercase;letter-spacing:.14em;color:#7c365b}
    nav{font-size:14px;display:flex;gap:20px;flex-wrap:wrap;margin-bottom:38px}
    a{color:#873f62;text-underline-offset:3px}figure{margin:44px 0 54px}img{display:block;width:100%;height:auto;border:1px solid #d2ccc3}
    figcaption{font-size:14px;line-height:1.6;max-width:820px;margin:12px auto;color:#596064;padding:0 8px}
    @media(max-width:600px){body{font-size:18px}main{padding:24px 18px}figure{margin:30px -8px}.subtitle{font-size:21px}}
    @media print{body{background:white;font-size:11pt}nav{display:none}main{padding:0}h1{font-size:32pt}figure{break-inside:avoid}figcaption{font-size:9pt}}
    """
    page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>{escape(meta['title'])} | Ada Research</title><style>{css}</style></head>
    <body><main><header><nav><a href="post.md">Read / edit the text</a>
    <a href="http://localhost:3003/blog/{SLUG}">Encyclopedia blog</a></nav>
    <div class="date">9 October 2026 · Endless Museum</div><h1>{escape(meta['title'])}</h1>
    <p class="subtitle">{escape(meta['subtitle'])}</p></header>{html_body}</main></body></html>'''
    (HERE / "index.html").write_text(page, encoding="utf-8")

    site_post = raw.replace('"images/', f'"/blog-images/{SLUG}/')
    site_post = site_post.replace('(images/', f'(/blog-images/{SLUG}/')
    site_post = site_post.replace('(../../book/', '(/book-review/doc/book/')
    post_path = SITE / "src/content/blog" / f"{SLUG}.md"
    post_path.write_text(site_post, encoding="utf-8")
    manifest = {"title": meta["title"], "local_targets_checked": len(local_targets),
                "native_images": evidence, "image_bytes_unchanged": True,
                "site_post": str(post_path), "browser_render_checked": False}
    (HERE / "publication.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"images": len(evidence), "local_targets": len(local_targets),
                      "post": str(post_path)}, indent=2))


if __name__ == "__main__":
    main()
