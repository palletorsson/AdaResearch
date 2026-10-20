"""Build this local review only; retain evidence without modifying canonical text."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, quote, unquote
import hashlib
import html
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MAP = ROOT / 'commons/maps/Random_Entropies'
EVIDENCE = ROOT / 'ada_run/encounter_pilot/Random_Entropies/doors-one-guess'
STYLE = '''
*{box-sizing:border-box}body{margin:0;color:#2e3434;background:#f4f1e9;font:17px/1.65 system-ui,sans-serif}main{max-width:1480px;margin:auto;padding:24px 32px 64px}header{max-width:1000px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.16}h1{font-size:clamp(36px,4vw,56px);margin:10px 0 14px}h2{font-size:32px}h3{font-size:20px}p{max-width:78ch}a{color:#6a456e;text-underline-offset:3px}nav{display:flex;flex-wrap:wrap;gap:10px 25px;font-size:15px;margin:18px 0 26px}.eyebrow{font-size:12px;letter-spacing:.09em;text-transform:uppercase;color:#5c6864}.pair{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:30px;align-items:start}article{min-width:0}figure{margin:0 0 14px}figure img{display:block;width:100%;height:auto;border:1px solid #cec8bc}figcaption{font-size:13px;color:#59635e;margin-top:5px}.card{border-top:3px solid #738e82;padding-top:12px}.card:nth-child(2){border-color:#aa7294}.card p{margin:10px 0}.small{font-size:14px}.note{padding:15px 22px;background:#ebe5ed;border-left:3px solid #aa7294;margin:26px 0}table{border-collapse:collapse;width:100%;font-size:15px;margin:18px 0}td,th{text-align:left;padding:9px;border-bottom:1px solid #c9c4b9;vertical-align:top}details{padding:14px 18px;background:#ece8dd;margin:22px 0}summary{font-weight:600;cursor:pointer}.prose{font:20px/1.78 Georgia,serif;max-width:66ch}.prose p{margin:0 0 1.2em}.prose .footnote{font:14px/1.6 system-ui,sans-serif;border-top:1px solid #ccc;padding-top:15px;margin-top:30px}.prose .footnote hr{display:none}.single{max-width:880px;margin:auto}.source{white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.6 ui-monospace,monospace}pre{overflow:auto;background:#e7e5de;padding:16px;font-size:14px}.tutorial h2,.notes h2{margin-top:32px}footer{margin-top:38px;border-top:1px solid #cbc6ba;padding-top:18px;font-size:14px;color:#59635e}li{margin-bottom:9px}sup{font:12px system-ui}@media(max-width:850px){main{padding:20px}.pair{grid-template-columns:1fr;gap:35px}.prose{font-size:19px}h2{font-size:28px}}@media print{nav,details{display:none}.pair{display:block}body{background:white}.prose{font-size:12pt;max-width:none}article{break-before:page}}
'''
NAV = '<nav aria-label="Review"><a href="index.html">The two encounters</a><a href="text.html">Chapter · before / after</a><a href="tutorial.html">Reconstruction tutorial</a><a href="notes.html">Evidence &amp; next test</a><a href="/long-museum/writing-wall?map=Random_Entropies">Writing wall</a></nav>'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def words(text):
    text = re.split(r'(?m)^\[\^[^\]]+\]:', text)[0]
    text = re.sub(r'<!--.*?-->', '', text, flags=re.S)
    text = re.sub(r'(?m)^#.*$|\[\^[^\]]+\]', '', text)
    return len(re.findall(r"\b[\w]+(?:['’-][\w]+)*\b", text))

def page(title, intro, body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>{html.escape(title)}</title><style>{STYLE}</style></head><body><main><header><div class="eyebrow">Ada Research · Entropy Types · 16 October 2026</div><h1>{html.escape(title)}</h1><p>{intro}</p></header>{NAV}{body}<footer>Native Godot views and source-checked text. The next evidence comes from the encounter: what changes, what remains, and what question follows?</footer></main></body></html>'

def render(text, source, prefix):
    def link(match):
        label, target = match.groups()
        parts = urlsplit(target)
        if parts.scheme or target.startswith(('/', '#')): return match.group(0)
        path = (source.parent / parts.path).resolve()
        planned = path.parent == HERE and path.name in ('index.html','text.html','tutorial.html','notes.html')
        assert path.is_relative_to(ROOT) and (path.exists() or planned), (source, target)
        if path.suffix == '.gd':
            out = 'source-' + path.stem + '.html'
            (HERE/out).write_text(page(path.name, 'Source retained with this review.', '<pre class="source">'+html.escape(path.read_text(encoding='utf-8'))+'</pre>'), encoding='utf-8')
            url = out
        else: url = '/book-review/' + quote(path.relative_to(ROOT).as_posix(), safe='/')
        if parts.fragment: url += '#' + parts.fragment
        return f'[{label}]({url})'
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link, text)
    rendered = markdown.markdown(text, extensions=['footnotes','tables','fenced_code'])
    rendered = rendered.replace('<h1>', '<h2>').replace('</h1>', '</h2>')
    return re.sub(r'((?:id|href)=")(#?)(fn[^" ]*)', lambda m: m[1]+m[2]+prefix+'-'+m[3], rendered)

def figure(file, caption):
    return f'<figure><a href="{file}"><img src="{file}" alt="{html.escape(caption, quote=True)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'

def build():
    (HERE/'hall').mkdir(exist_ok=True)
    for path in EVIDENCE.iterdir():
        if path.suffix in ('.png','.json','.log'): shutil.copy2(path,HERE/'hall'/path.name)
    reports = [json.loads((HERE/'report.json').read_text()), json.loads((HERE/'hall/report.json').read_text())]
    for report in reports:
        assert all(c['passed'] for c in report['checks']), 'Native verification has a failure.'
    counts = [len(r['checks']) for r in reports]
    current = (MAP/'final.md').read_text(encoding='utf-8')
    original = (HERE/'before/commons/maps/Random_Entropies/final.md').read_text(encoding='utf-8')
    count = words(current)
    assert count > 0, 'The chapter must contain prose.'
    if not 600 <= count <= 1500:
        print(f'Length review: {count} words. The 600–1,500 range is guidance; assess pacing, necessary explanation and transitions, not a hard cap.')
    wall = json.loads((MAP/'writing_wall.json').read_text(encoding='utf-8'))
    old_wall = json.loads((HERE/'before/commons/maps/Random_Entropies/writing_wall.json').read_text(encoding='utf-8'))
    anchors = re.findall(r'<!-- @([^\s>]+) -->', current)
    assert anchors == wall['order'] == old_wall['order']
    for magnet in wall['magnets']:
        old = next(m for m in old_wall['magnets'] if m['id']==magnet['id'])
        assert all(magnet.get(k)==old.get(k) for k in ('x','y','tags'))
    current_map = json.loads((MAP/'map_data.json').read_text(encoding='utf-8'))
    old_map = json.loads((HERE/'before/commons/maps/Random_Entropies/map_data.json').read_text(encoding='utf-8'))
    current_map['map_info']['description'] = old_map['map_info']['description']
    assert current_map == old_map, 'Unexpected room/placement change.'
    assert (ROOT/'commons/maps/Random_Entropy/final.md').read_bytes() == (HERE/'before/commons/maps/Random_Entropy/final.md').read_bytes()
    shutil.copy2(MAP/'final.md', HERE/'final.md')
    shutil.copy2(MAP/'tutorial.md', HERE/'tutorial.md')
    old_article = '<article class="card"><div class="eyebrow">Before · '+str(words(original))+' words</div><div class="prose">'+render(original,MAP/'final.md','before')+'</div></article>'
    new_article = '<article class="card"><div class="eyebrow">Revised · '+str(count)+' words</div><div class="prose">'+render(current,MAP/'final.md','after')+'</div></article>'
    (HERE/'text.html').write_text(page('What remains uncertain', 'The complete previous chapter and the revision. Doors and the final chair encounter change; the room order stays. The coffee transition remains a reading question.', '<div class="pair">'+old_article+new_article+'</div>'), encoding='utf-8')
    (HERE/'tutorial.html').write_text(page('Build the comparison', 'Small rules, declared observations, preserved states. Reconstruct a baseline before changing a condition.', '<div class="single tutorial">'+render((MAP/'tutorial.md').read_text(encoding='utf-8'),MAP/'tutorial.md','tutorial')+'</div>'), encoding='utf-8')
    (HERE/'notes.html').write_text(page('Evidence and the next question', 'Keep implementation checks separate from a reader or headset trial.', '<div class="single notes">'+render((HERE/'README.md').read_text(encoding='utf-8'),HERE/'README.md','notes')+'</div>'), encoding='utf-8')
    body = '<div class="pair"><article class="card"><h2>Two starts, two rules</h2>'+figure('hall/doors-in-hall.png','Installed in the hall. The centre passage stays open; histories sit below the two side pairs.')+'<p>Press <strong>STEP</strong> to advance both pairs. One halves its angles; the other doubles and wraps. <strong>GAP</strong> changes their starting difference. <strong>RESET</strong> begins again.</p><p>The default expanding pair meets again at step nine. What does its history retain that the current angles no longer show?</p></article><article class="card"><h2>One guess</h2>'+figure('hall/table-2.png','Table B in the hall: eight pink, four black, four black with arms. The best chance remains 50%.')+'<p>Choose a type, then <strong>DRAW</strong>. Compare two types with three: the best guess can stay the same while average uncertainty changes.</p><p><strong>CHANGE ONE</strong> alters the population. At the all-pink table, lift and turn the chairs. Their composition changes; the colour prediction remains certain.</p></article></div>'
    body += '<table><thead><tr><th>Table</th><th>Chair types</th><th>Best guess</th><th>Min-entropy</th><th>Shannon</th></tr></thead><tbody><tr><td>A</td><td>8 pink / 8 black</td><td>50%</td><td>1 bit</td><td>1 bit</td></tr><tr><td>B</td><td>8 pink / 4 black / 4 black with arms</td><td>50%</td><td>1 bit</td><td>1.5 bits</td></tr><tr><td>C</td><td>12 pink / 4 black</td><td>75%</td><td>0.415 bits</td><td>0.811 bits</td></tr><tr><td>D</td><td>16 pink · movable</td><td>100%</td><td>0 bits</td><td>0 bits</td></tr></tbody></table><p class="small">Each table selects one of sixteen chair IDs with replacement. These category readings assume that draw model. The seed-435 implementation is reproducible; knowing its state can reveal the next ID.</p>'
    body += '<div class="note"><strong>The reading question remains open.</strong><p>The close reading wanted to stay at the doors before moving to coffee. These controls make that longer investigation possible. Does the next encounter now follow from it, or does coffee still arrive too soon?</p><a href="text.html">Read the full chapter before and after →</a></div>'
    body += '<details><summary>Closer views of histories, controls and the movable ending</summary><div class="pair">'+figure('door-control.png','Shared door controls in the native standalone test.')+figure('door-history.png','LOW/HIGH histories in the native standalone test.')+figure('certain-chairs-moved.png','The all-pink table after chairs have been moved and turned.')+figure('hall/chairs-in-hall.png','The four chair tables occupy the existing final encounter in Entropy Types.')+'</div></details>'
    body += f'<p><strong>{counts[0]} focused checks + {counts[1]} installed-hall checks pass.</strong> Headset reach, independent reconstruction and the effect of the revised writing still need a person.</p><p class="small">Reload Entropy Types in the desktop/VR museum to load the new scenes. It remains immediately after Random Definition. <a href="tutorial.html">Reconstruction tutorial</a> · <a href="notes.html">Evidence and limits</a> · <a href="../2026-10-16-entropy-two-voices/index.html">Previous two-chapter edition</a></p>'
    (HERE/'index.html').write_text(page('Two starts. One guess.', 'Two revised encounters in Entropy Types: follow a difference through time, then test what the best possible guess can tell us.',body), encoding='utf-8')
    files = list((ROOT/'commons/artifacts/ordinary_entropies').glob('*.gd')) + list((ROOT/'commons/artifacts/ordinary_entropies').glob('*.tscn')) + [MAP/n for n in ['final.md','tutorial.md','plan.md','writing_wall.json','map_data.json']] + [ROOT/'commons/artifacts/registry/ordinary_entropies.json']
    report = {'date':'2026-10-16','focused_checks':counts[0],'installed_checks':counts[1],'final_words':count,'original_words':words(original),'room_final_order':anchors,'placements_and_tags_unchanged':True,'workshop_final_unchanged':True,'human_headset_trial':False,'independent_learner_trial':False,'source_sha256':{p.relative_to(ROOT).as_posix():sha(p) for p in files}}
    (HERE/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    class Links(HTMLParser):
        def __init__(self):super().__init__();self.links=[];self.ids=[]
        def handle_starttag(self,tag,attrs):
            a=dict(attrs)
            if 'id' in a:self.ids.append(a['id'])
            for key in ('href','src'):
                if key in a:self.links.append(a[key])
    for p in HERE.glob('*.html'):
        parser=Links();parser.feed(p.read_text(encoding='utf-8'))
        assert len(parser.ids)==len(set(parser.ids)),p
        for target in parser.links:
            url=urlsplit(target)
            if url.scheme:continue
            if not url.path:
                assert not url.fragment or url.fragment in parser.ids,(p,target)
            elif url.path.startswith('/book-review/'):
                assert (ROOT/unquote(url.path.removeprefix('/book-review/'))).exists(),(p,target)
            elif not url.path.startswith('/'):
                assert (p.parent/unquote(url.path)).exists(),(p,target)
    print(json.dumps({k:v for k,v in report.items() if k!='source_sha256'},indent=2))

if __name__ == '__main__': build()
