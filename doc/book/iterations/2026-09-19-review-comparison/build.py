"""Build a local reading page from actual before-files and current manuscripts."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import os
import re
import struct

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ESC = html.escape


def url(path):
    return Path(os.path.relpath(path, HERE)).as_posix()


def inline(text):
    text = ESC(text)
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    return re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)


def marked(a, b):
    aa, bb = re.findall(r'\S+\s*', a), re.findall(r'\S+\s*', b)
    left, right = [], []
    for tag, a1, a2, b1, b2 in difflib.SequenceMatcher(None, aa, bb, autojunk=False).get_opcodes():
        x, y = inline(''.join(aa[a1:a2])), inline(''.join(bb[b1:b2]))
        left.append(f'<del>{x}</del>' if tag in ('replace', 'delete') else x)
        right.append(f'<ins>{y}</ins>' if tag in ('replace', 'insert') else y)
    return ''.join(left), ''.join(right)


def figure(path, caption):
    # Reserve capture space before lazy loading so chapter fragments stay put.
    with Path(path).open('rb') as source:
        header = source.read(24)
    dimensions = ''
    if header[:8] == b'\x89PNG\r\n\x1a\n':
        width, height = struct.unpack('>II', header[16:24])
        dimensions = f' width="{width}" height="{height}"'
    return f'<figure><a href="{url(path)}"><img src="{url(path)}" alt="{ESC(caption)}"{dimensions} loading="lazy"></a><figcaption>{ESC(caption)}</figcaption></figure>'


def pair(paths, captions, note):
    return '<div class="images">' + ''.join(figure(p, c) for p, c in zip(paths, captions)) + '</div><p class="note">' + ESC(note) + '</p>'


def chapter(map_name, folder, title, reason, image_html):
    old_path = ROOT / f'doc/book/iterations/{folder}/before/commons/maps/{map_name}/final.md'
    new_path = ROOT / f'commons/maps/{map_name}/final.md'
    a, b = old_path.read_text(encoding='utf-8'), new_path.read_text(encoding='utf-8')
    ap, bp = a.strip().split('\n\n'), b.strip().split('\n\n')
    rows = []
    for tag, a1, a2, b1, b2 in difflib.SequenceMatcher(None, ap, bp, autojunk=False).get_opcodes():
        if tag == 'equal':
            continue
        left, right = marked('\n\n'.join(ap[a1:a2]), '\n\n'.join(bp[b1:b2]))
        rows.append(f'<div class="textpair"><div class="old"><span class="label">Before</span><p>{left or "<em>No passage here.</em>"}</p></div><div class="new"><span class="label">Current</span><p>{right or "<em>Passage removed.</em>"}</p></div></div>')
    patch = ''.join(difflib.unified_diff(a.splitlines(True), b.splitlines(True), fromfile=str(old_path.relative_to(ROOT)), tofile=str(new_path.relative_to(ROOT))))
    (HERE / f'{map_name}.diff').write_text(patch, encoding='utf-8')
    return f'''<section id="{map_name}"><div class="eyebrow">Book + encounter · applied</div><h2>{ESC(title)}</h2><p class="lead">{ESC(reason)}</p>{image_html}
    <h3>Changed passages</h3><p class="note">Only revised paragraphs are shown. Highlights mark changed words; the source files remain authoritative.</p>{''.join(rows)}
    <div class="links"><a href="http://localhost:3003/compose/sources?map={map_name}&doc=final">Read the complete current chapter ↗</a><a href="{map_name}.diff">Exact text diff</a></div>
    <details><summary>Original and current versions</summary><p>Before: <a href="{url(old_path)}">saved manuscript</a> · SHA-256 <code>{hashlib.sha256(old_path.read_bytes()).hexdigest()[:16]}</code></p><p>Current: <a href="{url(new_path)}">final.md</a> · SHA-256 <code>{hashlib.sha256(new_path.read_bytes()).hexdigest()[:16]}</code></p></details></section>'''


def build():
    point = ROOT / 'doc/book/iterations/2026-09-19-primitives-review'
    triangle = ROOT / 'doc/book/iterations/2026-09-19-triangle-shift-start'
    sections = [chapter('Point_One', point.name, 'One point, two addresses',
        'The chapter already asks what an address needs. Two adjacent cards now let the same point answer in WORLD and LOCAL coordinates. The text adds the invitation to compare them.',
        figure(point / 'point-one-after.png', 'Current encounter · actual Point One museum hall, captured 19 September. Both cards follow the same point. No matched original-layout image was captured.')),
        chapter('Point_Triangle_Context', triangle.name, 'The boundary stays. The fill changes.',
        'SHIFT START lets the visitor change one choice while keeping the six corners fixed. The manual retracing experiment remains available; its count is explained separately.',
        pair([triangle / 'triangle-start-a-plan.png', triangle / 'triangle-start-b-plan.png'],
             ['Experiment A · START 1. One six-corner L, four triangles.', 'Experiment B · START 2. The same outline and count; fill reaches into the notch.'],
             'These are two states of the updated artifact, not before/after software versions. Same camera, real Godot scene in an isolated fixture; this pair does not show a full museum or headset visit.'))]
    trans = ROOT / 'doc/book/iterations/2026-09-19-transformation-review'
    trans_record = json.loads((trans / 'final-verification.json').read_text(encoding='utf-8'))
    unchanged = trans_record['final_chapters_match_original_package']
    assert len(unchanged) == 7 and all(unchanged.values())
    sections.append(f'''<section id="transformation"><div class="eyebrow">Transformation · preserved</div><h2>Seven chapters retained</h2><p class="lead">The latest Transformation pass changed supporting descriptions and repaired source loading. It made no change to the seven final.md texts or hall layouts.</p><div class="path">Name an operation → make passage → test axes and bodies → make room</div><p>{' · '.join(ESC(x) for x in unchanged)}</p><p>Carousel, ScaleMe, grower and pickup descriptions were corrected against the implementations. Review packages now include grid utilities, and their frozen scripts are excluded from Godot’s live class imports.</p><p class="note">No visual before/after is claimed for these maintenance changes. Fresh tests support specific behaviors; Translation still needs a complete route check.</p><a href="{url(trans/'SUMMARY.md')}">Read the findings, tests and remaining questions ↗</a></section>''')
    for key, title in [('arrays', 'A collection becomes addressable'), ('wall-exception', 'The paper follows us'), ('color', 'A value enters a relation'), ('tiling', 'A recipe finds another body'), ('change', 'What an update keeps'), ('forces', 'What gives an arrow consequence'), ('formfinding', 'How did this form come to hold?'), ('wavefunctions', 'What returns, and what travels?'), ('randomness', 'What can chance change?'), ('noise', 'Where a value becomes a body'), ('cellularautomata', 'What can a neighbour make possible?'), ('fractals', 'What can one more call make?'), ('lsystems', 'An instruction meets a world'), ('proceduralgeneration', 'What can a generator make room for?'), ('softbodies', 'When does a body become a form?'), ('isosurfaces', 'What makes an opening possible?'), ('boolean_surfaces', 'Connected for which body?'), ('swarmintelligence', 'Where coordination lives'), ('machinelearning', 'What actually changes?'), ('graphtheory', 'What an early choice makes possible'), ('foundationscrisis', 'What did the measurement depend on?'), ('qfeplaboratory', 'What does one number leave out?'), ('postfoundationscrisis', 'Which decisions can we return to?')]:
        extra_path = HERE / f'{key}.json'
        if not extra_path.exists():
            continue
        review = json.loads(extra_path.read_text(encoding='utf-8'))
        blocks = []
        for item in review.get('items', []):
            content = f'<h3>{ESC(item["title"])}</h3><p>{ESC(item["description"])}</p>'
            if item.get('images'):
                content += pair([ROOT / p for p in item['images']], item['captions'], item['image_note'])
            if item.get('before') is not None:
                a, b = marked(item['before'], item['after'])
                content += f'<div class="textpair"><div class="old"><span class="label">Before · {ESC(item.get("text_kind", "interface"))}</span><p>{a}</p></div><div class="new"><span class="label">{ESC(item.get("after_label", "Current"))} · {ESC(item.get("text_kind", "interface"))}</span><p>{b}</p></div></div>'
            if item.get('report'):
                content += f'<p><a href="{url(ROOT/item["report"])}">{ESC(item.get("report_label", "Evidence and limits"))} ↗</a></p>'
            blocks.append('<article>' + content + '</article>')
        sections.append(f'<section id="{key}"><div class="eyebrow">{key.title()} · {ESC(review.get("status", "local review"))}</div><h2>{ESC(title)}</h2><p class="lead">' + ESC(review['summary']) + '</p>' + ''.join(blocks) + '</section>')
    css = '''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f5f2eb;color:#242624;font:17px/1.65 system-ui,sans-serif}header,main,footer{max-width:1380px;margin:auto;padding:44px 5vw}header{padding-bottom:24px}.eyebrow,.label{font:700 12px/1.5 system-ui;letter-spacing:.11em;text-transform:uppercase;color:#626860}h1{font:500 clamp(36px,5vw,66px)/1.09 Georgia,serif;margin:18px 0}h2{font:500 clamp(28px,3vw,42px)/1.15 Georgia,serif;margin:14px 0 20px}h3{font-size:21px;margin-top:30px}.lead{max-width:850px;font-size:20px}nav{display:flex;gap:10px;flex-wrap:wrap;margin:28px 0}nav a{padding:7px 14px;border:1px solid #bac2b8;border-radius:30px;text-decoration:none}a{color:#31564f;text-underline-offset:4px}section{border-top:1px solid #c7cdc4;padding:44px 0;scroll-margin-top:20px}figure{margin:0}figure img{display:block;width:100%;height:auto;background:#d8dcd7;border-radius:5px}figure a:focus{outline:3px solid #477b70}figcaption{font-size:14px;color:#586058;line-height:1.5;margin:10px 0 18px}.images,.textpair{display:grid;grid-template-columns:1fr 1fr;gap:18px}.textpair{margin:14px 0}.textpair>div{padding:21px 24px;border:1px solid #d5d9d1;border-radius:5px}.textpair p{white-space:pre-wrap;margin:14px 0 0;font:18px/1.8 Georgia,serif}.old{background:#fff9f4}.new{background:#f3f9f1}del{background:#f4d8c9;text-decoration:line-through;text-decoration-color:#bc7760}ins{background:#d5eace;text-decoration:none}code{font:14px/1.5 ui-monospace,monospace;overflow-wrap:anywhere}.note{font-size:14px;color:#626860;max-width:920px}.links{display:flex;gap:22px;flex-wrap:wrap;margin:24px 0}details{font-size:14px;color:#626860}summary{cursor:pointer}.path{font:23px/1.6 Georgia,serif;padding:24px;background:#e8ede4;border-left:3px solid #456c5b}article{margin-top:36px;padding-top:14px;border-top:1px dotted #c7cdc4}footer{font-size:14px;color:#626860;padding-top:0}@media(max-width:760px){.images,.textpair{grid-template-columns:1fr}.textpair{gap:6px}header,main,footer{padding-left:20px;padding-right:20px}main{padding-top:0}section{padding-top:30px}.lead{font-size:18px}}@media print{nav{display:none}section{break-before:page}details{display:none}body{background:white}.textpair>div{break-inside:avoid}}'''
    navigation = '<a href="#Point_One">Point One</a><a href="#Point_Triangle_Context">Triangle</a><a href="#transformation">Transformation</a>'
    navigation += ''.join(f'<a href="#{key}">{"Cellular Automata" if key == "cellularautomata" else "Post-Crisis" if key == "postfoundationscrisis" else key.replace("_", " ").title()}</a>' for key in ['arrays', 'wall-exception', 'color', 'tiling', 'change', 'forces', 'formfinding', 'wavefunctions', 'randomness', 'noise', 'cellularautomata', 'fractals', 'lsystems', 'proceduralgeneration', 'softbodies', 'isosurfaces', 'boolean_surfaces', 'swarmintelligence', 'machinelearning', 'graphtheory', 'foundationscrisis', 'qfeplaboratory', 'postfoundationscrisis'] if (HERE / f'{key}.json').exists())
    page = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Ada Research — text and encounters</title><style>' + css + '</style><header><div class="eyebrow">Ada Research · working comparison · 19 September 2026</div><h1>Text and encounters</h1><p class="lead">Read the revised passages beside their originals. Look at what the encounter lets a visitor compare.</p><nav aria-label="Chapters">' + navigation + '</nav><p class="note">Book prose, interface wording and runtime evidence are labelled separately. Images are Godot captures, not illustrations. Click any image to inspect it at full size.</p></header><main>' + ''.join(sections) + '</main><footer>Before-files are preserved. This page is regenerated from those snapshots and the current working copy; it does not apply an edit. Capture scope is stated beside each image.</footer></html>'
    (HERE / 'index.html').write_text(page, encoding='utf-8')
    print(HERE / 'index.html')


if __name__ == '__main__':
    build()
