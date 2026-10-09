from pathlib import Path
from datetime import datetime, timezone
import difflib, hashlib, html, json, re, shutil
import markdown
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
paths={'point-zero':'commons/maps/Point_Zero/final.md','preface':'doc/book/preface.md'}
old={k:read(OUT/'before'/p) for k,p in paths.items()}
new={k:read(ROOT/p) for k,p in paths.items()}
checks=[]
def check(label,ok):
    checks.append({'name':label,'passed':bool(ok)})
    if not ok:raise ValueError(label)
def words(s):
    s=re.sub(r'^\[\^.+','',s,flags=re.M)
    s=re.sub(r'```.*?```|<!--.*?-->|\[\^[^\]]+\]','',s,flags=re.S)
    return len(re.sub(r'^#.*','',s,flags=re.M).split())
def render(s,prefix):
    s=re.sub(r'~~([^~\n]+)~~',r'<del>\1</del>',s)
    soup=BeautifulSoup(markdown.markdown(s,extensions=['extra']),'html.parser')
    for node in soup.find_all(id=True):node['id']=prefix+'-'+node['id']
    for a in soup.find_all('a',href=True):
        if a['href'].startswith('#'):a['href']='#'+prefix+'-'+a['href'][1:]
    return str(soup)
counts={k:{'before':words(old[k]),'after':words(new[k])} for k in paths}
for k,p in paths.items():
    defs=re.findall(r'^\[\^([^\]]+)\]:',new[k],re.M)
    refs=re.findall(r'\[\^([^\]]+)\](?!:)',new[k])
    check(k+' footnotes complete and unique',set(defs)==set(refs) and len(defs)==len(set(defs)))
    (OUT/(k+'.current.md')).write_text(new[k],encoding='utf-8')
    (OUT/(k+'.diff')).write_text(''.join(difflib.unified_diff(old[k].splitlines(True),new[k].splitlines(True),fromfile='before/'+p,tofile='current/'+p)),encoding='utf-8')
check('Code excerpts and encounter anchors unchanged',re.findall(r'```.*?```|<!--.*?-->',old['point-zero'],re.S)==re.findall(r'```.*?```|<!--.*?-->',new['point-zero'],re.S))
inheritance=next(p for p in old['point-zero'].split('\n\n') if p.startswith('You can stand in a room you did not build.'))
check('Author inherited-work paragraph exact',inheritance in new['point-zero'])
check('Origin and exit encounter exact',old['point-zero'].split('<!-- @origin -->')[1].split('[^1]:')[0]==new['point-zero'].split('<!-- @origin -->')[1].split('[^1]:')[0])
check('Hall now shorter',counts['point-zero']['after']<counts['point-zero']['before'])
check('Historical reference retained in preface','1476589.1476686' in new['preface'] and '[^point-one-room-history]' not in new['point-zero'])
for p,h in json.loads(read(OUT/'baseline.json')).items():check('Unchanged '+p,sha(ROOT/p)==h)
c=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))
b=json.loads(read(OUT/'before/commons/data/museum_core_encounters.json'))
for key in ['text_sha256','local_review']:b['rooms']['Point_Zero'][key]=c['rooms']['Point_Zero'][key]
check('Only Point Zero text fingerprint and review reference changed in catalogue',b==c)
check('Catalogue matches current chapter',c['rooms']['Point_Zero']['text_sha256']==sha(ROOT/paths['point-zero']))
manifest=json.loads(read(ROOT/'doc/book/captures/primitives/primitives-book.manifest.json'))
check('Current Primitives capture sources',all(sha(ROOT/x['path'])==x['sha256'] for x in manifest['maps']))
check('Current Primitives capture output',sha(ROOT/'doc/book/captures/primitives/primitives-book.md')==manifest['output_sha256'])
frame=json.loads(read(ROOT/'doc/book/iterations/2026-09-23-book-frame/manifest.json'))
check('Framing preview includes current preface',frame['sources_sha256']['doc/book/preface.md']==sha(ROOT/'doc/book/preface.md'))
for name in ['primitives-book.md','primitives-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/primitives'/name,OUT/name)
css='*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:28px}body{margin:0;background:#f6f3eb;color:#292b29;font:19px/1.75 Georgia,serif}main{max-width:1100px;margin:auto;padding:56px 28px}header{padding-bottom:35px;border-bottom:1px solid #d4d1c7}header h1{font:normal clamp(38px,6vw,68px)/1.12 Georgia,serif;max-width:900px;margin:18px 0}header>p{max-width:760px}a{color:#864752;text-underline-offset:3px}nav{display:flex;flex-wrap:wrap;gap:10px 22px;font:14px/1.6 system-ui,sans-serif}.eyebrow,.meta,summary{font:12px/1.6 system-ui,sans-serif}.eyebrow{text-transform:uppercase;letter-spacing:.12em;color:#63645f}.meta{color:#63645f}article,.excerpt{max-width:750px;margin:65px auto}article h1{font-size:34px;font-weight:normal;line-height:1.25}h2{font-size:28px;font-weight:normal}p{margin:0 0 23px}section{padding-top:38px}details{border-top:1px solid #d4d1c7;padding:20px 0;margin:25px 0}summary{cursor:pointer;font-size:15px;font-weight:600}details[open]>summary{margin-bottom:24px}.comparison{display:grid;grid-template-columns:1fr 1fr;gap:40px;font-size:16px}.comparison>div{min-width:0}.comparison h1{font-size:26px}pre{padding:18px;background:#e9e6dd;overflow:auto;font:13px/1.6 Consolas,monospace}code{font:.86em Consolas,monospace}pre code{font:inherit}.footnote{font-size:14px;overflow-wrap:anywhere}.footnote p{margin:10px 0}.excerpt{border-left:3px solid #ac7c7a;padding-left:24px}footer{font:13px/1.6 system-ui,sans-serif;border-top:1px solid #d4d1c7;padding-top:24px}a:focus-visible,summary:focus-visible{outline:3px solid #557a85;outline-offset:5px}@media(max-width:760px){body{font-size:18px}main{padding:28px 20px}.comparison{display:block}.comparison>div{margin-bottom:40px}}@media print{nav,details,footer{display:none}body{background:white;font-size:12pt}main{padding:0}article{break-before:page}}'
comparisons=''
for k in paths:
    comparisons+=f'<details><summary>{html.escape(k)}: original beside current</summary><p class="meta">Main prose: {counts[k]["before"]} to {counts[k]["after"]} words; excludes title, notes and code.</p><div class="comparison"><div><p class="eyebrow">Before</p>{render(old[k],k+"-before")}</div><div><p class="eyebrow">Current</p>{render(new[k],k+"-after")}</div></div><p><a href="{k}.diff">Exact difference</a></p></details>'
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Arrival and changing conditions | Ada Research</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">Preface / Point Zero / 28 September 2026</p><h1>We find our bearings while the possibilities change.</h1><p>The wider argument moves into the preface. Point Zero returns to the fall, a running number, folding frames and somewhere to count from.</p><p class="meta">Point Zero: {counts['point-zero']['before']} to {counts['point-zero']['after']} words of main prose. Current canonical manuscripts; spatial arrangement unchanged.</p><nav><a href="#addition">New preface passage</a><a href="#reading">Read Point Zero</a><a href="#preface">Full preface</a><a href="#changes">Before and after</a></nav></header>
<section class="excerpt" id="addition"><p class="eyebrow">New passage / in the preface</p>{render(read(OUT/'preface-addition.md'),'excerpt')}</section>
<article id="reading"><p class="eyebrow">Current final.md / <a href="/compose/sources?map=Point_Zero&amp;doc=final">Read and comment</a></p>{render(new['point-zero'],'zero')}</article>
<article id="preface"><p class="eyebrow">Current canonical preface</p>{render(new['preface'],'preface')}</article>
<section id="changes">{render(read(OUT/'DECISIONS.md'),'decisions')}{comparisons}<p class="meta"><a href="point-zero.current.md">Point Zero Markdown</a> / <a href="preface.current.md">Preface Markdown</a> / <a href="primitives-book.md">Refreshed Primitives capture</a> / <a href="checks.json">Publication checks</a></p></section>
<footer><a href="/book-review/doc/book/iterations/2026-09-23-book-frame/index.html#preface">Preface and afterword reading edition</a>. The continuing Patterns pass resumes at Array_Patterns.</footer></main></body></html>"""
soup=BeautifulSoup(page,'html.parser');ids=[t['id'] for t in soup.find_all(id=True)]
check('Unique reading IDs',len(ids)==len(set(ids)))
check('Internal reading links resolve',all(a['href'][1:] in ids for a in soup.find_all('a',href=True) if a['href'].startswith('#')))
check('Footnotes rendered',not re.search(r'\[\^[^\]]+\]',soup.get_text()))
check('Removable you visibly struck through',soup.select_one('#reading del').get_text()=='you')
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'checks.json').write_text(json.dumps({'passed':True,'generated_at':datetime.now(timezone.utc).isoformat(),'word_counts':counts,'checks':checks,'scope':'Editorial relocation and publication. No runtime or reader test.'},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks_passed':len(checks),'word_counts':counts}))
