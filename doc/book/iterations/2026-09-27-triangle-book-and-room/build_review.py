from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
from PIL import Image
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
MAP='Point_Triangle_Context';REL=Path('commons/maps')/MAP/'final.md'
URL='http://localhost:3003/book-review/doc/book/iterations/'+HERE.name+'/index.html'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
old=read(HERE/'before'/REL);new=read(ROOT/REL);addition=read(HERE/'inserted-passage.md').strip()
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)});assert ok,name
check('Only the recorded passage was inserted',new.replace('\n\n'+addition,'',1)==old)
for rel,digest in json.loads(read(HERE/'baseline.json')).items():
 if rel not in [REL.as_posix(),'commons/data/museum_core_encounters.json']:check('Preserved '+rel,sha(ROOT/rel)==digest)
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))['rooms'][MAP]
before_core=json.loads(read(HERE/'before/commons/data/museum_core_encounters.json'))['rooms'][MAP]
check('Text hash current',core['text_sha256']==sha(ROOT/REL))
check('Review reference current',core['local_review']==URL+'#reading')
check('Other hall metadata preserved',{k:v for k,v in core.items() if k not in ['text_sha256','local_review']}=={k:v for k,v in before_core.items() if k not in ['text_sha256','local_review']})
manifest=json.loads(read(ROOT/'doc/book/captures/primitives/primitives-book.manifest.json'))
check('All eleven Primitives manuscripts current',len(manifest['maps'])==11 and all(sha(ROOT/m['path'])==m['sha256'] for m in manifest['maps']))
check('Capture output matches manifest',sha(ROOT/'doc/book/captures/primitives/primitives-book.md')==manifest['output_sha256'])
for name in ['primitives-book.md','primitives-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/primitives'/name,HERE/name)
shutil.copy2(ROOT/REL,HERE/'current-final.md')
(HERE/'final.md.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/final.md',tofile='current/final.md')),encoding='utf-8')
photo='/book-review/doc/book/iterations/2026-09-23-triangle-illustration/triangle-plate-in-hall.jpg'
for url in re.findall(r'!\[[^\]]*\]\(([^)]+)\)',new)+[photo]:
 with Image.open(ROOT/url.removeprefix('/book-review/')) as im:im.verify()
 check('Readable image '+url.rsplit('/',1)[-1],True)
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-27-rotation-follow-a-turn/index.html'),re.S).group(1)
css+='figure{max-width:900px;margin:40px auto}figure img{display:block;width:100%;height:auto}figcaption{font:14px/1.7 system-ui;color:#50574d;margin-top:10px}.insertion{max-width:760px;margin:45px auto;padding-left:22px;border-left:3px solid #9b5381}'
diff=difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(),new.splitlines(),'Before','Current final.md',context=True,numlines=3)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Triangle — the book and the room</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">POINT_TRIANGLE_CONTEXT · 27 SEPTEMBER 2026 · 97 WORDS ADDED</p><h1>The book and the room.</h1><p>A short disclosure beside the shared triangle illustration: this explanation acquired a place inside the museum while we were writing it.</p><nav><a href="#insertion">New passage</a><a href="#reading">Read in context</a><a href="#changes">Exact diff</a><a href="#decisions">Decision</a><a href="primitives-book.md">Full Primitives capture</a></nav></header>
<section class="insertion" id="insertion">{render(addition)}</section>
<figure><a href="{photo}"><img src="{photo}" alt="The three-stage triangle construction plate installed on a wall inside the museum."></a><figcaption>The construction in the museum. Existing native capture, 23 September. The book figure below renders the same scene with its stand hidden.</figcaption></figure>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map={MAP}&amp;doc=final">READ AND COMMENT</a></p>{render(new)}</article>
<section id="changes"><h2>Before and after</h2><p><a href="final.md.diff">Plain text diff</a> · <a href="current-final.md">Current Markdown</a></p><div class="diff-scroll">{diff}</div></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}</section>
<footer><p><a href="checks.json">Publication checks</a> · <a href="/book-review/doc/book/iterations/2026-09-23-triangle-illustration/SUMMARY.md">Original illustration provenance</a></p><p>Prose insertion only. Existing pictures are reused; no new scene or runtime test.</p></footer>
</main></body></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'scope':'Exact insertion, source preservation, current capture and readable existing images. No runtime changes or test.'},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'url':URL+'#insertion','added_words':len(addition.split()),'checks':len(checks)},indent=2))
