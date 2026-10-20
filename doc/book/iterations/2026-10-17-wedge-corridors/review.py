from pathlib import Path
import html, json, shutil
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent
MAP=ROOT/'commons/maps/Primitives_Polythedra'
run=ROOT/'ada_run/encounter_pilot/Primitives_Polythedra/wedge-corridors-v2'
report=json.loads((run/'report.json').read_text(encoding='utf-8'))
assert report['passed'], report['failures']
native=HERE/'native';native.mkdir(exist_ok=True)
for p in run.glob('*.png'):shutil.copy2(p,native/p.name)
for name in ['report.json','source_manifest.json','engine.log']:
    shutil.copy2(run/name,native/name)
after=HERE/'after';after.mkdir(exist_ok=True);(after/'.gdignore').touch()
for name in ['map_data.json','final.md','tutorial.md','summary.md','technical.md','artifacts.md']:
    shutil.copy2(MAP/name,after/name)
passed=len(report['checks'])
summary=f'''# Wedges become a route

The Polythedra hall now requires an ordinary walker to take one of two symmetric ramp corridors. A front wall divides the approach; a red STOP and a blue two-direction arrow mark that decision. Two smaller arrows indicate the entrances.

Both ramps are two metres wide. Each rises one metre over a two-metre run onto the same 4 × 4 m platform. The platform is authored with structure `2`; six stock `wp` units make the two approaches and the far descent. The earlier standalone platform is disabled only in this map, so it cannot overlap the new architecture.

The rear divider prevents walking around the crossing at floor level. The rock side room now opens beyond it. The basin keeps its floor and retaining profiles, and the first tetrahedron and wedge alignment encounters stay in place.

Updated final, tutorial, reference, summary and placement inventory. Only this hall's museum plan row was regenerated.

Verification: {passed}/{passed} native runtime checks pass, plus ten scoped data checks. The supplied walker ascends both ramps, crosses the landing, descends, enters and leaves the rock room, and reaches the exit approach. Three flat shortcuts meet physical walls. Native screenshots are included. The initial test's return waypoint incorrectly crossed the rock-room wall; the corrected probe returns through the actual doorway. The geometry did not need changing for that correction.

The pathfinder reports no failures. Its warnings concern the existing edge teleporter convention and the intentionally enclosed rock spawner. The render log contains existing renderer/registry warnings and no engine errors. Headset comfort and whether the signs make the turn natural remain a wearer trial. Jumping, teleporting and flying are outside the forced-walk claim.

Useful first trial: enter without instructions, find either ramp, cross, then return by the other approach. Do the walls make the wedge necessary while leaving the choice between the two approaches legible?
'''
(HERE/'summary.md').write_text(summary,encoding='utf-8')

def prose(text):
    chunks=[]
    for p in text.split('\n\n'):
        if not p.strip() or p.startswith('<!--'):continue
        tag='h3' if p.startswith('# ') else 'p'
        chunks.append('<'+tag+'>'+html.escape(p.removeprefix('# '))+'</'+tag+'>')
    return '\n'.join(chunks)

m=json.loads((MAP/'map_data.json').read_text(encoding='utf-8'))
svg=['<svg viewBox="0 0 1040 690" role="img" aria-label="Map-derived plan: two ramp corridors meet on a raised platform and descend into the basin room.">','<defs><marker id="head" markerWidth="6" markerHeight="6" refX="5" refY="3" orient="auto"><path d="M0 0L6 3L0 6Z" fill="#166a57"/></marker></defs>']
def xy(x,z):return 32+(x-1)*37,66+(z-23)*37
for z in range(23,39):
    for x in range(1,27):
        t=m['layers']['structure'][z][x];px,py=xy(x,z)
        color={'w':'#424f59','1':'#eee9df','2':'#d7a6bd','0':'#fffaf2'}.get(t,'white')
        svg.append(f'<rect x="{px}" y="{py}" width="37" height="37" fill="{color}" stroke="#fffaf2" stroke-width="1"/>')
        utility=m['layers']['utilities'][z][x]
        if utility.startswith('wp:'):
            arrow={'wp:90':'→','wp:270':'←','wp:180':'↓'}[utility]
            svg.append(f'<rect x="{px}" y="{py}" width="37" height="37" fill="#91c6c4"/><text x="{px+18.5}" y="{py+26}" text-anchor="middle" font-size="27">{arrow}</text>')
for points in [[(4.8,24),(4.8,27.5),(9.5,27.5),(9.5,33)],[(14.2,24),(14.2,27.5),(9.5,27.5)]]:
    coords=['%s,%s'%(xy(x,z)[0]+18.5,xy(x,z)[1]+18.5) for x,z in points]
    svg.append(f'<polyline points="{" ".join(coords)}" fill="none" stroke="#166a57" stroke-width="4" marker-end="url(#head)"/>')
labels=[(9.5,23,'ENTRY'),(9.5,25,'STOP · ↔'),(9.5,29,'2 · platform'),(9.5,34,'To basin'),(21.5,36,'Rock side room')]
for x,z,t in labels:
    px,py=xy(x,z);svg.append(f'<text x="{px+18.5}" y="{py+22}" text-anchor="middle" font-family="sans-serif" font-size="16" font-weight="600">{t}</text>')
svg.append('<text x="32" y="35" font-family="sans-serif" font-size="18">Plan from the map cells · pink: raised floor · teal: wp ramps · dark: walls</text></svg>')
(HERE/'route.svg').write_text(''.join(svg),encoding='utf-8')

styles='''*{box-sizing:border-box}body{margin:0;background:#f7f3eb;color:#28342f;font:18px/1.6 system-ui,sans-serif}main{max-width:1280px;margin:auto;padding:36px}h1{font:clamp(38px,5vw,64px)/1.1 Georgia,serif;max-width:950px;margin:12px 0 20px}h2{font:32px/1.2 Georgia,serif;margin-top:40px}h3{font:25px/1.3 Georgia,serif}p{max-width:78ch}.kicker{font-size:14px;letter-spacing:.12em;text-transform:uppercase;color:#526a60}.lead{font-size:23px;max-width:55ch}.pair{display:grid;grid-template-columns:1fr 1fr;gap:26px}.card{background:#fffdf7;padding:24px;border:1px solid #ded8cc;border-radius:10px}figure{margin:28px 0}img{width:100%;border-radius:8px}figcaption{font-size:16px;color:#526259;margin-top:8px}a{color:#116853}nav{display:flex;flex-wrap:wrap;gap:22px;padding:12px 0;border-top:1px solid #d7cdbf;border-bottom:1px solid #d7cdbf}.proof{padding:20px;background:#e7eee5;border-left:5px solid #43765f}.text p{font:19px/1.7 Georgia,serif}.text{align-items:start}@media(max-width:750px){main{padding:22px}.pair{grid-template-columns:1fr}}'''
old=(HERE/'before/commons/maps/Primitives_Polythedra/final.md').read_text(encoding='utf-8-sig')
new=(MAP/'final.md').read_text(encoding='utf-8')
body=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Wedges become a route · Ada Research</title><style>{styles}</style><main>
<div class="kicker">Ada Research · Polythedra · 17 October 2026</div><h1>Wedges become a route</h1>
<p class="lead">Two symmetrical corridors lead up to one platform. The choice is left or right; continuing through the hall requires the climb.</p>
<nav><a href="#route">The route</a><a href="#walk">From the floor</a><a href="#text">Before / revised text</a><a href="#checks">Verification</a><a href="summary.md">Short saved summary</a></nav>
<section id="route"><h2>Walls hold the approach</h2><p>A STOP sign meets the straight approach. The blue double arrow offers two ways around the wall. Each ramp is two metres wide and rises one metre over two metres onto a 4 × 4 m landing. The platform uses structure <code>2</code>; the ramps use the existing <code>wp</code> prisms.</p><figure><img src="route.svg" alt="Plan from actual map cells showing symmetric ramps and the far descent"><figcaption>The new doorway to the rock room is beyond the crossing, closing the former flat bypass. This is a plan diagram, not a Godot screenshot.</figcaption></figure><figure><img src="native/route-overview.png" alt="Native overhead view of the corridor walls, signs, landing and basin"><figcaption>Actual Godot capture. The basin, its floor and the rock side room remain.</figcaption></figure></section>
<section id="walk"><h2>From the floor</h2><div class="pair"><figure><img src="native/entry-signs.png" alt="STOP and a blue two-direction arrow before the wall"><figcaption>The sign asks; the wall constrains.</figcaption></figure><figure><img src="native/west-approach.png" alt="Stock wedge rising between corridor walls"><figcaption>The west approach. The east approach has the same dimensions.</figcaption></figure></div><figure><img src="native/platform-descent.png" alt="View from the raised landing down to the basin"><figcaption>An opening from the landing leads down the third ramp.</figcaption></figure></section>
<section id="checks"><h2>What was checked</h2><div class="proof"><strong>{passed}/{passed} native runtime checks passed.</strong> Both ascents, platform height, the far descent, three blocked flat shortcuts, rock-room access and the exit approach. Ten scoped data checks also passed; only the Polythedra museum plan row changed.</div><p>The first probe returned from the rock room through a wall. Its waypoint was corrected to use the doorway; this was a test-route error. The second run passes. Pathfinder warnings concern the existing edge exit convention and the enclosed rock spawner. Existing renderer and registry warnings remain; the runtime log contains no engine errors.</p><p>Headset comfort and whether a visitor naturally reads the signs are still open. The route claim concerns ordinary walking. Jumping, teleporting and flying were not tested.</p><p><a href="native/report.json">Runtime receipt</a> · <a href="data-checks.json">Data checks</a> · <a href="after/tutorial.md">Updated tutorial</a> · <a href="after/technical.md">Construction reference</a></p><p><strong>First wearer trial:</strong> enter without extra instructions, find either ramp, cross, then return by the other approach. Do the walls make the wedge necessary while leaving both approaches legible?</p></section>
<section id="text"><h2>The room and its account</h2><p>The changes below are limited to the crossing. The opening alignment encounters and the remainder of the chapter stay in their order.</p><div class="pair text"><article class="card"><div class="kicker">Before</div>{prose(old)}</article><article class="card"><div class="kicker">Revised</div>{prose(new)}</article></div></section></main></html>'''
(HERE/'index.html').write_text(body,encoding='utf-8')
print(f'Review created with {passed} passing runtime checks.')
