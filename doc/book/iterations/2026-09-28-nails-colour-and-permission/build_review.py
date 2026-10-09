from pathlib import Path
import difflib, hashlib, json, re, shutil
import markdown
from bs4 import BeautifulSoup
ROOT=Path(__file__).resolve().parents[4]; HERE=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(label,ok):
 checks.append({'name':label,'passed':bool(ok)})
 if not ok:raise ValueError(label)
def render(text,prefix):
 soup=BeautifulSoup(markdown.markdown(text,extensions=['extra']),'html.parser')
 for t in soup.find_all(id=True):t['id']=prefix+'-'+t['id']
 for a in soup.find_all('a',href=True):
  if a['href'].startswith('#'):a['href']='#'+prefix+'-'+a['href'][1:]
 return str(soup)
rel='commons/maps/Color_Nails/final.md'
old=read(HERE/'before'/rel);new=read(ROOT/rel);add=json.loads(read(HERE/'addition.json'))
check('Only the recorded addition and footnote',new.replace(add['passage']+'\n\n','').replace(add['note'],'').rstrip()==old.rstrip())
check('Code and encounter anchors preserved',re.findall(r'```.*?```|<!--.*?-->',old,re.S)==re.findall(r'```.*?```|<!--.*?-->',new,re.S))
check('Native salon figure unchanged',re.findall(r'!\[[^\]]*\]\([^\n]+\)',old)==re.findall(r'!\[[^\]]*\]\([^\n]+\)',new))
check('Playful closing and Rainbow handoff preserved',old[old.index('Choose a colour because'):].rstrip()==new[new.index('Choose a colour because'):].split('\n\n[^color-nails-lorde]:')[0].rstrip())
for name in ['commons/maps/Color_Nails/map_data.json','commons/maps/Color_Nails/tutorial.md','commons/maps/sequences/color.json']:
 check('Preserved '+name,sha(ROOT/name)==json.loads(read(HERE/'baseline.json'))[name])
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'));before=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'));e=core['rooms']['Color_Nails']
check('Current catalogue text hash',e['text_sha256']==sha(ROOT/rel))
for key in ['text_sha256','local_review']:before['rooms']['Color_Nails'][key]=e[key]
check('Other catalogue entries untouched',core==before)
manifest=json.loads(read(ROOT/'doc/book/captures/color/color-book.manifest.json'))
check('Eight current Colour chapter sources',len(manifest['maps'])==8 and all(sha(ROOT/r['path'])==r['sha256'] for r in manifest['maps']))
check('Capture hash matches',sha(ROOT/'doc/book/captures/color/color-book.md')==manifest['output_sha256'])
for name in ['color-book.md','color-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/color'/name,HERE/name)
defs=re.findall(r'^\[\^([^\]]+)\]:',new,re.M);refs=re.findall(r'\[\^([^\]]+)\](?!:)',new)
check('Footnote defined once and referenced',len(defs)==len(set(defs)) and set(refs)==set(defs))
(HERE/'Color_Nails.current.md').write_text(new,encoding='utf-8')
(HERE/'Color_Nails.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Color_Nails/final.md',tofile='current/Color_Nails/final.md')),encoding='utf-8')
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-28-nails-the-next-choice/index.html'),re.S).group(1)
css+='\n.footnote{font-size:.84em;overflow-wrap:anywhere}.addition{border-left:3px solid #a06a65;padding-left:24px}nav{flex-wrap:wrap}'
excerpt=render(add['passage']+'\n\n'+add['note'],'addition')
page=f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Nails — Colour and permission</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">COLOR_NAILS · 28 SEPTEMBER 2026 · AUDRE LORDE</p><h1>Colour and permission.</h1><p>The two points move with the same ease. What histories meet the hand they change?</p><nav><a href="#addition">The new passage</a><a href="#reading">Read the chapter</a><a href="#decisions">Decisions and source</a><a href="Color_Nails.diff">Exact difference</a></nav></header>
<section class="reading" id="addition"><p class="eyebrow">ADDED AFTER THE SHARED MATERIAL EXPLANATION</p><div class="addition">{excerpt}</div></section>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Color_Nails&amp;doc=final">READ AND COMMENT</a></p>{render(new,'chapter')}</article>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'),'decisions')}<p>{len(old.split())} → {len(new.split())} words including code, caption and the new source note.</p><p><a href="Color_Nails.current.md">Current Markdown</a> · <a href="Color_Nails.diff">Exact difference</a> · <a href="color-book.md">Colour capture</a> · <a href="color-book.manifest.json">Capture sources</a> · <a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a></p></section>
<footer><p>Previous reading: <a href="/book-review/doc/book/iterations/2026-09-28-nails-the-next-choice/index.html#reading">The next choice</a>. Next: <a href="/compose/sources?map=Color_Rainbow&amp;doc=final">Color_Rainbow</a>.</p></footer></main></body></html>"""
soup=BeautifulSoup(page,'html.parser');ids=[t['id'] for t in soup.find_all(id=True)]
check('Rendered IDs unique',len(ids)==len(set(ids)))
check('Footnote and navigation links resolve',all(a['href'][1:] in ids for a in soup.find_all('a',href=True) if a['href'].startswith('#')))
check('No unrendered footnote notation',not re.search(r'\[\^[^\]]+\]',soup.get_text()))
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'scope':'Editorial publication and preservation; no new runtime or headset test.'},indent=2)+'\n',encoding='utf-8')
print(str(len(checks))+' publication checks passed; '+str(len(old.split()))+' -> '+str(len(new.split()))+' words including source note.')
