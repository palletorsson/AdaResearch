"""Build the static comic reader from the existing proposal and selected image manifest.

Run before build.py. Images are generated assets, never synthesized or edited here.
"""
from pathlib import Path
from html import escape as e
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
from collections import Counter
import hashlib
import json
import struct
import zipfile

HERE = Path(__file__).resolve().parent
manifest = json.loads((HERE / 'illustrations.json').read_text(encoding='utf-8'))
proposal = json.loads((HERE / 'proposal.json').read_text(encoding='utf-8'))
ideas = {x['id']: x for x in proposal['ideas']}
plates = manifest['plates']
assert len(plates) == 10
assert Counter(i for p in plates for i in p['ids']) == Counter(ideas.keys())
assert [p['number'] for p in plates] == list(range(1, 11))
assert all(len(p['ids']) == 3 and [n['id'] for n in p['notes']] == p['ids'] for p in plates)

dimensions = {}
for p in plates:
    raw = (HERE / p['image']).read_bytes()
    assert raw[:8] == b'\x89PNG\r\n\x1a\n'
    w, h = struct.unpack('>II', raw[16:24])
    assert w >= 1024 and h >= 1536
    dimensions[p['image']] = {'width': w, 'height': h, 'sha256': hashlib.sha256(raw).hexdigest()}

css = '''
:root{--paper:#f1eee7;--ink:#242724;--line:#cfcac0;--muted:#62665e;--accent:#435b4b;--white:#fffdf8}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.55 Georgia,serif}a{color:var(--accent);text-underline-offset:3px}header,main,footer{max-width:1500px;margin:auto;padding:26px 36px}header{border-bottom:1px solid var(--line)}nav{display:flex;gap:24px;flex-wrap:wrap;font:13px/1.6 system-ui}h1{font-size:clamp(32px,4.5vw,64px);letter-spacing:-.035em;line-height:1.07;margin:24px 0 16px}h2{font-size:29px;line-height:1.2;margin:8px 0 20px}h3{font-size:23px;line-height:1.2;margin:8px 0 16px}p{margin:0 0 14px}.lead{font-size:22px;max-width:1050px}.note{font:13px/1.6 system-ui;color:var(--muted);max-width:1050px}.eyebrow{font:11px/1.6 system-ui;text-transform:uppercase;letter-spacing:.08em;color:var(--muted)}.thumbs{display:grid;grid-template-columns:repeat(10,1fr);gap:12px;margin:22px 0 26px}.thumb{display:block;text-decoration:none;background:var(--white);border:2px solid transparent;padding:5px;font:12px/1.5 system-ui}.thumb img{display:block;width:100%;aspect-ratio:2/3;object-fit:contain}.thumb span{display:block;padding:5px 0}.thumb[aria-current=true]{border-color:var(--accent)}.toolbar{display:flex;align-items:center;gap:14px;flex-wrap:wrap;margin:18px 0 24px;font:14px system-ui}button,select{font:14px system-ui;border:1px solid var(--line);padding:12px 15px;background:var(--white);color:var(--ink)}button{cursor:pointer}button:disabled{opacity:.4;cursor:default}.toolbar label{margin-left:auto}.layout{display:grid;grid-template-columns:minmax(0,2fr) minmax(280px,1fr);gap:32px;align-items:start}figure{margin:0}figure img{display:block;width:100%;height:auto;box-shadow:0 4px 28px #0002}figcaption{padding:15px 0;font:13px/1.6 system-ui;color:var(--muted)}.lesson{border-top:2px solid var(--accent);padding:19px 21px;background:var(--white);margin-bottom:22px}.lesson p{font-size:16px}.lesson .note{font-size:12px}.tags{display:flex;flex-wrap:wrap;gap:6px;margin:15px 0}.tags span{font:12px/1.4 system-ui;padding:5px 7px;background:#ecefe8}.badge{font:11px system-ui;text-transform:uppercase;border:1px solid var(--line);padding:4px 7px;margin-left:8px}.plate{scroll-margin-top:20px;margin-bottom:40px}.plate[hidden]{display:none}footer{border-top:1px solid var(--line);font:13px/1.6 system-ui}.printonly{display:none}:focus-visible{outline:3px solid #8b4f67;outline-offset:4px}@media(max-width:1000px){.thumbs{grid-template-columns:repeat(5,1fr)}.layout{grid-template-columns:minmax(0,1.6fr) minmax(250px,1fr);gap:20px}}@media(max-width:720px){header,main,footer{padding:22px 16px}.layout{display:block}.thumbs{gap:7px}.toolbar label{margin-left:0}h2{font-size:25px}.lesson{margin-top:20px}.thumb span{font-size:10px}.toolbar{gap:9px}}@media print{header nav,.thumbs,.toolbar,.openimage{display:none}header,main{padding:0}body{background:white}.plate,.plate[hidden]{display:block;break-before:page}.layout{display:block}figure img{max-height:250mm;width:auto;max-width:100%;margin:auto;box-shadow:none}aside{break-before:page}.lesson{break-inside:avoid}h1{font-size:28pt}.printonly{display:block}}
'''
thumbs = ''.join(f'<a class="thumb" href="#plate-{p["number"]:02d}" aria-label="Plate {p["number"]}: {e(p["title"])}"><img src="{p["image"]}" alt="" width="1024" height="1536" loading="lazy"><span>{p["ids"][0]:02d}–{p["ids"][-1]:02d}</span></a>' for p in plates)
options = ''.join(f'<option value="plate-{p["number"]:02d}">{p["number"]:02d} · Ideas {p["ids"][0]:02d}–{p["ids"][-1]:02d} · {e(p["title"].title())}</option>' for p in plates)
sections = []
caption_text = ['ENDLESS MUSEUM — THE POINT GAINS POWER', 'Thirty ideas / ten comic plates / sixty frames', manifest['status'], 'Each row reads left to right: setup, then reveal. Grey ghosts represent other recorded positions. Diagram scales and panel perspectives are illustrative, not measurements.', '']
for p in plates:
    lesson_cards = []
    for note in p['notes']:
        x = ideas[note['id']]
        role = 'optional extension' if x['role'] == 'extension' else x['role']
        tags = ''.join('<span>' + e(t) + '</span>' for t in x['learning_elements'])
        lesson_cards.append(f'<article class="lesson" id="caption-{x["id"]}"><p class="eyebrow">Idea {x["id"]:02d}<span class="badge">{e(role)}</span></p><h3>{e(x["title"])}</h3><p>{e(note["text"])}</p><div class="tags" aria-label="Learning elements">{tags}</div><p class="note">Hall: {e(x["hall"])}</p><a href="index.html#idea-{x["id"]}">Read the proposal and future check →</a></article>')
        caption_text += [f'{x["id"]:02d}. {x["title"]}', f'{role} / {x["hall"]}', note['text'], 'Learn: ' + '; '.join(x['learning_elements']), '']
    alt = 'Setup and reveal pairs for ' + '; '.join(f'{i:02d}, {ideas[i]["title"]}' for i in p['ids']) + '.'
    sections.append(f'<section class="plate" id="plate-{p["number"]:02d}" aria-labelledby="title-{p["number"]}"><p class="eyebrow">Plate {p["number"]:02d} / ten · Ideas {p["ids"][0]:02d}–{p["ids"][-1]:02d}</p><h2 id="title-{p["number"]}">{e(p["title"].title())}</h2><div class="layout"><figure><a class="openimage" href="{p["image"]}" target="_blank" rel="noopener" aria-label="Open plate {p["number"]} at full resolution"><img src="{p["image"]}" alt="{e(alt)}" width="1024" height="1536" loading="lazy"></a><img class="printonly" src="{p["image"]}" alt="{e(alt)}"><figcaption>Read each row left → right. Concept illustration for discussion. <a href="{p["image"]}" download>Download this plate</a>.</figcaption></figure><aside aria-label="Subjects and reading notes">{"".join(lesson_cards)}</aside></div></section>')

js = '''
const plates=[...document.querySelectorAll('.plate')],thumbs=[...document.querySelectorAll('.thumb')];
const prev=document.querySelector('#previous'),next=document.querySelector('#next'),select=document.querySelector('#choose'),count=document.querySelector('#position');
let current=0;
function render(){const id=location.hash.slice(1);const match=plates.findIndex(p=>p.id===id);current=match<0?0:match;plates.forEach((p,i)=>p.hidden=i!==current);thumbs.forEach((t,i)=>t.setAttribute('aria-current',String(i===current)));select.value=plates[current].id;prev.disabled=current===0;next.disabled=current===plates.length-1;count.textContent='Plate '+(current+1)+' / '+plates.length;}
function move(i){if(i>=0&&i<plates.length)location.hash=plates[i].id;}
prev.addEventListener('click',()=>move(current-1));next.addEventListener('click',()=>move(current+1));select.addEventListener('change',()=>location.hash=select.value);
window.addEventListener('hashchange',render);window.addEventListener('keydown',e=>{if(/INPUT|TEXTAREA|SELECT|BUTTON/.test(e.target.tagName)||e.altKey||e.ctrlKey||e.metaKey)return;if(e.key==='ArrowRight'){e.preventDefault();move(current+1);}if(e.key==='ArrowLeft'){e.preventDefault();move(current-1);}});render();
'''
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Thirty ideas, illustrated — Endless Museum</title><style>' + css + '</style></head><body>'
page += '<header><nav><b>ENDLESS MUSEUM / VECTOR & FORCE</b><a href="index.html">The full thirty-idea plan</a><a href="forces-thirty-illustrations.zip" download>Download ten plates + captions</a><a href="illustration-prompts.json">Image briefs</a></nav><h1>The point gains power.</h1><p class="lead">Thirty ideas. Ten comic plates. A setup and a reveal for every encounter.</p><p>The same student, point and cube move from describing a journey to influencing motion—and working with what the room keeps.</p><p class="note">' + e(manifest['status']) + ' Grey ghosts show recorded positions. Read the accompanying notes for the exact relation; drawings and arrow lengths are not calibrated measurements.</p></header><main><nav class="thumbs" aria-label="All ten plates">' + thumbs + '</nav>'
page += '<div class="toolbar"><button id="previous" type="button">← Previous</button><span id="position" aria-live="polite"></span><button id="next" type="button">Next →</button><label for="choose">Jump to</label><select id="choose">' + options + '</select></div>' + ''.join(sections)
page += '</main><footer>7 October 2026 · All 30 existing idea IDs retained. Core / practice / optional roles come from proposal.json. Generated with the built-in image tool; selected PNGs saved in this project. <a href="illustrations-validation.json">Coverage and asset validation</a> · <a href="illustrations.json">Captions and selected assets</a></footer><script>' + js + '</script></body></html>'
(HERE / 'illustrations.html').write_text(page, encoding='utf-8')
(HERE / 'illustration-captions.txt').write_text('\n'.join(caption_text), encoding='utf-8')
with zipfile.ZipFile(HERE / 'forces-thirty-illustrations.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for p in plates:
        archive.write(HERE / p['image'], p['image'])
    archive.write(HERE / 'illustration-captions.txt', 'READ-ME-CAPTIONS.txt')

class Check(HTMLParser):
    def __init__(self):
        super().__init__(); self.ids=set(); self.refs=[]
    def handle_starttag(self, tag, attrs):
        attrs=dict(attrs)
        if 'id' in attrs:
            assert attrs['id'] not in self.ids
            self.ids.add(attrs['id'])
        for key in ('src','href'):
            if key in attrs:self.refs.append(attrs[key])

check=Check();check.feed(page)
for ref in check.refs:
    parts=urlsplit(ref)
    if parts.scheme:continue
    if not parts.path:
        assert parts.fragment in check.ids, ref
    elif parts.path != 'illustrations-validation.json':
        target=HERE/unquote(parts.path)
        assert target.is_file(), ref
        if parts.fragment and target.suffix == '.html':
            dest=Check();dest.feed(target.read_text(encoding='utf-8'))
            assert parts.fragment in dest.ids, ref
with zipfile.ZipFile(HERE / 'forces-thirty-illustrations.zip') as archive:
    assert archive.testzip() is None
    assert len(archive.namelist()) == 11
result={'plates':10,'illustrated_ideas':30,'frames':60,'each_idea_exactly_once':True,'idea_ids':sorted(ideas),'all_selected_images_visually_reviewed':True,'local_refs_checked':len(check.refs),'archive_files':11,'images':dimensions,'runtime_test':'not run; concept illustrations only','review_limit':'Qualitative scene/subject review; arrows, perspective and silhouettes are not measurement evidence. Corrected direction and attachment errors through image generation.'}
(HERE / 'illustrations-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k not in ('images','idea_ids')},indent=2))
