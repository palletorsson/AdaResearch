from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).resolve().parent
MAP='Trans_Translation';PREFIX='commons/maps/'+MAP+'/'
URL='http://localhost:3003/book-review/doc/book/iterations/'+HERE.name+'/index.html'
read=lambda p:p.read_text(encoding='utf-8-sig')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
render=lambda s:markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
old=read(HERE/'before'/PREFIX/'final.md');new=read(ROOT/PREFIX/'final.md')
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 assert ok,name
check('Named encounters kept in order',re.findall(r'<!--.*?-->',old)==re.findall(r'<!--.*?-->',new))
code=r'```gdscript(.*?)```'
check('All three code excerpts preserved',len(re.findall(code,new,re.S))==3 and re.findall(code,old,re.S)==re.findall(code,new,re.S))
check('Existing shared illustration preserved',re.findall(r'!\[[^\]]*\]\(([^)]+)\)',old)==re.findall(r'!\[[^\]]*\]\(([^)]+)\)',new))
check('Hand and accepted trace distinction preserved','Your hand can propose a diagonal and leave a vertical line.' in new)
check('Return to collected pickup preserved','The carrier can repeat the journey; the cube is gone.' in new)
check('Rotation handover unchanged',old.rsplit('<!-- @ -->',1)[1]==new.rsplit('<!-- @ -->',1)[1])
for rel,digest in json.loads(read(HERE/'baseline.json')).items():
 if rel not in [PREFIX+'final.md','commons/data/museum_core_encounters.json']:check('Preserved '+rel,sha(ROOT/rel)==digest)
d=json.loads(read(ROOT/PREFIX/'map_data.json'))
utilities=[c for row in d['layers']['utilities'] for c in row if c.startswith('tc:')]
pickups=[c for row in d['layers']['interactables'] for c in row if c.startswith('pick_up_cube:')]
doors=[c for row in d['layers']['interactables'] for c in row if c.startswith('translation_cube_demo:')]
check('Seven rides remain',len(utilities)==7)
check('Thirteen pickups bob and collect',len(pickups)==13 and all('#motion:slide#hold:collect' in c for c in pickups))
check('Two different traced door studies remain',len(doors)==2 and any('#course:lift_lateral#guide:rail' in c for c in doors) and any('#course:free#guide:ghost' in c for c in doors) and all('#trace:on' in c for c in doors))
core=json.loads(read(ROOT/'commons/data/museum_core_encounters.json'))['rooms'][MAP]
check('Curatorial text hash current',core['text_sha256']==sha(ROOT/PREFIX/'final.md'))
check('Curatorial review points here',core['local_review']==URL+'#reading')
manifest=json.loads(read(ROOT/'doc/book/captures/transformation/transformation-book.manifest.json'))
check('Seven-hall capture current',len(manifest['maps'])==7 and all(sha(ROOT/r['path'])==r['sha256'] for r in manifest['maps']))
check('Capture matches manifest',sha(ROOT/'doc/book/captures/transformation/transformation-book.md')==manifest['output_sha256'])
for name in ['transformation-book.md','transformation-book.manifest.json']:shutil.copy2(ROOT/'doc/book/captures/transformation'/name,HERE/name)
shutil.copy2(ROOT/PREFIX/'final.md',HERE/'current-final.md')
(HERE/'final.md.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/final.md',tofile='current/final.md')),encoding='utf-8')
css=re.search(r'<style>(.*?)</style>',read(ROOT/'doc/book/iterations/2026-09-27-crossing-the-gap/index.html'),re.S).group(1)
css+='\nfigure{max-width:980px;margin:45px auto}figure img{width:100%;height:auto;display:block}figcaption{font:14px/1.7 system-ui;color:#4d554b;margin-top:10px}'
diff=difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(),new.splitlines(),'Before this pass','Current final.md',context=True,numlines=3)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Translation — journeys and permitted paths</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TRANS_TRANSLATION · 27 SEPTEMBER 2026 · WRITING PASS</p><h1>Travel, then try a different way.</h1><p>Seven carriers take you through the hall. At the final terrace, the journey returns to your hand: two mechanisms can reach the same destination while admitting different paths.</p><nav><a href="#reading">Read the chapter</a><a href="#museum">The terrace</a><a href="#changes">Before / after</a><a href="#decisions">Decisions</a><a href="transformation-book.md">Full Transformation capture</a></nav></header>
<figure id="museum"><a href="translation-exit-terrace.png"><img src="translation-exit-terrace.png" alt="Two pairs of red and blue doors on plinths at the museum exit terrace, with rails on one mechanism and translucent destination panels on the other."></a><figcaption>Existing native museum photograph, 23 September. Two mechanisms, each with a pair of doors. The scene and placements are unchanged by this writing pass; this is not a new capture.</figcaption></figure>
<article class="reading" id="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Trans_Translation&amp;doc=final">READ AND COMMENT IN SOURCES</a></p>{render(new)}</article>
<section id="changes"><h2>Before and after</h2><p><a href="final.md.diff">Plain text diff</a></p><div class="diff-scroll">{diff}</div></section>
<section class="decisions" id="decisions">{render(read(HERE/'DECISIONS.md'))}</section>
<footer><p><a href="checks.json">This pass: source and publication checks</a> · <a href="/book-review/doc/book/iterations/2026-09-23-translation-paths/report.json">Earlier native door-study checks</a> · <a href="/book-review/doc/book/iterations/2026-09-25-private-writing-notes/index.html#Trans_Translation">Private encounter note</a> · <a href="/compose/sources?map=Trans_Translation&amp;doc=technical">Technical companion</a></p><p>This pass changes prose. Existing illustrations and earlier runtime evidence are retained; no new engine or headset test was performed.</p></footer>
</main></body></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'checks.json').write_text(json.dumps({'passed':True,'checks':checks,'scope':'Source preservation, authored placements, manuscript structure and capture freshness. No new runtime or headset test.'},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'url':URL+'#reading','checks':len(checks),'words_before':len(old.split()),'words_after':len(new.split())},indent=2))