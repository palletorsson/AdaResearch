"""Render a local research article and bind its claims to saved Trace evidence."""
from pathlib import Path
from urllib.parse import urlparse
import hashlib
import json
import re
import shutil

import markdown
from bs4 import BeautifulSoup

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ENCYCLOPEDIA = ROOT.parent / 'ada_encyclopedia'
SLUG = '2026-10-05-the-tutorial-must-run'
TITLE = 'The tutorial must run'
SUBTITLE = 'Writing for an imagined student, with code that has to work'

native_path = ROOT / 'doc/book/iterations/2026-10-05-trace-the-carried-point/student/report-runtime.json'
native = json.loads(native_path.read_text(encoding='utf-8'))
assert native['passed'] and all(c['passed'] for c in native['checks'])
assert len(native['checks']) == 124
assert native['continuation_composes_exactly'] and native['supplied_helper_unchanged_and_printed']
assert all(c['expected_failure_detected'] for c in native['negative_controls'])
drift = [p for p, h in native['inputs'].items()
         if hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != h]
assert not drift, drift
dependency_drift = [p for p, h in native['dependencies'].items()
                    if hashlib.sha256((ROOT / p).read_bytes()).hexdigest() != h]
assert not dependency_drift, dependency_drift

image_source = ROOT / 'doc/book/iterations/2026-10-05-eight-interaction-lessons/figures/trace.png'
shutil.copy2(image_source, HERE / 'trace-hall.png')
source = (HERE / 'BLOG.md').read_text(encoding='utf-8')
body = markdown.markdown(source, extensions=['extra'])
css = '''
:root{color-scheme:light;--paper:#f6f2eb;--ink:#292b2c;--muted:#62615d;--accent:#8e4265;--line:#d8cdc5}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:20px/1.78 Georgia,serif}
header,footer{padding:22px 5vw;font:13px/1.6 system-ui,sans-serif;border-bottom:1px solid var(--line)}
header{display:flex;justify-content:space-between;gap:18px;flex-wrap:wrap}nav{display:flex;gap:20px;flex-wrap:wrap}
main{max-width:830px;margin:62px auto 80px;padding:0 26px}h1{font-size:clamp(48px,8vw,86px);font-weight:400;line-height:1.04;letter-spacing:-.04em;margin:0 0 24px}
main>p:first-of-type{font:14px/1.6 system-ui,sans-serif;color:var(--muted)}p{margin:23px 0}a{color:var(--accent);text-underline-offset:4px}
a:focus-visible{outline:2px solid var(--accent);outline-offset:4px}code{font:.85em/1.5 Consolas,monospace;overflow-wrap:anywhere}
pre{overflow:auto;padding:18px;background:#eae6de}h2{font-size:32px;line-height:1.2;font-weight:400;margin-top:45px}table{width:100%;border-collapse:collapse;font:14px/1.65 system-ui,sans-serif}th,td{border-bottom:1px solid var(--line);padding:10px;text-align:left}
img{display:block;width:100%;height:auto}p:has(img){margin:40px 0 12px}p:has(img)+p{font:13px/1.65 system-ui,sans-serif;color:var(--muted);margin-top:12px}
blockquote{margin:35px 0;padding:2px 24px;border-left:3px solid var(--accent);background:#eae6de;font:16px/1.8 system-ui,sans-serif}
ol{padding-left:1.2em}li{padding-left:.3em;margin:20px 0}hr{margin:45px 0 24px;border:0;border-top:1px solid var(--line)}
hr~p{font:14px/1.7 system-ui,sans-serif;color:var(--muted)}footer{border-top:1px solid var(--line);border-bottom:0}
@media(max-width:700px){body{font-size:18px}main{padding:0 21px;margin-top:36px}header{padding:18px 21px}}
@media print{body{background:white;font-size:11pt}header,footer{display:none}main{max-width:none;margin:0;padding:0}h1{font-size:34pt}img{max-height:100mm;object-fit:contain}p{orphans:3;widows:3}li,blockquote{break-inside:avoid}}
'''
rules_source = ROOT / 'doc/book/course/functional_text/RECONSTRUCTION.md'
shutil.copy2(rules_source, HERE / 'RECONSTRUCTION.md')
rules_text = rules_source.read_text(encoding='utf-8')
rules_display = rules_text.replace('[functional text](FUNCTIONAL_TEXT.md)', 'functional text')
for target in re.findall(r'(?<!!)\[[^]]*\]\(([^)]+)\)', rules_display):
    if urlparse(target).scheme or target.startswith('/'):
        continue
    path, _, fragment = target.partition('#')
    resolved = (rules_source.parent / path).resolve()
    assert resolved.exists(), target
    route = '/book-review/' + resolved.relative_to(ROOT).as_posix()
    if fragment:
        route += '#' + fragment
    rules_display = rules_display.replace(f']({target})', f']({route})')
rules_body = markdown.markdown(rules_display, extensions=['extra', 'toc'])
rules_page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Can the student make it? | Ada Research</title><style>{css}</style><header><span>ADA / WORKING METHOD</span><nav><a href="index.html">Read the article</a><a href="RECONSTRUCTION.md">Source snapshot</a></nav></header><main>{rules_body}</main><footer>Rendered from doc/book/course/functional_text/RECONSTRUCTION.md · 5 October 2026.</footer></html>'''
(HERE / 'rules.html').write_text(rules_page, encoding='utf-8')
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{TITLE} | Ada Research</title><meta name="description" content="{SUBTITLE}"><style>{css}</style></head><body>
<header><span>ADA / RESEARCH JOURNAL</span><nav><a href="../2026-10-05-primitives-facing-pages/Point_Trace.html">Read Trace</a><a href="rules.html#rules-for-accepting-the-next-lesson">Working rules</a><a href="BLOG.md">Editable article</a></nav></header><main>{body}</main><footer>5 October 2026 · Local research journal · Saved native evidence, editorial judgement and human learning remain distinct.</footer></body></html>'''
(HERE / 'index.html').write_text(page, encoding='utf-8')
links = []
for el in BeautifulSoup(page, 'html.parser').select('[href], [src]'):
    target = el.get('href') or el.get('src')
    if urlparse(target).scheme or target.startswith('#'):
        continue
    assert (HERE / target.split('#')[0]).exists(), target
    links.append(target)

# The existing local journal is repository content. This does not deploy it remotely.
post_dir = ENCYCLOPEDIA / 'src/content/blog'
assert post_dir.is_dir()
assets = ENCYCLOPEDIA / 'public/blog' / SLUG
assets.mkdir(parents=True, exist_ok=True)
shutil.copy2(HERE / 'trace-hall.png', assets / 'trace-hall.png')
post_body = '\n'.join(source.splitlines()[4:]).lstrip()
post_body = post_body.replace('](trace-hall.png)', f'](/blog/{SLUG}/trace-hall.png)')
for target in re.findall(r'(?<!!)\[[^]]*\]\(([^)]+)\)', post_body):
    if urlparse(target).scheme or target.startswith('/'):
        continue
    path, _, fragment = target.partition('#')
    resolved = (HERE / path).resolve()
    assert resolved.exists(), target
    route = '/book-review/' + resolved.relative_to(ROOT).as_posix()
    if fragment:
        route += '#' + fragment
    post_body = post_body.replace(f']({target})', f']({route})')
post_body = post_body.replace('](http://localhost:3003/', '](/')
frontmatter = f'''---
title: "{TITLE}"
subtitle: "{SUBTITLE}"
date: "2026-10-05"
author: "Ada Research"
tags: ["pedagogy", "godot", "tutorials", "testing", "ghost-student"]
sequence: "primitives"
thumbnail: "/blog/{SLUG}/trace-hall.png"
---

'''
post = post_dir / f'{SLUG}.md'
post.write_text(frontmatter + post_body, encoding='utf-8')
evidence = {
    'article_sha256': hashlib.sha256(source.encode()).hexdigest(),
    'rules_source_sha256': hashlib.sha256(rules_source.read_bytes()).hexdigest(),
    'native_report': native_path.relative_to(ROOT).as_posix(),
    'native_report_sha256': hashlib.sha256(native_path.read_bytes()).hexdigest(),
    'native_checks_passed': len(native['checks']),
    'native_rerun_this_documentation_pass': False,
    'current_input_hashes_match': not drift,
    'input_files_compared': len(native['inputs']),
    'dependency_files_compared': len(native['dependencies']),
    'current_dependency_hashes_match': not dependency_drift,
    'negative_controls_detected': [c['name'] for c in native['negative_controls']],
    'local_links_checked': len(links),
    'image_source': image_source.relative_to(ROOT).as_posix(),
    'image_sha256': hashlib.sha256((HERE / 'trace-hall.png').read_bytes()).hexdigest(),
    'local_blog_post': str(post),
    'local_blog_route': '/blog/' + SLUG,
    'remote_publication': False,
}
(HERE / 'blog-checks.json').write_text(json.dumps(evidence, indent=2) + '\n', encoding='utf-8')
print(json.dumps(evidence))
