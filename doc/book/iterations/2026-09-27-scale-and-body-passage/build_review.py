from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
URL='http://localhost:3003/book-review/doc/book/iterations/'+HERE.name+'/index.html'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
MAPS=[('Trans_Scale','reading-scale'),('Trans_Body','reading-body')]
changed={f'commons/maps/{name}/final.md' for name,_ in MAPS}|{f'commons/maps/Trans_Body/{name}.md' for name in ['critical','intent','summary','tutorial']}|{'commons/data/museum_core_encounters.json'}
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 assert ok,name
for rel,digest in json.loads(read(HERE/'baseline.json')).items():
 if rel not in changed:check('Preserved '+rel,sha(ROOT/rel)==digest)
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))['rooms']
old_core=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'))['rooms']
articles=[];comparisons=[];counts={}
for name,anchor in MAPS:
 path=Path('commons/maps')/name/'final.md';old=read(HERE/'before'/path);new=read(ROOT/path)
 check(name+' encounter markers preserved',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
 check(name+' code excerpts preserved',re.findall(r'```gdscript.*?```',old,re.S)==re.findall(r'```gdscript.*?```',new,re.S))
 images=lambda s:re.findall(r'!\[[^\]]*\]\(([^)]+)\)',s)
 check(name+' museum figure retained',images(old)==images(new))
 for url in images(new):
  with Image.open(ROOT/url.removeprefix('/book-review/')) as im:im.verify()
  check(name+' valid image '+url.rsplit('/',1)[-1],True)
 check(name+' current text hash',core[name]['text_sha256']==sha(ROOT/path))
 check(name+' review points here',core[name]['local_review']==URL+'#'+anchor)
 check(name+' other metadata preserved',{k:v for k,v in core[name].items() if k not in ['text_sha256','local_review']}=={k:v for k,v in old_core[name].items() if k not in ['text_sha256','local_review']})
 (HERE/(name+'.current.md')).write_text(new,encoding='utf-8')
 (HERE/(name+'.diff')).write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+name+'/final.md',tofile='current/'+name+'/final.md')),encoding='utf-8')
 counts[name]={'before':len(old.split()),'after':len(new.split())}
 articles.append(f'<article class="reading" id="{anchor}"><p class="eyebrow">{name} · CURRENT FINAL.MD · <a href="/compose/sources?map={name}&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>')
 table=difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(),new.splitlines(),'Before this pass','Current final.md',context=True,numlines=3)
 comparisons.append(f'<section id="diff-{name}"><h2>{name.replace("_"," ")}</h2><p>{len(old.split()):,} → {len(new.split()):,} words, including code and caption. <a href="{name}.diff">Plain text diff</a> · <a href="{name}.current.md">Current Markdown</a></p><div class="diff-scroll">{table}</div></section>')
manifest=json.loads(read(ROOT/'doc/book/captures/transformation/transformation-book.manifest.json'))
check('All seven capture sources current',len(manifest['maps'])==7 and all(sha(ROOT/r['path'])==r['sha256'] for r in manifest['maps']))
check('Capture output matches manifest',sha(ROOT/'doc/book/captures/transformation/transformation-book.md')==manifest['output_sha256'])
for name in ['transformation-book.md','transformation-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/transformation'/name,HERE/name)
companion_diff=[]
for name in ['critical','intent','summary','tutorial']:
 rel=Path('commons/maps/Trans_Body')/(name+'.md')
 companion_diff+=difflib.unified_diff(read(HERE/'before'/rel).splitlines(True),read(ROOT/rel).splitlines(True),fromfile='before/'+rel.as_posix(),tofile='current/'+rel.as_posix())
(HERE/'body-companions.diff').write_text(''.join(companion_diff),encoding='utf-8')
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-27-rotation-follow-a-turn/index.html'),re.S).group(1)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Scale and Body — what a passage leaves</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TRANSFORMATION · 27 SEPTEMBER 2026 · TWO HALLS</p><h1>What a passage leaves.</h1><p>Scale changes the room in a cut. Body lets the room answer your approach. Look back to find what has returned and what remains.</p><nav><a href="#reading-scale">Scale: read</a><a href="#reading-body">Body: read</a><a href="#changes">Before / after</a><a href="#decisions">Decisions</a><a href="transformation-book.md">Full Transformation capture</a></nav></header>
<div id="reading">{''.join(articles)}</div>
<section id="changes"><h2>Before and after</h2>{''.join(comparisons)}<p><a href="body-companions.diff">Companion corrections: the cut's session memory</a></p></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}</section>
<footer><p>Both illustrations are existing native museum captures from 23 September. The low lattice is photographed from above to show the open-topped cut. This is a writing pass; no new runtime or headset trial.</p><p><a href="checks.json">Source and publication checks</a> · <a href="/book-review/doc/book/iterations/2026-09-23-scale-door-and-body/report.json">Earlier Scale illustration checks</a> · <a href="/book-review/doc/book/iterations/2026-09-23-body-what-remains/report.json">Earlier Body checks</a></p><p>Next: <a href="/compose/sources?map=Trans_Pit&amp;doc=final">The Moving Boundary</a>.</p></footer>
</main></body></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'words':counts,'scope':'Source preservation, manuscript routing, original code excerpts, existing images and capture freshness. No new runtime/session-restoration or headset trial.','private_notes':'All 203 notes present. Existing Point_Zero/Point_One format and grounding warnings remain.'},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'url':URL+'#reading','checks':len(checks),'words':counts},indent=2))
