from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import html
import json
import shutil
import hashlib

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
STUDY = ROOT / "doc/book/studies/sphere-in-pink"
for p in (STUDY / "captures").glob("*.png"):
    shutil.copy2(p, HERE / p.name)
shutil.copy2(STUDY / "captures/report.json", HERE / "report.json")
shutil.copy2(STUDY / "README.md", HERE / "README.md")
reference = HERE / "lewitt-reference.png"
if not reference.exists():
    shutil.copy2("C:/Users/palle/AppData/Local/Temp/codex-clipboard-33b25d3f-42aa-489f-a761-abdb2129b0d7.png", reference)
report = json.loads((HERE / "report.json").read_text(encoding="utf-8"))
states = [v for v in report["views"] if v["file"].startswith("state-")]
gallery = "\n".join(f'<button class="tile" data-mask="{v["mask"]}" aria-label="{html.escape(v["lights"])}"><img loading="lazy" src="{v["file"]}" alt="{html.escape(v["lights"])}"><span>{html.escape(v["lights"].split(" — ")[0])}</span></button>' for v in states)
style = '''
:root{color-scheme:dark;--ink:#f5e9ef;--muted:#c0a5b3;--paper:#181316;--pink:#ffa3ce}*{box-sizing:border-box}
body{margin:0;background:var(--paper);color:var(--ink);font:19px/1.7 Georgia,serif}a{color:var(--pink);text-underline-offset:4px}
header{display:flex;justify-content:space-between;gap:18px;flex-wrap:wrap;padding:20px 5vw;border-bottom:1px solid #46323e;font:13px/1.5 system-ui}header nav{display:flex;gap:22px}
main{max-width:1250px;margin:65px auto;padding:0 25px}.reading{max-width:740px;margin:55px auto}h1{font:400 clamp(58px,10vw,110px)/1 Georgia;margin:0 0 20px;letter-spacing:-.04em}h2{font-weight:400;font-size:32px;line-height:1.3;margin:45px 0 18px}
.eyebrow{font:12px/1.6 system-ui;letter-spacing:.15em;color:var(--muted)}.lead{font-size:26px;max-width:700px;line-height:1.5}figure{margin:0}img{max-width:100%;display:block}figcaption,.small{font:14px/1.6 system-ui;color:var(--muted);margin-top:13px}
.viewer{display:grid;grid-template-columns:minmax(0,1fr) 300px;gap:25px;align-items:center;margin:40px 0}.viewer>img{width:100%;background:#111;aspect-ratio:1;object-fit:contain}.controls{font:16px/1.6 system-ui}.switch{display:block;margin:12px 0;padding:8px 0;border-bottom:1px solid #46323e}input{accent-color:var(--pink);width:18px;height:18px;vertical-align:middle;margin-right:15px}button{font:14px/1.5 system-ui;cursor:pointer;border:1px solid #846578;background:transparent;color:var(--ink);padding:10px 14px;border-radius:3px}button:hover{background:#3b2833}button:focus-visible,a:focus-visible{outline:3px solid var(--pink);outline-offset:4px}.actions{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}
.grid{display:grid;grid-template-columns:repeat(8,minmax(0,1fr));gap:8px;margin:35px 0}.tile{padding:0;border:0;border-radius:0;text-align:left}.tile img{width:100%;aspect-ratio:1;object-fit:contain}.tile span{display:block;font:10px/1.4 system-ui;color:var(--muted);padding:6px 3px;min-height:40px}.tile.selected{outline:2px solid var(--pink);outline-offset:2px}
.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px;margin:35px 0}.pair img{width:100%}footer{font:13px/1.6 system-ui;border-top:1px solid #46323e;padding:25px 5vw;color:var(--muted)}.quote{font-size:30px;line-height:1.4;border-left:2px solid var(--pink);padding-left:25px}
@media(max-width:800px){main{padding:0 18px;margin-top:40px}.viewer{grid-template-columns:1fr}.controls{display:grid;grid-template-columns:1fr 1fr;gap:0 16px}.controls>p,.controls>.actions{grid-column:1/-1}.grid{grid-template-columns:repeat(4,minmax(0,1fr))}.pair{grid-template-columns:1fr}.lead{font-size:23px}}
'''
script = '''
const states=STATE_DATA, byMask=new Map(states.map(s=>[s.mask,s]));
let mask=1,timer=null;
const image=document.querySelector('#view'),description=document.querySelector('#active'),play=document.querySelector('#play');
function show(next){mask=next;const state=byMask.get(mask);image.src=state.file;image.alt=state.lights+'; pale sphere under pink light';description.textContent=state.lights;
document.querySelectorAll('[data-bit]').forEach(input=>input.checked=Boolean(mask & (1<<Number(input.dataset.bit))));
document.querySelectorAll('[data-mask]').forEach(tile=>{const selected=Number(tile.dataset.mask)===mask;tile.classList.toggle('selected',selected);tile.setAttribute('aria-pressed',String(selected));});}
function step(){const i=states.findIndex(s=>s.mask===mask);show(states[(i+1)%states.length].mask);}
function pause(){clearInterval(timer);timer=null;play.textContent='Play one switch at a time';}
document.querySelectorAll('[data-bit]').forEach(input=>input.addEventListener('change',()=>{pause();show(mask ^ (1<<Number(input.dataset.bit)));}));
document.querySelectorAll('[data-mask]').forEach(tile=>tile.addEventListener('click',()=>{pause();show(Number(tile.dataset.mask));}));
play.addEventListener('click',()=>{if(timer){pause();}else{timer=setInterval(step,2500);play.textContent='Pause';}});
document.querySelector('#next').addEventListener('click',()=>{pause();step();});
document.addEventListener('visibilitychange',()=>{if(document.hidden)pause();});show(1);
'''.replace("STATE_DATA", json.dumps(states))
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A sphere in pink light — Ada</title><style>{style}</style></head><body>
<header><span>ADA / COLOUR · LIGHT · A RECEIVING BODY</span><nav><a href="#study">The study</a><a href="#series">The series</a><a href="sphere-in-pink.zip">Godot project ↓</a></nav></header>
<main><p class="eyebrow">AFTER SOL LEWITT / 1 OCTOBER 2026</p><h1>In pink.</h1><p class="lead">The sphere stays where it was.<br>What reaches it changes.</p>
<section class="viewer" id="study"><img id="view" src="state-01.png" alt="Pale sphere illuminated from above by pink light."><div class="controls"><p class="eyebrow">FIVE LAMPS / ONE PALE SPHERE</p>
<label class="switch"><input type="checkbox" data-bit="0" checked>Above</label><label class="switch"><input type="checkbox" data-bit="1">Left</label><label class="switch"><input type="checkbox" data-bit="2">Right</label><label class="switch"><input type="checkbox" data-bit="3">Front</label><label class="switch"><input type="checkbox" data-bit="4">Behind</label>
<div class="actions"><button id="play">Play one switch at a time</button><button id="next">Next</button></div><p id="active" aria-live="polite">Top</p><p class="small">Switch between recorded native Godot states. The downloadable project runs the lights live and lets you look around. Every lamp uses the same pink and fixed energy.</p></div></section>
<div class="reading"><h2>Where is the pink?</h2><p>Let one lamp find the edge of the sphere. Add another. The body keeps its shape, but a boundary you had been using to read that shape has moved. On the floor, its shadow divides and overlaps. The pink reaches beyond the object we intended to study.</p><p>We have met this sphere before. Now we can keep its construction still and investigate the conditions under which it appears. The lamp's colour is one value; what we see ranges through dark rose, grey and bright pink.</p></div>
<section id="series"><p class="eyebrow">THIRTY-TWO SETTINGS / READ LEFT TO RIGHT, THEN DOWN</p><div class="grid">{gallery}</div><p class="small">Five on/off switches give 32 settings including all-off. Consecutive frames change one switch. A faint fixed ambient contribution remains. This is our ordering, not the original work's 28-plate arrangement.</p></section>
<div class="reading"><h2>Pink light, or a pink body?</h2><p>Keep the same two lamps in the same places. First let their pink fall on a pale sphere. Then make the lamps white and assign pink to the sphere's material. Look at the floor before deciding that these are the same colour.</p></div>
<div class="pair"><figure><img src="pink-light.png" alt="Pale sphere and neutral floor receiving pink light from above and left."><figcaption>Pink light / pale sphere. The floor receives pink too.</figcaption></figure><figure><img src="pink-material.png" alt="Pink sphere under white lamps, with a neutral floor."><figcaption>White light / pink material. The floor retains its neutral appearance in this direct-light renderer.</figcaption></figure></div>
<div class="reading"><p>This comparison exchanges two assignments. It is separate from the series above, which changes only the switches. The scene uses RGB lights and a material model; it does not simulate a spectrum or coloured indirect light bouncing from the sphere.</p><p class="quote">The colour of a body is not a complete description of how it will appear.</p>
<h2>A return in Color_Flashlight</h2><p>This fits beside the existing lamps and faceted sphere. Point One gave us a sun we could switch off. The primitive gave us a sphere. Arrays gave us a way to compare a family. Here those earlier operations let us ask a new question of the same body.</p><p>In the hall, I would give the live sphere one place and the comparison sheet a wall beside it. A visitor could move around the sphere, then return to the fixed view recorded on the wall. The small station would lead into the white room where the light changes around the visitor. This is proposed placement; the standalone study has not yet been installed in the museum.</p>
<h2>The reference</h2><p>LeWitt's <em>A sphere lit from the top, four sides, and all their combinations</em> (2004) comprises 28 inkjet prints, documented in the <a href="https://www.sollewittprints.org/artwork/lewitt-raisonne-2004-06/">catalogue raisonné</a>. <a href="https://fraenkelgallery.com/exhibitions/sol-lweitt-photographic-works-1968-2004">Fraenkel Gallery</a> describes the four-by-seven arrangement. Our pink, 32-state experiment is a response to its method, not a reconstruction of its exact lighting or selection.</p></div>
<figure><img src="lewitt-reference.png" alt="User-supplied installation photograph of LeWitt's 28 monochrome sphere studies."><figcaption>Reference photograph supplied by Palle. The pink studies above were rendered in Godot, not recoloured from this photograph.</figcaption></figure>
<div class="reading"><p><a href="sphere-in-pink.zip">Download the independent Godot project</a> · <a href="README.md">Read the setup and method</a> · <a href="pink-light-sheet.png">Open the full comparison sheet</a></p><p class="small">Eight native checks pass: all switch combinations, one-switch transitions, fixed scene conditions, distinct renders, image proportions, sheet contents and reversible material/light comparison. <a href="report.json">Evidence</a>. No physical headset or learner trial.</p></div>
</main><footer>Made in Godot 4.6 · Proposed for Color_Flashlight · <a href="../2026-10-01-lewitt-reading-a-rule/index.html">Earlier study: reading a rule</a></footer><script>{script}</script></body></html>'''
(HERE / "index.html").write_text(page, encoding="utf-8")
files = ["project.godot", "study.tscn", "study.gd", "capture.gd", "README.md"]
with ZipFile(HERE / "sphere-in-pink.zip", "w", ZIP_DEFLATED) as bundle:
    for name in files:
        bundle.write(STUDY / name, "sphere-in-pink/" + name)
manifest = {name: hashlib.sha256((STUDY / name).read_bytes()).hexdigest() for name in files}
(HERE / "source-hashes.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print("Built pink light study, 32 interactive states and native project archive.")
