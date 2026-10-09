"""Render the article and optionally mirror it to the existing local Ada blog."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit
import argparse
import hashlib
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SLUG = '2026-10-04-making-form-from-points-lines-and-light'
TITLE = 'Making form from points lines and light'
SUBTITLE = 'From borrowed outlines to free drawing in space'
source = (HERE / 'BLOG.md').read_text(encoding='utf-8')
previous = HERE.parent / '2026-10-04-glyph-form-atlas/blog.html'
css = re.search(r'<style>(.*?)</style>', previous.read_text(encoding='utf-8'), re.S).group(1)
css += '\nnav{flex-wrap:wrap}@media(max-width:500px){header{padding:20px 22px}nav{gap:14px}}'
body = markdown.markdown(source, extensions=['extra'])
html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{TITLE} | Ada Research</title><meta name="description" content="{SUBTITLE}"><style>{css}</style></head>
<body><header><span>ADA / RESEARCH JOURNAL</span><nav><a href="index.html">The working studies</a><a href="BLOG.md">Editable text</a><a href="painting-space.zip">Godot project</a></nav></header><main>{body}</main>
<footer>4 October 2026 · Ada Research · Native Godot illustrations from Painting space.</footer></body></html>'''
(HERE / 'blog.html').write_text(html, encoding='utf-8')

class LocalLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.count = 0
        self.images = 0

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == 'img':
            assert values.get('alt'), 'Image needs descriptive alternative text'
            self.images += 1
        for key, value in attrs:
            if key not in ('href', 'src') or not value:
                continue
            url = urlsplit(value)
            if url.scheme or not url.path:
                continue
            assert (HERE / url.path).exists(), value
            self.count += 1

links = LocalLinks()
links.feed(html)
evidence = {'title': TITLE, 'local_links': links.count, 'illustrations': links.images,
            'article_sha256': hashlib.sha256(source.encode()).hexdigest(),
            'word_count_approx': len(re.findall(r"\b[\w’'-]+\b", re.sub(r'\[[^]]*\]\([^)]*\)', '', source))),
            'remote_publication': False}
parser = argparse.ArgumentParser()
parser.add_argument('--sync-local-blog', action='store_true')
if parser.parse_args().sync_local_blog:
    encyclopedia = ROOT.parent / 'ada_encyclopedia'
    posts = encyclopedia / 'src/content/blog'
    assert posts.is_dir()
    images = encyclopedia / 'public/blog' / SLUG
    images.mkdir(parents=True, exist_ok=True)
    blog_body = '\n'.join(source.splitlines()[4:]).lstrip()
    for image_name in re.findall(r'!\[[^]]*\]\(([^)]+)\)', blog_body):
        origin = HERE / image_name
        destination = images / Path(image_name).name
        shutil.copy2(origin, destination)
        assert origin.read_bytes() == destination.read_bytes()
        blog_body = blog_body.replace(f']({image_name})', f'](/blog/{SLUG}/{destination.name})')
    for target in re.findall(r'(?<!!)\[[^]]*\]\(([^)]+)\)', blog_body):
        url = urlsplit(target)
        if url.scheme or target.startswith('/'):
            continue
        resolved = (HERE / url.path).resolve()
        assert resolved.exists(), target
        route = '/book-review/' + resolved.relative_to(ROOT).as_posix()
        if url.fragment:
            route += '#' + url.fragment
        blog_body = blog_body.replace(f']({target})', f']({route})')
    frontmatter = f'''---
title: "{TITLE}"
subtitle: "{SUBTITLE}"
date: "2026-10-04"
author: "Ada Research"
tags: ["form", "drawing", "godot", "perception", "critical-making"]
sequence: "primitives"
thumbnail: "/blog/{SLUG}/brush-bubbles.png"
---

'''
    post = posts / (SLUG + '.md')
    post.write_text(frontmatter + blog_body, encoding='utf-8')
    assert post.read_text(encoding='utf-8') == frontmatter + blog_body
    for target in re.findall(r'\]\((/[^)]+)\)', blog_body):
        path = urlsplit(target).path
        asset = encyclopedia / 'public' / path.lstrip('/') if path.startswith('/blog/') else ROOT / path.removeprefix('/book-review/')
        assert asset.exists(), target
    evidence['local_blog_post'] = str(post)
    evidence['local_blog_route'] = '/blog/' + SLUG

(HERE / 'blog-checks.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')
print(json.dumps(evidence))
