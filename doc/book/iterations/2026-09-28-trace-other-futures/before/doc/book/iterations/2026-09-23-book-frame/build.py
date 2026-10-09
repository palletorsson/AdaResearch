"""Build the framing reading edition. Prose is edited only in doc/book/*.md."""
from pathlib import Path
from urllib.parse import urlsplit, unquote, quote
from datetime import datetime, timezone
import hashlib, html, json, re
import markdown
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
BASE='/book-review/'+OUT.relative_to(ROOT).as_posix()
SOURCES={}
def record(path):
    path=path.resolve()
    if not path.is_relative_to(ROOT) or not path.is_file(): raise ValueError('Missing source: '+str(path))
    rel=path.relative_to(ROOT).as_posix()
    SOURCES[rel]=hashlib.sha256(path.read_bytes()).hexdigest()
    return rel
def snapshot(path):
    rel=record(path); dest=OUT/'sources'/rel
    dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(path.read_bytes())
    return BASE+'/sources/'+quote(rel,safe='/')
def document(filename,prefix):
    path=ROOT/filename;text=path.read_text(encoding='utf-8');download=snapshot(path)
    defs=re.findall(r'^\[\^([^\]]+)\]:',text,re.M);refs=re.findall(r'\[\^([^\]]+)\](?!:)',text)
    if len(defs)!=len(set(defs)) or set(refs)!=set(defs):raise ValueError('Footnote mismatch: '+filename)
    body,_,editorial=text.partition('\n---\n\n## Editorial development slots')
    if editorial:body+='\n\n<details class="development" markdown="1"><summary>Editorial development slots</summary>\n\n'+editorial+'\n\n</details>'
    soup=BeautifulSoup(markdown.markdown(body,extensions=['extra','toc','sane_lists']),'html.parser')
    for tag in soup.find_all(re.compile(r'^h[1-6]$')):tag.name='h'+str(min(6,int(tag.name[1])+1))
    for tag in soup.find_all(id=True):tag['id']=prefix+'-'+tag['id']
    for a in soup.find_all('a',href=True):
        href=a['href'];parts=urlsplit(href)
        if href.startswith('#'):a['href']='#'+prefix+'-'+href[1:];continue
        if parts.scheme or parts.netloc or href.startswith('/'):continue
        target=(path.parent/unquote(parts.path)).resolve()
        if target==OUT/'index.html':a['href']=BASE+'/index.html'
        elif re.fullmatch(r'commons/maps/[^/]+/final\.md',target.relative_to(ROOT).as_posix()):a['href']='/book-review/'+record(target)
        else:a['href']=snapshot(target)
        if parts.fragment and target.suffix.lower()!='.md':a['href']+='#'+parts.fragment
    return str(soup),[(h.get('id'),h.get_text()) for h in soup.find_all('h3')],download
preface,_,preface_source=document('doc/book/preface.md','preface')
afterword,headings,afterword_source=document('doc/book/afterword-qfep.md','afterword')
plan,_,plan_source=document('doc/book/BOOK_FRAME.md','plan')
spine_path=ROOT/'commons/maps/curriculum_spine.json';record(spine_path)
sequences=sorted(json.loads(spine_path.read_text(encoding='utf-8'))['spine']['sequences'],key=lambda s:s['order'])
chapters=[]
for sequence in sequences:
    name=sequence['name'];source=ROOT/'commons/maps/sequences'/(name+'.json');record(source)
    maps=json.loads(source.read_text(encoding='utf-8'))['sequences'][name]['maps']
    chapters.append({'sequence':name,'maps':maps})
first=chapters[0]['maps'][0];last=chapters[-1]['maps'][-1]
for name in [first,last]:record(ROOT/'commons/maps'/name/'final.md')
count=sum(len(c['maps']) for c in chapters)
menu=''.join('<li><a href="#'+html.escape(i)+'">'+html.escape(t)+'</a></li>' for i,t in headings)
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Ada Research — Preface and QFEP afterword</title>
<style>
:root{color-scheme:light;--paper:#f7f4ed;--ink:#252625;--muted:#62645f;--line:#d8d4c8;--accent:#843d50}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:2rem}body{margin:0;background:var(--paper);color:var(--ink);font:18px/1.72 Georgia,serif}a{color:var(--accent);text-decoration-thickness:1px;text-underline-offset:3px}a:focus-visible,summary:focus-visible{outline:3px solid #496e79;outline-offset:4px}header{max-width:1180px;margin:auto;padding:52px 32px 36px;border-bottom:1px solid var(--line)}.eyebrow,.meta,nav,summary,.source,.part{font-family:system-ui,sans-serif}.eyebrow{font-size:12px;letter-spacing:.13em;text-transform:uppercase;color:var(--muted)}header h1{font-size:clamp(36px,5vw,60px);line-height:1.08;font-weight:400;max-width:900px;margin:20px 0}header p{max-width:690px;margin:0}.path{display:flex;flex-wrap:wrap;gap:10px;margin-top:28px}.path a{padding:8px 15px;border:1px solid var(--line);border-radius:3px;font-size:14px;text-decoration:none}.path a:hover{background:white}.layout{display:grid;grid-template-columns:210px minmax(0,760px);gap:64px;max-width:1180px;margin:0 auto;padding:45px 32px}aside nav{position:sticky;top:28px;font-size:13px;line-height:1.45}aside ol{padding-left:17px}aside li{margin:12px 0}aside nav>a{display:block;margin-bottom:16px;font-weight:650}main{min-width:0}article,section{scroll-margin-top:25px}article{padding-bottom:44px}h2{font-size:34px;font-weight:400;line-height:1.2;margin:12px 0 24px}h3{font-size:26px;font-weight:400;line-height:1.3;margin:40px 0 16px}p{margin:0 0 22px}.part{font-size:12px;color:var(--muted);letter-spacing:.1em;text-transform:uppercase}.source,.meta{font-size:12px;color:var(--muted)}.source{display:flex;flex-wrap:wrap;gap:18px;margin-bottom:26px}.spine{border-block:1px solid var(--line);padding:35px 0;margin:0 0 48px}.footnote{border-top:1px solid var(--line);font-size:14px;margin-top:38px;padding-top:14px;overflow-wrap:anywhere}.footnote li{margin-bottom:16px}.footnote p{margin:0}.footnote hr{display:none}code{font:.85em/1.5 ui-monospace,Consolas,monospace;background:#e9e6df;padding:2px 4px;border-radius:3px;overflow-wrap:anywhere}pre{white-space:pre-wrap;padding:16px;background:#e9e6df}pre code{padding:0}sup{line-height:0}details{border:1px solid var(--line);padding:16px 20px;margin:30px 0;font-size:16px}summary{cursor:pointer;font-weight:600;font-size:14px}details[open]>summary{margin-bottom:24px}details table{display:block;overflow-x:auto;font:13px/1.5 system-ui,sans-serif}td,th{padding:10px;text-align:left;vertical-align:top;border-bottom:1px solid var(--line);min-width:150px}footer{max-width:1180px;margin:auto;padding:25px 32px 50px;border-top:1px solid var(--line)}blockquote{border-left:3px solid var(--line);margin-left:0;padding-left:20px}
@media(max-width:800px){.layout{display:block;padding:24px}aside{display:none}header{padding:30px 24px}h2{font-size:30px}body{font-size:17px}.source{gap:12px}.path{gap:7px}.path a{padding:7px 10px}}
@media print{aside,header nav,.source,.development,footer{display:none}.layout{display:block;max-width:none;padding:0}body{background:white;font-size:11pt}header{padding:0 0 20px}.spine,#afterword{break-before:page}a{color:inherit}h2,h3{break-after:avoid}}
</style></head><body>
<header><div class="eyebrow">Ada Research · Book framing · Working drafts · Preface revised 24 September 2026</div><h1>What bodies are possible?</h1><p>An invitation before the journey. A return to its questions after the spine.</p><nav class="path" aria-label="Publication order"><a href="#preface">01 · Preface</a><a href="#spine">02 · The spine</a><a href="#afterword">03 · QFEP afterword</a><a href="#editorial">Editorial scaffold</a></nav></header>
<div class="layout"><aside><nav aria-label="On this page"><a href="#preface">Before the first point</a><a href="#spine">The active spine</a><a href="#afterword">The QFEP afterword</a><ol>'''+menu+'''</ol><a href="#editorial">Next writing pass</a><a href="/book?map=Point_One&amp;section=final">Book editor</a></nav></aside><main>
<article id="preface"><div class="part">01 · Before the spine</div><div class="source"><a href="'''+preface_source+'''">Preface source · this edition</a></div>'''+preface+'''</article>
<section id="spine" class="spine"><div class="part">02 · The journey</div><h2>The active spine</h2><p>Read the halls in sequence, carrying an operation and an unanswered question into the next. The afterword follows the whole journey, including the halls after the QFEP Laboratory.</p><p>'''+str(len(chapters))+' sequences · '+str(count)+' halls in this reading edition. From <strong>'+html.escape(first)+'</strong> to <strong>'+html.escape(last)+'''</strong>.</p><nav class="path" aria-label="Spine reading"><a href="/museum-progress">Browse the active spine</a><a href="/book-review/commons/maps/'''+quote(first)+'''/final.md">First hall · live text</a><a href="/book-review/commons/maps/'''+quote(last)+'''/final.md">Final hall · live text</a><a href="#afterword">Continue to the afterword ↓</a></nav></section>
<article id="afterword"><div class="part">03 · After the complete spine</div><div class="source"><a href="'''+afterword_source+'''">Afterword source · this edition</a></div>'''+afterword+'''</article>
<details id="editorial" class="development"><summary>Editorial scaffold — evidence, cases, and next revision</summary>'''+plan+'''</details></main></div><footer class="meta">A scaffold for revision. Manuscript sources: doc/book/preface.md and doc/book/afterword-qfep.md.<br>Reading edition rebuilt from those files; hall links open their live final.md sources. <a href="manifest.json">Edition and source record</a></footer></body></html>'''
soup=BeautifulSoup(page,'html.parser');ids=[t['id'] for t in soup.find_all(id=True)]
if len(ids)!=len(set(ids)):raise ValueError('Duplicate rendered ids')
for a in soup.find_all('a',href=True):
    if a['href'].startswith('#') and a['href'][1:] not in ids:raise ValueError('Broken anchor '+a['href'])
if soup.find('script'):raise ValueError('Review preview must remain static')
(OUT/'index.html').write_text(page,encoding='utf-8')
manifest={'kind':'book-framing-reading-edition','generated_at':datetime.now(timezone.utc).isoformat(),'status':'working drafts; not accepted final manuscript','order':['preface','active spine','QFEP afterword'],'canonical_manuscripts':['doc/book/preface.md','doc/book/afterword-qfep.md'],'sequence_count':len(chapters),'hall_count':count,'chapters':chapters,'first':first,'last':last,'sources_sha256':SOURCES,'preview_url':'http://localhost:3003'+BASE+'/index.html'}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'url':manifest['preview_url'],'sequences':len(chapters),'halls':count,'sources':len(SOURCES),'afterword_sections':len(headings)}))