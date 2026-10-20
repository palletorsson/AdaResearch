from pathlib import Path
import json,shutil,html
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent
MAP=ROOT/'commons/maps/Primitives_Polythedra'
RUN=ROOT/'ada_run/encounter_pilot/Primitives_Polythedra/wedge-grid-route-v1'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
r=read(RUN/'report.json');assert r['passed']
assert r['observations']['left_clear_passage_m']==3.0 and r['observations']['right_clear_passage_m']==3.0
old=read(HERE/'before/commons/data/museum/em_plan.json');new=read(ROOT/'commons/data/museum/em_plan.json')
assert len(old['plans'])==len(new['plans'])
assert [b['map'] for a,b in zip(old['plans'],new['plans']) if a!=b]==['Primitives_Polythedra']
assert {k:v for k,v in old.items() if k!='plans'}=={k:v for k,v in new.items() if k!='plans'}
m=read(MAP/'map_data.json');before=read(HERE/'before/commons/maps/Primitives_Polythedra/map_data.json')
assert m['layers']['structure']==m['layers']['museum']
assert sum(t=='2' for row in m['layers']['structure'] for t in row)==48
assert sum(t.startswith('wp:') for row in m['layers']['utilities'] for t in row)==10
assert sum(t.startswith('prism_block:') for row in m['layers']['interactables'] for t in row)==5
assert sum(t.startswith('street_sign:') for row in m['layers']['interactables'] for t in row)==4
for z in list(range(23))+list(range(35,46)):
    assert all(m['layers'][k][z]==before['layers'][k][z] for k in m['layers'])
checks={'passed':True,'checks':['Only Polythedra plan row changed','Other plan metadata preserved','Structure/museum agree','48 raised cells','10 stock wp units','5 central stoppers','4 signs','Other map regions preserved'],'clear_side_passages_m':[3.0,3.0]}
(HERE/'data-checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
native=HERE/'native';native.mkdir(exist_ok=True)
for name in ['first-central-blockers.png','then-side-ramp.png','right-side-ramp.png','on-the-platform.png','grid-route-overview.png','far-descent.png','report.json','source_manifest.json','engine.log']:
    shutil.copy2(RUN/name,native/name)
after=HERE/'after';after.mkdir(exist_ok=True);(after/'.gdignore').touch()
for name in ['map_data.json','final.md','tutorial.md','technical.md','summary.md','artifacts.md','intent.md']:shutil.copy2(MAP/name,after/name)
summary='''# First around the centre, then up the sides

The central collection now comes first. Five standing two-metre prisms occupy an exact 10 × 2-cell bank across the middle of the hall. Three full grid columns remain clear at either side. STOP and a double arrow mark the bank.

The walk continues forward to wp ramps along both sides. Three stock wedges make each three-metre-wide approach, rising one metre over two metres in the direction of travel. Short inner walls hold the ramps beside the outer walls. Both arrive on the same 16 × 3 m structure-2 platform. A centred four-metre descent returns towards the basin and rock room.

This follows the clarification: a central stopper collection to walk around, then side climbing wedges onto a platform. It replaces the earlier layout of opposing ramps and a three-metre landing. The three metres now describe the clear side passages; they are measured from the actual loaded geometry.

78/78 native runtime checks pass: the central bank blocks a straight approach; both three-metre side passages, detours, ascents and descent work; the rock room and exit approach remain reachable. Eight scoped data checks pass. Only this map's museum plan row changed; no artifact runtime code changed. Pathfinder has no failures, retaining warnings for the old edge teleporter convention and enclosed rock spawner. The runtime log has existing renderer/registry warnings but no engine errors.

Final, tutorial, technical reference, summary, intent and inventory follow the corrected sequence. Before sources, after texts and native screenshots are retained here. Headset comfort, Quest performance and whether the obstruction-to-support progression reads naturally remain human trials. No commit or push requested.
'''
(HERE/'summary.md').write_text(summary,encoding='utf-8')
style='''*{box-sizing:border-box}body{margin:0;background:#f7f3eb;color:#26382f;font:18px/1.65 system-ui,sans-serif}main{max-width:1200px;margin:auto;padding:34px}h1{font:clamp(36px,5vw,58px)/1.15 Georgia,serif;max-width:1000px;margin:15px 0 20px}h2{font:31px Georgia,serif;margin-top:38px}.lead{font-size:23px;max-width:66ch}.kicker{font-size:14px;text-transform:uppercase;letter-spacing:.1em;color:#5e7265}img{width:100%;border-radius:8px}figure{margin:26px 0}figcaption{font-size:16px;color:#5e7265}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.proof{background:#e3edde;padding:18px;border-left:5px solid #42725c}nav{display:flex;flex-wrap:wrap;gap:24px;border-block:1px solid #d6cdbd;padding:12px 0}a{color:#176b53}.prose{font:20px/1.7 Georgia,serif;max-width:78ch}@media(max-width:740px){main{padding:20px}.pair{grid-template-columns:1fr}}'''
final=(MAP/'final.md').read_text(encoding='utf-8')
passage=final[final.index('Five upright prisms'):final.index('<!-- @concrete_barrier -->')].replace('<!-- @wedge_palace -->','').strip()
paras=''.join('<p>'+html.escape(p)+'</p>' for p in passage.split('\n\n') if p.strip())
page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>First around, then up · Ada Research</title><style>{style}</style><main><div class="kicker">Polythedra · grid route · 17 October 2026</div><h1>First around the centre.<br>Then up the sides.</h1><p class="lead">One central collection of standing wedges redirects the walk. Farther ahead, forward-facing wp ramps rise along both sides onto a shared platform.</p><nav><a href="#route">Grid arrangement</a><a href="#encounters">The two encounters</a><a href="#text">Revised passage</a><a href="summary.md">Saved summary</a></nav>
<section id="route"><figure><img src="native/grid-route-overview.png" alt="Overhead Godot view showing the central wedge collection followed by side ramps and a broad platform"><figcaption>Actual Godot capture. Enter from the bottom: around the central bank, up either side, across the platform, down towards the basin.</figcaption></figure><p>The five standing prisms occupy a 10 × 2-cell bank. Three grid columns remain clear on each side. The climbing wedges come afterwards, pointing forward. Their landing spans the hall: 16 metres across, three metres deep and one metre above the normal floor.</p><p>This replaces the opposing-ramp arrangement. The three metres are now clear floor passages beside the central collection.</p></section>
<section id="encounters"><h2>Obstruction first, support afterwards</h2><div class="pair"><figure><img src="native/first-central-blockers.png" alt="Five standing prisms form the central STOP collection"><figcaption>1. The central bank stops a straight walk. The side passages remain open.</figcaption></figure><figure><img src="native/then-side-ramp.png" alt="A wp ramp climbs forward between an inner and outer wall"><figcaption>2. A forward-facing side ramp carries the walk up onto the platform.</figcaption></figure></div><figure><img src="native/on-the-platform.png" alt="View across the shared raised platform"><figcaption>The two routes meet on one level surface. A centred far ramp descends towards the later encounters.</figcaption></figure></section>
<h2>What is verified</h2><div class="proof"><strong>78/78 native runtime checks pass.</strong> Grid-aligned bank footprints, three-metre passages, straight-route blocking, both detours and ascents, the shared landing, descent, rock-room access and exit approach. Eight scoped data checks pass.</div><p>The pathfinder has no failures; existing edge-teleporter and enclosed-rock-spawner warnings remain. The runtime log has existing renderer/registry warnings and no engine errors. Headset comfort and whether the sequence reads naturally remain wearer tests.</p><p><a href="native/report.json">Runtime receipt</a> · <a href="data-checks.json">Data checks</a> · <a href="after/tutorial.md">Tutorial</a> · <a href="after/technical.md">Exact placement table</a> · <a href="../2026-10-17-wedge-spacing-stoppers/index.html">Previous interpretation</a></p>
<section id="text"><h2>The revised encounter</h2><div class="prose">{paras}</div><p><a href="after/final.md">Complete revised chapter</a></p></section></main></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
print('Grid route review, source copies and eight data checks saved.')
