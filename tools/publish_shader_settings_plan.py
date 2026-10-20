"""Publish a source-grounded spatial proposal; never mutate museum/runtime files."""
from pathlib import Path
import collections
import hashlib
import html
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-10-shaders-in-situ'
OLD = ROOT / 'doc/book/iterations/2026-10-10-shader-pattern-survey'
OUT.mkdir(parents=True, exist_ok=True)
gallery = json.loads((OLD / 'gallery-manifest.json').read_text(encoding='utf-8-sig'))
images = {e['id']: e for e in gallery['entries']}

# The staging and interactions below are proposals. Source existence is checked below.
halls = [
    dict(map='Shader_01_Shaping', title='A mark becomes a surface', setting='Graphic wall / small workbench', image='shader_01_shaping',
         encounter='Begin at the museum wall, with one large circle mask beside the existing graphs. A small cube provides the same rule on another receiver. Leave enough blank wall for the boundary to read.',
         learn='UV coordinates, a distance mask, one uniform controlling its boundary. Keep step versus smoothstep as a visible comparison.',
         action='Move the boundary with one nearby control, then change its radius in the complete printed shader. Predict which sampled positions change.',
         keep='The same mask and its parameters travel forward as code. No new geometry is needed to draw the circle.',
         reflection='An image of an opening is not yet an opening you can pass through.',
         extra='Use the existing five graphs as reference exhibits; only one mask carries the reconstruction lesson.'),
    dict(map='Shader_05_Patterns', title='The image leaves its frame', setting='Patterned passage / domestic fragments', image='tiles_explained',
         encounter='Let the wall pattern continue onto a floor, a column and a familiar chair. Keep a neutral strip along the route. Reuse actual project props rather than inventing another sample rack.',
         learn='Transform and repeat the sampling coordinates. Distinguish the address of a tile from the position inside it.',
         action='Keep the chair still and slide the pattern; then move the chair. Compare attached UVs with a supplied world-coordinate material.',
         keep='The learner retains the original mask and adds a coordinate function. The woven cloth is a reference for continuity, not a prerequisite clothing system.',
         reflection='A repeated mark can suggest that several unrelated objects belong to one place.',
         extra='Tartan, optical checks and one animal mask can be nearby applications without becoming three extra coding lessons.'),
    dict(map='Shader_11_QueerRubber', title='A familiar object acquires another skin', setting='Uncanny furnished room / material stage', image='Shader_Gallery',
         encounter='Use the project sofa, chair and vase alongside the carried sphere. Give the same objects velvet, leather, oil sheen or pearl. Keep the silhouette recognizable so the material change can be felt.',
         learn='Material response: surface normal, roughness and view-dependent rim. Begin on the same sphere under fixed light.',
         action='Walk around it; then change one response while holding mesh and lighting constant. Transfer that material to one furnished object.',
         keep='The same receiver and mask now control material channels. Normal-based detail is compared with actual silhouette change only after it is understood.',
         reflection='A surface suggests softness, expense, bodily contact or discomfort; those suggestions do not establish its physical behaviour.',
         extra='Oil-Slick Latex, Crushed Pearl and Sad Metal are existing material candidates. Their names are invitations, not verified physical models.'),
    dict(map='Shader_09_FBM', title='Water becomes a place', setting='Sunken basin / impossible bathhouse', image='waves',
         encounter='Give water a substantial place in the hall: a low basin, a visible edge and a route around it, with a chair or column reflected in the composition. Begin with the existing basin rather than installing an unrelated ocean.',
         learn='Reuse waves and noise as a height field; apply it to a sufficiently subdivided mesh and account for the visible normal. Layered noise is a return to prior work.',
         action='Hold the field fixed; compare colour only, normal response and vertex displacement. Look at the edge to identify which mode changes the silhouette.',
         keep='The familiar surface rule now affects vertices. Mesh density returns from Primitives; the floor/support remains an explicitly separate construction.',
         reflection='What looks deep, wet or yielding may still be supported by a flat invisible collider. The room makes that distinction available to experience.',
         extra='Show one water application at scale. Refraction, foam and underwater viewing stay supporting studies until validated; do not pack them all into the first water lesson.'),
    dict(map='Shader_12_PinkExtravaganza', title='The room can be otherwise', setting='Abstract and surreal assemblage / open stage', image='shader_12_pinkextravaganza',
         encounter='Recombine recognizable furniture, the learner sphere, cloth, columns and water-like surfaces at deliberate scales. A reflective sofa, hovering drape or apparently liquid ceiling should change a spatial expectation, not just add decoration.',
         learn='Compose known masks, domains and material channels. No compulsory new mathematical technique.',
         action='Choose one prefab; make two distinct readings by changing only its material rule, then change its setting while keeping the material fixed.',
         keep='A material recipe and the declared receiver. Wearing the result can be an optional return to Tiling once the actual player material adapter is checked.',
         reflection='Which qualities did the asset library assume, and which did the student alter? Surreal space comes from relationships as well as unusual colour.',
         extra='Candidates include candy deformation, patterned skin, foil and dream water. Select a few that make a composition, not all available shaders.'),
    dict(map='Shader_10_ReactionDiffusion', title='An encounter leaves a trace', setting='Quiet return / wall that remembers', image='shader_10_reactiondiffusion',
         encounter='Return to a restrained room after the stage. Put an animated material beside a surface that genuinely retains a mark, once its state path is implemented.',
         learn='Time-driven evaluation versus a stored previous state. Actual reaction–diffusion is a further operation, not a synonym for a retained mark.',
         action='Leave a mark, stop input and test that the stored record remains; reset it deliberately. Compare with a pattern that only changes with TIME.',
         keep='A declared state owner and update rule, providing a concrete bridge toward cellular automata.',
         reflection='A surface can appear to carry history without keeping any. Locate what the world actually retains.',
         extra='The current reaction–diffusion panel has a missing previous-state input. The degradation manager needs integration. Memory Skin is moving noise, not contact history.'),
]

assets = [
 ('Water basin', 'commons/artifacts/basin_water/basin_water.tscn', 'Existing Shaders / FBM anchor', 'Directional sines, value noise, displaced surface and a separate supporting construction. Strong starting point for the room-scale application.'),
 ('Water comparison', 'algorithms/patterngeneration/waves/waves.tscn', 'Pattern_Generation_Five source', 'Several older water materials on simple receivers. Re-stage a selected one; do not import the whole floor arrangement unexamined.'),
 ('Noise-displaced water', 'algorithms/patterngeneration/waves/water2.gdshader', 'Repair candidate', 'Plain SCREEN_TEXTURE/DEPTH_TEXTURE sampler uniforms lack screen/depth hints; the scene assigns noise as SCREEN_TEXTURE. Do not describe this as verified scene refraction.'),
 ('Waterfloor', 'commons/resourses/shaders/waterfloor.gdshader', 'Water study', 'Normal textures, displacement and hinted screen/depth sampling. Source found; renderer/depth and stereo behaviour still require testing.'),
 ('View under water', 'commons/resourses/shaders/see_under_water.gdshader', 'Optional optical study', 'Samples a screen texture with distortion. A viewing effect, not a complete underwater physical environment.'),
 ('Dream water', 'algorithms/shaders/book_of_shaders/queer_water.gdshader', 'Pink composition candidate', 'Sine displacement, animated noise, view-dependent colour and emission. No fluid solver.'),
 ('Flag-coloured water', 'commons/resourses/shaders/bitwisewater.gdshader', 'Optional material', 'Palette presets, waves and shimmer. Queer inquiry must also examine body, relation and constraints; a flag palette alone is not the argument.'),
 ('Frosted divider', 'algorithms/patterngeneration/glassdivider/glassdivider.tscn', 'Window / passage candidate', 'An existing divider scene with screen/depth-dependent material. Test what is visible through it in each eye.'),
 ('Material transmission', 'algorithms/shaders/materialtransmission/materialstransmission.tscn', 'Optional optical comparison', 'Existing code-driven gallery with transmission material. Keep camera-dependent effects out of the minimal first shader.'),
 ('Normal / displaced stone', 'algorithms/patterngeneration/fabrics/normalstone.gdshader', 'Controlled comparison', 'An explicit vertex-displacement toggle makes normal-only detail versus silhouette change teachable.'),
 ('Leather / velvet / plastic gallery', 'algorithms/shaders/Shader_Gallery.tscn', 'Material room sources', 'Useful on the same known form, then on a recognizable prefab. These are visual responses, not simulated leather or cloth.'),
 ('Oil, pearl, skin, metal, candy collection', 'algorithms/shaders/queer_collection_2/Collection_Gallery_A.tscn', 'Additional collection outside six-hall teaching list', 'Five material spheres with their own lights, environment and camera. Extract selected materials; do not import a second global environment blindly.'),
 ('Memory Skin', 'algorithms/shaders/queer_collection_2/memory_skin.gdshader', 'Counterexample in final hall', 'Its marks are sampled from moving noise using TIME. No contact record is retained by this shader.'),
 ('Melted Candy', 'algorithms/shaders/queer_collection_2/melted_candy.gdshader', 'Surreal composition', 'Sine-based vertex deformation and glossy colour. Does not accumulate a melting process.'),
 ('Foil', 'commons/resourses/shaders/foil_paper.gdshader', 'Drape / stage candidate', 'Perturbs NORMAL and roughness; no vertex function. A crumpled appearance does not make a folded mesh.'),
 ('Coffee swirl', 'commons/resourses/shaders/coffeeswirl.gdshader', 'Small domestic counterpoint', 'Polar-coordinate and sine warps; useful at cup/table scale. Its entropy parameter is an artistic control, not a measured physical entropy.'),
 ('Animal patterns', 'algorithms/patterngeneration/animalpatterns/animalpatterns.tscn', 'Pattern passage / composition', 'Stripes, spots and patterned receivers. Compare mask and palette separately; do not claim biological growth.'),
 ('Spatial material collection', 'commons/artifacts/shader_arch_gallery/shader_arch_gallery.tscn', 'Abstract staging source', 'A spatial composition of pattern/domain choices, useful after one controlled receiver.'),
 ('Degrading surface', 'algorithms/shaders/degrading_shader/DegradingShaderManager.gd', 'Stateful candidate needing wiring', 'A candidate owner for retained marks. Existing demo does not establish that the manager is connected to museum interaction.'),
 ('Pixelated view', 'commons/resourses/shaders/pp_pixelate_spatial.gdshader', 'Optional backstage viewing booth', 'Treat changing the camera image as a different operation from changing an object material. Not a compulsory extra hall.'),
 ('Sofa prefab', 'commons/primitives/sofa/sofa.tscn', 'Existing furnished receiver', 'Inspect UVs, material slots and collider before replacing materials.'),
 ('Chair prefab', 'commons/primitives/chair/chair_modern.tscn', 'Existing furnished receiver', 'A recognizable object supports comparisons between appearance and expected use.'),
 ('Vase prefab', 'commons/primitives/design_classics/aalto_vase.tscn', 'Existing furnished receiver', 'A familiar profile makes changes in surface response legible.'),
]

def esc(s): return html.escape(str(s), quote=True)
def link_source(p): return '/book-review/' + p

shader_paths = subprocess.check_output(['rg', '--files', '-g', '*.gdshader', 'algorithms', 'commons'], cwd=ROOT, text=True).splitlines()
shader_paths = sorted(p.replace('\\', '/') for p in shader_paths)
shader_counts = dict(collections.Counter('/'.join(p.split('/')[:2]) for p in shader_paths))
source_hashes = {}
for _, path, _, _ in assets:
    p = ROOT / path
    assert p.is_file(), path
    source_hashes[path] = hashlib.sha256(p.read_bytes()).hexdigest()
source_hashes['doc/VR_VR_PT_2023.md'] = hashlib.sha256((ROOT/'doc/VR_VR_PT_2023.md').read_bytes()).hexdigest()
inventory = dict(date='2026-10-10', scope='Planning and selected source inspection. No new engine/headset validation.',
                 shader_file_count=len(shader_paths), count_scope='rg --files, .gdshader files under algorithms and commons; not unique effects, excludes inline shader strings',
                 shader_counts=shader_counts, shader_paths=shader_paths,
                 candidates=[dict(title=t,path=p,status=s,finding=f) for t,p,s,f in assets],
                 halls=halls, source_hashes=source_hashes)
(OUT/'inventory.json').write_text(json.dumps(inventory,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

intro = '''# Shaders in places

10 October 2026 · spatial and tutorial proposal for Endless Museum

The shader sequence needs scenes with a reason to be there. A furnished room, basin, passage or abstract stage gives the material something to change. The existing six-hall route remains a useful provisional structure; its order and density can still change after one staged hall is tested.

This pass records a direction and a source inventory. The settings below are not built yet. Museum maps, runtime code and tutorial/final manuscripts are unchanged. Images are reused Godot specimens from the earlier survey, not renders of these proposed rooms.

## What the references contribute

- [Intro till Queer 3D world 2024](https://docs.google.com/document/d/1ndU2dkp55eR-qC2qC121hLkFXIML41-Nu3PFVo1AxYg/edit): prefabs and digital archives as artistic material; skins, impossible rooms and the relation between technical literacy and aesthetic choices. Carry a recognizable thing through a change so the operation has consequences.
- [edgeartist](https://docs.google.com/document/d/1p0hG1Og96_CwDl-OA1eZMUG0GPdLy41Am2Adstc07Qo/edit): a collection of spatial desires—folding, softness, scale, accumulation, inside/outside and unstable material identity. It explicitly places Claudia Hart near shaders. Use these as research prompts, not verified histories or recipes for copying an artist's style.
- [VR_VR_PT_2023 research application](/book-review/doc/VR_VR_PT_2023.md): the project proposes an increasingly complex landscape of algorithms, strange realities, exploratory spaces and a relation between abstraction and surrealism. The application is a statement of aims; its historical examples need independent checking before reuse in the book.

My reading: the technical operation must stay exact, while the encounter can become extravagant. The same rule should be inspectable on a simple receiver and meaningful when situated in a larger world. A strange colour does not by itself establish a queer relation; ask what the setting permits a body to do, expect or become.

## Two simultaneous progressions

Teaching: coordinates → mask → repeated/transformed domain → material response → displaced field → composition → retained state.

Experience: image → patterned place → familiar object made strange → water at architectural scale → abstract/surreal assemblage → a room that keeps an encounter.

For each hall, use one primary reconstruction object and at most a few nearby comparisons. Retain the student's sphere/cube and shader functions where they still clarify the work. A furnished prop is a second receiver, not a reason to explain modelling from scratch. The museum can contain more than the tutorial teaches.

## Six proposed settings
'''
md = intro
for i,h in enumerate(halls,1):
    md += f"\n### {i}. {h['title']} — {h['map']}\n\n**Setting:** {h['setting']}. {h['encounter']}\n\n**Tutorial:** {h['learn']} {h['action']}\n\n**Carried forward:** {h['keep']}\n\n**Reflective question:** {h['reflection']}\n\n**Supporting encounters:** {h['extra']}\n"
md += '''
## Give water enough room without making it every subject

Water is already partly in the route through basin_water, while the larger collection remains outside it. Use the basin as the next environmental proof: one controlled height field, a simple object beside it, a visible edge and a clearly supported path. Do not present refraction, foam, buoyancy, displacement, noise and fluid simulation as one tiny lesson. If the water encounter needs a separate teaching step after testing, split it explicitly; six is a working structure, not a quota.

The existing water2 shader is a concrete repair candidate: its screen and depth samplers have no capture hints, and the scene feeds noise into its screen slot. Godot's [screen-reading documentation](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html) specifies those hints and explains that the 3D screen copy excludes transparent geometry. A good desktop still cannot establish working refraction in a headset. Validate the chosen renderer, both eyes and the actual scene inputs.

## Existing sources to choose from

The inventory counts shader source files, not distinct working artifacts. Only the selected candidates below received this inspection. The old visual survey contains 76 specimens across shaders, patterns, machines and spaces; it is not a complete shader inventory.

| Existing source | Proposed role / current limit |
|---|---|
'''
for title,path,status,finding in assets:
    md+=f'| [{title}]({link_source(path)}) | **{status}.** {finding} |\n'
md+='''
## Next implementation pass

1. Start Shaping with one complete printed mask and a declared receiver. Preserve useful existing graphs as supporting exhibits.
2. Reconstruct the printed code in a fresh learner fixture. Assert parameter binding and expected samples; verify real rendered output as well as shader compilation.
3. Stage the same rule in its proposed setting. Check entry view, close interaction and side view; provide a nearby control and reset.
4. For the water and material halls, compare fixed geometry, normal response and displacement independently. Test collider/support separately.
5. Capture the real museum; label desktop versus headset evidence accurately. Then revise tutorial.md and final.md around what that encounter actually does.

Only after the water proof and the first lessons should we decide whether optical effects need their own hall. Keep screen effects, elaborate transmission and the wider material catalogue available as optional encounters.

## Compact AI brief

WORLD: existing Endless Museum. DIRECTION: situate shaders in prefab/domestic, abstract, surreal settings; water at room scale. TEACH: one operation + one carried receiver per hall. SECOND RECEIVER: recognizable prop. SHOW: rule → appearance → spatial consequence. SEPARATE: pixel colour / normal / vertex / collider / retained state. KEEP: six-hall order provisional; archive wider than tutorial. SOURCES: Queer 3D 2024, edgeartist, VR_VR_PT_2023 application. VERIFY: actual source, printed-code reconstruction, render, museum path, headset when available. DO NOT: treat shader names as behaviour, pink as a complete queer argument, animated marks as memory, or specimen images as newly built rooms.
'''
(OUT/'PLAN.md').write_text(md,encoding='utf-8')

cards=[]
for i,h in enumerate(halls,1):
    im=images[h['image']]
    src='../'+OLD.name+'/'+im['image']
    assert (OUT/src).resolve().is_file()
    cards.append(f'''<article id="{h['map']}"><div class="number">0{i} / {esc(h['map'])}</div><h2>{esc(h['title'])}</h2><p class="setting">{esc(h['setting'])}</p><figure><a href="{src}"><img src="{src}" alt="Existing {esc(im['title'])} Godot specimen" loading="lazy"></a><figcaption>Existing specimen: {esc(im['title'])}. {esc(im['provenance'])}. Proposed setting below is not built.</figcaption></figure><p>{esc(h['encounter'])}</p><dl><dt>One teaching focus</dt><dd>{esc(h['learn'])}</dd><dt>Student action</dt><dd>{esc(h['action'])}</dd><dt>What travels</dt><dd>{esc(h['keep'])}</dd><dt>Reflection</dt><dd>{esc(h['reflection'])}</dd></dl><p class="support">{esc(h['extra'])}</p></article>''')
rows=''.join(f'<tr><td><a href="{esc(link_source(p))}">{esc(t)}</a></td><td>{esc(s)}</td><td>{esc(f)}</td></tr>' for t,p,s,f in assets)
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Shaders in places · Endless Museum</title><style>
*{{box-sizing:border-box}}body{{margin:0;background:#f2eee7;color:#212226;font:17px/1.6 system-ui,sans-serif}}header,main,footer{{max-width:1360px;margin:auto;padding:38px}}header{{padding-top:60px}}h1{{font:clamp(46px,7vw,90px)/1.03 Georgia,serif;max-width:900px;margin:16px 0 25px}}h2{{font:32px/1.1 Georgia,serif;margin:15px 0}}a{{color:#8a3157;text-underline-offset:4px}}nav{{display:flex;gap:20px;flex-wrap:wrap;margin-top:20px}}.kicker,.number{{font:12px/1.4 monospace;letter-spacing:.1em;text-transform:uppercase}}.lede{{font-size:22px;max-width:930px}}.notice,.support{{padding:16px;background:#e7e0d4;border-left:3px solid #a15570}}.route{{padding:25px;background:#22232a;color:#fff;margin:20px 0 40px}}.route span{{color:#f2b5cf}}.grid{{display:grid;grid-template-columns:1fr 1fr;gap:24px}}article{{padding:26px;background:#fffdf9;border:1px solid #d4ccbf;scroll-margin-top:25px}}.setting{{color:#8a3157;font-weight:600}}figure{{margin:24px 0}}img{{width:100%;height:250px;object-fit:contain;background:#17191d}}figcaption{{font-size:12px;color:#666;line-height:1.4;margin-top:7px}}dt{{font-weight:650;margin-top:15px}}dd{{margin:3px 0 0}}.sources{{margin:55px 0}}table{{width:100%;border-collapse:collapse;font-size:14px}}td,th{{text-align:left;border-bottom:1px solid #cfc5b9;padding:14px;vertical-align:top}}td:first-child{{width:24%}}td:nth-child(2){{width:23%}}footer{{font-size:14px}}@media(max-width:800px){{.grid{{grid-template-columns:1fr}}header,main,footer{{padding:22px}}table{{font-size:12px}}td,th{{padding:8px}}}}@media print{{.grid{{display:block}}article{{break-inside:avoid;margin:15px 0}}nav{{display:none}}}}
</style></head><body><header><div class="kicker">Endless Museum · spatial proposal · 10 October 2026</div><h1>What happens when a shader has a place?</h1><p class="lede">A material on a chair, a pattern across a passage, water at architectural scale. Keep the operation small enough to learn; let its setting open another experience.</p><p class="notice">Source survey + proposed settings. No museum or lesson code changed. Images are existing Godot specimens, not renders of these proposed rooms.</p><nav><a href="#route">Six settings</a><a href="#sources">23 existing sources</a><a href="PLAN.md">Full editable plan</a><a href="inventory.json">Source inventory</a><a href="../{OLD.name}/gallery.html">Existing 76-specimen gallery</a></nav></header><main><section class="route" id="route"><div class="kicker">Two progressions, one museum</div><p><span>Experience</span> · image → patterned place → unfamiliar skin → basin → surreal stage → retained encounter</p><p><span>Teaching</span> · coordinates → mask → domain → material → displacement → composition → state</p></section><div class="grid">{''.join(cards)}</div><section class="sources" id="sources"><h2>The collection is larger than the route</h2><p>{len(shader_paths)} shader files found under algorithms/ and commons/ (not {len(shader_paths)} verified effects). The existing visual survey has 76 shader/pattern specimens. This pass selects 23 source candidates and prefab receivers.</p><table><thead><tr><th>Source</th><th>Role</th><th>What we can claim now</th></tr></thead><tbody>{rows}</tbody></table></section><section><h2>References as working questions</h2><p><a href="https://docs.google.com/document/d/1ndU2dkp55eR-qC2qC121hLkFXIML41-Nu3PFVo1AxYg/edit">Queer 3D world 2024</a> supplies the archive, prefab and impossible-room direction. <a href="https://docs.google.com/document/d/1p0hG1Og96_CwDl-OA1eZMUG0GPdLy41Am2Adstc07Qo/edit">edgeartist</a> supplies spatial desires: folding, scale, softness, accumulation and inside/outside. The <a href="/book-review/doc/VR_VR_PT_2023.md">2023 application</a> places abstraction and surrealism within the project's aims.</p><p>These are research notes and aims. Historical attributions need checking before entering final.md. The proposals here are our interpretation for Ada.</p><h2>First concrete step</h2><p>Reconstruct one mask in Shaping, verify its actual rendered result, then stage it in the museum. Develop the water basin as the first environmental proof. Keep six halls provisional; expand only when a distinct operation needs room.</p><p>Water's screen/depth inputs need particular care. <a href="https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html">Godot's screen-reading documentation</a> explains the capture hints and transparent-surface limitations. Neither an old shader name nor a desktop specimen proves headset behaviour.</p></section></main><footer><a href="PLAN.md">PLAN.md</a> is the editable brief. <a href="inventory.json">inventory.json</a> records candidates, paths and hashes. No new render, native test or headset pass claimed.</footer></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
print(json.dumps({'output':str(OUT),'halls':len(halls),'candidates':len(assets),'shader_files':len(shader_paths),'existing_images':len(cards)},indent=2))
