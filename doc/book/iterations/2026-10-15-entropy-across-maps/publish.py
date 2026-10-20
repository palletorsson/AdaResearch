"""Render canonical research documents as inert, linked review pages."""
from pathlib import Path
import hashlib
import html
import json
import re
from urllib.parse import urlsplit
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
RESEARCH = ROOT / 'doc/book/research/entropy'
PAGES = {
    RESEARCH / 'README.md': 'framework.html',
    RESEARCH / 'observation-card.md': 'observation-card.html',
    RESEARCH / 'cross-map-plan.md': 'plan.html',
    RESEARCH / 'cards/prefab-disorder.md': 'prefab-card.html',
    RESEARCH / 'cards/seed-record.md': 'seed-card.html',
    ROOT / 'doc/book/course/text-plans/Random_Entropy/research-brief.md': 'hall-plan.html',
    ROOT / 'doc/VR_VR_PT_2023.md': 'proposal-2023.html',
    HERE / 'README.md': 'receipt.html',
    HERE / 'supplied-proposal.md': 'proposal.html',
}
PAGES = {p.resolve(): name for p, name in PAGES.items()}
RAW_VIEWS = {(HERE / 'verify.py').resolve(): 'verify.py.txt'}
STYLE = '''body{margin:0;background:#f2f0e9;color:#20363b;font:18px/1.7 system-ui}main{max-width:1080px;margin:auto;padding:32px}a{color:#006d74}nav{display:flex;gap:22px;flex-wrap:wrap;font-size:14px;margin-bottom:32px}h1{font-size:38px;line-height:1.2}h2{margin-top:42px;font-size:26px}h3{font-size:22px}table{border-collapse:collapse;width:100%;font-size:15px;line-height:1.55}th,td{text-align:left;vertical-align:top;border-bottom:1px solid #b6c9c7;padding:14px 10px}th{background:#e2e7df}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#e6e8df;padding:18px}code{font-size:.88em}li{margin:10px 0}img{max-width:100%}.source{font-size:13px;color:#53666a;overflow-wrap:anywhere}blockquote{border-left:3px solid #45868a;margin-left:0;padding-left:20px}@media(max-width:700px){main{padding:18px}table{display:block;overflow-x:auto}h1{font-size:29px}}'''

def rewrite(markup, source):
    def replace(match):
        address = html.unescape(match.group(1))
        split = urlsplit(address)
        if split.scheme or address.startswith(('/', '#')):
            return match.group(0)
        target = (source.parent / split.path).resolve()
        suffix = '#' + split.fragment if split.fragment else ''
        if target in RAW_VIEWS:
            dest = RAW_VIEWS[target] + suffix
        elif target in PAGES:
            dest = PAGES[target] + suffix
        else:
            relative = target.relative_to(ROOT).as_posix()
            dest = '/book-review/' + relative + suffix
        return 'href="' + html.escape(dest, quote=True) + '"'
    return re.sub(r'href="([^"]+)"', replace, markup)

manifest = {}
for source, name in RAW_VIEWS.items():
    (HERE / name).write_bytes(source.read_bytes())
for source, name in PAGES.items():
    raw = source.read_text(encoding='utf-8-sig')
    body = rewrite(markdown.markdown(raw, extensions=['tables', 'fenced_code']), source)
    title = raw.splitlines()[0].lstrip('# ')
    relative = source.relative_to(ROOT).as_posix()
    sha = hashlib.sha256(source.read_bytes()).hexdigest()
    page = '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
    page += '<title>' + html.escape(title) + '</title><style>' + STYLE + '</style><main>'
    page += '<nav><a href="index.html">Overview</a><a href="framework.html">Framework</a><a href="plan.html">Map and task plan</a><a href="observation-card.html">Observation card</a></nav>'
    page += body + '<p class="source">Review copy of ' + html.escape(relative) + '<br>SHA-256 ' + sha + '</p></main></html>'
    (HERE / name).write_text(page, encoding='utf8')
    manifest[relative] = {'view': name, 'sha256': sha}

index = HERE / 'index.html'
raw = index.read_text(encoding='utf8')
raw = rewrite(raw, index)
index.write_text(raw, encoding='utf8')
(HERE / 'reading-manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf8')
print(f'Rendered {len(PAGES)} linked reading pages; canonical source hashes retained.')
