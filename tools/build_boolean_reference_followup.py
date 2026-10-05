"""Publish the installed egg encounter and the next, separately reviewed study."""
from pathlib import Path
import html, json, re
ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT/'doc/book/iterations'
EGG = BASE/'2026-10-01-boolean-eggs-in-the-spine'
CUT = BASE/'2026-10-01-matta-clark-one-cut'
EGG.mkdir(exist_ok=True)
CUT.mkdir(exist_ok=True)
def read(path): return (ROOT/path).read_text(encoding='utf-8-sig')
def write(path,text): (ROOT/path).write_text(text,encoding='utf-8')
def save(path,data): write(path,json.dumps(data,ensure_ascii=False,indent=2)+'\n')

path='commons/data/artifact_roles.json'
data=json.loads(read(path))
data['roles'].setdefault('Boolean_Works',{})['boolean_eggs']='secondary'
order=data['order']['Boolean_Works']['secondary']
if 'boolean_eggs' not in order: order.insert(order.index('booleanvariations'),'boolean_eggs')
save(path,data)

path='commons/artifacts/registry/reference_studies.json'
data=json.loads(read(path))
data['artifacts']['conical_sightline']={
    'lookup_name':'conical_sightline','name':'One cut, three rooms',
    'scene':'res://commons/artifacts/conical_sightline/conical_sightline.tscn',
    'description':'Three walls receive one conical cutter; a witness display retains the intersections. An original study after Conical Intersect, not a reconstruction.',
    'category':'reference_studies','sequence':'boolean_surfaces','map_ready':False,'include_in_map_data':False,
    'reference_artist':'Gordon Matta-Clark','proposed_maps':['Boolean_Works'],
    'complexity':'intermediate','minimum_display_bounds_m':[18.6,5.4,11],
    'parameters':{'cut_x':'Shared cutter X offset, -0.65 to 0.85 metres; set_cut_x(value).','cut_enabled':'Before/cut comparison; set_cut_enabled(value).'},
    'interactions':['Use the separate study.tscn desktop viewer: Approach, Inside, Offcuts, Before / cut, Shift cut, Reset.'],
    'signals':[],'tags':['boolean','architecture','sightline','reference-study'],
    'qfep_connection':'One deterministic cut changes relations between several spaces; permission and historical loss are not computed by it.',
    'status':'Native Godot companion, 17 desktop checks passed; not installed in the museum.'
}
save(path,data)

css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#17191e;color:#eeebe5;font:18px/1.65 system-ui,sans-serif}main,header,footer{max-width:1180px;margin:auto;padding:32px}header{padding-top:72px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.1}h1{font-size:clamp(48px,7vw,86px);margin:16px 0 26px}h2{font-size:38px;margin-top:0}.eyebrow{font-size:12px;letter-spacing:.15em;text-transform:uppercase;color:#d8acba}.lead{font:27px/1.5 Georgia,serif;max-width:850px}a{color:#efaac4;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:24px;margin:28px 0}section{border-top:1px solid #49484b;padding:44px 0;scroll-margin-top:24px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0 0 26px}img{width:100%;display:block}figcaption,.small{font:14px/1.5 system-ui,sans-serif;color:#bcb9b8;margin-top:10px}article{max-width:780px;margin:auto;font:24px/1.6 Georgia,serif}pre{overflow:auto;background:#0b0d11;padding:22px;font:15px/1.6 Consolas,monospace}code{font-size:.9em}details{padding:20px;border:1px solid #49484b}summary{cursor:pointer}footer{border-top:1px solid #49484b;color:#bcb9b8}@media(max-width:700px){.pair{grid-template-columns:1fr}header,main,footer{padding-left:20px;padding-right:20px}article{font-size:21px}}'''
def page(title,lead,nav,body):
    return f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)} · Ada</title><style>{css}</style></head><body><header><div class="eyebrow">Ada · Boolean Surfaces · 1 October 2026</div><h1>{title}</h1><p class="lead">{lead}</p><nav>{nav}</nav></header><main>{body}</main><footer>Native Godot 4.6 desktop captures. Read the encounter, then open its making score.</footer></body></html>'
def paragraphs(text):
    return ''.join('<p>'+html.escape(p.strip())+'</p>' for p in text.split('\n\n') if p.strip() and not p.strip().startswith('<!--'))

final=read('commons/maps/Boolean_Works/final.md')
eggtext=final.split('## A darkness held\n\n')[1].split('\n## A collection within reach')[0]
EGG.joinpath('READING.md').write_text('# A darkness held\n\n'+eggtext+'\n',encoding='utf-8')
EGG.joinpath('index.html').write_text(page('A darkness held.',
    'The three eggs now stand in Boolean Works. Union, intersection and subtraction return from architecture to the scale of a body you can circle.',
    '<a href="#museum">In the museum</a><a href="#reading">Read</a><a href="../2026-10-01-matta-clark-one-cut/index.html">Next: one cut, three rooms →</a>',
    '<section id="museum"><figure><img src="figures/eggs-in-museum.png" alt="The three deep-colour Boolean eggs on their white plinth inside the assembled Boolean Works hall"><figcaption>The actual museum assembly, looking toward the new bay. The bright museum lighting and neighbouring displays remain visible. Ten authored artifacts placed, none relocated or refused.</figcaption></figure><figure><img src="figures/eggs-museum-cavity.png" alt="Closer view of the teal egg and its black concavity in the museum"><figcaption>A real cut with an unlit interior. The triangulated rim remains visible.</figcaption></figure></section>'
    '<section id="reading"><article><h2>A darkness held</h2>'+paragraphs(eggtext)+'</article></section>'
    '<section id="making"><h2>The place in the sequence</h2><p>Boolean Verbs → Boolean Gallery → <strong>Boolean Works</strong>. The egg bay follows the cavern and precedes the final rack and coincident-face comparison. The hall now has twelve more rows for the plinth and its approach, with routes around either side.</p><p>The short passage is in the current <code>Boolean_Works/final.md</code>. Its tutorial separates the geometric cut from a one-property material comparison. No new capability prerequisite is added.</p><details><summary>Verification and files</summary><p><a href="figures/report.json">Museum capture report</a> · <a href="figures/godot.log">Engine log</a></p><p>Captured from the actual endless-museum assembly with private runtime state. Its distance culling follows the photographic eye. The scene is frozen for the stills. Headset traversal was not tested.</p></details></section>'),encoding='utf-8')

reading=CUT.joinpath('READING.md').read_text(encoding='utf-8')
passage=reading.split('\n\n',1)[1].split('\n## Making score')[0]
CUT.joinpath('index.html').write_text(page('One cut,<br>three rooms.',
    'After the eggs: a study after Gordon Matta-Clark. One shared opening changes what separate rooms can see of each other.',
    '<a href="#study">Godot study</a><a href="#reading">Read</a><a href="#making">Make</a><a href="#source">Source</a><a href="../2026-10-01-boolean-eggs-in-the-spine/index.html">← Eggs in the spine</a>',
    '<section id="study"><figure><img src="figures/cut-approach.png" alt="Three successive plaster walls with circular openings narrowing into the distance and warm coloured cut edges"><figcaption>Original Godot construction: three walls, one shared conical cutter. This companion is ready to examine; it is not yet installed in the museum.</figcaption></figure><div class="pair"><figure><img src="figures/cut-before.png" alt="The same walls before the conical cut"><figcaption>Before: the small doorways provide a route.</figcaption></figure><figure><img src="figures/cut-inside.png" alt="An eye-level view through the aligned openings"><figcaption>Inside: the new sightline crosses the rooms’ divisions.</figcaption></figure></div><figure><img src="figures/cut-offcuts.png" alt="Cut walls beside three retained circular offcuts on slender supports"><figcaption>Difference keeps the walls. Intersection keeps the parts removed from them. The dark specimen deck belongs to the study, not to Matta-Clark’s original work.</figcaption></figure></section>'
    '<section id="reading"><article>'+paragraphs(passage)+'</article></section>'
    '<section id="making"><h2>Move one cut.</h2><p>Coordinates → line and sightline → transformation → Boolean difference and intersection. The learner already has these operations. The supplied viewer keeps the camera, lights, walls and controls out of the small making score.</p><pre><code>for cutter in cutters:\n    cutter.position.x = cut_x</code></pre><p>Keep the walls still. Change the common offset to 0.75 metres. Observe from the same eye position; then move the eye. A change to the construction and a change of viewpoint do different things.</p><p>Open <code>commons/artifacts/conical_sightline/study.tscn</code> in Godot. The desktop buttons select Approach, Inside, Offcuts, Before / cut, Shift cut and Reset.</p><details><summary>What has been checked?</summary><p><a href="figures/verification.json">17 checks passed</a>: the three remaining meshes, an open central ray, a blocked ray through solid wall, clear side-door rays in both states, the changed sightline after translation, reset, and four saved images. The six UI callbacks supply these controls. This is not a structural or walking-body simulation.</p><p><a href="figures/provenance.json">Source hashes and renderer provenance</a> · <a href="READING.md">Reading and making score</a></p></details></section>'
    '<section id="source"><h2>The history the cut cannot compute</h2><p><em>Conical Intersect</em> (1975) was made through two Paris buildings awaiting demolition. The opening exposed internal structures and reframed a view through the changing neighbourhood. <a href="https://www.centrepompidou.fr/en/ressources/oeuvre/crgBqpa">Centre Pompidou’s collection account</a>.</p><p>These digital walls have never been inhabited. Reset can restore them without restoring a home. The study takes that difference into the reading; it borrows a spatial question without claiming to reproduce the buildings or the work.</p></section>'),encoding='utf-8')

# Current status belongs beside the older review, whose dated captures remain intact.
path='doc/book/iterations/2026-10-01-kapoor-surface-and-depth/BOOLEAN-EGGS.md'
text=read(path).replace('It is not installed in the museum spine.', 'It is now installed as `boolean_eggs` in Boolean_Works, after the cavern and before the final comparisons. [See the actual museum capture](../2026-10-01-boolean-eggs-in-the-spine/index.html).')
write(path,text)
path='doc/book/iterations/2026-10-01-kapoor-surface-and-depth/boolean-eggs.html'
text=read(path)
notice='<p class="note">Installed in Boolean Works: <a href="../2026-10-01-boolean-eggs-in-the-spine/index.html">see the current museum bay and book passage</a>. The photographs below preserve the earlier standalone lighting study.</p>'
if notice not in text: text=text.replace('<main>','<main>'+notice,1)
write(path,text)

path='doc/book/tutorial-lineage/README.md'
text=read(path)
text=text.replace('but are not installed in the spine or runtime-verified.', 'and the egg component is now installed in Boolean_Works and captured in native Godot.')
text=text.replace('The Kapoor chapter companion and its separate Boolean egg scene are authored, but are not installed in a map or capability-ladder node. Runtime and headset behavior remain unverified.', 'The three-station Kapoor companion remains separate. The Boolean eggs are now installed in Boolean_Works as a secondary application of the existing Boolean and light/material capabilities; no new ladder node is needed. The museum placement has been rendered in native Godot. Headset behaviour remains untested.')
addition='\nApplication study, 1 October 2026: [One cut, three rooms](../iterations/2026-10-01-matta-clark-one-cut/index.html) takes Matta-Clark’s Conical Intersect as a question for three walls and one shared cutter. Difference retains the walls; intersection retains their offcuts. Coordinates, line, transformation and Boolean operations supply the making lineage. Seventeen native desktop checks passed. This companion is not installed and adds no ladder node.\n'
if addition not in text: text+=addition
write(path,text)

path='doc/book/artist-capacity/README.md'
text=read(path).replace('A separate deep-colour Boolean egg component and preview scene are now authored as companions; they are not installed in the spine.', 'The deep-colour Boolean eggs are now installed in Boolean_Works; their standalone preview remains available as a lighting comparison.')
text=text.replace('This is a chapter companion, not a reconstruction of Kapoor and not an installed spine map.', 'The three void studies remain companions. The original egg counterpoint is now installed in Boolean_Works; it is not a reconstruction of Kapoor.')
addition='\nNext application: [One cut, three rooms — after Matta-Clark](../iterations/2026-10-01-matta-clark-one-cut/index.html) extends the Boolean question into a shared sightline across walls. It is an additional researched reference beyond the supplied index; the 100-entry source atlas is preserved. Native companion built and checked, museum placement still proposed.\n'
if addition not in text: text+=addition
write(path,text)
print('Published the installed egg review and the Matta-Clark companion review.')
