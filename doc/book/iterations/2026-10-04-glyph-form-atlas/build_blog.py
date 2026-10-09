"""Render the editable article and optionally add it to the local Ada blog."""
from pathlib import Path
from html.parser import HTMLParser
import argparse
import hashlib
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SLUG = '2026-10-04-the-room-inside-a-letter'
TITLE = 'The room inside a letter'
SUBTITLE = 'Borrowing font outlines to build forms in Godot'
source = (HERE / 'BLOG.md').read_text(encoding='utf-8')
report = json.loads((HERE / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and len(report['checks']) == 37

css = '''
:root{color-scheme:light;--paper:#f3eee8;--ink:#302934;--muted:#6b5866;--accent:#8c3b64}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:20px/1.75 Georgia,serif}
header,footer{padding:24px 5vw;font:13px/1.6 system-ui,sans-serif;border-bottom:1px solid #d5c7ce}
header{display:flex;justify-content:space-between;gap:20px;flex-wrap:wrap}nav{display:flex;gap:22px}
main{max-width:820px;margin:65px auto 85px;padding:0 26px}h1{font-size:clamp(48px,7vw,86px);line-height:1.06;font-weight:400;letter-spacing:-.035em;margin:0 0 28px}
p{margin:24px 0}main>p:first-of-type{font:14px/1.6 system-ui,sans-serif;color:var(--muted)}
main>p:has(img){width:min(1120px,calc(100vw - 48px));position:relative;left:50%;transform:translateX(-50%);margin:42px 0 14px}
img{display:block;width:100%;height:auto}p:has(img)+p{font:14px/1.65 system-ui,sans-serif;color:var(--muted);margin-top:12px;margin-bottom:38px}
a{color:var(--accent);text-underline-offset:4px}a:hover{color:#54223a}a:focus-visible{outline:2px solid var(--accent);outline-offset:4px}
hr{border:0;border-top:1px solid #d5c7ce;margin:46px 0 28px}hr~p{font:14px/1.7 system-ui,sans-serif;color:var(--muted)}
footer{border-top:1px solid #d5c7ce;border-bottom:0;color:var(--muted)}
@media(max-width:700px){main{margin-top:38px;padding:0 22px}body{font-size:18px}main>p:has(img){width:calc(100vw - 28px)}}
@media print{body{background:white;font-size:11pt}header,footer{display:none}main{max-width:none;margin:0;padding:0}h1{font-size:34pt}main>p:has(img){width:100%;left:0;transform:none;break-inside:avoid}img{max-height:110mm;object-fit:contain}p{orphans:3;widows:3}}
'''
body = markdown.markdown(source, extensions=['extra'])
html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{TITLE} | Ada Research</title><meta name="description" content="{SUBTITLE}"><style>{css}</style></head>
<body><header><span>ADA / RESEARCH JOURNAL</span><nav><a href="index.html">Six-body study</a><a href="BLOG.md">Editable text</a><a href="borrowed-outlines.zip">Godot project</a></nav></header><main>{body}</main>
<footer>4 October 2026 · Ada Research · Illustrations captured in Godot from the working studies.</footer></body></html>'''
(HERE / 'blog.html').write_text(html, encoding='utf-8')

class LocalLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.checked = 0
    def handle_starttag(self, tag, attrs):
        for key, value in attrs:
            if key in ('href', 'src') and value and not value.startswith(('https:', 'http:', '#')):
                target = HERE / value.split('#')[0]
                assert target.exists(), f'Missing local link: {value}'
                self.checked += 1

links = LocalLinks()
links.feed(html)
evidence = {'title': TITLE, 'local_links': links.checked, 'article_sha256': hashlib.sha256(source.encode()).hexdigest(),
            'word_count_approx': len(re.findall(r"\b[\w’'-]+\b", re.sub(r'\[[^]]*\]\([^)]*\)', '', source))),
            'native_checks_referenced':len(report['checks']), 'remote_publication':False}

args = argparse.ArgumentParser()
args.add_argument('--sync-local-blog', action='store_true')
if args.parse_args().sync_local_blog:
    encyclopedia = ROOT.parent / 'ada_encyclopedia'
    posts = encyclopedia / 'src/content/blog'
    assert posts.is_dir()
    images = encyclopedia / 'public/blog' / SLUG
    images.mkdir(parents=True,exist_ok=True)
    blog_body = '\n'.join(source.splitlines()[4:]).lstrip()
    for image_name in re.findall(r'!\[[^]]*\]\(([^)]+)\)', blog_body):
        origin = HERE / image_name
        destination = images / image_name
        shutil.copy2(origin,destination)
        assert origin.read_bytes() == destination.read_bytes()
        blog_body = blog_body.replace(f']({image_name})', f'](/blog/{SLUG}/{image_name})')
    for target in re.findall(r'(?<!!)\[[^]]*\]\(([^)]+)\)', blog_body):
        if target.startswith(('http:', 'https:', '/')):
            continue
        resolved = (HERE / target).resolve()
        assert resolved.exists()
        route = '/book-review/' + resolved.relative_to(ROOT).as_posix()
        blog_body = blog_body.replace(f']({target})',f']({route})')
    frontmatter = f'''---
title: "{TITLE}"
subtitle: "{SUBTITLE}"
date: "2026-10-04"
author: "Ada Research"
tags: ["form", "typography", "godot", "topology", "critical-making"]
sequence: "primitives"
thumbnail: "/blog/{SLUG}/wells.png"
---

'''
    post = posts / (SLUG + '.md')
    post.write_text(frontmatter+blog_body,encoding='utf-8')
    assert post.read_text(encoding='utf-8') == frontmatter+blog_body
    for url in re.findall(r'\]\((/[^)]+)\)',blog_body):
        asset = (encyclopedia/'public'/url.lstrip('/')) if url.startswith('/blog/') else ROOT / url.removeprefix('/book-review/')
        assert asset.exists(), url
    evidence['local_blog_post'] = str(post)
    evidence['local_blog_route'] = '/blog/' + SLUG
    evidence['images_copied'] = len(re.findall(r'!\[',blog_body))

(HERE / 'blog-checks.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
print(json.dumps(evidence))
