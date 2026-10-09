"""Publish real museum evidence for Endless Drive after both probes pass."""
from pathlib import Path
import json, shutil, hashlib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-endless-drive'
def main():
    reports=[ROOT/'ada_run/endless_racer_tests.json',OUT/'museum/report.json']
    data=[json.loads(p.read_text(encoding='utf8')) for p in reports]
    assert all(r['passed'] and not r['failures'] for r in data)
    for p in [ROOT/'ada_run/endless_racer_tests.log',OUT/'museum/engine.log']:
        assert 'SCRIPT ERROR' not in p.read_text(encoding='utf8',errors='replace')
    (OUT/'tests').mkdir(exist_ok=True)
    for name in ['endless_racer_tests.json','endless_racer_tests.log']:
        shutil.copy2(ROOT/'ada_run'/name,OUT/'tests'/name)
    count=sum(len(r['checks']) for r in data)
    manifest={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'commons/artifacts/endless_racer').glob('*')) if p.is_file()}
    (OUT/'source-hashes.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf8')
    html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Endless Drive · a small racer in the museum</title><style>
*{box-sizing:border-box}body{margin:0;background:#101922;color:#e9ece8;font:18px/1.6 system-ui,sans-serif}main{max-width:1220px;margin:auto;padding:42px 24px 80px}h1{font-size:clamp(44px,7vw,86px);line-height:1;margin:22px 0}h2{margin-top:45px}a{color:#85e5d4}small,.meta{color:#b4bec8}.intro{max-width:750px;font-size:22px}.tag{color:#efa5c9;letter-spacing:.1em;text-transform:uppercase;font-size:13px}img{display:block;width:100%;border-radius:8px}figure{margin:28px 0}figcaption{color:#b4bec8;font-size:15px;margin-top:9px}.cards{display:grid;grid-template-columns:repeat(2,1fr);gap:20px}.card{background:#1c2936;padding:24px;border:1px solid #344553;border-radius:8px}table{border-collapse:collapse;width:100%;margin:24px 0}th,td{text-align:left;border-bottom:1px solid #344553;padding:13px}code{color:#efa5c9}details{margin-top:24px} @media(max-width:700px){.cards{grid-template-columns:1fr}body{font-size:16px}main{padding:24px 16px}}
</style><main><div class="tag">Endless Museum / Forces / 7 October 2026</div>
<h1>Endless Drive</h1><p class="intro">A rose car, a wheel in your hands, and a road with no last room. Take bends, collect cubes, and carry your speed into the next decision.</p>
<p><a href="#controls">Controls</a> · <a href="#bay">Find the car</a> · <a href="#model">What runs</a> · <a href="#tests">Tests</a></p>
<figure><img src="museum/cockpit.png" alt="Actual Godot cockpit with rose wheel grips, dashboard and the road extending beneath stars"><figcaption>Actual Godot capture from inside the cockpit. The dashboard sits above the wheel; both local buttons remain in reach.</figcaption></figure>
<div class="cards" id="controls"><section class="card"><h2>In VR</h2><p>Press <b>DRIVE</b> beside the museum car. Grip either rose handle and turn the wheel. <b>Right trigger</b> accelerates; <b>left trigger</b> brakes. Release the wheel to let it centre.</p><p><b>RESTART</b> begins a fresh countdown. <b>MUSEUM</b> returns you to the boarding bay.</p></section><section class="card"><h2>On desktop</h2><p><b>W / S</b>: accelerate / brake.<br><b>A / D</b>: steer. Mouse: look around.<br><b>R</b>: restart. <b>Backspace</b>: return.</p><p>Gold cubes add to your count. Rose barriers and guard rails cost speed. Distance, cubes and hits stay on the dashboard.</p></section></div>
<h2 id="bay">Before the capability court</h2><p>Find the car in <b>Forces → Carry the point through</b> (<code>Vectors_Act5_ForceAsPlace</code>). Its bay is beside the route before the court. One decorative column was removed to give the car clear space; the cross-wall and central passage remain.</p>
<figure><img loading="lazy" src="museum/museum-bay.png" alt="Rose car in its boarding bay inside the Endless Museum"><figcaption>The car is part of the museum. DRIVE sits on a nearby post. Returning restores your position in this hall.</figcaption></figure>
<h2 id="model">An arcade road</h2><p>The road bends continuously and recycles 28 sections. Throttle builds speed; resistance and braking reduce it. Steering has a short response time. A hit slows the car instead of ending the run.</p>
<figure><img loading="lazy" src="museum/endless-bend.png" alt="The car on a curving road with collectible cubes and glowing guard rails"><figcaption>A view from above and behind the car. The same finite pool supplies the next stretch.</figcaption></figure>
<p>This first version uses an arcade movement model. The road moves around a stationary cockpit in the same 3D world. It does not simulate tyres or suspension. Tracked head motion remains yours; the game does not impose head roll. The sphere remains the primary tutorial object in this hall, with the car offering another way to play with acceleration, resistance and correction.</p>
<h2 id="tests">COUNT checks passed</h2><p>Tests cover throttle, coast, braking, rail and barrier hits, cube collection, restart, desktop boarding and return, XR trigger inputs, steering through an actual XRTools grab driver, and restoring the XR rig. Recycling over a simulated 100 km keeps the node count fixed.</p><p>The production museum probe checks the route, exit, car clearance, keyboard drive, driver view and return. Images above are Godot captures. <b>Physical headset comfort and Quest performance still need testing.</b></p>
<details><summary>Evidence and implementation</summary><ul><li><a href="tests/endless_racer_tests.json">Model and XR checks</a> · <a href="tests/endless_racer_tests.log">engine log</a></li><li><a href="museum/report.json">Museum checks</a> · <a href="museum/engine.log">engine log</a></li><li><a href="source-hashes.json">Source hashes</a></li></ul><p>Existing project diagnostics remain for an unresolved resource UID, Jolt solver bias and a catalyst viewport texture. The probes report no script errors. Best distance currently lasts for the artifact's lifetime.</p></details>
</main></html>'''.replace('COUNT checks',str(count)+' checks')
    (OUT/'index.html').write_text(html,encoding='utf8')
    print(f'Published {count} checks and actual museum captures: {OUT}')
if __name__=='__main__':main()
