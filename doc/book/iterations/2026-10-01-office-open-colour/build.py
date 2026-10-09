"""Publish the actual museum revision, including frozen source and native evidence."""
from pathlib import Path
import difflib
import hashlib
import html
import json
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
MAP = ROOT/'commons/maps/Color_Walls'
RUN = ROOT/'ada_run/encounter_pilot/Color_Walls'
report = json.loads((RUN/'report.json').read_text(encoding='utf-8'))
assert report['passed'] and len(report['checks']) == 47, 'Do not publish a failed or unrelated run'
for name in ['arrival-glass','arrival-opaque','layers-glass','layers-opaque','across-glass','back-glass','plan-oblique']:
    shutil.copyfile(RUN/(name+'.png'), HERE/(name+'.png'))
for name in ['report.json','source_manifest.json','stdout.log']:
    shutil.copyfile(RUN/name, HERE/name)
for image in RUN.glob('diagnostic-*.png'):
    shutil.copyfile(image, HERE/image.name)

def save_current(path, content):
    before = HERE/'before'/path.relative_to(ROOT)
    if not before.exists():
        before.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, before)
    tmp = path.with_name(path.name+'.office-edit.tmp')
    tmp.write_text(content, encoding='utf-8')
    tmp.replace(path)

note = '''## 2026-10-01 — Open colour planes

The active office now uses layout=planes: twelve large freestanding coloured sheets replace the eight cubicles. Three furnished places remain. Interrupted pale wings and a split canopy give the layered colours a readable ground; the central ceiling slot, side gaps and rear opening remain open. The FILTER / OPAQUE button changes alpha/transparency and shadow casting, preserving every pane's RGB, transform and exact collider. These are layered screen tints, not spectral glass or projected coloured light.

The supplied photograph prompted the arrangement; no artist attribution or exact reconstruction is claimed. Current final.md, tutorial, technical, critical, intent and summary follow the new layout. The earlier forty-pane and eight-cubicle observations below are historical.

47 focused native checks pass in the actual isolated production museum: ordinary-controller passage through the staggered route and rear exit in both modes, refusal at a pane, actual pointer callbacks, material state, fixed collision/geometry, repeated-config stability and the retained legacy layouts. No headset, learner or Quest performance trial. Review and working-copy snapshots: doc/book/iterations/2026-10-01-office-open-colour/index.html.

'''
for filename in ['field_notes.md','walked.md']:
    p = MAP/filename
    text = p.read_text(encoding='utf-8')
    if note.splitlines()[0] not in text:
        save_current(p, note + '---\n\n'+text)
p = MAP/'artifacts.md'
text = p.read_text(encoding='utf-8').replace('Office space with adaptive additive/subtractive constellations', 'The active office contains twelve freestanding colour planes and three workstations. Walk to change their overlap; FILTER / OPAQUE changes the view while keeping the same physical gaps. Pale backing and an open ceiling slot frame the installation.')
text = text.replace('![color_constellation_office](/scene-catalog/color_constellation_office.png)', '![The open colour office in the museum](/book-review/doc/book/iterations/2026-10-01-office-open-colour/across-glass.png)')
save_current(p, text)

p = ROOT/'commons/data/museum_core_encounters.json'
text = p.read_text(encoding='utf-8')
row = json.loads(text)['rooms']['Color_Walls']
for key, source in [('text_sha256',MAP/'final.md'),('map_sha256',MAP/'map_data.json')]:
    text = text.replace(row[key], hashlib.sha256(source.read_bytes()).hexdigest())
save_current(p, text)

files = [p.relative_to(HERE/'before').as_posix() for p in (HERE/'before').rglob('*') if p.is_file()]
files += ['algorithms/color/color_mixing/office_planes.gd']
sources = {}
diffs = []
for relative in sorted(set(files)):
    source = ROOT/relative
    frozen = HERE/'after'/relative
    frozen.parent.mkdir(parents=True,exist_ok=True)
    shutil.copyfile(source,frozen)
    sources[relative] = hashlib.sha256(source.read_bytes()).hexdigest()
    old = HERE/'before'/relative
    before = old.read_text(encoding='utf-8-sig').splitlines(keepends=True) if old.exists() else []
    after = source.read_text(encoding='utf-8-sig').splitlines(keepends=True)
    diff = ''.join(difflib.unified_diff(before,after,fromfile='before/'+relative,tofile='after/'+relative))
    diff_path = HERE/'diffs'/(relative+'.diff')
    diff_path.parent.mkdir(parents=True,exist_ok=True)
    diff_path.write_text(diff,encoding='utf-8')
    if diff:
        diffs.append(f'<details><summary>{html.escape(relative)}</summary><pre>{html.escape(diff)}</pre></details>')
(HERE/'source-hashes.json').write_text(json.dumps(sources,indent=2)+'\n',encoding='utf-8')

def prose(name):
    return markdown.markdown((MAP/name).read_text(encoding='utf-8'),extensions=['fenced_code','tables','footnotes'])

def figure(file, caption):
    return f'<figure><a href="{file}"><img src="{file}" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

def pair(key, first, second, labels):
    return f'''<div class="comparison">
    <input type="radio" name="{key}" id="{key}-a" checked><label for="{key}-a">{labels[0]}</label>
    <input type="radio" name="{key}" id="{key}-b"><label for="{key}-b">{labels[1]}</label>
    <div class="pair-a">{figure(first,labels[0]+' · native Godot museum')}</div>
    <div class="pair-b">{figure(second,labels[1]+' · native Godot museum')}</div></div>'''

css = '''
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f5f2ed;color:#202528;font:17px/1.6 system-ui,sans-serif}a{color:inherit;text-underline-offset:.22em}header,main,footer{max-width:1380px;margin:auto;padding:2rem 5vw}header{padding-top:4rem}nav{display:flex;flex-wrap:wrap;gap:1.4rem;font-size:.88rem;margin:1.7rem 0}h1{font-size:clamp(2.8rem,5vw,5.4rem);line-height:1;letter-spacing:-.05em;font-weight:500;max-width:900px;margin:1rem 0 1.8rem}h2{font-size:2rem;font-weight:500;margin-top:3.5rem}h3{font-size:1.2rem}.eyebrow{letter-spacing:.16em;font-size:.72rem;text-transform:uppercase}.lede{font-size:1.3rem;max-width:740px;color:#4b5457}figure{margin:1.2rem 0 2rem}img{display:block;width:100%;height:auto;background:#ddd}figcaption{font-size:.82rem;color:#576267;margin:.65rem 0}section{scroll-margin-top:2rem;border-top:1px solid #c8cfca;margin-top:3rem;padding-top:1rem}.reading{max-width:760px;margin:auto;font:21px/1.75 Georgia,serif}.reading h1{font:42px/1.1 Georgia,serif}.reading p:has(img){margin:2rem -5vw}.reading p:has(img) img{width:100%}.reading pre{font-size:14px;line-height:1.4}.columns{display:grid;grid-template-columns:1fr 1fr;gap:2rem}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#e6e8e2;padding:1.2rem;border-radius:4px;font:13px/1.6 monospace}code{font-size:.85em}details{border-top:1px solid #ccd1ca;padding:1rem 0}summary{cursor:pointer}table{width:100%;border-collapse:collapse;font-size:15px}td,th{text-align:left;padding:12px;border-bottom:1px solid #ccd1ca}.comparison>input{position:absolute;opacity:0}.comparison>label{display:inline-block;padding:.6rem 1rem;border:1px solid #9da7a0;border-radius:999px;cursor:pointer;margin:0 .5rem .3rem 0}.comparison>input:checked+label{background:#233a3e;color:#fff;border-color:#233a3e}.comparison>input:focus-visible+label{outline:3px solid #d565ae;outline-offset:3px}.pair-a,.pair-b{display:none}.comparison>input:first-of-type:checked~.pair-a,.comparison>input:nth-of-type(2):checked~.pair-b{display:block}.reference{max-width:850px;margin:auto}.note{border-left:3px solid #d474ad;padding-left:1.2rem;max-width:850px}.pill{padding:.3rem .8rem;background:#dce9e1;border-radius:999px;font-size:.85rem}footer{color:#69746e;font-size:.85rem;padding-bottom:4rem}@media(max-width:760px){.columns{grid-template-columns:1fr}.reading{font-size:19px}.reading p:has(img){margin:1rem 0}header,main,footer{padding-left:6vw;padding-right:6vw}}
'''
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Office · colour between the walls</title><style>{css}</style>
<header><div class="eyebrow">Ada / Colour / Color_Walls / 1 October 2026</div><h1>Colour between<br>the walls.</h1><p class="lede">The office opens into twelve coloured planes. Your movement composes the overlaps; the gaps give your body a way through.</p><nav><a href="#museum">Museum</a><a href="#comparison">Filter / opaque</a><a href="#reading">Read</a><a href="#making">Make</a><a href="#evidence">Evidence</a></nav></header>
<main><div id="museum">{figure('across-glass.png','Within the actual Color_Walls museum hall. Cyan, magenta and blue cross the view; the ceiling opens to the sky.')}</div>
<div class="columns"><div><h2>The cubicle opens</h2><p>Forty panes enclosing eight workstations become twelve freestanding sheets and three places to sit. Different heights, angled accents and interrupted edges loosen the repeated boxes.</p><p>A pale floor, open wings and a split canopy give the colours a bright ground. There is a route through the middle, a rear opening and gaps at the sides.</p></div><div><h2>A surface between us</h2><p>Look through two panes, then move until only one covers the chair. The geometry stays still while the visible composition changes.</p><p>The entrance button closes the view into opaque colour. Every collider and gap stays where it was. Seeing a way through and having a way through remain different conditions.</p></div></div>
<section><h2>Before / after</h2><p>Same arrival camera in the production museum, before and after this revision.</p>{pair('revision','before-office.png','arrival-glass.png',['Former cubicles','Open planes'])}</section>
<section id="comparison"><h2>Same room. Same gaps.</h2><p>Switch between two native captures from the same camera. In the museum, use the FILTER / OPAQUE button at the entrance.</p>{pair('visibility','layers-glass.png','layers-opaque.png',['Filter','Opaque'])}<p class="note">The surfaces use layered alpha tint, not a physical model of glass. The colour changes with both overlap and the renderer’s ordering of transparent surfaces.</p></section>
<section><h2>Other positions</h2><div class="columns">{figure('back-glass.png','Looking back through the open arrangement.')}{figure('plan-oblique.png','An oblique view reveals the staggered route and three workstations.')}</div><details><summary>The supplied reference</summary><div class="reference">{figure('reference.png','User-supplied reference: overlapping transparent planes, a pale setting and views through several colours. Artist and title have not been established here.')}</div></details></section>
<section id="reading"><div class="reading">{prose('final.md')}</div></section>
<section id="making"><h2>Make a change you can follow</h2><div class="reading">{prose('tutorial.md')}</div><details><summary>Implementation and limits</summary>{prose('technical.md')}</details></section>
<section id="evidence"><h2>Checked in the museum</h2><p><span class="pill">47 / 47 native checks pass</span></p><p>The ordinary desktop controller follows ten route legs and leaves through the rear opening in both material states. Direct approaches to a pane are blocked in both. Supplied pointer events operate the actual button. Colour, geometry and collision identity return after two switches; repeated placement configuration does not rebuild the installation.</p><p>These are native GPU captures from the production museum. There has been no headset or learner trial. The RGB/HSV and gradient benches remain placed; their earlier detailed checks are retained as dated evidence.</p><p><a href="report.json">Runtime report</a> · <a href="baseline-report.json">Before report</a> · <a href="source-hashes.json">Current source hashes</a> · <a href="DECISIONS.md">Design decisions and replay</a></p><details><summary>What the first material trial taught us</summary><p>Multiplication made even a white test sheet dark in this museum’s Compatibility rendering. Disabling fog did not resolve it; a minimal shader showed the same result. We retained alpha blending, inspected it from several viewpoints, and documented that its mixing depends on draw order. No claim of spectral absorption follows from the image.</p>{figure('diagnostic-white-multiply.png','Rejected diagnostic: one neutral white multiplier still darkened the view. This is evidence from an intermediate trial, not the final installation.')}</details><details><summary>Exact changes from the working-copy baseline</summary>{''.join(diffs)}</details></section>
</main><footer>Installed in Color_Walls, in the Colour sequence. The main text and tutorial shown here are frozen from the updated canonical manuscripts.</footer></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
(HERE/'DECISIONS.md').write_text('''# Colour between the walls

The supplied photograph calls for overlapping transparent planes and open views, rather than repeating closed cubicles. Twelve single-sheet panes replace forty box-shaped glass panels in the active Color_Walls placement. Three workstations retain the office association. The layout has pale interrupted wings and a split canopy, three small angled accents, a staggered central route and a rear exit.

The first multiplier material trial was rejected after inspecting the native images. Even an isolated white multiplier darkened the background in this Compatibility museum; a minimal shader reproduced it. The final installation uses unshaded alpha tint at 0.52, disables fog on the pane itself and uses one QuadMesh per sheet. Opaque mode preserves RGB values and geometry, sets alpha to 1.0 and enables shadow casting. Transparent sorting remains order-dependent. No spectral glass, refraction, projected coloured lighting or Quest performance claim.

The pale architectural backing is deliberately unshaded and casts no shadow: it is display apparatus inside the existing museum, with openings at its edges. Furniture and panes collide; the thin floor overlay and overhead visual canopy do not replace the museum's existing collision floor. All dimensions are in the editable PANES table, separate from furniture/support construction.

Canonical final.md, tutorial.md, technical.md, critical.md, summary.md, blurb.md and intent.md now follow this arrangement. History is retained with dated current notes. The colour models and gradient encounter remain as before. Existing unconfigured and layout=cubicles placements retain their own geometry and behaviour; the active Color_Walls token opts in to layout=planes.

Replay from repository root:

```powershell
python tools/run_encounter_probe.py Color_Walls --sequence color --render --probe doc/book/iterations/2026-10-01-office-open-colour/probe.gd
python doc/book/iterations/2026-10-01-office-open-colour/build.py
```

The route driver uses real supplied key events and a 15 cm waypoint tolerance, with a brief key-release interval between legs. Earlier runs exposed an oscillation at an 11 cm threshold and a missed key transition; the apparatus was corrected without changing collisions. Final runtime report: 47 checks pass, including both complete routes, pane blocking, pointer callbacks, material state, preserved bodies and the two legacy configurations.

Reference attribution remains the user's supplied image; its artist and title are not established here. The photo is a spatial prompt, not a recovered score. Technical reference: [Godot BaseMaterial3D](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html), including alpha blending and disable_fog. Native checks establish this implementation's desktop behaviour, not headset comfort or student understanding.
''',encoding='utf-8')
print(f'Published {HERE.relative_to(ROOT)}/index.html; {len(sources)} frozen current sources.')
