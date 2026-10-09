"""Publish the built Forces encounters and their actual museum evidence."""
from pathlib import Path
import json,html,hashlib,shutil
from expand_force_play import CATALOG
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-forces-extravaganza'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def esc(s):return html.escape(str(s))
def figure(path,caption):
    if not (OUT/path).exists():return ''
    return f'<figure><a href="{path}"><img loading="lazy" src="{path}" alt="{esc(caption)}"></a><figcaption>{esc(caption)}</figcaption></figure>'
INTERACTIONS={
'tower':('Gravity / loss of support','Pull the rose brick by hand. The upper stack falls through real contacts.','42 upper bricks; a separate low edge catches one side. No scripted collapse.'),
'gravity':('Gravity / release','Walk across the rose threshold, or use the adjacent RELEASE button.','Cargo, a hinged trapdoor and a leaning pole release together.'),
'mass':('Applied force / mass','Press PUSH 1 s and compare the live speeds. Reset for the same trial.','Same 0.36 m radius, matching 0.72 m mesh height and collider; masses 1, 2 and 4 kg.'),
'trolley':('Applied force / load','Pull the rose grip, then load the cart with the loose prefabs.','The wheels are visual; the constrained carrier uses a low-friction sliding contact model.'),
'puzzle':('Applied force / contact','Push the three weighted cubes through the openings onto their marked destinations.','The walls and other cubes remain part of the problem.'),
'bowling':('Impulse / collision','Roll the black point by hand, or use the nearby ROLL button.','Ten physical pins, a 23 m lane, side bumpers and banked sides; misses remain.'),
'recoil':('Impulse / reaction','Press FIRE. Compare the free cart with the braced one.','The ball and cart receive equal opposite impulses. The brace transfers the reaction to the room.'),
'friction':('Friction / rolling','Release all four runners together, then try hand launches.','Smooth/rough contact × cube/ball. Coloured trails record the actual positions.'),
'liquids':('Drag / resistance','Drop the matching points into the three volumes. Walk through them yourself.','Quadratic body drag and a simple upward buoyancy term; approximate resistance for walking. No fluid solver.'),
'springs':('Restoring force / coupling','Pull one hanging point and release it into the row.','Seven familiar points, seven suspension springs and six neighbour springs.'),
'swings':('Damping','Pull a rose seat grip, or give the three pairs the same NUDGE.','Real hinges; linked pairs compare weak, medium and strong angular damping.'),
'torque':('Torque / lever arm','Pull near the pivot, then farther away on the gate, seesaw or crank.','Rose grips apply a force to the real hinged body. The existing catapult remains nearby.'),
'constraints':('Constraint forces','Swing the basket and chain, pull the plank, then guide the articulated arm. Hold its grip and trigger the claw.','Eight physical joints. The claw has moving collision shapes; it does not teleport cargo into a socket.'),
'magnet':('Attraction / release','Activate the large magnet for three seconds. Grab the separate point, aim and hold its trigger to pull one prefab.','Twelve varied bodies. Releasing the gravity-gun trigger stops its spring force; the gun does not also propel the visitor.'),
'vortex':('A position-dependent field','Walk into the arrows or release objects across them.','Eighteen prefabs; forty-nine solid cylinder arrows. Inward and tangential acceleration act on bodies and the player.'),
'mutual':('Mutual attraction','Watch the five orbiting points, then enter the field as the sixth source.','Stronger, larger orbits with tangential initial motion. Softened attraction, contact disabled; visitor mass is a model parameter.'),
'support':('Contact / support','Move the rose leg beneath the loaded table.','The asymmetric load shifts outside the remaining support triangle. No fall animation.'),
'flight':('Thrust / gravity','Stand at the mat, hold two points, aim down/back and press the triggers. Fly through the numbered gates.','Uses the actual player movement adapter and player collision body. The mat follows the rider; it is not a second independent rigid vehicle. Points carried from the earlier court also supply thrust.')
}
def build():
    plan=read(ROOT/'commons/artifacts/force_halls/curation.json')
    sections=[];nav=[];checks=[]
    for row in plan['halls']:
        map_id=row['map'];studies=[a for a in row['placements'] if a['token'].startswith('force_play_')]
        if not studies:continue
        nav.append(f'<a href="#{map_id}">{row["number"]:02d} · {esc(row["title"])}</a>')
        cards=[]
        for a in studies:
            kind=a['token'].removeprefix('force_play_');title=CATALOG[kind][0];subject,gesture,model=INTERACTIONS[kind]
            path=f'after/{map_id}/{kind}'
            images=figure(path+'-before.png','Before the action · '+title)
            if (OUT/(path+'-after.png')).exists():images+='<details><summary>See the consequence</summary>'+figure(path+'-after.png','After the action · '+title)+'</details>'
            if kind=='magnet':images+=figure(path+'-released.png','The three-second attraction has ended; gravity remains.')
            if kind=='tower' and (OUT.parent/'2026-10-07-mini-stacking-table/index.html').exists():images+='<p><a href="../2026-10-07-mini-stacking-table/index.html">New: a miniature companion table. Reorder nine loose shapes with your hands.</a></p>'
            cards.append(f'<article id="{kind}"><p class="eyebrow">{esc(subject)} · {esc(a["role"])}</p><h3>{esc(title)}</h3><p class="action">{esc(gesture)}</p>{images}<p class="model">{esc(model)}</p></article>')
        old=ROOT/f'doc/book/iterations/2026-10-07-forces-curated-progression/after/{map_id}/above.png'
        previous=''
        if old.exists():
            dest=OUT/'earlier'/map_id/'above.png';dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(old,dest)
            previous='<details><summary>Earlier curated arrangement</summary>'+figure(f'earlier/{map_id}/above.png','Earlier arrangement, before this expansion. Existing comparison objects remain in the collection.')+'</details>'
        extra=''
        if map_id=='Vectors_Act5_ForceAsPlace':extra='<article id="mortar"><p class="eyebrow">Impulse · existing court upgraded</p><h3>Nine posts for the donut-cake mortar</h3><p>Three rows of posts at increasing heights. All three mortar controls are turned 180° around Y to face the approach. The open ring collision, eight-shot budget, launch pad, moving platform and vector visor remain.</p>'+figure(f'after/{map_id}/mortar.png','The existing mortar with nine target posts.')+'</article>'
        sections.append(f'<section id="{map_id}"><header><p class="eyebrow">Forces / hall {row["number"]:02d} · {esc(map_id)}</p><h2>{esc(row["title"])}</h2><p>{esc(row["principle"])}</p></header><div class="overview">{figure(f"after/{map_id}/above.png","Actual museum · the new arrangement")}{previous}</div><div class="cards">'+''.join(cards)+extra+f'</div><details class="lesson"><summary>The tutorial’s single line through this hall</summary><p>{esc(row["lesson"])}</p><p><b>Carry onward:</b> {esc(row["carry"])}</p><p>This is the revised artifact/lesson contract. The full tutorial.md and final.md manuscripts were not rewritten in this pass.</p></details></section>')
        report=OUT/'after'/map_id/'report.json'
        if report.exists():
            r=read(report);checks.append(dict(name=map_id,passed=r['passed'],checks=len(r['checks']),failures=r['failures'],path=f'after/{map_id}/report.json'))
    for directory,label in [('models','Force and input models'),('teleports','Eleven-hall teleport route'),('court','Existing capability court')]:
        path=OUT/'tests'/directory/'report.json'
        if path.exists():
            r=read(path);checks.append(dict(name=label,passed=r['passed'],checks=len(r['checks']),failures=r['failures'],path=f'tests/{directory}/report.json'))
    total=sum(c['checks'] for c in checks);failed=sum(len(c['failures']) for c in checks)
    table=''.join(f'<tr><td><a href="{c["path"]}">{esc(c["name"])}</a></td><td>{c["checks"]-len(c["failures"])}/{c["checks"]}</td></tr>' for c in checks)
    manifest={}
    sources=list((ROOT/'commons/artifacts/force_play').glob('*'))+[ROOT/'commons/artifacts/force_capability_lab'/f for f in ['force_point.gd','force_capability_lab.gd','ring_mortar.gd']]+[ROOT/'tools/probes/force_play_models.gd',ROOT/'tools/probes/force_play_museum.gd',ROOT/'tools/expand_force_play.py',ROOT/'tools/publish_force_play.py']
    for path in sources:
        if path.suffix in ['.gd','.tscn','.py']:
            manifest[path.relative_to(ROOT).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    (OUT/'verification.json').write_text(json.dumps({'passed':failed==0,'checks':total,'failures':failed,'reports':checks,'source_sha256':manifest},indent=2),encoding='utf8')
    css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#ece8df;color:#202128;font:17px/1.55 system-ui,sans-serif}main{max-width:1380px;margin:auto;padding:35px 32px}h1{font-size:clamp(42px,6vw,82px);line-height:1.02;max-width:1000px;letter-spacing:-.05em}h2{font-size:37px;line-height:1.15;margin:5px 0 12px}h3{font-size:27px;line-height:1.2;margin:4px 0 18px}a{color:inherit}nav{display:flex;gap:8px;flex-wrap:wrap;margin:32px 0}nav a{background:#202128;color:#fff;border-radius:4px;padding:8px 12px;text-decoration:none;font-size:13px}.lead{max-width:820px;font-size:21px}.eyebrow{text-transform:uppercase;font-size:12px;letter-spacing:.1em;color:#675962}.badge{display:inline-block;background:#79c4c8;padding:8px 14px;font-weight:650}section{margin:75px 0;border-top:2px solid #24242b;padding-top:28px;scroll-margin-top:25px}header p{max-width:950px}.cards{display:grid;grid-template-columns:1fr 1fr;gap:22px}article{background:#faf8f2;padding:25px;scroll-margin-top:25px;min-width:0}figure{margin:18px 0}img{width:100%;height:auto;display:block;background:#202128}figcaption,.model{font-size:14px;color:#5d5760}details{margin:15px 0}summary{cursor:pointer;font-weight:600}details.lesson{background:#eed6e0;padding:20px}.overview>figure{max-width:1000px}.action{min-height:3.1em}table{border-collapse:collapse;width:100%;max-width:850px}td{border-bottom:1px solid #c3bbb2;padding:9px}footer{max-width:1000px;margin:60px 0}.review{background:#fff;padding:25px;max-width:1000px}@media(max-width:800px){main{padding:22px 15px}.cards{grid-template-columns:1fr}h2{font-size:29px}}'''
    page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Forces · the room plays out</title><style>'+css+'</style><main><p class="eyebrow">Endless Museum · 7 October 2026 · built encounter review</p><h1>The room plays out.</h1><p class="lead">Eighteen larger physical studies across nine existing Forces halls. The black point returns as a weighted body, spring partner, orbiting source, gravity gun and handheld thruster. Cubes, hinges and earlier machines give it something to disturb.</p><p class="badge">Physics engine: GodotPhysics3D. Jolt is not enabled.</p><p class="lead">The eleven-hall order is retained. Restart or reload the museum, enter Forces, and use the existing NEXT / PREVIOUS hall controls. Each experiment has a nearby RESET; ordinary misses remain until you choose it.</p><nav>'+''.join(nav)+'</nav>'+''.join(sections)+f'<section id="verification"><h2>What was checked</h2><p>{total-failed}/{total} assertions passed in the recorded runs. The images above are renders from the actual placed museum scenes.</p><table>{table}</table><p><a href="verification.json">Evidence and source hashes</a> · <a href="artifact-list.json">Artifact list</a> · <a href="curation.json">Editable arrangement snapshot</a></p><div class="review"><b>Still needs your headset visit</b><p>Hand reach, grip feel, comfort while flying, text legibility and Quest frame timing. The liquid volumes are resistance models. The mat uses the player’s collision body; its full rectangle is not a separate colliding vehicle. The trolley uses a sliding model. These distinctions are stated beside the artifacts.</p><p>The source arrangement is <code>commons/artifacts/force_halls/curation.json</code>; the migration lives in <code>tools/expand_force_play.py</code>. The compact vector room, choreography conveyor, earlier pit and 107 Keep decisions remain. Full tutorial and reflective manuscripts need a separate writing pass after this spatial review.</p></div></section><footer><p>One reconstruction per principle. Other objects can make the room stranger without all becoming another programming lesson.</p></footer></main></html>'
    if '3d/physics_engine="Jolt Physics"' in (ROOT/'project.godot').read_text(encoding='utf8'):
        page=page.replace('Physics engine: GodotPhysics3D. Jolt is not enabled.', 'These captures used GodotPhysics3D. The project now uses Jolt. <a href="../2026-10-07-jolt-physics/index.html">See the Jolt checks and new captures.</a>')
    (OUT/'index.html').write_text(page,encoding='utf8')
    print(f'Published {len(sections)} halls / {len(CATALOG)} studies / {total-failed} of {total} assertions.')
if __name__=='__main__':build()
