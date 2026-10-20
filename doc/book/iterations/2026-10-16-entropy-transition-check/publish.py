"""Retain current texts and native visual evidence; publish an editorial test, not a new final."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit
import hashlib
import html
import json
import re
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
PREVIOUS = HERE.parent/'2026-10-16-entropy-room-to-breathe'
STYLE = '''*{box-sizing:border-box}body{margin:0;background:#f4f1e9;color:#292e2b;font:17px/1.65 system-ui,sans-serif}main{max-width:1350px;margin:auto;padding:26px 36px 65px}h1{font:clamp(32px,3.5vw,46px)/1.15 Georgia,serif;margin:10px 0 18px}h2{font:29px/1.3 Georgia,serif;margin-top:35px}h3{font:23px/1.3 Georgia,serif}.eyebrow{font-size:13px;text-transform:uppercase;letter-spacing:.055em;color:#576454}a{color:#56517a;text-underline-offset:3px}nav{display:flex;gap:12px 24px;flex-wrap:wrap;font-size:15px;margin:22px 0 30px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:26px}.card{border-top:3px solid #74876b;padding:18px 22px;background:#fcfaf6}.card:nth-child(2){border-color:#9973a3}.card h2{margin-top:5px}.reading{max-width:960px;margin:auto}.reading p,.reading li{max-width:80ch}.reading blockquote{font:22px/1.7 Georgia,serif;border-left:3px solid #9973a3;margin:24px 0;padding:0 24px}.reading h1{font-size:38px}table{border-collapse:collapse;width:100%;font-size:15px;margin:25px 0}th,td{vertical-align:top;text-align:left;border-bottom:1px solid #cac3b7;padding:11px 12px}th{background:#e9e4d9}figure{margin:20px 0}figure img{width:100%;height:auto;display:block}figcaption{font-size:14px;line-height:1.55;color:#536052;margin-top:8px}.note{padding:16px 22px;background:#eae4ed;border-left:3px solid #9973a3;margin:24px 0}.pill{display:inline-block;border:1px solid #79718c;padding:7px 14px;text-decoration:none;border-radius:3px;margin:8px 16px 8px 0}details{background:#ebe7dc;padding:14px 18px;margin:22px 0}summary{cursor:pointer;font-weight:600}.gallery{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:26px}footer{border-top:1px solid #c6beaf;margin-top:45px;padding-top:16px;font-size:14px;color:#536052}@media(max-width:850px){main{padding:20px}.pair,.gallery{grid-template-columns:1fr}table{display:block;overflow:auto}}'''
NAV = '<nav><a href="index.html">Findings</a><a href="reading.html">Full transition review</a><a href="visuals.html">Chair and room views</a><a href="trials.html">Three writing trials</a><a href="../2026-10-16-entropy-room-to-breathe/index.html">Current full texts</a></nav>'

def read(p): return p.read_text(encoding='utf-8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(name,s): (HERE/name).write_text(s,encoding='utf-8')
def page(title,intro,body): return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{STYLE}</style></head><body><main><div class="eyebrow">Ada Research · 16 October 2026 · editorial and visual test</div><h1>{html.escape(title)}</h1><p>{intro}</p>{NAV}{body}<footer>Assistant editorial judgement and native desktop views. Human reading and headset recognition remain separate tests.</footer></main></body></html>'
def figure(path,caption): return f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

report={'kind':'editorial-and-render-check','date':'2026-10-16','canonical_finals_unchanged':True,'reader_response':None,'headset_result':None,'sources':{},'native_runs':{}}
for name in ['Random_Entropies','Random_Entropy']:
    current=ROOT/'commons/maps'/name/'final.md'
    assert read(current)==read(PREVIOUS/f'{name}-final.md'), f'Changed final: {name}'
    target=HERE/'baseline'/name/'final.md';target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(current,target)
    report['sources'][current.relative_to(ROOT).as_posix()]=sha(current)

for label,room,tag in [('types','Random_Entropies','entropy-transition-visual'),('workshop','Random_Entropy','entropy-transition-visual'),('controlled','Random_Entropies','entropy-glass-control')]:
    origin=ROOT/'ada_run/encounter_pilot'/room/tag
    native=json.loads(read(origin/'report.json'))
    assert native['passed'] and not native['failures']
    target=HERE/label;target.mkdir(exist_ok=True)
    for path in list(origin.glob('*.png'))+[origin/'report.json',origin/'source_manifest.json']:
        shutil.copy2(path,target/path.name)
    report['native_runs'][label]={'checks':len(native['checks']),'report':f'{label}/report.json','meaning':'load, camera retention and supplied control invariants; not an automatic judgement of image quality'}

for rel in ['commons/artifacts/ordinary_entropies/objects.gd','commons/artifacts/ordinary_entropies/frost.gdshader','commons/artifacts/ordinary_entropies/coffee.gdshader','commons/artifacts/ordinary_entropies/comparison.gd','commons/artifacts/ordinary_entropies/encounter.gd','commons/artifacts/_hangar/hangar_kit.gd']:
    path=ROOT/rel;target=HERE/'sources'/path.name;target.parent.mkdir(exist_ok=True);shutil.copy2(path,target)
    report['sources'][rel]=sha(path)
report['production_material_changes']=False
report['entry_warning']='Entropy Types entry frame blocked; safe spawn fallback. Camera captures do not verify the entrance route.'

for source,out,title,intro in [('review.md','reading.html','Where the next encounter is earned','A close reading of the adopted finals, checked against the installed rooms.'),('trials.md','trials.html','Three small writing trials','Proposed passages for comparison. The adopted finals and room order remain unchanged.')]:
    content=re.sub(r'^# .*\n','',read(HERE/source),count=1)
    write(out,page(title,intro,'<div class="reading">'+markdown.markdown(content,extensions=['tables','toc'])+'</div>'))

controlled='<div class="pair">'+figure('controlled/same-pane-0.4.png','Same installed pane C: obscurity 0.40; chair identity 3; colour record, 2 bits.')+figure('controlled/same-pane-0.78.png','Same pane and viewpoint: obscurity 0.78. The chair and colour record stay fixed. Production shader settings were restored.')+'</div>'
body='<h2>One pane, one controlled change</h2><p>Only the blur uniform changes in memory. The chair, camera, geometry and declared record are held. Decorative background effects remain live. These are test states, not an additional installed exhibit.</p>'+controlled
body+='<h2>The five installed panes</h2><p>Their backgrounds and lighting differ. C and D have the same record, but this gallery alone does not isolate frosting from the surrounding scene.</p><div class="gallery">'
for letter,record in zip('ABCDE',['Identity · 0 bits','Colour + arms · 1 bit','Colour · 2 bits','Colour · 2 bits','No detail · 3 bits']):
    body+=figure('types/glass-'+letter+'.png',letter+' / '+record+' — native approach view.')
body+='</div><h2>Chair parts and the next encounters</h2><div class="gallery">'
for path,caption in [('types/chair-types.png','Three-type table: black armchairs are visible in this close view; dark surfaces flatten some shading. Check the distinction at headset distance.'),('types/coffee-approach.png','Five small cups, visible swirls and elapsed-time labels. The thermal explanation is on a side wall; the surroundings have no separate visible body.'),('workshop/cabinet-front.png','The cabinet is an object we stand outside. Its readings leave arrangements unspecified.'),('workshop/cabinet-oblique.png','Moving around the cabinet already changes overlap and visible relations.'),('workshop/points-aligned.png','Inside the point enclosure, the field surrounds the camera. This is the new bodily scale the prose can use.'),('workshop/points-offset.png','A second viewpoint one metre sideways. The points remain fixed; this is a supplied camera comparison, not a human perception result.')]: body+=figure(path,caption)
body+='</div><details><summary>Native run receipts and limits</summary><p>14 Types, 7 Workshop and 6 controlled-glass checks passed. These check loading, captured cameras and unchanged record/identity in the controlled pair. Image interpretation is the assistant’s inspection. No headset trial is claimed.</p><p>The Types run reported an entry-frame fallback; these cameras do not verify a complete walking route.</p><a href="verification.json">Source and test record</a></details>'
write('visuals.html',page('What the chair lets us see','Native Godot images from the current halls, with a separate controlled frosting comparison.',body))

cards='<div class="pair"><article class="card"><h2>Doors → coffee</h2><p><strong>A promising question, delayed by its arrival.</strong> RESET raises return and reconstruction. The narrator introduces heat early; the cups first answer with milk. Let the temperature labels give the heat question an occasion.</p></article><article class="card"><h2>Cabinet → points</h2><p><strong>The weakest join remains.</strong> We can already change viewpoint at the cabinet. Entering the field is the new affordance to test; a saved cabinet state is not carried into it.</p></article></div>'
body=cards+'<p><a class="pill" href="reading.html">Read the full transition review</a><a class="pill" href="trials.html">Compare three small trials</a></p><div class="note"><strong>The glass supplies a stronger encounter.</strong><p>The edges of a chair spread while its declared colour record stays fixed. Let the armrest or back rail carry attention before the definition. The black chair materials also need a headset-distance legibility check.</p></div>'+controlled
body+='<p><a href="visuals.html">See all five panes, chair types, coffee, cabinet and points →</a></p><p>The current finals remain at 1,748 and 1,712 prose words. The room and final order stay. No production material has been changed. A fresh human reading response is pending.</p>'
write('index.html',page('Does one encounter need the next?','The longer texts give the objects more space. Two bridges still rely on explanation; the chair imagery offers a more specific way forward.',body))

class Links(HTMLParser):
    def __init__(self):super().__init__();self.refs=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='a' and 'href' in a:self.refs.append(a['href'])
        if tag=='img':self.refs.append(a['src'])
write('verification.json',json.dumps(report,ensure_ascii=False,indent=2)+'\n')
for file in HERE.glob('*.html'):
    parser=Links();parser.feed(read(file))
    for ref in parser.refs:
        if ref.startswith(('#','http:','https:','/')):continue
        assert (HERE/urlsplit(ref).path).exists(),(file,ref)
print('Retained both finals unchanged; 27 load/capture/control checks; local page links valid.')
