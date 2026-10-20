"""Package real museum captures and placement checks for review."""
from pathlib import Path
import collections, hashlib, html, json, shutil
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-tiling-placement'
notes={
 'Pattern_Foundry':('Room around the machines','Grouped the small editors near the entrance, separated the loom, mill and presses, and gave the eleven historical samples their own comparison area. The floor starts neutral so the machines’ outputs can be read. The architecture control can still cover the room.',['small-studies','machines','miniatures']),
 'Tutorial_Pattern':('Three plates, then a comparison','Spaced the three floor-and-source plates evenly. Raised the small editors and rear controls; levelled the obsolete internal partitions. The existing P1/PM comparison remains in its east bay.',['three-plates','small-studies','comparison-bay']),
 'Array_Patterns':('Small studies beside a walkable pattern','Raised the four tile editors, separated the specimen gallery from the other displays, and fitted the historical samples into a compact group. The tunnel, raised deck and access ramps remain. Embedded galleries now use the hall’s lighting.',['study-floor','small-studies','tunnel']),
 'Symmetry_Seventeen':('Compare the looms, then the makers','Arranged the looms and mills in distinct groups, opened the floor, and gave the nineteen credited atlas plates three accessible rows. Wallpaper stays on the walls; its overlays now follow the wall axes instead of protruding into the room.',['looms','mills','atlas'])
}
summaries=[];sections=[]
def base(t):return t.split('#')[0].split(':')[0]
def inventory(d):return [(x,z,t) for z,row in enumerate(d['layers']['interactables']) for x,t in enumerate(row) if str(t).strip()]
for name,(title,body,shots) in notes.items():
 src=R/'ada_run/encounter_pilot'/name
 before=json.loads((O/'before'/name/'map_data.json').read_text(encoding='utf-8'))
 after=json.loads((R/'commons/maps'/name/'map_data.json').read_text(encoding='utf-8'))
 assert collections.Counter(base(t) for _,_,t in inventory(before))==collections.Counter(base(t) for _,_,t in inventory(after))
 report=json.loads((src/'tiling-placement-after/report.json').read_text(encoding='utf-8'))
 assert report['passed'],(name,report['failures'])
 target=O/'images'/name;target.mkdir(parents=True,exist_ok=True)
 for phase in ['before','after']:
  shutil.copy2(src/('tiling-placement-'+phase)/'above.png',target/(phase+'.png'))
 for shot in shots:shutil.copy2(src/'tiling-placement-after'/(shot+'.png'),target/(shot+'.png'))
 receipt=O/'evidence'/name;receipt.mkdir(parents=True,exist_ok=True)
 for file in ['report.json','engine.log','manifest.json','spec.json']:
  if (src/'tiling-placement-after'/file).exists():shutil.copy2(src/'tiling-placement-after'/file,receipt/file)
 rows=report['observations']['approaches'];assert all(a['clear'] and a['supported'] for a in rows)
 summaries.append({'map':name,'authored_exhibits':len(inventory(after)),'checks':len(report['checks']),'approach_samples':len(rows),'passed':True,'old':inventory(before),'new':inventory(after)})
 sections.append(f'''<section id="{name}"><header><p class="eyebrow">{html.escape(name.replace('_',' '))}</p><h2>{title}</h2><p>{body}</p><p class="receipt">{len(inventory(after))} exhibits retained · {len(report['checks'])} native checks passed · {len(rows)} supported, clear approach samples</p></header>
 <div class="pair"><figure><img loading="lazy" src="images/{name}/before.png" alt="{name} before, viewed from above"><figcaption>Before</figcaption></figure><figure><img loading="lazy" src="images/{name}/after.png" alt="{name} after, same overview camera"><figcaption>After · same camera</figcaption></figure></div>
 <div class="details">{''.join(f'<a href="images/{name}/{s}.png"><img loading="lazy" src="images/{name}/{s}.png" alt="{s.replace("-"," ")}"><span>{s.replace("-"," ")}</span></a>' for s in shots)}</div>
 <p><a href="evidence/{name}/report.json">Read the native checks</a></p></section>''')
total=sum(x['checks'] for x in summaries);approaches=sum(x['approach_samples'] for x in summaries)
(O/'changes.json').write_text(json.dumps({'maps':summaries,'all_authored_exhibits_preserved':True,'checks':total,'approach_samples':approaches,'scope':'Placement, display coverage, miniature spacing and embedded lighting. Tutorial and reflective prose unchanged. No headset acceptance test.'},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tiling — space to compare</title><style>
*{box-sizing:border-box}body{margin:0;background:#f3f1eb;color:#25272c;font:17px/1.55 system-ui,sans-serif}main{max-width:1440px;margin:auto;padding:40px 3vw}h1{font-size:clamp(36px,5vw,68px);line-height:1.08;margin:12px 0 24px;letter-spacing:-.04em}h2{font-size:32px;line-height:1.2;margin:8px 0 16px}p{max-width:850px}.eyebrow{font-size:12px;letter-spacing:.15em;text-transform:uppercase;color:#655974;font-weight:750}.receipt{font-size:14px;color:#35614b}nav{display:flex;gap:12px;flex-wrap:wrap;padding:18px 0 28px}a{color:#4c3d71;text-underline-offset:4px}nav a{border:1px solid #c3bdce;padding:7px 12px;border-radius:20px;text-decoration:none;font-size:14px}section{padding:36px 0 24px;border-top:1px solid #ccc6bd}figure{margin:0}img{width:100%;display:block}figcaption{padding:8px 0 20px;font-size:14px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}.details{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}.details a{text-decoration:none}.details span{display:block;padding:7px 0;font-size:14px}footer{border-top:1px solid #ccc6bd;margin-top:35px;padding:20px 0;font-size:14px}@media(max-width:700px){.pair,.details{grid-template-columns:1fr}}
</style><main><p class="eyebrow">Endless Museum · 9 October 2026 · spatial revision</p><h1>Space to compare.</h1><p>The small source, the repeated pattern, and the machine that joins them need room to be seen together. Four Tiling halls now have clearer groups, raised editors, and open approaches. Every authored exhibit remains.</p>'''
page+=f'<p class="receipt">56 authored exhibits retained · {total} native checks passed · {approaches} floor-and-clearance samples</p><nav>'+''.join(f'<a href="#{name}">{name.replace("_"," ")}</a>' for name in notes)+'</nav>'
page+=''.join(sections)
page+='''<footer><p>Surveyed all nine Tiling halls. This pass changes Pattern Foundry, Tutorial Pattern, Array Patterns and Symmetry Seventeen. Pattern Disco, Pattern Temple and the three Ribbon halls keep their existing arrangements.</p><p>Images are captures of the actual Godot museum. Tests check exhibit presence, editor height, world-space cell lookup, miniature construction and sampled standing clearance. They do not certify every route, physical controller use or comfort in a headset. Existing UID / viewport-texture diagnostics remain in the engine logs.</p><p>Pattern generation and tutorial subjects are retained. Presentation changes add opt-in wall coverage and shared museum lighting for embedded galleries. The next tutorial-writing step remains Array Patterns.</p><a href="changes.json">Placement record</a></footer></main></html>'''
(O/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'halls':4,'exhibits':56,'checks':total,'approaches':approaches,'report':str(O/'index.html')}))
