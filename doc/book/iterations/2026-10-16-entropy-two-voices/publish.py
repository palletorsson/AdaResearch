"""Render the retained editorial edition, without changing maps or canonical prose."""
from pathlib import Path
from urllib.parse import urlsplit, urlunsplit, quote
from html.parser import HTMLParser
import hashlib
import html
import json
import math
import re
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PREFIX = '/book-review/' + HERE.relative_to(ROOT).as_posix() + '/'
NAMES = ['Random_Entropies', 'Random_Entropy']
LABELS = ['Entropy Types', 'Entropy Workshop']
STYLE = '''
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f4f1e9;color:#292e2b;font:17px/1.6 system-ui,sans-serif}main{max-width:1480px;margin:auto;padding:24px 32px 70px}header{margin-bottom:26px}header h1{font:clamp(30px,3.1vw,45px)/1.12 Georgia,serif;margin:8px 0 12px}header p{max-width:86ch;margin:8px 0}.eyebrow{font:13px/1.6 system-ui,sans-serif;letter-spacing:.065em;text-transform:uppercase;color:#536252}a{color:#56517a;text-underline-offset:3px}nav{display:flex;gap:12px 23px;flex-wrap:wrap;font-size:15px;margin:18px 0}nav a{padding:3px 0}.pair{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:38px;align-items:start}article{min-width:0;border-top:3px solid #6d826c;padding-top:15px}article:nth-child(2){border-color:#917a9d}article h2{font:34px/1.15 Georgia,serif;max-width:24ch;margin:8px 0 22px}.prose{font:20px/1.75 Georgia,serif;max-width:64ch}.prose p{margin:0 0 1.15em}.prose .footnote{border-top:1px solid #ccc5b8;margin-top:35px;padding-top:10px;font:15px/1.6 system-ui,sans-serif}.footnote p{margin-bottom:12px}.footnote li{margin-bottom:18px}.footnote hr{display:none}sup{font:12px system-ui,sans-serif}.single{max-width:760px;margin:auto}.encounter{height:0;scroll-margin-top:24px}.encounter:not(:first-child){margin-top:32px}.tools{font:14px/1.6 system-ui,sans-serif;margin-bottom:18px}.tools a{margin-right:15px}details{margin:20px 0;background:#ebe7dc;padding:12px 16px}summary{cursor:pointer;font-size:15px;font-weight:600}.route{font-size:15px;max-width:90ch}.source{white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.6 ui-monospace,monospace;background:#fcfaf5;padding:22px}.notes{max-width:900px}.notes table{border-collapse:collapse;width:100%;font-size:15px}.notes th,.notes td{text-align:left;vertical-align:top;border-bottom:1px solid #ccc5b8;padding:10px}.notes h2{margin-top:35px;font:28px Georgia,serif}.notes li{margin-bottom:10px}.note{border-left:3px solid #917a9d;padding:12px 18px;background:#eee7ef}footer{border-top:1px solid #cbc5b9;margin-top:38px;padding-top:20px;font-size:15px;color:#596158}@media(max-width:900px){main{padding:20px}.pair{grid-template-columns:1fr;gap:45px}.prose{max-width:66ch}article h2{font-size:31px}}@media print{nav,.tools,details{display:none}body{background:white}.pair{display:block}article{page-break-before:always}.prose{font-size:12pt;max-width:none}article h2{font-size:23pt}main{padding:0}}
'''
NAV = '''<nav aria-label="Readings"><a href="index.html">Two revised chapters</a><a href="types-compare.html">Types: before / after</a><a href="workshop-compare.html">Workshop: before / after</a><a href="reference.html">Random Definition reference</a><a href="notes.html">Revision notes</a></nav>'''

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def words(text):
    text = re.split(r'(?m)^\[\^[^\]]+\]:', text)[0]
    text = re.sub(r'<!--.*?-->', '', text, flags=re.S)
    text = re.sub(r'(?m)^#.*$', '', text)
    text = re.sub(r'\[\^[^\]]+\]', '', text)
    return len(re.findall(r"\b[\w]+(?:['’-][\w]+)*\b", text))

def page(title, intro, body):
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)}</title><style>{STYLE}</style></head><body><main><header><div class="eyebrow">Ada Research · 16 October 2026 · reading edition</div><h1>{html.escape(title)}</h1><p>{intro}</p>{NAV}</header>{body}<footer>Read against the room: stop at the first transition where the next encounter feels unnecessary. An accurate description is not yet evidence of an effective encounter.</footer></main></body></html>'''

def render(text, source, id_prefix):
    # Relative references belong to the original chapter directory, not this review.
    def link(match):
        label, target = match.groups()
        parts = urlsplit(target)
        if parts.scheme or target.startswith(('/', '#')):
            return match.group(0)
        path = (source.parent / parts.path).resolve()
        assert path.is_relative_to(ROOT), target
        assert path.exists(), (source, target)
        if path.suffix == '.gd':
            out = 'source-' + path.stem + '.html'
            body = '<pre class="source">' + html.escape(path.read_text(encoding='utf-8-sig')) + '</pre>'
            (HERE / out).write_text(page(path.name, 'Source retained with this reading edition.', body), encoding='utf-8')
            url = out
        else:
            url = '/book-review/' + quote(path.relative_to(ROOT).as_posix(), safe='/')
        if parts.fragment:
            url += '#' + parts.fragment
        return f'[{label}]({url})'
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link, text)
    text = re.sub(r'<!-- @([^\s>]+) -->', lambda m: f'<div class="encounter" id="{id_prefix}-{html.escape(m[1], quote=True)}"></div>', text)
    rendered = markdown.markdown(text, extensions=['footnotes', 'tables'])
    rendered = rendered.replace('<h1>', '<h2>').replace('</h1>', '</h2>')
    # Each column has independently named footnote targets.
    rendered = re.sub(r'((?:id|href)=")(#?)(fn[^" ]*)', lambda m: m[1] + m[2] + id_prefix + '-' + m[3], rendered)
    return rendered

def article(text, source, label, id_prefix, tools=''):
    return f'<article><div class="eyebrow">{html.escape(label)} · {words(text):,} words</div>{tools}<div class="prose">{render(text, source, id_prefix)}</div></article>'

def build():
    report = {'date': '2026-10-16', 'kind': 'editorial-source-audit', 'maps': {}, 'sources': {}, 'new_runtime_test': False, 'human_reading_result': None}
    install = json.loads((HERE / 'installation.json').read_text(encoding='utf-8'))
    revised, originals = {}, {}
    for name in NAMES:
        directory = ROOT / 'commons/maps' / name
        revised[name] = (HERE / f'{name}-final.md').read_text(encoding='utf-8')
        originals[name] = (HERE / 'before' / name / 'final.md').read_text(encoding='utf-8')
        assert (directory / 'final.md').read_bytes() == (HERE / f'{name}-final.md').read_bytes(), 'Canonical final differs from this edition.'
        wall = json.loads((directory / 'writing_wall.json').read_text(encoding='utf-8'))
        wall_before = json.loads((HERE / 'before' / name / 'writing_wall-at-install.json').read_text(encoding='utf-8'))
        anchors = re.findall(r'<!-- @([^\s>]+) -->', revised[name])
        by_id = {m['id']: m for m in wall['magnets']}
        expected = [artifact for artifact in wall['order'] if 'final' in by_id[artifact].get('tags', [])]
        assert anchors == expected, (name, anchors, expected)
        map_text = (directory / 'map_data.json').read_text(encoding='utf-8')
        assert all(artifact in map_text for artifact in anchors)
        for magnet in wall['magnets']:
            previous = next(m for m in wall_before['magnets'] if m['id'] == magnet['id'])
            assert {k:v for k,v in magnet.items() if k!='final'} == {k:v for k,v in previous.items() if k!='final'}
        assert {k:v for k,v in wall.items() if k!='magnets'} == {k:v for k,v in wall_before.items() if k!='magnets'}
        assert sha(directory / 'map_data.json') == install['maps'][name]['map_sha256']
        assert sha(directory / 'tutorial.md') == install['maps'][name]['tutorial_sha256']
        count = words(revised[name])
        assert 600 <= count <= 1500
        report['maps'][name] = {'words': count, 'original_words': words(originals[name]), 'final_sha256': sha(directory/'final.md'), 'anchors_in_wall_order': anchors, 'anchors_placed': True, 'map_unchanged': True, 'tutorial_unchanged': True, 'wall_changed_only_final_notes': True}

    # Arithmetic cross-checks for the examples in the prose; not scene tests.
    report['arithmetic'] = {'chair_ways': math.comb(4,2)**2, 'chair_log_ways': math.log(36), 'bench_ways': math.comb(8,4)**2, 'bench_log_ways': math.log(4900), 'min_entropy_bits': [-math.log2(p) for p in [.5,.75,1]], 'frost_remaining_bits': [math.log2(n) for n in [1,2,4,4,8]]}
    assert report['arithmetic']['chair_ways'] == 36 and report['arithmetic']['bench_ways'] == 4900
    sources = [
        'commons/artifacts/ordinary_entropies/comparison.gd', 'commons/artifacts/ordinary_entropies/model.gd',
        'commons/artifacts/ordinary_entropies/best_guess.gd', 'commons/artifacts/ordinary_entropies/jar_states.gd',
        'commons/artifacts/ordinary_entropies/column_mixing.gd', 'commons/artifacts/ordinary_entropies/jar_column.gd',
        'commons/artifacts/shannon_entropy_meter/shannon_entropy_meter.gd',
        'algorithms/randomness/entropy_jar/entropy_jar.gd',
        'commons/artifacts/entropy_sorting_table/sorting_model.gd',
        'commons/artifacts/entropy_compartments/compartment_model.gd', 'commons/artifacts/entropy_compartments/entropy_compartments.gd',
        'algorithms/randomness/entropy_axiom/entropy_axiom_multimesh.gd',
        'commons/artifacts/randomness_space/entropy_ruin_physics.gd', 'commons/artifacts/signal_room/signal_room.gd',
        'commons/artifacts/registry/ordinary_entropies.json', 'commons/maps/sequences/randomness.json',
    ]
    report['sources'] = {path:sha(ROOT/path) for path in sources}
    report['external_sources'] = ['https://arxiv.org/abs/2002.07674', 'https://csrc.nist.gov/glossary/term/min_entropy']
    report['limits'] = ['Source and numerical review, not a new Godot run.', 'No visitor or headset result.', 'Entropy Types generated plan contains older positions for three support placements; this prose pass uses the authored map and changes no geometry.']
    (HERE/'verification.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')

    articles = []
    for i,name in enumerate(NAMES):
        slug = 'types' if i == 0 else 'workshop'
        source = ROOT/'commons/maps'/name/'final.md'
        controls = f'<div class="tools"><a href="{slug}.html">Read this chapter alone</a><a href="/long-museum/writing-wall?map={name}">Writing wall</a></div>'
        art = article(revised[name], source, LABELS[i], slug, controls)
        articles.append(art)
        (HERE/f'{slug}.html').write_text(page(LABELS[i], 'Revised final · room order retained.', '<div class="single">'+art+'</div>'), encoding='utf-8')
        pair = '<div class="pair">' + article(originals[name], source, 'Before · retained original', slug+'-before') + article(revised[name], source, 'After · revised final', slug+'-after') + '</div>'
        (HERE/f'{slug}-compare.html').write_text(page(LABELS[i]+' · before and after', 'The complete previous chapter and the complete revision. Read either column continuously; paragraph lengths and pacing have changed.', pair), encoding='utf-8')
    intro = 'Two complete final chapters in the situated “we” voice developed for Random Definition. Each follows its room; the first chapter’s last comparison becomes an action at the next entrance.'
    route = '<details><summary>Room order and the connection between chapters</summary><p class="route"><strong>Types:</strong> colour → arrangements → descriptions → doors → cups → glass → best guess.</p><p class="route"><strong>Workshop:</strong> ledger → four jars → hand jar → four cubes → compartments → points → ruin → signal room. Hybrids and hardware remain optional.</p><p class="route">The all-pink tray can be rearranged without changing the colour answer. In the next hall, SORT changes neighbours while the colour reading stays still.</p></details>'
    (HERE/'index.html').write_text(page('Two ways through entropy', intro, route+'<div class="pair">'+''.join(articles)+'</div>'), encoding='utf-8')
    reference = (HERE/'random-definition-reference.md').read_text(encoding='utf-8')
    (HERE/'reference.html').write_text(page('The reference voice', 'Random Definition, retained as it stood when this revision began.', '<div class="single">'+article(reference, ROOT/'commons/maps/Random_Definition/final.md','Reference · unchanged','reference')+'</div>'), encoding='utf-8')
    notes = (HERE/'README.md').read_text(encoding='utf-8')
    (HERE/'notes.html').write_text(page('What changed, and what remains to test', 'Editorial record · 16 October 2026.', '<div class="notes">'+markdown.markdown(notes,extensions=['tables'])+'</div>'), encoding='utf-8')
    # Check generated local links and footnotes without claiming browser validation.
    class Links(HTMLParser):
        def __init__(self):
            super().__init__();self.links=[];self.ids=[]
        def handle_starttag(self, tag, attrs):
            attrs=dict(attrs)
            if 'id' in attrs:self.ids.append(attrs['id'])
            if tag=='a' and 'href' in attrs:self.links.append(attrs['href'])
    for file in HERE.glob('*.html'):
        parsed=Links();parsed.feed(file.read_text(encoding='utf-8'))
        assert len(parsed.ids)==len(set(parsed.ids)), f'duplicate ID in {file.name}'
        for link in parsed.links:
            if link.startswith('#'):assert link[1:] in parsed.ids, (file.name,link)
            elif not link.startswith(('/', 'http:', 'https:')):assert (HERE/urlsplit(link).path).exists(),(file.name,link)
    print(json.dumps({name:report['maps'][name]['words'] for name in NAMES},ensure_ascii=False))
    print('Rendered paired chapters, full before/after pages, reference, notes and source audit; local links and IDs valid.')

if __name__ == '__main__':
    build()
