"""Publish native Godot evidence and a chapter-linked companion gallery."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import html
import json
import shutil
import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
STUDY = ROOT / 'doc/book/studies/reference-rooms'
ARTIFACTS = ROOT / 'commons/artifacts/reference_studies'
PREFIX = 'http://localhost:3003/book-review/'

ROOMS = [
    dict(id='suspension', title='A place still held', artist='Mona Hatoum',
         sequence='array_tutorial', maps=['Array','Tutorial_3D'], chapter='Arrays → the third dimension',
         rule='Change the fragments. Keep every address.', labels=['Regular blocks','Varied fragments'],
         text='A fragment hangs where the grid says it should. Its neighbours keep the same distance, although their edges no longer agree. The arrangement can remember a place for each piece; it cannot tell us what broke, or whether anything here can be repaired. Move around the rows. A small shift of your body separates what looked like one vertical line into many. Order survives in the distances between things that have lost their regular shape.',
         making='Reuse positions, loops and spacing. The fragment maker is supplied; changing its corners belongs to a later return through Randomness and Noise.',
         critical='Hatoum’s Remains to be Seen (2019) uses aligned rebar and concrete-like fragments with architectural associations. An array is one way to study its arrangement. It does not explain away the building materials, confinement or destruction invoked by the reference.',
         source='https://www.whitecube.com/gallery-exhibitions/remains-to-be-seen', source_label='White Cube · Remains to be Seen',
         reference='codex-clipboard-7abb8fc2-b9e0-4815-8912-9dc15d3f6b45.png',
         bounds=[5.4,5.0,5.4], question='What can a grid preserve when its contents are no longer whole?'),
    dict(id='passage', title='Who fits through?', artist='Mirosław Bałka',
         sequence='transformation', maps=['Trans_Scale','Trans_Body'], chapter='Transformation → scale and body',
         rule='Change the opening. Keep the visitor the same size.', labels=['0.48 m opening','1.68 m opening'],
         text='A wall stands inside the room. There is room around it, and an opening through it. From a distance, either route looks available. Up close, one of them may refuse you. The wall has not moved; only the width of its opening has changed. Your body makes that small difference consequential. A dimension becomes a condition of entry when something tries to pass.',
         making='Reuse box dimensions and collision. Two side pieces move together; the outer wall stays 5.2 m wide. Test the same 0.56 m capsule against both openings.',
         critical='This is an original passage prompted by the supplied Bałka photograph. Its photographed artwork’s exact title, date, dimensions and materials have not been verified. Our wall is assembled from boxes, not made by a Boolean operation. The test capsule is one chosen body, not a model for everybody.',
         source=None, source_label='User-supplied reference; identification remains open',
         reference='codex-clipboard-9c517d9c-a34e-4d20-9ecf-e3d729f38a27.png',
         bounds=[5.4,3.6,7.0], question='When does a measurement become permission?'),
    dict(id='landscape', title='A world from a cone', artist='Alex McLeod',
         sequence='color', maps=['Color_Context_Placed'], chapter='Colour → composition, with a return in shaders',
         rule='Change the height. Keep the forest’s sites and parts.', labels=['Low cones','Tall trees'],
         text='Three cones are enough for us to begin calling something a tree. Forty-eight groups become a forest; a glossy strip between them becomes water. Nothing in a cone knows about a tree. The resemblance gathers from repetition, colour and the things placed nearby. Lower the trees and the world becomes a collection of small objects again. The pieces have kept their addresses. What changes is the scale of the place we imagine ourselves entering.',
         making='Reuse primitives, scale, repetition and materials. The seeded site generator and curved arch are supplied. First change tree height; then exchange one part or one material.',
         critical='The supplied McLeod landscape is a reference for constructing a world through familiar synthetic forms. Its exact title is unverified. This kit uses original primitive arrangements; it does not infer the production method of the photographed work.',
         source='https://momentabiennale.com/en/artist/alex-mcleod/', source_label='MOMENTA · Alex McLeod',
         reference='codex-clipboard-c0b3f74d-7ed0-42fa-8665-314882fd2f16.png',
         bounds=[12,4.5,10], question='How little geometry does a world need before we believe in its scale?'),
    dict(id='pattern_garden', title='The pattern crosses over', artist='Claudia Hart',
         sequence='shaders', maps=['Shader_05_Patterns'], chapter='Shaders → patterns across surfaces',
         rule='Move the pattern. Keep the flowers and room still.', labels=['Phase 0','Half a cell later'],
         text='A black square reaches the edge of a petal. The flower does not move, but the square leaves it. The same change carries colour across the floor and the wall. For a moment a surface looks continuous with its surroundings; then another patch makes its edge appear again. We can still name the flower. Following its outline has become less certain. The room holds its shape while the pattern unsettles the places where we thought one thing ended and another began.',
         making='Reuse shader coordinates, uniforms and repetition. A shared phase feeds three pattern rules. The three-axis projection is supplied for the first exercise and can be opened for a later close reading.',
         critical='Hart’s Inside the Flower Matrix (2016) brings patterned architecture and fantastical flowers into a virtual labyrinth concerned with commercial digital space. Our coordinate experiment follows one visual question from that reference. It uses new geometry and does not reproduce her symbolic imagery, animation or score.',
         source='https://claudiahart.com/Inside-the-Flower-Matrix-XR-2016', source_label='Claudia Hart · Inside the Flower Matrix',
         reference='codex-clipboard-28328dd2-5a09-4f80-8bf9-bdf8d863150f.png',
         bounds=[12,5.5,10], question='Does the pattern help you see the object, or make its boundary harder to follow?'),
    dict(id='plural_body', title='A body in the plural', artist='Peaches & Pussykrew',
         sequence='shaders', maps=['Shader_11_QueerRubber','Shader_12_PinkExtravaganza'], chapter='Shaders → Queer Rubber and Pink Extravaganza',
         rule='Unfold the body. Keep its six arms and three heads.', labels=['Gathered','Unfolded'],
         text='The arms draw inward, then open. Three heads remain attached to the same trunk. Each part is a familiar surface, but their arrangement asks us to decide what belongs to a body. The pink rim follows our view; it offers no evidence that the material would yield to touch. Even this excessive figure obeys a strict agreement between its left and right sides. One next change could break that agreement. What would we keep recognising then?',
         making='Reuse transforms, interpolation and view-dependent shading. Curved limbs are supplied meshes. Alter one attachment, then one side’s material. Rigging, scans and physical deformation would require separate lessons.',
         critical='The last two supplied images are references to Peaches & Pussykrew’s Fill the Whole at CTM 2021. This is a new primitive assemblage, without their likenesses, scans, game, voice or music. More heads, arms or pink do not define queerness; the study asks which bodily arrangements the code permits and insists on.',
         source='https://www.factmag.com/2021/02/21/ctm-2021-peaches-pussykrew-fill-the-whole/', source_label='FACT / CTM · Fill the Whole',
         reference='codex-clipboard-e30afda3-8d34-404d-887f-6a8e941ea9ce.png',
         bounds=[6,4.5,5], question='Which attachments can change while we continue to recognise a body?'),
]

HERE.mkdir(exist_ok=True)
for file in (STUDY / 'captures').glob('*.png'):
    shutil.copyfile(file, HERE / file.name)
shutil.copyfile(STUDY / 'captures/report.json', HERE / 'report.json')
for name in ['README.md','MAKING.md','source-hashes.json']:
    shutil.copyfile(STUDY / name, HERE / name)
for room in ROOMS:
    source = Path('C:/Users/palle/AppData/Local/Temp') / room['reference']
    shutil.copyfile(source, HERE / (room['id']+'-reference.png'))
shutil.copyfile(Path('C:/Users/palle/AppData/Local/Temp/codex-clipboard-419b127d-e938-4af9-913a-3abdfde0f39a.png'), HERE/'plural_body-game-reference.png')

registry = {'artifacts':{}}
for room in ROOMS:
    lookup = 'reference_'+room['id']
    registry['artifacts'][lookup] = {
        'lookup_name':lookup, 'name':room['title'],
        'scene':'res://commons/artifacts/reference_studies/'+room['id']+'.tscn',
        'description':room['rule']+' Independent chapter companion; use the reference-rooms desktop viewer.',
        'sequence':room['sequence'], 'category':'reference_studies',
        'map_ready':False, 'include_in_map_data':False,
        'complexity':'intermediate', 'tags':['reference-study',room['sequence']],
        'signals':['state_changed'], 'parameters':{'amount':'0–1, set_amount(value)'},
        'interactions':['Change amount in the inspector or supplied desktop viewer'],
        'qfep_connection':room['question'],
        'proposed_maps':room['maps'], 'minimum_display_bounds_m':room['bounds'],
        'reference_artist':room['artist'], 'status':'chapter companion; not installed in the spine'
    }
(ROOT/'commons/artifacts/registry/reference_studies.json').write_text(json.dumps(registry,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
(HERE/'CHAPTERS.json').write_text(json.dumps({'status':'chapter companions; no main museum placements','rooms':ROOMS},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

files = [STUDY/name for name in ['project.godot','gallery.tscn','gallery.gd','capture.gd','README.md','MAKING.md','source-hashes.json']]
files += [p for p in (STUDY/'artifacts').iterdir() if p.suffix in ['.gd','.gdshader','.tscn']]
with ZipFile(HERE/'five-reference-rooms.zip','w',ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path,'five-reference-rooms/'+path.relative_to(STUDY).as_posix())
(HERE/'archive-hashes.json').write_text(json.dumps({p.relative_to(STUDY).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in files},indent=2)+'\n',encoding='utf-8')

css = '''
:root{color-scheme:dark;--bg:#161419;--ink:#f1ece5;--muted:#c1b7bf;--pink:#f2adcb}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--bg);color:var(--ink);font:18px/1.65 system-ui,sans-serif}a{color:var(--pink);text-underline-offset:4px}header,main,footer{max-width:1320px;margin:auto;padding:38px 32px}header{padding-top:70px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.08}h1{font-size:clamp(44px,7vw,86px);max-width:900px;margin:16px 0 28px}h2{font-size:clamp(32px,4vw,56px);margin:10px 0 18px}h3{font-size:19px}.eyebrow{letter-spacing:.13em;text-transform:uppercase;font-size:12px;color:var(--pink)}.lead{font-size:23px;max-width:850px}.muted,figcaption,.small{color:var(--muted);font-size:14px}.actions{display:flex;gap:12px;flex-wrap:wrap;align-items:center}.button,button{display:inline-block;border:1px solid #756773;border-radius:3px;padding:9px 15px;background:transparent;color:var(--ink);font:inherit;font-size:15px;text-decoration:none;cursor:pointer}.button:hover,button:hover,button[aria-pressed=true]{background:var(--pink);color:#221820}nav{position:sticky;top:0;background:#161419ee;backdrop-filter:blur(12px);z-index:2;display:flex;gap:24px;padding:14px 32px;overflow:auto;border-block:1px solid #3c343e}nav a{white-space:nowrap;text-decoration:none;color:var(--ink);font-size:14px}section{padding-top:65px;margin-bottom:65px;scroll-margin-top:55px}figure{margin:24px 0}img{display:block;width:100%;height:auto;border-radius:3px}figcaption{padding-top:8px}article{max-width:820px;font:24px/1.7 Georgia,serif;margin:35px auto}.notes{display:grid;grid-template-columns:1fr 1fr;gap:36px;border-top:1px solid #493c47;padding-top:24px}.notes p{font-size:16px}.refs img{max-width:850px;margin:18px auto}.refs summary{cursor:pointer;color:var(--muted)}.compare{position:relative}.compare img{aspect-ratio:8/5;object-fit:contain}.state{font-size:13px;letter-spacing:.06em;text-transform:uppercase;margin-left:10px;color:var(--pink)}.rule{font-size:20px}pre{overflow:auto;background:#242029;padding:18px;font:15px/1.6 monospace}.reading{max-width:850px;margin:auto}.reading p,.reading li{font-size:18px}.reading h1{font-size:52px}.reading h2{font-size:32px;margin-top:50px}table{border-collapse:collapse;width:100%;font-size:15px}th,td{border-bottom:1px solid #493c47;padding:12px;text-align:left}.steps{display:grid;grid-template-columns:repeat(5,1fr);gap:12px;margin:32px 0}.steps img{aspect-ratio:8/5;object-fit:cover}.steps a{font-size:13px;text-decoration:none}footer{border-top:1px solid #493c47}code{font-size:.84em}button:focus-visible,a:focus-visible,summary:focus-visible{outline:3px solid var(--pink);outline-offset:4px}@media(max-width:760px){header,main,footer{padding:24px 18px}.notes{grid-template-columns:1fr;gap:14px}article{font-size:21px}.steps{grid-template-columns:repeat(2,1fr)}nav{padding:12px 18px;gap:18px}.lead{font-size:20px}section{padding-top:42px}}
'''
css += '''.choice{position:absolute;opacity:0;width:1px;height:1px}.compare .first-view,.compare .second-view{display:none}.first:checked~.first-view,.second:checked~.second-view{display:block}.first:checked~.actions .first-label,.second:checked~.actions .second-label{background:var(--pink);color:#221820}.first:focus-visible~.actions .first-label,.second:focus-visible~.actions .second-label{outline:3px solid var(--pink);outline-offset:4px}'''
nav = '<nav aria-label="Study rooms">'+''.join(f'<a href="#{r["id"]}">{i+1:02d} · {html.escape(r["title"])}</a>' for i,r in enumerate(ROOMS))+'</nav>'
sections=[]
for i,r in enumerate(ROOMS):
    rid=r['id']
    source=(f'<a href="{r["source"]}">{html.escape(r["source_label"])}</a>' if r['source'] else html.escape(r['source_label']))
    map_links=' · '.join(f'<a href="{PREFIX}commons/maps/{m}/final.md">{m.replace("_"," ")}</a>' for m in r['maps'])
    sections.append(f'''<section id="{rid}">
<div class="eyebrow">{i+1:02d} / {html.escape(r['chapter'])}</div><h2>{html.escape(r['title'])}</h2>
<p class="rule">{html.escape(r['rule'])}</p>
<figure><img src="{rid}-hero.png" alt="Native Godot interior: {html.escape(r['title'])}" loading="lazy"><figcaption>Our Godot study · {html.escape(r['artist'])} reference below · desktop room, not a screenshot of an installed spine hall.</figcaption></figure>
<article><p>{html.escape(r['text'])}</p></article>
<div class="compare" role="group" aria-label="{html.escape(r['title'])} comparison"><input class="choice first" type="radio" name="{rid}-state" id="{rid}-first" checked><input class="choice second" type="radio" name="{rid}-state" id="{rid}-second"><div class="actions"><label class="button first-label" for="{rid}-first">{html.escape(r['labels'][0])}</label><label class="button second-label" for="{rid}-second">{html.escape(r['labels'][1])}</label></div><figure class="first-view"><img src="{rid}-before.png" alt="Fixed-camera comparison: {html.escape(r['labels'][0])}" loading="lazy"><figcaption>{html.escape(r['labels'][0])} · Recorded native Godot state.</figcaption></figure><figure class="second-view"><img src="{rid}-after.png" alt="Fixed-camera comparison: {html.escape(r['labels'][1])}" loading="lazy"><figcaption>{html.escape(r['labels'][1])} · Recorded native Godot state.</figcaption></figure><p class="small">Select a state to compare. Continuous control and walking are in the downloadable project.</p></div>
<div class="notes"><div><h3>What the learner brings</h3><p>{html.escape(r['making'])}</p><p><a href="making.html#{rid}">Try the small exercise</a> · <a href="{rid}-controls.png">See native controls</a></p><p class="small">Chapter companions: {map_links}</p></div><div><h3>Keep the reference in view</h3><p>{html.escape(r['critical'])}</p><p>{source}</p></div></div>
<details class="refs"><summary>Open the supplied reference image</summary><figure><img src="{rid}-reference.png" alt="User-supplied reference attributed to {html.escape(r['artist'])}" loading="lazy"><figcaption>Supplied by Palle. Reference artwork; not generated by this project. The annotation, where present, belongs to the supplied image.</figcaption></figure></details>
</section>''')
report=json.loads((HERE/'report.json').read_text())
assert report['passed'], 'Do not publish failed native verification.'
count=len(report['checks'])
thumbs=''.join(f'<a href="#{r["id"]}"><img src="{r["id"]}-hero.png" alt="" loading="lazy">{r["title"]}</a>' for r in ROOMS)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Five rooms after an image · Ada</title><style>{css}</style></head><body>
<header><div class="eyebrow">Ada / native Godot studies / 01 October 2026</div><h1>Five rooms<br>after an image.</h1><p class="lead">An arrangement gives us somewhere to begin. Change one relation, enter it, and see what the image could not show.</p><p>Five original responses to your references, made as chapter companions with editable code, a walking viewer and a small experiment in each room.</p><div class="actions"><a class="button" href="five-reference-rooms.zip">Download all five · Godot project</a><a class="button" href="making.html">The making route</a><a href="README.md">Method and controls</a></div><div class="steps">{thumbs}</div></header>
{nav}<main>{''.join(sections)}<section id="evidence"><h2>From image to something we can change.</h2><p class="lead">The picture starts the inquiry. The artifact lets us test a choice. The text keeps asking what that choice means.</p><div class="notes"><div><h3>Built and checked</h3><p>{count} native checks passed in Godot 4.6, including actual capsule passage, fixed addresses, visible parameter changes and restoring the original state. <a href="report.json">Read the report</a>.</p><p>Five portable scenes are also saved in the project’s artifact library. They have no player or camera dependency and expose a single amount control.</p></div><div><h3>Where they are now</h3><p>These are independent chapter companions, with proposed homes recorded in <a href="CHAPTERS.json">the chapter manifest</a>. They have not been placed in the main museum halls or inserted into final.md. There is no headset or learner-trial claim.</p><p>The exercises identify borrowed apparatus. A learner can change the central rule before knowing how to build every mesh or the viewing system.</p></div></div></section></main><footer><a href="../2026-10-01-lewitt-reading-a-rule/index.html">Reading a rule · LeWitt</a> · <a href="../2026-10-01-sphere-in-pink/index.html">A sphere in pink</a> · <a href="MAKING.md">Making source</a></footer></body></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
making=markdown.markdown((STUDY/'MAKING.md').read_text(encoding='utf-8'),extensions=['fenced_code','tables'])
# Stable room anchors alongside the prose's own headings.
for i,r in enumerate(ROOMS):
    making=making.replace(f'<h2>{i+1}. ',f'<span id="{r["id"]}"></span><h2>{i+1}. ',1)
(HERE/'making.html').write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Five small transfers · Ada</title><style>{css}</style></head><body><header><a href="index.html">← Five rooms</a> · <a href="five-reference-rooms.zip">Download the project</a></header><main class="reading">{making}</main><footer><a href="index.html">Back to the rooms</a></footer></body></html>',encoding='utf-8')
# Save the proposed main-text passages separately from the live manuscript.
(HERE/'PASSAGES.md').write_text('# Five chapter companion passages\n\nDrafts beside the built studies; not promoted to final.md.\n\n'+'\n\n'.join(f'## {r["title"]}\n\n{r["text"]}' for r in ROOMS)+'\n',encoding='utf-8')
print(f'Published five rooms, {count} native checks and {len(files)} portable files.')
