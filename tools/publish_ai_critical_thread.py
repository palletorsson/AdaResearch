"""Publish the author's critical direction and a source-grounded ML planning brief."""
from pathlib import Path
from html import escape
import hashlib,json,shutil
import markdown
from bs4 import BeautifulSoup

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-11-ai-a-room-that-can-change'
SOURCE=R/'doc/book/course/storyboards/AI_CRITICAL_THREAD.md'
O.mkdir(parents=True,exist_ok=True)
text=SOURCE.read_text(encoding='utf-8')
shutil.copy2(SOURCE,O/'brief.md')
shutil.copy2(Path('C:/Users/palle/.codex/attachments/5d11fec3-4fa4-48e4-a322-8cd8d080df5e/Pasted text.txt'),O/'author-standpoint.txt')
sequence=R/'commons/maps/sequences/machinelearning.json'
order=json.loads(sequence.read_text(encoding='utf-8-sig'))['sequences']['machinelearning']['maps']
assert len(order)==8 and all(h in text for h in order)
paths=[sequence,R/'commons/maps/curriculum_spine.json',R/'commons/artifacts/registry/machinelearning.json']
paths += [R/'commons/maps'/h/(track+'.md') for h in order for track in ['tutorial','final']]
manifest={p.relative_to(R).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
(O/'source-register.json').write_text(json.dumps({'date':'2026-10-11','scope':'Read-only source inspection; no new engine validation','source_sha256':manifest},indent=2)+'\n',encoding='utf-8')
css='''*{box-sizing:border-box}body{background:#edeae2;color:#233537;margin:0;font:19px/1.65 Georgia,serif}main{max-width:1260px;margin:auto;padding:38px}h1{font-size:clamp(36px,5vw,68px);line-height:1.1;max-width:900px}h2{font-size:29px;margin-top:55px;line-height:1.25}p,ul,ol{max-width:920px}a{color:#276158}nav,.meta{font:14px/1.6 system-ui}nav{display:flex;gap:22px;flex-wrap:wrap;border-bottom:1px solid #adb8b0;padding:15px 0}.notice{background:#dce8df;border-left:4px solid #47725e;padding:18px 23px;max-width:920px}table{width:100%;border-collapse:collapse;font:16px/1.6 system-ui}td,th{padding:16px;border-bottom:1px solid #b6c2b8;text-align:left;vertical-align:top}th{background:#dce8df}td:first-child{width:18%;overflow-wrap:anywhere}code{font-size:.82em;overflow-wrap:anywhere}.table-scroll{overflow:auto}footer{border-top:1px solid #b6c2b8;margin-top:50px;padding:20px 0;font:14px/1.6 system-ui}@media(max-width:700px){main{padding:18px}table{min-width:780px}}'''
body=markdown.markdown(text,extensions=['tables','fenced_code'])
soup=BeautifulSoup(body,'html.parser')
toc=[]
for i,h in enumerate(soup.find_all('h2')):
    h['id']='section-'+str(i)
    toc.append('<a href="#'+h['id']+'">'+escape(h.get_text())+'</a>')
for t in soup.find_all('table'):
    wrap=soup.new_tag('div',attrs={'class':'table-scroll'});t.wrap(wrap)
html='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>AI: a room that can change</title><style>'+css+'</style></head><body><main><p class="meta">Endless Museum · working direction · 11 October 2026</p><nav><a href="brief.md">Editable brief</a><a href="author-standpoint.txt">Author’s supplied standpoint</a><a href="source-register.json">Inspected sources</a></nav><p class="notice">The standpoint is adopted. The eight hall proposals and two additional connections remain a plan. Existing tutorial/final texts, code and map order are unchanged by this planning pass.</p><nav>'+''.join(toc)+'</nav>'+str(soup)+'<footer>The frozen author note, editable repository brief and dated source register distinguish intention, proposal and inspected evidence.</footer></main></body></html>'
(O/'index.html').write_text(html,encoding='utf-8')
parsed=BeautifulSoup(html,'html.parser')
for a in parsed.find_all('a',href=True):
    href=a['href']
    if href.startswith('#'):assert parsed.find(id=href[1:])
    elif not href.startswith('http'):assert (O/href).exists()
assert len(parsed.select('tbody tr'))==8
print(json.dumps({'report':str(O/'index.html'),'halls':len(order),'sources':len(paths),'runtime_or_canonical_lesson_changes':False}))
