from pathlib import Path
import json,hashlib,difflib,html,markdown,urllib.request,re
ROOT=Path(__file__).resolve().parents[4]; B=Path(__file__).resolve().parent
maps=['Randomness_10_PRINT_Algorithm','Random_Cubes','Noise_Perlin_Simplex','CA_Introduction']
changed=[]
for f in json.loads((B/'snapshot-files.json').read_text(encoding='utf-8')):
 old=B/'before'/f;live=ROOT/f
 if old.read_bytes()==live.read_bytes():continue
 changed.append(f)
 target=B/'after'/f;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(live.read_bytes())
 delta=''.join(difflib.unified_diff(old.read_text(encoding='utf-8-sig').splitlines(True),live.read_text(encoding='utf-8-sig').splitlines(True),fromfile='before/'+f,tofile=f))
 diff=B/'diffs'/(f+'.diff');diff.parent.mkdir(parents=True,exist_ok=True);diff.write_text(delta,encoding='utf-8')
for f in ['algorithms/cellularautomata/ca_showcase/line_network_history.gd']+['commons/maps/'+m+'/encounter-notes.md' for m in maps]:
 changed.append(f);target=B/'after'/f;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes((ROOT/f).read_bytes())
(B/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
(B/'source-hashes.json').write_text(json.dumps({f:hashlib.sha256((ROOT/f).read_bytes()).hexdigest() for f in changed},indent=2)+'\n',encoding='utf-8')
render_count=0
def md(s):
 global render_count
 render_count+=1
 rendered=markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
 return re.sub(r'(id="|href="#)(fn[^" ]*)',lambda m:m.group(1)+'render'+str(render_count)+'-'+m.group(2),rendered)
css='*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f3f0e9;color:#242a2b;font-family:Georgia,serif;line-height:1.7}header,main{max-width:1160px;margin:auto;padding:2rem}header{padding-top:4rem}h1,h2,h3,nav,.meta{font-family:system-ui,sans-serif;line-height:1.2}header h1{font-size:clamp(2.2rem,5vw,4rem);max-width:850px;margin:.4em 0}a{color:#266b67}nav{display:flex;flex-wrap:wrap;gap:1rem;padding:1.2rem 0}nav a{padding:.65rem .9rem;border:1px solid #b6c4bf;border-radius:99px;text-decoration:none;font-size:.85rem}section{padding:2rem 0 3rem;border-top:1px solid #bcc5be;scroll-margin-top:1rem}.reading{max-width:740px;margin:2rem auto;font-size:1.13rem}.reading h1{font-size:2rem}.reading p{margin:1.25em 0}.pair,.compare{display:grid;grid-template-columns:1fr 1fr;gap:1.4rem}.pair img{width:100%;display:block}figure{margin:0}figcaption,.meta{font-size:.82rem;line-height:1.5;color:#536362}details{background:#e9e9df;padding:1rem;margin:1rem 0}summary{cursor:pointer;font-family:system-ui,sans-serif}.compare{font-size:.88rem;max-height:900px;overflow:auto;padding:1rem}.compare>div{min-width:0}pre{overflow:auto;padding:1rem;background:#e3e6df;font-size:.85rem}code{font-family:Consolas,monospace}table{border-collapse:collapse}td,th{padding:.6rem;border-bottom:1px solid #bbc5bf;text-align:left}.pill{font-family:system-ui,sans-serif;font-size:.83rem;background:#dce8df;padding:.5rem .8rem;display:inline-block;border-radius:4px}footer{padding:3rem 0;font-size:.9rem}@media(max-width:750px){.pair,.compare{grid-template-columns:1fr}header,main{padding:1.2rem}.reading{font-size:1.08rem}}'
nav=''.join('<a href="#'+m+'">'+html.escape(m.replace('_',' '))+'</a>' for m in maps)
page=['<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Let the encounter carry it</title><style>'+css+'</style><header><p class="meta">ADA RESEARCH / 24 SEPTEMBER 2026 / SECOND PASS</p><h1>Let the encounter carry it.</h1><p>Four focused revisions after Claude’s handback. The drawings gain room to act; the chapters leave more room to read.</p><span class="pill">Canonical final.md updated · 31 room records integrated</span><nav>'+nav+'</nav><p class="meta">30 new native checks and five existing gates pass. Headset verification remains open.</p></header><main>']
counts=json.loads((B/'word-counts.json').read_text())
for m in maps:
 before=(B/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8-sig');after=(ROOT/'commons/maps'/m/'final.md').read_text(encoding='utf-8-sig')
 page.append('<section id="'+m+'"><h2>'+html.escape(m.replace('_',' '))+'</h2><p class="meta">'+str(counts[m]['before'])+' → '+str(counts[m]['after'])+' words · <a href="/compose/sources?map='+m+'&amp;doc=final">Current source</a> · <a href="diffs/commons/maps/'+m+'/final.md.diff">Exact diff</a></p>')
 if m=='Noise_Perlin_Simplex':
  page.append('<div class="pair"><figure><img src="noise-relief.png" alt="Two noise fields expressed as relief"><figcaption>Relief, after choosing new seeds.</figcaption></figure><figure><img src="noise-plate.png" alt="The same fields as flat colour arrangements"><figcaption>VIEW keeps those fields. Only their expression changes.</figcaption></figure></div>')
 if m=='CA_Introduction':
  page.append('<div class="pair"><figure><img src="network-early.png" alt="First retained network stage"><figcaption>The first saved stage waits for arrival.</figcaption></figure><figure><img src="network-grown.png" alt="The full retained network"><figcaption>Twenty saved stages later. Earlier lines retain their places.</figcaption></figure></div><p class="meta">Native studio captures of production artifacts; these are not new museum or headset photographs.</p>')
 page.append('<article class="reading">'+md(after)+'</article><details><summary>Before / after — read alongside</summary><div class="compare"><div><h3>Claude’s delivery</h3>'+md(before)+'</div><div><h3>This pass</h3>'+md(after)+'</div></div></details></section>')
page.append('<section id="integration">'+md((B/'DECISIONS.md').read_text(encoding='utf-8'))+'<p><a href="native-checks.json">30 new checks</a> · <a href="claude-gates.json">Five retained gates</a> · <a href="changed-files.json">Changed files</a> · <a href="validation.json">Publication checks</a></p></section><footer><a href="../2026-09-24-claude-randomness-onwards/HANDBACK.md">Claude’s full handback</a> remains the detailed first-pass record.</footer></main></html>')
(B/'index.html').write_text(''.join(page),encoding='utf-8')
print('Published',len(changed),'changed/new production files')
