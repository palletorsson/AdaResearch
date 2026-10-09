from pathlib import Path
import difflib,hashlib,json,re,shutil
import markdown
root=Path(__file__).resolve().parents[4];out=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
render=lambda s:markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
source=root/'commons/maps/Trans_Introduction/final.md'
old=read(out/'before/commons/maps/Trans_Introduction/final.md');new=read(source)
report=json.loads(read(out/'report.json'));assert report['passed']
for name in ['final.md','intent.md','map_data.json','summary.md','tutorial.md','critical.md']:
 p=root/'commons/maps/Trans_Introduction'/name
 shutil.copy2(p,out/('current-'+name))
 (out/(name+'.diff')).write_text(''.join(difflib.unified_diff(read(out/'before/commons/maps/Trans_Introduction'/name).splitlines(True),read(p).splitlines(True),fromfile='before/'+name,tofile='current/'+name)),encoding='utf-8')
manifest=json.loads(read(root/'doc/book/captures/transformation/transformation-book.manifest.json'))
assert all(hashlib.sha256((root/x['path']).read_bytes()).hexdigest()==x['sha256'] for x in manifest['maps'])
for name in ['transformation-book.md','transformation-book.manifest.json']:shutil.copy2(root/'doc/book/captures/transformation'/name,out/name)
css=re.search(r'<style>(.*?)</style>',read(root/'doc/book/iterations/2026-09-27-crossing-the-gap/index.html'),re.S).group(1)
css+='\nfigure{margin:30px 0}figure img{display:block;width:100%;height:auto}figcaption{font:15px/1.6 system-ui;color:#4d554b;margin-top:10px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}.hero{margin:35px auto;max-width:1100px}@media(max-width:760px){.pair{grid-template-columns:1fr}}'
diff=difflib.HtmlDiff(wrapcolumn=62).make_table(old.splitlines(),new.splitlines(),'Before the spatial change','Current final.md',context=True,numlines=2)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Crossings — fire and a fitted bridge</title><style>{css}</style></head><body><main>
<header><p class="eyebrow">TRANS_INTRODUCTION · 27 SEPTEMBER 2026 · MUSEUM REVISION</p><h1>Fire below. Edges meet.</h1><p>The three basins burn beneath the crossings. The rotating plank is now three metres long, meeting the banks at its held quarter-turn.</p><nav><a href="#museum">Museum photographs</a><a href="#reading">Updated chapter</a><a href="#changes">Text changes</a><a href="#decisions">Decisions and checks</a><a href="transformation-book.md">Full Transformation capture</a></nav></header>
<section id="museum"><figure class="hero"><a href="rotation-eye-level.png"><img src="rotation-eye-level.png" alt="A three-metre orange plank joins the near floor to the blue landing above the glowing fire basin."></a><figcaption>At standing eye level inside the museum. The aligned plank stops at the floor edge; the fire remains below the supporting surface.</figcaption></figure>
<div class="pair"><figure><a href="bank-before.png"><img src="bank-before.png" alt="Earlier bridge extends onto the near floor above an empty basin."></a><figcaption>Earlier: 3.6 metres long, extending 30 cm onto each bank. Fire disabled.</figcaption></figure><figure><a href="bank-at-crossing.png"><img src="bank-at-crossing.png" alt="Shortened bridge meets the banks above the burning basin."></a><figcaption>Now: 3 metres long, meeting edges. Existing basin fire restored.</figcaption></figure></div>
<figure class="hero"><a href="bank-gap.png"><img loading="lazy" src="bank-gap.png" alt="The landing has moved one metre away from the unchanged plank."></a><figcaption>Moving the bank now opens a full one-metre gap. RESET brings its edge back to the plank.</figcaption></figure></section>
<article id="reading" class="reading"><p class="eyebrow">CURRENT FINAL.MD · <a href="/compose/sources?map=Trans_Introduction&amp;doc=final">READ AND COMMENT IN SOURCES</a></p>{render(new)}</article>
<section id="changes"><h2>Text follows the changed crossing</h2><p><a href="final.md.diff">Plain text diff</a> · <a href="tutorial.md.diff">Companion measurements</a></p><div class="diff-scroll">{diff}</div></section>
<section id="decisions" class="decisions">{render(read(out/'DECISIONS.md'))}</section>
<footer><a href="report.json">35 native checks</a> · <a href="engine-log.txt">Engine log</a> · <a href="fire-under-the-ferry.png">Fire below the ferry</a><p>The screenshots come from the production museum in an isolated desktop run. The bridge is held at its quarter-turn for comparison; normal play retains its movement and four-second pauses. No headset test was performed.</p></footer>
</main></body></html>'''
(out/'index.html').write_text(page,encoding='utf-8')
records={}
for rel in ['commons/maps/Trans_Introduction/map_data.json','commons/maps/Trans_Introduction/final.md','commons/scenes/mapobjects/rotation_cube.gd','commons/artifacts/adjustable_landing/adjustable_landing.gd','tools/probes/introduction_fire_and_fit.gd']:
 records[rel]=hashlib.sha256((root/rel).read_bytes()).hexdigest()
(out/'current-sha256.json').write_text(json.dumps(records,indent=2)+'\n',encoding='utf-8')
print('Built review with fresh museum photographs, manuscript diff and verified seven-hall capture.')