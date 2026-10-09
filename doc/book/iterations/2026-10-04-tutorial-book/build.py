"""Read-only compilation of current tutorial.md files in the live museum spine."""
from pathlib import Path
import hashlib
import json
import re
import shutil
from html import escape
from urllib.parse import unquote, urlsplit, quote

import markdown
from bs4 import BeautifulSoup

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DATE = '4 October 2026'
ROUTE = ROOT / 'doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json'
SPINE = ROOT / 'commons/maps/curriculum_spine.json'
INTENTS = {'Primitives_Godot', 'Primitives_Columns', 'Primitives_Profiles'}


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save_json(name, value):
    (HERE / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


CSS = '''
*{box-sizing:border-box}html{scroll-behavior:auto}body{margin:0;background:#f8f5ed;color:#26352f;font:17px/1.7 Georgia,serif}a{color:#47654d;text-underline-offset:3px}a:focus-visible,summary:focus-visible{outline:2px solid #9b633f;outline-offset:4px}nav{position:fixed;inset:0 auto 0 0;width:274px;background:#eeeee3;border-right:1px solid #d7dbcf;padding:25px 20px;overflow:auto;font:12px/1.5 Arial,sans-serif}nav h2{font-size:17px;margin-top:0}nav>p{color:#667165;font-size:11px}nav details{padding:8px 0;border-top:1px solid #d7dbcf}nav summary{cursor:pointer;font-weight:bold}nav ol{padding-left:22px}nav li{margin:7px 0}nav .gap-label{color:#955740;font-size:10px}main{margin-left:274px;padding:60px 52px 80px;max-width:1200px}h1,h2,h3,h4{font-weight:400;line-height:1.18}h1{font-size:58px;letter-spacing:-2px;margin:15px 0}h2{font-size:38px;margin:18px 0}h3{font-size:30px;margin:15px 0 26px}h4{font-size:23px;margin-top:35px}.eyebrow,.metadata,.links,.label,.back{font:11px/1.6 Arial,sans-serif;letter-spacing:.04em}.eyebrow{text-transform:uppercase;letter-spacing:.16em}.lead{font-size:22px;line-height:1.5;max-width:42ch}.cover{border-bottom:2px solid #26352f;padding-bottom:32px;margin-bottom:28px}.stats{display:flex;flex-wrap:wrap;gap:20px;font:13px Arial,sans-serif;border-top:1px solid #d7dbcf;padding-top:20px}.stats b{font-size:23px;font-weight:500;margin-right:5px}.notice,.gap{background:#f0eee3;border-left:3px solid #ae8565;padding:18px 22px;margin:25px 0;font-size:15px}.notice p,.gap p{margin:0}.links{display:flex;gap:10px 24px;flex-wrap:wrap;margin:20px 0}.assessment{padding:14px 0 25px;border-bottom:1px solid #d7dbcf}.assessment summary{cursor:pointer;font-size:22px}.assessment li{margin:12px 0}.part{padding-top:60px}.part-head{border-top:2px solid #26352f;padding-top:25px;margin-bottom:25px}.part-head .metadata{color:#687265}.chapter{padding:34px 0 40px;border-top:1px solid #d7dbcf;scroll-margin-top:24px}.chapter .label{color:#687265}.chapter .metadata{display:flex;gap:10px 22px;flex-wrap:wrap;margin:15px 0 25px}.body{max-width:72ch}.body p{margin:1em 0}.body li{margin:.45em 0}.body blockquote{margin:25px 0;padding:0 20px;border-left:2px solid #8d9c83;color:#53614f}.body pre{font:13px/1.6 Consolas,monospace;overflow:auto;background:#eaece4;border:1px solid #d8ddd0;padding:18px;border-radius:3px;white-space:pre}.body code{font:13px/1.5 Consolas,monospace;overflow-wrap:anywhere}.body p code,.body li code{background:#eceee4;padding:2px 4px}.body pre code{padding:0;background:none;overflow-wrap:normal;white-space:pre}.body img{display:block;max-width:100%;height:auto;margin:25px auto}.body table{font:13px/1.5 Arial,sans-serif;border-collapse:collapse;width:100%;display:block;overflow:auto;margin:25px 0}.body th,.body td{border:1px solid #cfd6c9;padding:8px;vertical-align:top}.body hr{border:0;border-top:1px solid #d7dbcf;margin:30px 0}.body .footnote{font-size:13px}.unavailable{font:12px/1.5 Arial,sans-serif;color:#815e43}.appendix{border-top:2px solid #26352f;margin-top:60px;padding-top:25px}.appendix li{font-size:15px}.skip{position:fixed;top:-100px;left:20px;background:white;padding:10px;z-index:5}.skip:focus{top:10px}@media(max-width:1050px){nav{width:235px}main{margin-left:235px;padding:40px 28px}h1{font-size:47px}}@media(max-width:720px){nav{position:static;width:auto;max-height:240px;border-bottom:1px solid #d7dbcf}main{margin-left:0;padding:25px 20px}h1{font-size:40px}h2{font-size:30px}h3{font-size:26px}.body pre{font-size:12px;padding:12px}}@page{size:A4;margin:20mm 19mm}@media print{body{background:white;color:black;font-size:10.5pt;line-height:1.5}nav,.links,.back,.skip{display:none}main{margin:0;padding:0;max-width:none}.cover{break-after:page}h1{font-size:38pt}h2{font-size:26pt}h3{font-size:21pt}h4{font-size:15pt}.part{break-before:page;padding-top:0}.part-head{border-top:0}.chapter{padding-top:20px}.body{max-width:none}.body pre{font-size:8pt;white-space:pre-wrap;overflow-wrap:anywhere}.body pre code{font-size:8pt;white-space:pre-wrap;overflow-wrap:anywhere}.body img{max-height:220mm;object-fit:contain}.metadata{font-size:8pt}.assessment{display:none}h1,h2,h3,h4{break-after:avoid}p{widows:3;orphans:3}a{color:inherit}}
'''


def main():
    HERE.mkdir(parents=True, exist_ok=True)
    route, spine = read_json(ROUTE), read_json(SPINE)
    source_paths = [SPINE, ROUTE]
    ordered = sorted(spine['spine']['sequences'], key=lambda s: s['order'])
    assert [s['name'] for s in ordered] == [s['id'] for s in route['sequences']]
    parts, chapter_index = [], {}
    for seq, saved in zip(ordered, route['sequences']):
        path = ROOT / 'commons/maps/sequences' / (seq['name'] + '.json')
        data = read_json(path)
        current = data.get('sequences', {}).get(seq['name'], data)
        maps = [m if isinstance(m, str) else m['name'] for m in current['maps']]
        assert maps == saved['maps'], f"Saved route differs from live sequence: {seq['name']}"
        source_paths.append(path)
        part = {'id': seq['name'], 'title': current.get('name', saved['label']), 'chapters': []}
        for name in maps:
            path = ROOT / 'commons/maps' / name / 'tutorial.md'
            chapter = {'map': name, 'path': path.relative_to(ROOT).as_posix(), 'exists': path.is_file()}
            if path.is_file():
                content = path.read_text(encoding='utf-8-sig')
                heading = re.match(r'^# (.+)', content)
                chapter.update(title=heading[1] if heading else name.replace('_', ' '),
                               prose_words=len(re.findall(r'\S+', re.sub(r'```.*?```', '', content, flags=re.S))),
                               code_blocks=len(re.findall(r'^```[^\n]*\n(.*?)^```', content, flags=re.S | re.M)),
                               sha256=digest(path), text=content, intent_only=name in INTENTS)
                snapshot = HERE / 'sources' / name / 'tutorial.md'
                snapshot.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(path, snapshot)
                source_paths.append(path)
            else:
                chapter.update(title=name.replace('_', ' '), prose_words=0, code_blocks=0, intent_only=False)
            part['chapters'].append(chapter)
            chapter_index[path.resolve()] = name
        parts.append(part)

    assets, unresolved = {}, []

    def local_link(url, source, image=False):
        parsed = urlsplit(url)
        if parsed.scheme in ('http', 'https', 'mailto'):
            return url
        if not parsed.path:
            return url
        if parsed.scheme:
            return None
        if parsed.netloc:
            return url if not image else None
        if parsed.path.startswith('/') and not parsed.path.startswith('/book-review/'):
            return url  # Existing application route.
        if parsed.path.startswith('/book-review/'):
            dest = (ROOT / unquote(parsed.path.removeprefix('/book-review/'))).resolve()
        else:
            dest = (source.parent / unquote(parsed.path)).resolve()
        if not dest.is_relative_to(ROOT) or not dest.is_file():
            unresolved.append({'source': source.relative_to(ROOT).as_posix(), 'target': url})
            return None
        if dest in chapter_index:
            name = chapter_index[dest]
            return '#' + (f'{name}--{parsed.fragment}' if parsed.fragment else f'hall-{name}')
        # Keep illustrated review pages at their original location so their own assets resolve.
        if dest.suffix.lower() == '.html' and dest.is_relative_to(ROOT / 'doc/book/iterations'):
            return '/book-review/' + quote(dest.relative_to(ROOT).as_posix(), safe='/') + ('#' + parsed.fragment if parsed.fragment else '')
        allowed = {'.md', '.txt', '.gd', '.gdshader', '.tscn', '.json', '.png', '.jpg', '.jpeg', '.webp', '.svg', '.html', '.zip'}
        if dest.suffix.lower() not in allowed:
            unresolved.append({'source': source.relative_to(ROOT).as_posix(), 'target': url})
            return None
        if dest not in assets:
            rel = 'references/' + hashlib.sha256(str(dest).encode()).hexdigest()[:12] + '-' + dest.name
            target = HERE / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(dest, target)
            assets[dest] = rel
        return quote(assets[dest], safe='/') + ('#' + parsed.fragment if parsed.fragment else '')

    def render(chapter):
        source = ROOT / chapter['path']
        soup = BeautifulSoup(markdown.markdown(chapter['text'], extensions=['extra', 'toc']), 'html.parser')
        for unsafe in soup.select('script,iframe,object,embed,form'):
            unsafe.decompose()
        first = soup.find('h1')
        if first and first.get_text() == chapter['title']:
            first.decompose()
        for node in soup.find_all(True):
            for key in list(node.attrs):
                if key.lower().startswith('on'):
                    del node.attrs[key]
            if node.get('id'):
                node['id'] = chapter['map'] + '--' + node['id']
            if re.fullmatch(r'h[1-6]', node.name):
                node.name = 'h' + str(min(6, int(node.name[1]) + 2))
            if node.name == 'a' and node.get('href'):
                href = node['href']
                target = '#' + chapter['map'] + '--' + href[1:] if href.startswith('#') else local_link(href, source)
                if target:
                    node['href'] = target
                else:
                    del node['href']
                    node['title'] = href + ' — source reference, not included in this reading copy'
            if node.name == 'img' and node.get('src'):
                src = local_link(node['src'], source, image=True)
                if src and not urlsplit(src).scheme:
                    node['src'] = src
                    node['loading'] = 'lazy'
                else:
                    replacement = soup.new_tag('p', attrs={'class': 'unavailable'})
                    replacement.string = 'Figure reference: ' + node.get('alt', '') + ' — ' + node['src']
                    node.replace_with(replacement)
        return str(soup)

    toc, sections, combined = [], [], ['# Ada — the tutorial manuscript', '', f'Current tutorial.md files, {DATE}. Read-only compilation in live museum order. Missing files and teaching intents are retained as gaps. Critical final.md chapters and preparation documents are separate.', '']
    totals = {'sequences': len(parts), 'halls': sum(len(p['chapters']) for p in parts), 'files': 0, 'prose_words': 0, 'code_blocks': 0}
    missing = []
    sequence_stats = []
    for number, part in enumerate(parts, 1):
        title = escape(part['title'])
        entries, chapters = [], []
        found = sum(c['exists'] for c in part['chapters'])
        words = sum(c['prose_words'] for c in part['chapters'])
        codes = sum(c['code_blocks'] for c in part['chapters'])
        totals['files'] += found; totals['prose_words'] += words; totals['code_blocks'] += codes
        sequence_stats.append({'id': part['id'], 'title': part['title'], 'halls': len(part['chapters']), 'files': found, 'prose_words': words, 'code_blocks': codes})
        combined += ['---', '', f'## {number:02d}. {part["title"]}', '']
        for c in part['chapters']:
            marker = ' <span class="gap-label">missing</span>' if not c['exists'] else (' <span class="gap-label">intent</span>' if c['intent_only'] else '')
            entries.append(f'<li><a href="#hall-{c["map"]}">{escape(c["title"])}</a>{marker}</li>')
            label = f'<p class="label">{escape(c["map"])}{marker}</p><h3>{escape(c["title"])}</h3>'
            combined += [f'### {c["map"]}', '', f'Source: `{c["path"]}`', '']
            if c['exists']:
                note = '<aside class="notice"><p>This source explicitly describes teaching intent. It is not a completed lesson.</p></aside>' if c['intent_only'] else ''
                meta = f'<p class="metadata"><span>{c["prose_words"]:,} prose words · {c["code_blocks"]} code blocks</span><a href="sources/{c["map"]}/tutorial.md">Original Markdown snapshot</a></p>'
                body = note + meta + '<div class="body">' + render(c) + '</div>'
                combined += [c['text'].rstrip(), '']
            else:
                missing.append(c['map'])
                body = '<aside class="gap"><p>No tutorial.md file exists here in this snapshot. This hall remains in the book’s route; no substitute lesson has been invented.</p></aside>'
                combined += ['**Missing tutorial.md — no substitute text added.**', '']
            chapters.append(f'<article class="chapter" id="hall-{c["map"]}">{label}{body}<p class="back"><a href="#seq-{part["id"]}">Back to sequence</a> · <a href="#top">Contents</a></p></article>')
        toc.append(f'<details><summary><a href="#seq-{part["id"]}">{number:02d}. {title}</a></summary><ol>{"".join(entries)}</ol></details>')
        sections.append(f'<section class="part" id="seq-{part["id"]}"><header class="part-head"><p class="eyebrow">Sequence {number:02d}</p><h2>{title}</h2><p class="metadata">{found}/{len(part["chapters"])} tutorial files · {words:,} prose words · {codes} code blocks</p></header>{"".join(chapters)}</section>')

    assessment_path = HERE / 'ASSESSMENT.md'
    assessment = markdown.markdown(assessment_path.read_text(encoding='utf-8'), extensions=['extra']) if assessment_path.exists() else '<p>The current files have been assembled without rewriting. Editorial assessment is being prepared.</p>'
    html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ada — the tutorial manuscript</title><style>{CSS}</style></head><body><a class="skip" href="#reading">Skip to the manuscript</a><nav aria-label="Book contents"><h2><a href="#top">The tutorial manuscript</a></h2><p>{DATE} · current files</p><p><a href="#assessment">Editorial reading</a> · <a href="#gaps">Missing chapters</a></p>{''.join(toc)}</nav><main id="top"><header class="cover"><p class="eyebrow">Ada / Endless Museum / reading copy</p><h1>The tutorial manuscript</h1><p class="lead">A walk through the current lessons, in the order of the museum.</p><p>{DATE}. This gathers the actual <code>tutorial.md</code> files. It lets us read the book we have alongside the progression we are planning.</p><div class="stats"><span><b>{totals['sequences']}</b>sequences</span><span><b>{totals['files']}/{totals['halls']}</b>files present</span><span><b>{totals['prose_words']:,}</b>prose words</span><span><b>{len(missing)}</b>missing files</span></div><aside class="notice"><p>Working manuscript, not a finished course. A present file may be a lesson, a field guide, a code sketch or a teaching intent. The new foundation proposals have not been substituted for these texts. Setup/preparation and the critical <code>final.md</code> track remain separate.</p></aside><p class="links"><a href="#reading">Begin reading</a><a href="tutorial-book.md">Whole manuscript as Markdown</a><a href="manifest.json">Sources and counts</a><a href="/research-outline">Research outline</a></p><p class="metadata">Prose count excludes fenced code and uses whitespace-separated words. {totals['code_blocks']} code blocks are retained. This is a saved snapshot; rebuild to pick up later edits. Browser Find searches the complete text.</p></header><details class="assessment" id="assessment"><summary>How it reads as a book</summary>{assessment}</details><div id="reading">{''.join(sections)}</div><section class="appendix" id="gaps"><h2>Ten places with no tutorial file</h2><p>These gaps are visible in the reading order above. They are not filled with <code>final.md</code>, summaries or generated lessons.</p><ul>{''.join(f'<li><a href="#hall-{m}">{escape(m)}</a></li>' for m in missing)}</ul></section></main></body></html>'''
    (HERE / 'index.html').write_text(html, encoding='utf-8')
    (HERE / 'tutorial-book.md').write_text('\n'.join(combined), encoding='utf-8')
    save_json('manifest.json', {'date': '2026-10-04', 'scope': 'Current tutorial.md only; source chapters unchanged', 'counts': totals, 'missing': missing, 'explicit_intent_files': sorted(INTENTS), 'sequences': sequence_stats,
        'sources': [{'path': p.relative_to(ROOT).as_posix(), 'sha256': digest(p)} for p in source_paths],
        'references': [{'source': p.relative_to(ROOT).as_posix(), 'snapshot': rel, 'sha256': digest(p)} for p, rel in assets.items()], 'unresolved_references': unresolved})
    print(json.dumps({'counts': totals, 'missing': missing, 'copied_references': len(assets), 'unresolved_references': len(unresolved)}, indent=2))


if __name__ == '__main__':
    main()
