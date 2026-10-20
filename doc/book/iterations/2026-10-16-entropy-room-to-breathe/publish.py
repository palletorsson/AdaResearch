"""Publish a frozen editorial comparison and audit its relation to the installed room."""
from pathlib import Path
from urllib.parse import urlsplit, quote, unquote
from html.parser import HTMLParser
import hashlib
import html
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
NAMES = ['Random_Entropies', 'Random_Entropy']
LABELS = ['Entropy Types', 'Entropy Workshop']
SLUGS = ['types', 'workshop']
TITLES = ['What remains uncertain', 'What the gauge forgets']
STYLE = '''
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f4f1e9;color:#292e2b;font:17px/1.6 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:22px 36px 65px}header h1{font:clamp(30px,3.5vw,46px)/1.12 Georgia,serif;margin:9px 0 14px}header p{max-width:90ch;margin:8px 0}.eyebrow{font:13px/1.5 system-ui,sans-serif;letter-spacing:.06em;text-transform:uppercase;color:#576454}a{color:#56517a;text-underline-offset:3px}nav{display:flex;gap:12px 24px;flex-wrap:wrap;font-size:15px;margin:19px 0 24px}.pair{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:42px;align-items:start}article{min-width:0;border-top:3px solid #74876b;padding-top:15px}article:nth-child(2){border-color:#9973a3}article h2{font:32px/1.2 Georgia,serif;margin:10px 0 25px}.prose{font:20px/1.75 Georgia,serif;max-width:65ch}.prose p{margin:0 0 1.15em}.prose .footnote{border-top:1px solid #c6c0b4;margin-top:35px;padding-top:10px;font:15px/1.65 system-ui,sans-serif}.footnote hr{display:none}.footnote li{margin-bottom:20px}sup{font:12px system-ui,sans-serif}.encounter{scroll-margin-top:22px}.encounter:not(:first-child){margin-top:36px}.single{max-width:790px;margin:auto}.note{border-left:3px solid #9973a3;background:#ece6ec;padding:16px 22px;margin:22px 0}details{background:#ece8de;padding:12px 18px;margin:18px 0}summary{cursor:pointer;font-weight:600}.route{font:14px/1.7 system-ui,sans-serif}.route a{display:inline-block;margin-right:14px}.cards{margin:28px 0}.cards article{background:#fcfaf6;padding:24px}.cards article p{max-width:62ch}.button{display:inline-block;border:1px solid #79718c;padding:8px 14px;border-radius:3px;margin:4px 10px 4px 0;text-decoration:none}.button:hover{background:#e7ddec}figure{margin:24px 0}figure img{width:100%;height:auto;display:block}figcaption{font:14px/1.6 system-ui,sans-serif;color:#56605a;padding-top:9px}.notes h2{font:28px Georgia,serif;margin-top:32px}.notes li{margin-bottom:12px}.source{white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.6 ui-monospace,monospace;background:#fcfaf5;padding:22px}footer{margin-top:44px;border-top:1px solid #cbc3b5;padding-top:18px;font-size:14px;color:#596158}@media(max-width:900px){main{padding:20px}.pair{grid-template-columns:1fr;gap:38px}.prose{max-width:none}article h2{font-size:29px}}@media print{nav,details,.button{display:none}body{background:white}.pair{display:block}article{break-before:page}.prose{font-size:12pt}main{padding:0}}
'''
NAV = '<nav aria-label="Reading editions"><a href="index.html">Overview</a><a href="types-compare.html">Types: before / after</a><a href="workshop-compare.html">Workshop: before / after</a><a href="revised.html">Both revised chapters</a><a href="notes.html">Changes and evidence</a></nav>'

def read(path): return path.read_text(encoding='utf-8')
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def write(name, value): (HERE/name).write_text(value, encoding='utf-8')

def words(value):
    value = re.split(r'(?m)^\[\^[^\]]+\]:', value)[0]
    value = re.sub(r'<!--.*?-->|\[\^[^\]]+\]', '', value, flags=re.S)
    value = re.sub(r'(?m)^#.*$', '', value)
    return len(re.findall(r"\b\w+(?:['’-]\w+)*\b", value))

def page(title, intro, body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{STYLE}</style></head><body><main><header><div class="eyebrow">Ada Research · 16 October 2026 · retained reading edition</div><h1>{html.escape(title)}</h1><p>{intro}</p>{NAV}</header>{body}<footer>The room order stays. Whether the next encounter feels necessary remains a reading question.</footer></main></body></html>'

source_paths = set()
def render(value, source, prefix):
    def link(match):
        label, target = match.groups()
        parts = urlsplit(target)
        if parts.scheme or target.startswith(('/', '#')): return match[0]
        path = (source.parent/parts.path).resolve()
        assert path.is_relative_to(ROOT) and path.exists(), (source, target)
        if path.suffix == '.gd':
            source_paths.add(path)
            out = 'source-'+path.stem+'.html'
            write(out, page(path.name, 'Source retained with this reading edition.', '<pre class="source">'+html.escape(read(path))+'</pre>'))
            url = out
        else: url = '/book-review/'+quote(path.relative_to(ROOT).as_posix(), safe='/')
        if parts.fragment: url += '#'+parts.fragment
        return f'[{label}]({url})'
    value = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link, value)
    value = re.sub(r'<!-- @([^\s>]+) -->', lambda m: f'<div class="encounter" id="{prefix}-{m[1]}"></div>', value)
    result = markdown.markdown(value, extensions=['footnotes', 'tables']).replace('<h1>', '<h2>').replace('</h1>', '</h2>')
    return re.sub(r'((?:id|href)=")(#?)(fn[^" ]*)', lambda m: m[1]+m[2]+prefix+'-'+m[3], result)

def article(value, source, label, prefix):
    return f'<article><div class="eyebrow">{label} · {words(value):,} words</div><div class="prose">{render(value, source, prefix)}</div></article>'

def figure(name, caption): return f'<figure><img src="{name}" alt="{html.escape(caption, quote=True)}"><figcaption>{caption}</figcaption></figure>'

report = {'date': '2026-10-16', 'maps': {}, 'human_reading': None, 'headset_trial': False}
before, revised = {}, {}
for name, label, slug, title in zip(NAMES, LABELS, SLUGS, TITLES):
    folder = ROOT/'commons/maps'/name
    old_folder = HERE/'before/commons/maps'/name
    before[name] = read(old_folder/'final.md')
    revised[name] = read(HERE/f'{name}-final.md')
    assert revised[name] == read(folder/'final.md')
    wall = json.loads(read(folder/'writing_wall.json'))
    old_wall = json.loads(read(old_folder/'writing_wall.json'))
    ids = {m['id'] for m in wall['magnets'] if 'final' in m.get('tags', [])}
    order = [token for token in wall['order'] if token in ids]
    anchors = re.findall(r'<!-- @([^\s>]+) -->', revised[name])
    assert anchors == order
    for a, b in zip(wall['magnets'], old_wall['magnets']):
        assert {k:v for k,v in a.items() if k!='final'} == {k:v for k,v in b.items() if k!='final'}
    assert {k:v for k,v in wall.items() if k!='magnets'} == {k:v for k,v in old_wall.items() if k!='magnets'}
    current_map = json.loads(read(folder/'map_data.json'))
    old_map = json.loads(read(old_folder/'map_data.json'))
    assert current_map['layers']['interactables'] == old_map['layers']['interactables']
    assert current_map['layers']['utilities'] == old_map['layers']['utilities']
    changes = [(x,z,a,b) for z,(ra,rb) in enumerate(zip(old_map['layers']['structure'],current_map['layers']['structure'])) for x,(a,b) in enumerate(zip(ra,rb)) if a!=b]
    assert changes == ([(9,3,'p:1','1')] if name=='Random_Entropies' else [])
    positions = {token.split(':')[0]:(x,z) for z,row in enumerate(current_map['layers']['interactables']) for x,token in enumerate(row) if token.strip()}
    assert all(token in positions for token in order)
    assert [positions[t][1] for t in order] == sorted(positions[t][1] for t in order)
    report['maps'][name] = {'before_words':words(before[name]), 'revised_words':words(revised[name]), 'final_order':order, 'placements_unchanged':True, 'magnet_layout_and_tags_unchanged':True, 'structure_edits':changes}
    route = '<details><summary>Jump to an encounter in the revision</summary><div class="route">'+''.join(f'<a href="#after-{token}">{i+1}. {html.escape(next(m["brief"] for m in wall["magnets"] if m["id"]==token))}</a>' for i,token in enumerate(order))+'</div></details>'
    body = route+'<div class="pair">'+article(before[name],folder/'final.md','Current before this revision','before')+article(revised[name],folder/'final.md','Revised · adopted final','after')+'</div>'
    write(slug+'-compare.html', page(label+' — before and after', 'Complete chapters, with the same encounter order. The left column preserves the text immediately before this pass; the right is now the canonical final.md.', body))
    write(slug+'-revised.html', page(title, label+' · the complete revised chapter.', '<div class="single">'+article(revised[name],folder/'final.md','Revised','single')+'</div>'))

native = ROOT/'ada_run/encounter_pilot/Random_Entropies/entropy-floor-chair'
native_report = json.loads(read(native/'report.json'))
assert native_report['passed'] and not native_report['failures']
report['native_checks'] = len(native_report['checks'])
for name in ['report.json', 'source_manifest.json', 'chair-on-floor.png', 'chairs-at-floor-level.png']:
    assert (native/name).exists(), name
    shutil.copy2(native/name, HERE/name)

write('revised.html', page('Two ways through entropy', 'Both new chapters, in their consecutive hall order. Use the comparison pages to read each beside its previous version.', '<div class="pair">'+''.join(article(revised[name],ROOT/'commons/maps'/name/'final.md',label,slug) for name,label,slug in zip(NAMES,LABELS,SLUGS))+'</div>'))
write('notes.html', page('Changes and evidence', 'Editorial revisions, a floor-level chair and the next reading test.', '<div class="single notes">'+render(read(HERE/'README.md'),HERE/'README.md','notes')+'</div>'))

cards = '<div class="pair cards">'
for name,label,slug,title in zip(NAMES,LABELS,SLUGS,TITLES):
    sizes = report['maps'][name]
    reason = ('RESET supplies a beginning. Coffee asks what returning would require once heat has passed elsewhere.' if slug=='types' else 'The cabinet preserves positions. The point enclosure asks how a moving viewpoint changes the relations we can see.')
    cards += f'<article><div class="eyebrow">{label} · {len(sizes["final_order"])} encounters</div><h2>{title}</h2><p>{reason}</p><p>{sizes["before_words"]:,} → <strong>{sizes["revised_words"]:,} words</strong>, excluding notes.</p><a class="button" href="{slug}-compare.html">Read before / after</a><a href="{slug}-revised.html">Read the revision alone</a></article>'
cards += '</div>'
body = cards+'<div class="note"><strong>More time with each object.</strong><p>The definitions stay close to what we see, do and record. The room and final keep the same order; optional encounters remain optional. Extra length is used for observation and transitions, rather than a new quota.</p></div>'
body += '<div class="pair"><section><h2>The chair shares our floor</h2>'+figure('chair-on-floor.png','Native museum view: the full-size entrance chair now stands clear on the visitor floor, in front of its wall label.')+'</section><section><h2>Approach, without climbing</h2>'+figure('chairs-at-floor-level.png','The full-size comparison chairs remain on the floor. The final sixteen-chair guessing studies retain their separate miniature tabletop scale.')+'</section></div>'
body += f'<p><strong>{report["native_checks"]} native floor and geometry checks pass.</strong> Both finals match the tagged writing-wall order. Headset comfort and the effect of the new transitions still need a human reading.</p><p><a href="notes.html">Read the changes, evidence and next test →</a></p>'
write('index.html', page('Room to breathe', 'Two revised entropy chapters, each preserved beside the current text. More space for the encounters, and a clearer passage from doors to coffee.', body))

# Retain active sources without turning the old review into a new edition.
source_paths.update((ROOT/'commons/artifacts/ordinary_entropies').glob('*.gd'))
for folder in ['entropy_compartments', 'entropy_sorting_table', 'shannon_entropy_meter', 'signal_room']:
    source_paths.update((ROOT/'commons/artifacts'/folder).glob('*.gd'))
for rel in ['algorithms/randomness/entropy_axiom/entropy_axiom_multimesh.gd', 'algorithms/randomness/entropy_jar/entropy_jar.gd', 'commons/artifacts/randomness_space/entropy_ruin.gd', 'commons/artifacts/registry/ordinary_entropies.json']:
    p = ROOT/rel
    assert p.exists(), rel
    source_paths.add(p)
for name in NAMES:
    source_paths.update((ROOT/'commons/maps'/name/file) for file in ['final.md','tutorial.md','plan.md','writing_wall.json','map_data.json'])
report['source_sha256'] = {}
for path in sorted(source_paths):
    relative = path.relative_to(ROOT)
    target = HERE/'after'/relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, target)
    report['source_sha256'][relative.as_posix()] = sha(path)

class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links=[]; self.ids=[]
    def handle_starttag(self, tag, attrs):
        a=dict(attrs)
        if 'id' in a: self.ids.append(a['id'])
        if tag=='a' and 'href' in a: self.links.append(a['href'])
        if tag=='img': self.links.append(a['src'])

for path in HERE.glob('*.html'):
    parsed=Links();parsed.feed(read(path))
    assert len(parsed.ids)==len(set(parsed.ids)), path.name
    for link in parsed.links:
        parts=urlsplit(link)
        if parts.scheme: continue
        if link.startswith('#'): assert parts.fragment in parsed.ids, (path,link)
        elif link.startswith('/book-review/'): assert (ROOT/unquote(parts.path.removeprefix('/book-review/'))).exists(), (path,link)
        elif not link.startswith('/'): assert (path.parent/unquote(parts.path)).exists(), (path,link)
report['html_links_and_ids_valid'] = True
write('verification.json', json.dumps(report, ensure_ascii=False, indent=2)+'\n')
print(json.dumps({'words': {k:[v['before_words'],v['revised_words']] for k,v in report['maps'].items()}, 'native_checks':report['native_checks'], 'links_valid':True}, ensure_ascii=False))
