from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
URL='http://localhost:3003/book-review/doc/book/iterations/'+HERE.name+'/index.html'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
rel=Path('commons/maps/Tutorial_3D/final.md')
old=read(HERE/'before'/rel);new=read(ROOT/rel)
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 assert ok,name
changed={rel.as_posix(),'commons/data/museum_core_encounters.json'}
for name,digest in json.loads(read(HERE/'baseline.json')).items():
 if name not in changed:check('Preserved '+name,sha(ROOT/name)==digest)
check('Encounter markers preserved',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
check('Two code excerpts preserved',re.findall(r'```gdscript.*?```',old,re.S)==re.findall(r'```gdscript.*?```',new,re.S) and new.count('```gdscript')==2)
flight=next(p for p in old.split('\n\n') if p.startswith('Walk through the ground-level opening.'))
check('Complete VR movement guidance preserved',flight in new)
gap=next(p for p in old.split('\n\n') if p.startswith('The gap is not an extra entry.'))
check('Space between entries preserved',gap in new)
images=lambda s:re.findall(r'!\[[^\]]*\]\(([^)]+)\)',s)
check('Museum figure reference retained',images(old)==images(new) and len(images(new))==1)
for url in images(new):
 with Image.open(ROOT/url.removeprefix('/book-review/')) as im:im.verify()
 check('Readable '+url.rsplit('/',1)[-1],True)
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))
before=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'))
entry=core['rooms']['Tutorial_3D']
check('Text hash current',entry['text_sha256']==sha(ROOT/rel))
check('Review points here',entry['local_review']==URL+'#reading')
for key in ('text_sha256','local_review'):before['rooms']['Tutorial_3D'][key]=entry[key]
check('Rest of catalogue unchanged',before==core)
manifest=json.loads(read(ROOT/'doc/book/captures/array_tutorial/array_tutorial-book.manifest.json'))
check('All five capture sources current',len(manifest['maps'])==5 and all(sha(ROOT/r['path'])==r['sha256'] for r in manifest['maps']))
check('Capture output current',sha(ROOT/'doc/book/captures/array_tutorial/array_tutorial-book.md')==manifest['output_sha256'])
for name in ('array_tutorial-book.md','array_tutorial-book.manifest.json'):shutil.copy2(ROOT/'doc/book/captures/array_tutorial'/name,HERE/name)
(HERE/'Tutorial_3D.current.md').write_text(new,encoding='utf-8')
(HERE/'Tutorial_3D.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Tutorial_3D/final.md',tofile='current/Tutorial_3D/final.md')),encoding='utf-8')
table=difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(),new.splitlines(),'Before this pass','Current final.md',context=True,numlines=3)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-27-rotation-follow-a-turn/index.html'),re.S).group(1)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Room between the entries</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TUTORIAL_3D · 27 SEPTEMBER 2026 · ARRAYS</p><h1>Room between the entries.</h1><p>Select an address above your head. Fly to its cube, collect it, and stay a moment in the place it leaves.</p><nav><a href="#reading">Read the chapter</a><a href="#changes">Before / after</a><a href="#decisions">Decisions</a><a href="array_tutorial-book.md">Full Arrays capture</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Tutorial_3D&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>Before and after</h2><p>{len(old.split()):,} → {len(new.split()):,} words, including code and captions. Both code excerpts and the complete flight guidance remain. <a href="Tutorial_3D.diff">Plain text diff</a> · <a href="Tutorial_3D.current.md">Current Markdown</a></p><div class="diff-scroll">{table}</div></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}</section>
<footer><p>The paired figure is an existing native museum illustration from 23 September with matched camera poses and separate console insets. This is a writing pass, with no new scene or headset test. <a href="/book-review/doc/book/iterations/2026-09-23-array-entered-address/index.html">Earlier illustration and desktop journey evidence</a>.</p><p><a href="checks.json">Publication checks</a> · <a href="http-checks.json">Served-file checks</a> · <a href="array_tutorial-book.manifest.json">Capture source manifest</a></p><p>Next: <a href="/compose/sources?map=Tutorial_Tiling_Floor&amp;doc=final">A rule underfoot</a>.</p></footer>
</main></body></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'words':{'before':len(old.split()),'after':len(new.split())},'scope':'Prose revision, unchanged map and artifact sources, existing native museum illustration, current five-hall capture. No new runtime or headset test.'},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'url':URL+'#reading','checks':len(checks),'words':{'before':len(old.split()),'after':len(new.split())}},indent=2))
