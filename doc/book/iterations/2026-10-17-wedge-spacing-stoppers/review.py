from pathlib import Path
import json,shutil,html
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent
MAP=ROOT/'commons/maps/Primitives_Polythedra'
RUN=ROOT/'ada_run/encounter_pilot/Primitives_Polythedra/wedge-spacing-stoppers-v2'
report=json.loads((RUN/'report.json').read_text(encoding='utf-8'))
assert report['passed'] and report['observations']['gap_between_ramp_upper_edges_m']==3.0
old=json.loads((HERE/'before/commons/data/museum/em_plan.json').read_text(encoding='utf-8-sig'))
new=json.loads((ROOT/'commons/data/museum/em_plan.json').read_text(encoding='utf-8-sig'))
changed=[b.get('map') for a,b in zip(old['plans'],new['plans']) if a!=b]
assert len(old['plans'])==len(new['plans']) and changed==['Primitives_Polythedra']
assert {k:v for k,v in old.items() if k!='plans'}=={k:v for k,v in new.items() if k!='plans'}
m=json.loads((MAP/'map_data.json').read_text(encoding='utf-8'))
assert m['layers']['structure']==m['layers']['museum']
assert sum(t=='2' for row in m['layers']['structure'] for t in row)==12
assert sum(t.startswith('wp:') for row in m['layers']['utilities'] for t in row)==7
assert sum(t.startswith('prism_block:') for row in m['layers']['interactables'] for t in row)==2
assert sum(t.startswith('street_sign:') for row in m['layers']['interactables'] for t in row)==4
before=json.loads((HERE/'before/commons/maps/Primitives_Polythedra/map_data.json').read_text(encoding='utf-8'))
for z in list(range(24))+list(range(32,46)):
    assert all(m['layers'][k][z]==before['layers'][k][z] for k in m['layers'])
checks={'passed':True,'changed_plan_rows':changed,'checks':['Only Polythedra plan row changed','Other plan metadata preserved','Museum/structure agree','12 raised cells','7 wp units','2 prism stoppers','4 signs','Other map regions preserved'],'measured_gap_m':3.0}
(HERE/'data-checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
native=HERE/'native';native.mkdir(exist_ok=True)
for name in ['standing-stoppers.png','three-metre-landing.png','route-overview.png','report.json','source_manifest.json','engine.log']:
    shutil.copy2(RUN/name,native/name)
after=HERE/'after';after.mkdir(exist_ok=True);(after/'.gdignore').touch()
for name in ['map_data.json','final.md','tutorial.md','technical.md','summary.md','artifacts.md','intent.md']:
    shutil.copy2(MAP/name,after/name)
summary='''# Three metres between the ramps; standing wedge stoppers

The raised landing is now three metres across between the facing ramps' upper ends, and four metres deep. Both approaches remain two metres wide, with a one-metre rise over a two-metre run. The far descent is three metres wide and stays centred.

Two existing upright prism blocks now stand before the approaches, at (5, 24) and (13, 24). Each is two metres tall. Their triangular ends physically block a straight walk; the route continues around the outside and up the ramps. The STOP and arrow signs remain. The right detour also clears the existing monitor.

The geometry therefore offers two uses of a wedge: first an obstruction to go around, then a supporting surface to go up. This revision interprets “gap” as the raised landing between the ramp heads, not an empty pit or a lower passage.

63/63 runtime checks pass, including an exact native measurement of 3.0 m, both straight approaches meeting the stoppers, both detours, both ascents, the descent, rock room and exit approach. Eight scoped data checks pass; only this museum plan row changed. The first right-side test ran into the monitor; the passing route moves outside its case. No artifact code changed in this revision. Pathfinder has no failures; warnings remain for the existing edge teleporter convention and enclosed rock spawner. Runtime has existing renderer/registry warnings but no engine errors.

Updated final, tutorial, technical reference, summary, intent and inventory. Native screenshots and before/after sources are retained. Headset comfort, Quest performance and the unprompted reading of the route remain human tests. No commit or push requested.
'''
(HERE/'summary.md').write_text(summary,encoding='utf-8')
style='''*{box-sizing:border-box}body{margin:0;background:#f7f3eb;color:#28342f;font:18px/1.65 system-ui,sans-serif}main{max-width:1160px;margin:auto;padding:36px}h1{font:clamp(36px,5vw,58px)/1.1 Georgia,serif;max-width:900px}h2{font:32px Georgia,serif;margin-top:40px}.kicker{color:#5a6d62;text-transform:uppercase;letter-spacing:.1em;font-size:14px}.lead{font-size:23px;max-width:65ch}a{color:#176c55}figure{margin:30px 0}img{width:100%;border-radius:8px}figcaption{font-size:16px;color:#52665a}.receipt{background:#e2eddf;border-left:5px solid #4a795c;padding:18px}.text{max-width:76ch;font:21px/1.65 Georgia,serif}nav{display:flex;gap:20px;flex-wrap:wrap;border-block:1px solid #d6cfc1;padding:12px 0}code{font-size:.9em}@media(max-width:700px){main{padding:22px}}'''
final=(MAP/'final.md').read_text(encoding='utf-8')
passage=final[final.index('Two upright prisms'):final.index('<!-- @concrete_barrier -->')]
passage=passage.replace('<!-- @wedge_palace -->','').strip()
paras=''.join('<p>'+html.escape(p)+'</p>' for p in passage.split('\n\n') if p.strip())
page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Three metres and two stoppers · Ada Research</title><style>{style}</style><main>
<div class="kicker">Polythedra · 17 October 2026</div><h1>Three metres and two stoppers</h1><p class="lead">The facing ramps meet a three-metre-wide landing. Before either climb, an upright wedge makes the walking body go around.</p>
<nav><a href="#stoppers">Standing wedges</a><a href="#gap">The gap</a><a href="#text">Revised passage</a><a href="summary.md">Saved summary</a><a href="../2026-10-17-wedge-corridors/index.html">Previous version</a></nav>
<section id="stoppers"><h2>A wedge that redirects the walk</h2><p>Two existing <code>prism_block</code> objects, scaled to two metres, stand before the approaches. Their triangular ends stop a straight walk. There is space to go around the outside, then turn into either ramp corridor. STOP and direction signs remain at the wall.</p><figure><img src="native/standing-stoppers.png" alt="Two upright prism stoppers before the STOP sign and ramp approaches"><figcaption>Actual Godot capture. The stoppers retain the existing prism mesh and physical collider.</figcaption></figure></section>
<section id="gap"><h2>Three metres across the raised landing</h2><p>The upper edges of the facing ramps are exactly <strong>3.0 metres apart</strong>, measured in the loaded Godot scene. That gap is filled by the level structure-2 landing. The platform is now 3 × 4 metres, still one metre above the normal floor. Both approaches remain two metres wide; the far descent is centred and three metres wide.</p><figure><img src="native/three-metre-landing.png" alt="Native overhead view of the two facing ramps and three metre landing"><figcaption>The flat span between the two red-edged ramp heads is three metres. This is a raised landing, rather than a lower passage or an empty pit.</figcaption></figure></section>
<h2>Walking checks</h2><div class="receipt"><strong>63/63 runtime checks pass.</strong> Exact spacing; both stoppers blocking straight movement; both detours and ascents; descent; blocked flat bypasses; rock room and exit access. Eight scoped data checks pass.</div><p>The first right-hand test crossed the existing monitor's case. The passing path goes outside it. The level geometry did not need an invisible blocker or a new collider. Only this hall's museum plan row changed.</p><p>Headset comfort and whether the route reads naturally still need a wearer trial. Existing renderer and registry warnings remain; no engine errors were reported. Pathfinder warnings concern the old edge teleporter convention and enclosed rock spawner.</p><p><a href="native/report.json">Runtime receipt</a> · <a href="data-checks.json">Data checks</a> · <a href="after/tutorial.md">Updated tutorial</a> · <a href="after/technical.md">Dimensions and placements</a></p>
<section id="text"><h2>The revised encounter</h2><div class="text">{paras}</div><p><a href="after/final.md">Complete current final text</a></p></section></main></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
print('Review, source copies and eight scoped data checks saved.')
