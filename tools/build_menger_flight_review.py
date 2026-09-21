"""Publish only verified, current flight evidence and a small museum review."""
from pathlib import Path
import hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/research/possible-bodies'
BASE=ROOT/'doc/space/menger-flight-2026-09-14'
RUN=ROOT/'ada_run/menger-flight-review-2026-09-14'
def dump(path,obj):path.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
receipt=json.loads((RUN/'run.json').read_text(encoding='utf-8'))
assert receipt['exit']==0 and not receipt['failures'] and receipt['sources_unchanged']
assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in receipt['source_sha256'].items())
assets=[]
for name in ['entrance','at-opening','above-sponge','enclosure']:
    dest=OUT/f'menger-flight-{name}.png'
    shutil.copyfile(RUN/'Fractal_MengerSponge'/f'{name}.png',dest);assets.append(dest.name)
dump(OUT/'menger-flight-verification.json',receipt);assets.append('menger-flight-verification.json')
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Borrowing flight · Ada Research</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#101d27;color:#edeaf1;font:18px/1.65 system-ui,sans-serif}main{max-width:1080px;margin:auto;padding:30px 24px 65px}nav{display:flex;gap:22px;flex-wrap:wrap;font-size:14px}a{color:#8ee4ef}h1{font:clamp(45px,8vw,82px)/1.06 Georgia,serif;margin:42px 0 24px}h2{font:30px/1.25 Georgia,serif}.lead{font:24px/1.5 Georgia,serif;max-width:770px}.tag{color:#a2b6c4;letter-spacing:.12em;font-size:12px;margin-top:38px}figure{margin:32px 0}img{width:100%;height:auto;display:block;border:1px solid #345364;border-radius:5px}figcaption{font-size:14px;color:#b5c5cd;margin-top:10px}.controls{display:grid;grid-template-columns:1fr 1fr;gap:18px}.controls>div{padding:20px;background:#1b303c;border:1px solid #355161;border-radius:5px}.controls h2{margin-top:0}.controls p{margin-bottom:0}kbd{font:14px monospace;border:1px solid #63848e;border-radius:4px;padding:2px 6px;white-space:nowrap}blockquote{font:29px/1.45 Georgia,serif;border-left:3px solid #b8a2e9;padding-left:24px;margin:36px 0}.note{font-size:15px;color:#b8c6d0;border-top:1px solid #3c5662;padding-top:20px}footer{margin-top:45px;font-size:14px}@media(max-width:650px){main{padding:22px 16px}.controls{grid-template-columns:1fr}.lead{font-size:21px}}
</style></head><body><main><nav><a href="fractal-learning-arc.html#Fractal_MengerSponge">← Fractal learning arc</a><a href="/necklace/thread?map=Fractal_MengerSponge&role=primary">Hall and book</a></nav>
<p class="tag">ADA RESEARCH · MENGER SPONGE · 14 SEPTEMBER 2026</p><h1>Borrowing flight.</h1><p class="lead">The hole was already there. What needed to change was how our body could reach it.</p>
<figure><img src="menger-flight-enclosure.png" alt="The nine-metre sponge enclosed by a cyan frame and glass walls"><figcaption>Actual Godot capture: a twelve-metre glass cube surrounds the nine-metre sponge. The museum keeps all five existing artifacts.</figcaption></figure>
<h2>Enter the frame. Leave the floor.</h2><p>Flight begins inside the cube. Rise towards the large central opening, pass through, then circle around the sides and over the top. Let go of the movement controls to hover. The glass bounds the space; the sponge's retained cubes remain solid.</p>
<div class="controls"><div><h2>Desktop</h2><p>Look with the mouse. <kbd>W</kbd> <kbd>A</kbd> <kbd>S</kbd> <kbd>D</kbd> move relative to your view, including its tilt. Hold <kbd>Space</kbd> to rise or <kbd>Ctrl</kbd> to descend.</p></div><div><h2>VR</h2><p>Tilt the left controller to aim your movement and use its stick to travel or strafe. A neutral stick hovers. Flight activates within the enclosure.</p></div></div>
<p>Descend to either ground-level doorway to leave. Walking and ordinary gravity resume outside. Speed is limited to 2.4 metres per second, including combined directions.</p>
<figure><img loading="lazy" src="menger-flight-at-opening.png" alt="View into the sponge's large central passage, with smaller openings visible in its sides"><figcaption>The view becomes a route. This passage was traversed by the museum's actual desktop walker, with collisions enabled.</figcaption></figure>
<blockquote>We changed the body's movement without changing the sponge's selection rule.</blockquote>
<p>Some openings admit this body; smaller copies refuse it. Flying makes an existing connection accessible. It does not turn every dark square into a doorway. Geometry, connectivity and bodily access can now be compared through the same encounter.</p>
<figure><img loading="lazy" src="menger-flight-above-sponge.png" alt="Looking down across the top and side openings while flying above the sponge"><figcaption>A viewpoint from above, reached by rising inside the glass cube.</figcaption></figure>
<p class="note">__CHECKS__ Godot checks passed: enclosure and floor placement; 400 retained cubes; hover, ascent, central passage and exterior circuit; roof, glass and sponge collisions; exit and restored gravity; room unload; and steering through a simulated XR controller and the real XRTools receiver. Keyboard events were synthetic, using the actual museum movement code. Headset comfort and performance remain untested.</p>
<footer><a href="menger-flight-verification.json">Recorded verification</a> · <a href="/necklace/thread?map=Fractal_MengerSponge&role=primary">Read the updated book passage</a><p>The full hall review continues later. The next hall to develop in the agreed arc remains <a href="/necklace/thread?map=Fractal_Recursion&role=primary">Fractal_Recursion</a>.</p></footer></main></body></html>'''.replace('__CHECKS__',str(receipt['checks']))
(OUT/'menger-flight.html').write_text(page,encoding='utf-8');assets.append('menger-flight.html')
assets += ['fractal-learning-arc.html','fractal-learning-arc.json','fractal-learning-arc.md']
targets=['possible-bodies/'+a for a in assets]
dump(BASE/'publish-targets.json',targets)
dump(BASE/'publish-hashes.json',{r:hashlib.sha256((ROOT/'doc/research'/r).read_bytes()).hexdigest() for r in targets})
for name,source in [('receipt.json',RUN/'run.json'),('report.json',RUN/'Fractal_MengerSponge/probe_ca_edge_live.json'),('engine.log',RUN/'Fractal_MengerSponge/engine.log')]:shutil.copyfile(source,BASE/name)
print(f'Built flight review and {len(targets)} publishable assets.')
