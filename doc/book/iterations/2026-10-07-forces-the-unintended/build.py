"""Build the illustrated research companion; never changes museum logic."""
from pathlib import Path
from html import escape as e
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import json, shutil, hashlib, zipfile, struct
import markdown

OUT=Path(__file__).resolve().parent
cards=json.loads((OUT/'captions.json').read_text(encoding='utf-8'))
images=json.loads((OUT/'images.json').read_text(encoding='utf-8'))
assert len(cards)==len(images)==3
for image in images:
    target=OUT/image['saved_file']; target.parent.mkdir(exist_ok=True)
    source=Path(image['source_path'])
    if source.is_file(): shutil.copy2(source,target)
    assert target.is_file()

css='''
:root{--paper:#f5f1e8;--ink:#252629;--muted:#67615c;--accent:#87394e;--line:#d4cbbd}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:80px}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.7 system-ui,sans-serif}a{color:var(--accent);text-underline-offset:3px}header,main,footer{max-width:1320px;padding:36px;margin:auto}header{padding-top:70px}h1,h2,h3{font-family:Georgia,serif;line-height:1.12;letter-spacing:-.025em}h1{font-size:clamp(42px,6vw,84px);margin:16px 0 24px}h2{font-size:37px}h3{font-size:25px}.eyebrow{text-transform:uppercase;color:var(--accent);font-size:11px;letter-spacing:.14em;font-weight:bold}.lead{font:25px/1.55 Georgia,serif;max-width:850px}.status{font-size:13px;color:var(--muted);max-width:800px}.thumbs{display:grid;grid-template-columns:repeat(3,1fr);gap:24px;margin:40px 0 0}.thumbs a{text-decoration:none}.thumbs img{display:block;width:100%;height:auto;border:1px solid var(--line)}.thumbs span{display:block;font:22px/1.3 Georgia,serif;margin:12px 0}nav{position:sticky;top:0;z-index:2;display:flex;justify-content:center;gap:24px;flex-wrap:wrap;padding:13px 22px;background:rgba(245,241,232,.98);border-block:1px solid var(--line);font-size:13px}nav a{text-decoration:none}.encounter{display:grid;grid-template-columns:minmax(0,1.5fr) minmax(260px,1fr);gap:44px;align-items:start;padding:40px 0 60px;border-bottom:1px solid var(--line)}figure{margin:0}figure img{display:block;width:100%;height:auto}figcaption{font-size:12px;color:var(--muted);margin:12px 0}.notes{position:sticky;top:80px}.notes h2{margin:10px 0 22px}.notes p{font-size:16px}.notes h3{font-size:23px;margin-top:30px}blockquote{font:25px/1.5 Georgia,serif;border-left:2px solid var(--accent);padding-left:20px;margin:30px 0}.reading{max-width:850px;margin:75px auto}.reading h1{font-size:48px}.reading h2{font-size:30px;margin-top:45px}.reading table{border-collapse:collapse;display:block;overflow-x:auto;font-size:14px}.reading th,.reading td{border-bottom:1px solid var(--line);padding:12px;min-width:165px;text-align:left;vertical-align:top}footer{font-size:13px;color:var(--muted);border-top:1px solid var(--line);padding-bottom:50px}.button{display:inline-block;padding:9px 15px;border:1px solid var(--accent);text-decoration:none;font-size:13px;margin-top:15px}@media(max-width:780px){header,main,footer{padding:24px}.thumbs{gap:12px}.thumbs span{font-size:17px}.encounter{grid-template-columns:1fr;gap:22px}.notes{position:static}.notes{order:-1}h2{font-size:31px}.lead{font-size:22px}nav{gap:14px}}@media print{nav,.thumbs{display:none}.notes{position:static}.encounter{display:block;break-before:page}.encounter img{height:240mm;width:auto;max-width:100%;margin:auto}.reading table{font-size:10px}header{padding:20px}}
'''
thumbs=''.join(f'<a href="#{c["id"]}"><img src="images/{c["id"]}.png" width="1024" height="1536" alt="{e(c["caption"])}"><span>{e(c["title"])}</span></a>' for c in cards)
sections=''
for i,c in enumerate(cards,1):
    sections+=f'''<section class="encounter" id="{c['id']}"><figure><a href="images/{c['id']}.png"><img loading="lazy" src="images/{c['id']}.png" width="1024" height="1536" alt="{e(c['caption'])}"></a><figcaption>Original AI-generated museum proposal · click for full-size PNG.</figcaption></figure><div class="notes"><p class="eyebrow">{i:02} / {e(c['kicker'])}</p><h2>{e(c['title'])}</h2><p>{e(c['caption'])}</p><blockquote>{e(c['question'])}</blockquote><h3>Artistic connection</h3><p>{e(c['connection'])} <a href="{c['source']}">{e(c['artist'])} — source</a>.</p><h3>What the learner could inspect</h3><p>{e(c['lesson'])}</p><p class="status">A proposed situation, not a tested reconstruction or a reproduction of the referenced artist's work.</p></div></section>'''
reading=markdown.markdown((OUT/'READING.md').read_text(encoding='utf-8'),extensions=['tables'])
html=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The world plays out — Endless Museum</title><style>{css}</style></head><body><header><p class="eyebrow">Endless Museum / Forces / 7 October 2026</p><h1>The world plays out.</h1><p class="lead">You give the point an ability. Then it meets another body, a snag, a task you did not assign. What happens next becomes part of the work.</p><p class="status">Three original illustrated encounters connect the force sequence with mechanical comedy, responsive worlds and material assemblage. The notes distinguish artistic references from our interpretations. Museum code and canonical manuscripts are unchanged.</p><a class="button" href="forces-the-unintended.zip">Download images, reading and prompts</a><div class="thumbs">{thumbs}</div></header><nav><a href="#01-the-machine-keeps-going">The machine</a><a href="#02-a-room-with-other-plans">The inhabitants</a><a href="#03-the-body-carries-its-history">The attachments</a><a href="#reading">Reading + sources</a><a href="../2026-10-06-forces-illustrated-atlas/index.html">Forces atlas</a></nav><main>{sections}<article class="reading" id="reading">{reading}</article></main><footer>Built-in OpenAI image generation. <a href="prompts.json">Full prompts</a> · <a href="images.json">Saved images and provenance</a> · <a href="READING.md">Editable research note</a> · <a href="manifest.json">File checks</a></footer></body></html>'''
(OUT/'index.html').write_text(html,encoding='utf-8')

class Links(HTMLParser):
    def __init__(self): super().__init__(); self.urls=[]; self.ids=set()
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if 'id' in a: self.ids.add(a['id'])
        self.urls.extend(a[k] for k in ('href','src') if k in a)
p=Links(); p.feed(html)
checked=0
for url in p.urls:
    u=urlsplit(url)
    if u.scheme: continue
    if u.path and u.path not in ('manifest.json','forces-the-unintended.zip'):
        assert (OUT/unquote(u.path)).is_file(),url
    if not u.path and u.fragment: assert u.fragment in p.ids,url
    checked+=1
files={}
for image in images:
    f=OUT/image['saved_file']; b=f.read_bytes()
    assert b[:8]==b'\x89PNG\r\n\x1a\n'
    files[image['saved_file']]={'sha256':hashlib.sha256(b).hexdigest(),'dimensions':struct.unpack('>II',b[16:24])}
manifest={'kind':'illustrated research; no runtime evidence','images':files,'local_links_checked':checked,'method':'built-in OpenAI image generation','canonical_manuscripts_changed':False,'museum_code_changed':False}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
with zipfile.ZipFile(OUT/'forces-the-unintended.zip','w',zipfile.ZIP_DEFLATED) as z:
    for f in OUT.rglob('*'):
        if f.is_file() and f.suffix!='.zip' and '__pycache__' not in f.parts: z.write(f,f.relative_to(OUT))
with zipfile.ZipFile(OUT/'forces-the-unintended.zip') as z: assert z.testzip() is None
print(json.dumps({'images':len(files),'local_links_checked':checked,'zip':'CRC passed','path':str(OUT/'index.html')}))
