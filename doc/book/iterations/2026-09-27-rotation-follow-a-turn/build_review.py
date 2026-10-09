from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
MAP='Trans_Rotation';PREFIX='commons/maps/'+MAP+'/'
URL='http://localhost:3003/book-review/doc/book/iterations/'+HERE.name+'/index.html'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
old=read(HERE/'before'/PREFIX/'final.md');new=read(ROOT/PREFIX/'final.md')
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 assert ok,name
anchors=lambda s:re.findall(r'<!--.*?-->',s)
check('All encounter and transition markers kept in order',anchors(old)==anchors(new))
code=lambda s:re.findall(r'```gdscript(.*?)```',s,re.S)
check('Four retained code excerpts are unchanged',len(code(new))==4 and code(new)==[code(old)[i] for i in [0,1,3,4]])
figures=lambda s:re.findall(r'!\[[^\]]*\]\(([^)]+)\)',s)
check('Both shared museum figures retained',len(figures(new))==2 and figures(new)==figures(old))
for url in figures(new):
 path=ROOT/url.removeprefix('/book-review/')
 with Image.open(path) as im: im.verify()
 check('Readable figure: '+path.name,True)
for rel,digest in json.loads(read(HERE/'baseline.json')).items():
 if rel not in [PREFIX+'final.md','commons/data/museum_core_encounters.json']:check('Preserved '+rel,sha(ROOT/rel)==digest)
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))['rooms'][MAP]
old_core=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'))['rooms'][MAP]
check('Curatorial text hash current',core['text_sha256']==sha(ROOT/PREFIX/'final.md'))
check('Curatorial review points here',core['local_review']==URL+'#reading')
check('Other hall metadata preserved',{k:v for k,v in core.items() if k not in ['text_sha256','local_review']}=={k:v for k,v in old_core.items() if k not in ['text_sha256','local_review']})
manifest=json.loads(read(ROOT/'doc/book/captures/transformation/transformation-book.manifest.json'))
check('Seven-hall capture current',len(manifest['maps'])==7 and all(sha(ROOT/r['path'])==r['sha256'] for r in manifest['maps']))
check('Capture matches manifest',sha(ROOT/'doc/book/captures/transformation/transformation-book.md')==manifest['output_sha256'])
for name in ['transformation-book.md','transformation-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/transformation'/name,HERE/name)
shutil.copy2(ROOT/PREFIX/'final.md',HERE/'current-final.md')
(HERE/'final.md.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/final.md',tofile='current/final.md')),encoding='utf-8')
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-27-crossing-the-gap/index.html'),re.S).group(1)
diff=difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(),new.splitlines(),'Before this pass','Current final.md',context=True,numlines=3)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Rotation — follow a turn</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TRANS_ROTATION · 27 SEPTEMBER 2026 · WRITING PASS</p><h1>Follow a turn.</h1><p>A platform carries you. A tilted row meets your feet. A marked face goes around the corner. Follow what moves, and see what counts as coming back.</p><nav><a href="#reading">Read the chapter</a><a href="#changes">Before / after</a><a href="#decisions">Decisions</a><a href="transformation-book.md">Full Transformation capture</a></nav></header>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Trans_Rotation&amp;doc=final">READ AND COMMENT IN SOURCES</a></p>{render(new)}</article>
<section id="changes"><h2>Before and after</h2><p>{len(old.split()):,} → {len(new.split()):,} words, including code and captions. All six encounters remain. <a href="final.md.diff">Plain text diff</a> · <a href="current-final.md">Revised Markdown</a></p><div class="diff-scroll">{diff}</div></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}</section>
<footer><p>The two figures are existing native museum captures from 23 September, reused for this writing pass. No scene or interaction changes and no new runtime or headset test.</p><p><a href="checks.json">Source and publication checks</a> · <a href="/book-review/doc/book/iterations/2026-09-23-rotation-return-and-sweep/report.json">Earlier native illustration checks</a> · <a href="/book-review/doc/book/iterations/2026-09-25-private-writing-notes/index.html#Trans_Rotation">Private encounter note</a> · <a href="/compose/sources?map=Trans_Rotation&amp;doc=technical">Technical companion</a></p><p>Next: <a href="/compose/sources?map=Trans_Scale&amp;doc=final">A door, at last</a>.</p></footer>
</main></body></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'scope':'Source preservation, manuscript routing, existing image validity and capture freshness. No new runtime or headset test.','private_notes':'All 203 notes present. Existing Point_Zero/Point_One format and grounding warnings remain; no Rotation warning.'},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'url':URL+'#reading','checks':len(checks),'words_before':len(old.split()),'words_after':len(new.split())},indent=2))
