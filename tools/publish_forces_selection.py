"""The selected artifacts, their actual museum photographs and tested limits."""
from pathlib import Path
import json, html, hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-forces-selected-in-the-halls'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def esc(s):return html.escape(str(s))
INFO={
'bubble_blaster':('Bubble Blaster','Grab the pink blaster. Its bubble stream makes the output velocity visible.','Existing hand prop. The drawn launch vector and animated stream return the vector lesson in a carried object.'),
'force_mower':('Force Mower','Push the mower by its handle; watch the signed work accumulate along your displacement.','W = F · d. The drawn force is a nominal value; the controller does not measure the pressure of your hand.'),
'viscosity_layers':('Viscosity Layers','Drop the three identical points together. Compare their speeds through air, water and honey.','Existing numerical drag model, raised onto a museum plinth. These are three resistance coefficients, not simulated liquids.'),
'launch_arc':('Launch Arc','Change the launch and follow what its velocity becomes under gravity.','Already in this hall, and still its tutorial anchor. The additional launchers compare different receivers of a launch.'),
'firework_burst':('Firework Burst','Forty-eight coloured projectiles rise into a canopy more than five metres high. Sometimes the whole fountain holds still.','NEW: ballistic motion, coloured trails, a 2.4-second automatic pause near the apex, and adjacent FREEZE / RESUME and AUTO controls. Only this exhibit’s clock stops.'),
'catapult':('Catapult','Set the angle and launch speed, then throw a ball along the displayed arc.','The selected existing catapult is added beside the earlier physical lever experiment. Its arm swing is prescribed; the released ball carries the launch.'),
'human_catapult':('Human Catapult','Step into the basket, choose the launch, and press FIRE from the basket. Now you are the projectile.','The launch now goes through the museum’s desktop and XR movement system so normal locomotion cannot immediately erase it. Gravity and player collisions remain active.'),
'centrifuge_ring':('Centrifuge Ring','Hold the rose handle and travel around the ring. Press the held trigger to change speed. Let go into the tangent.','NEW: a grabbable ride, 2 / 4 / 6 m/s speeds, and velocity and inward-acceleration cylinders. This is a prescribed circular ride. It moves the player collision body without rotating the tracked head; release coasts and slows.'),
'orbit_walk':('Orbit Walk','Stand beside the barycentre while the two bodies circle their shared centre.','Existing prescribed two-body diagram. Compare it with the primary mutually attracting PointBodies, whose trajectories are integrated.'),
'SpringSuspension':('SpringSuspension','Pull the rose point on the wheel and release. The spring and its travel limits respond.','Actual Jolt Generic6DOF joint. Added a force-transmitting hand grip and a visible coil; removed the standalone camera and environment in museum mode.'),
'spring_tower':('Spring Tower','Stand beside the large coil and follow the mass as the spring length changes.','Existing cosine animation illustrating spring period. The coupled physical PointBody row remains the tutorial anchor and the hand-led experiment.'),
'momentum_cradle':('Momentum Cradle','Change LIFT and read the posed input and output together.','Existing static explanation of an ideal equal-mass exchange. It is deliberately presented beside a running model.'),
'newton_cradle':("Newton’s Cradle",'Release one ball, two balls, or both ends. Follow how the motion travels through the row.','Existing integrated pendulum-angle model with idealized velocity exchange. It does not use the Jolt contact solver used by the nearby bowling lane.'),
'wind_room':('Wind Room','Pick up and aim the rose point to redirect the wind. Push a cube into it. Walk into it yourself.','NEW: relative-velocity drag pushes eight physical cubes and points, with real position trails. Windsocks and cylinder arrows reveal direction. WIND / CALM, TURN and RESET are beside the hand control. Visitor resistance uses a declared comparison mass.'),
'force_vortex':('Force Vortex','Enter the spiral, approach its core, and be thrown outward.','The selected older vortex prescribes a velocity field. Its ejection now retains momentum through the museum’s movement system. Compare it with the acceleration-based primary vortex in the same hall.')}
def figure(path,caption):
    return f'<figure><a href="{path}"><img loading="lazy" src="{path}" alt="{esc(caption)}"></a><figcaption>{esc(caption)}</figcaption></figure>'
def build():
    selection=read(OUT/'selection.json');plan=read(ROOT/'commons/artifacts/force_halls/curation.json')
    reports=[];parts=[];nav=[];status=[]
    for h in plan['halls']:
        chosen=[a for a in selection['artifacts'] if a['map']==h['map']]
        if not chosen:continue
        m=h['map'];nav.append(f'<a href="#{m}">{h["number"]:02d} · {esc(h["title"])}</a>')
        cards=[]
        for item in chosen:
            token=item['token'];title,action,note=INFO[token]
            photo=f'museum/{m}/{token}.png'
            assert (OUT/photo).exists(),photo
            cards.append(f'<article id="{token}"><p class="eyebrow">{esc(token)}</p><h3>{esc(title)}</h3><p class="action">{esc(action)}</p>{figure(photo,"Inside Endless Museum · "+title)}<p class="note">{esc(note)}</p></article>')
        before=OUT.parent/f'2026-10-07-forces-extravaganza/after/{m}/above.png'
        old=''
        if before.exists():old=figure(f'../2026-10-07-forces-extravaganza/after/{m}/above.png','Previous arrangement · historical capture before this selection and the Jolt switch')
        parts.append(f'<section id="{m}"><p class="eyebrow">FORCES · HALL {h["number"]:02d} · {m}</p><h2>{esc(h["title"])}</h2><p class="contract">Tutorial object: <code>{h["tutorial_artifact"]}</code>. {esc(h["selection_note"])}</p><details><summary>See the arrangement before and after</summary><div class="comparison">{old}{figure(f"museum/{m}/above.png","Current arrangement · actual museum / Jolt")}</div></details><div class="cards">'+''.join(cards)+'</div></section>')
        path=f'museum/{m}/report.json';r=read(OUT/path)
        script_errors='SCRIPT ERROR' in (OUT/f'museum/{m}/engine.log').read_text(encoding='utf8',errors='replace')
        passed=r['passed'] and not script_errors
        status.append({'map':m,'passed':passed,'exit':0 if passed else 1})
        reports.append(dict(name=h['title'],path=path,checks=len(r['checks']),passed=passed))
    for path,name in [('tests/models.json','Interaction and model tests'),('tests/route/report.json','Eleven-hall teleport route and XR return')]:
        r=read(OUT/path);reports.append(dict(name=name,path=path,checks=len(r['checks']),passed=r['passed']))
    total=sum(r['checks'] for r in reports);passed=all(r['passed'] for r in reports)
    assert passed,'Do not publish failed tests as passed'
    files=[ROOT/'tools/place_forces_selection.py',ROOT/'tools/probes/forces_selection_models.gd',ROOT/'tools/probes/forces_selection_museum.gd',ROOT/'commons/artifacts/force_halls/curation.json',ROOT/'project.godot']
    for directory in ['firework_burst','centrifuge_ring','wind_room','human_catapult','force_vortex']:files.extend((ROOT/'commons/artifacts'/directory).glob('*.gd'))
    files.extend([ROOT/'commons/artifacts/force_play/player_launch.gd',ROOT/'algorithms/joint/05_spring_suspension/SpringSuspension.gd'])
    evidence={'passed':passed,'checks':total,'reports':reports,'source_sha256':{str(p.relative_to(ROOT)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in files}}
    (OUT/'verification.json').write_text(json.dumps(evidence,indent=2),encoding='utf8')
    (OUT/'capture-status.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    table=''.join(f'<tr><td><a href="{r["path"]}">{esc(r["name"])}</a></td><td>{r["checks"]} passed</td></tr>' for r in reports)
    css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#eeece5;color:#22252c;font:17px/1.55 system-ui,sans-serif}main{max-width:1450px;margin:auto;padding:35px}h1{font-size:clamp(42px,6vw,80px);max-width:950px;line-height:1.03;letter-spacing:-.055em}h2{font-size:36px;line-height:1.15}h3{font-size:27px;margin:3px 0;line-height:1.2}a{color:inherit}nav{display:flex;gap:8px;flex-wrap:wrap;margin:32px 0}nav a{padding:7px 13px;background:#252831;color:white;text-decoration:none;font-size:13px;border-radius:3px}.lead{max-width:900px;font-size:21px}.eyebrow{text-transform:uppercase;font-size:12px;letter-spacing:.1em;color:#73616a}.badge{background:#f0c5d6;padding:9px 14px;display:inline-block}.cards,.comparison{display:grid;grid-template-columns:1fr 1fr;gap:24px}article{background:#fffdf8;padding:23px;min-width:0;scroll-margin-top:20px}section{margin:70px 0;border-top:2px solid #262832;padding-top:23px;scroll-margin-top:20px}.contract{max-width:1040px}.action{min-height:3.2em}figure{margin:18px 0}img{display:block;width:100%;height:auto}figcaption,.note{font-size:14px;color:#58535a}summary{cursor:pointer;font-weight:600;margin:14px 0}table{border-collapse:collapse;width:100%;max-width:950px}td{padding:10px;border-bottom:1px solid #bbb}footer{max-width:1000px;margin:70px 0}code{font-size:.9em;overflow-wrap:anywhere}@media(max-width:800px){main{padding:20px 15px}.cards,.comparison{grid-template-columns:1fr}.action{min-height:0}}'''
    page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Your Forces selections · Endless Museum</title><style>{css}</style><main><p class="eyebrow">Endless Museum / 7 October 2026</p><h1>Your selections, in the Forces halls.</h1><p class="lead">Fifteen selected artifacts, placed through seven existing halls. The point remains the tutorial thread; the other objects offer comparisons, bodily encounters and consequences.</p><p class="badge">{total} passing checks · Jolt Physics · photographs from the actual museum</p><p class="lead">The fountain now moves and sometimes freezes. The centrifuge has a held ride. Wind pushes bodies and the visitor. Restart the museum and enter Forces; NEXT and PREVIOUS connect the eleven halls.</p><p><a href="http://localhost:3003/vector-force-picker">Open the picker</a> · <a href="selection.json">Selection record</a> · <a href="#verification">What was tested</a></p><nav>{''.join(nav)}</nav>{''.join(parts)}<footer id="verification"><h2>What was tested</h2><table>{table}</table><p>The checks cover scene construction, automatic and manual fountain pause, rigid-body wind response, actual XRTools pickup and circular player-body motion, spring-joint response, launch/ejection delivery, museum placement, supported perimeter routes and NEXT/PREVIOUS travel.</p><p>Headset reach, comfort and Quest frame time still need a physical visit. Orbit Walk, Spring Tower and Momentum Cradle are diagrams; Newton’s Cradle uses an idealized numerical model. The gallery records those differences rather than treating every moving picture as a rigid-body simulation.</p><p>The known project UID warning and Jolt’s ignored legacy solver-bias warning remain in the logs; these runs have no SCRIPT ERROR. Full tutorial.md and final.md were not rewritten. Hall lesson contracts identify where these comparisons belong.</p><p><a href="verification.json">Verification and source hashes</a></p></footer></main></html>'''
    (OUT/'index.html').write_text(page,encoding='utf8')
    lines=['# Selected Forces artifacts','',f'15 selections; {total} passing checks. See index.html for actual museum photographs.','']
    for item in selection['artifacts']:
        title,action,note=INFO[item['token']]
        lines.extend([f'## {title} — {item["map"]}',action,'',note,''])
    (OUT/'REPORT.md').write_text('\n'.join(lines),encoding='utf8')
    print(f'Published 15 artifact cards, seven hall comparisons and {total} passing checks.')
if __name__=='__main__':build()
