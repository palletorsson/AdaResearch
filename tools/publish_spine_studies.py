"""Reconcile the reading order, learning index and review of installed studies."""
from pathlib import Path
import json, hashlib, html, re, sys
import markdown
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from integrate_recent_studies import READINGS, snapshot, save
manifest=json.loads((ROOT/'doc/book/recent-studies.json').read_text(encoding='utf-8'))
OUT=ROOT/'doc/book/iterations/2026-10-02-studies-in-the-spine'
anchors={
 'Trans_Rotation':'In the next hall, the surroundings change size',
 'Trans_Scale':"Beyond the changing opening, turn toward the museum's own exit.",
 'Tutorial_3D':'The third index has extended what we can address.',
 'Color_Context_Placed':'We have brought primitives, transformations and arrays into composition.',
 'Color_Flashlight':'Carry the distinction with you:',
 'Color_Walls':'Ahead, the disco floor returns in colour.',
 'Random_Entropy':'The last room asked how an arrangement could return.',
 'Shader_05_Patterns':'Press RESET if you have lost the defaults.',
 'Shader_12_PinkExtravaganza':'<!-- @ -->',
 'Boolean_Works':'In the next hall many small bodies lay a trace',
}
edits={
 'hinge_release':('commons/artifacts/spine_studies/hinge_score.gd','degrees_per_second = 20.0','Change the existing degrees_per_second value from 45 to 20. Return takes longer; the destination angle stays the same.'),
 'reference_passage':('commons/artifacts/reference_studies/passage.gd','var width := lerpf(0.60, 1.68, amount)','Change the minimum opening from 0.48 to 0.60 metres. Keep the 0.56-metre comparison strip and test the narrow state again.'),
 'open_structures':('commons/artifacts/spine_studies/open_rules.gd','return column','In form_at(), replace the cyclic return with this expression. Read one row, then one column; every address remains occupied.'),
 'reference_suspension':('commons/artifacts/reference_studies/suspension.gd','corners.append(base + offset * amount)','This is the existing corner rule in fragment(). Change only the multiplier on offset, for example amount * 0.5. The enclosing loops still place 75 fragments.'),
 'reference_landscape':('commons/artifacts/reference_studies/landscape.gd','var height := lerpf(0.28, 1.25, amount) * random.randf_range(0.65, 1.15)','In build(), reduce the maximum height from 1.85 to 1.25. Leave the seeded tree_sites generation and tier count intact. Random shape variation is supplied at this point in the spine.'),
 'sphere_in_pink':('commons/artifacts/spine_studies/pink_sphere.gd','set_lights(3)','Replace the final set_lights(1) call in _ready(). Mask 3 enables the first two lamps. Bit-mask construction is supplied here; the first task is to compare illumination while the sphere stays fixed.'),
 'colour_assembly':('commons/artifacts/colour_assembly/colour_assembly.gd','var palette_index := (index + 1) % PALETTE.size()','In colour_for(), replace the initial palette_index assignment with this line. In the alternating colour mode, each numbered panel gets the next colour; its transform stays fixed.'),
 'colour_wall_studies':('commons/artifacts/colour_wall_studies/colour_wall_studies.gd','set_spacing(0.21)','The installed SPACING control calls this setter. Try 0.18 as a third state inside station.gd’s wall branch. Twenty-four centres retain their order and count.'),
 'signal_room':('commons/artifacts/signal_room/signal_room.gd','set_pattern(2, 2026)','Call this on the supplied signal_room component. Mode 2 permutes cells with a repeatable seed. Compare values.count(1) and the neighbour-change readout before and after; then try another seed.'),
 'reference_pattern_garden':('commons/artifacts/reference_studies/pattern_garden.gd','result.set_shader_parameter("phase", amount * 0.25)','In surface(), halve the original 0.5 phase range. Watch the same petal through the parameter change; keep density and flower positions.'),
 'reference_plural_body':('commons/artifacts/reference_studies/plural_body.gd','lerpf(1.0, 2.3, amount)','This existing expression controls one lateral control point of the limb curve. Change 2.3 to 1.8. Keep the outer loops and compare all six limbs at the same unfolding setting.'),
 'conical_sightline':('commons/artifacts/conical_sightline/conical_sightline.gd','set_cut_x(0.75)','The SHIFT CUT control uses this setter. Try 0.35 metres instead; all six cutter instances share the same offset, including the retained intersections.'),
 'kapoor_void_studies':('commons/artifacts/kapoor_void_studies/kapoor_void_studies.gd','set_black_surface(false)','The BLACK / CHALK control calls this setter. Compare from one fixed position. It replaces materials without rebuilding the bowl mesh.'),
}

from relations_studies import ANCHORS, EDITS
anchors.update(ANCHORS); edits.update(EDITS)
from tension_study import ANCHORS as TENSION_ANCHORS, EDITS as TENSION_EDITS
anchors.update(TENSION_ANCHORS); edits.update(TENSION_EDITS)
from paired_time_study import ANCHORS as TIME_ANCHORS, EDITS as TIME_EDITS, FOOTNOTE as TIME_FOOTNOTE
anchors.update(TIME_ANCHORS); edits.update(TIME_EDITS)
from tube_painting_study import ANCHORS as TUBE_ANCHORS, EDITS as TUBE_EDITS
anchors.update(TUBE_ANCHORS); edits.update(TUBE_EDITS)

# Move only the newly inserted passages, keeping every pre-existing paragraph.
for hall in dict.fromkeys(s['map'] for s in manifest['studies']):
    records=[s for s in manifest['studies'] if s['map']==hall]
    p=ROOT/f'commons/maps/{hall}/final.md';text=p.read_text(encoding='utf-8-sig')
    for s in records:
        key=s['id'];block=r'<!-- study-spine:'+re.escape(key)+r' -->\s*<!-- @'+re.escape(key)+r' -->.*?(?=<!-- study-spine:|<!-- @ -->|\Z)'
        # Replace the owned section by its boundary, including an earlier wording.
        text=re.sub(block,'',text,flags=re.S)
    if hall=='Trans_Scale': text=text.replace("Beyond the two frames, turn toward the museum's own exit.","Beyond the changing opening, turn toward the museum's own exit.")
    anchor=anchors[hall]
    at=text.rfind(anchor)
    if at<0:
        # Keep references after the closing paragraph, and out of the encounter.
        foot=re.search(r'^\[\^[^\]]+\]:',text,re.M)
        at=foot.start() if foot else len(text)
    insert='\n\n'.join('<!-- study-spine:'+s['id']+' -->\n\n<!-- @'+s['id']+' -->\n\n'+READINGS[s['id']] for s in records)
    text=text[:at].rstrip()+'\n\n'+insert+'\n\n<!-- @ -->\n\n'+text[at:].lstrip()
    text=re.sub(r'(?:<!-- @ -->\s*){2,}', '<!-- @ -->\n\n', text)
    p.write_text(text.rstrip()+'\n',encoding='utf-8')
    # Keep the primary learning objects primary; these are application returns.
    for s in records:
        p=ROOT/f'commons/maps/{hall}/tutorial.md';text=p.read_text(encoding='utf-8-sig')
        marker='<!-- study-edit:'+s['id']+' -->'
        source,code,instruction=edits[s['id']]
        block=marker+'\n\n### One source change: '+s['title']+'\n\n'+instruction+'\n\n```gdscript\n'+code+'\n```\n\nSource: `'+source+'`. Use the prepared scene to run and compare.\n'
        if marker in text:
            text=re.sub(re.escape(marker)+r'.*?(?=\n<!-- |\Z)',lambda _:block,text,flags=re.S)
        else: text=text.rstrip()+'\n\n'+block
        p.write_text(text.rstrip()+'\n',encoding='utf-8')

for rel in ['commons/data/artifact_roles.json','commons/data/museum_core_encounters.json']:
    snapshot(rel)
roles=json.loads((ROOT/'commons/data/artifact_roles.json').read_text(encoding='utf-8-sig'))
core=json.loads((ROOT/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
for s in manifest['studies']:
    roles['roles'].setdefault(s['map'],{})[s['id']]='secondary'
    room=core['rooms'].setdefault(s['map'],{'sequence':s['sequence'],'primary_tokens':[]})
    apps=room.setdefault('application_tokens',[])
    if s['id'] not in apps: apps.append(s['id'])
    for key,filename in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
        room[key]=hashlib.sha256((ROOT/'commons/maps'/s['map']/filename).read_bytes()).hexdigest()
    room['application_review']='doc/book/iterations/2026-10-02-studies-in-the-spine/index.html'
    room['learner_verified']=False
save('commons/data/artifact_roles.json',roles);save('commons/data/museum_core_encounters.json',core)

# Historical study packages keep their evidence. A dated pointer states current placement.
for directory in ['doc/book/tutorial-lineage','doc/book/artist-capacity']:
    p=ROOT/directory/'README.md';text=p.read_text(encoding='utf-8-sig')
    marker='## 2 October: studies installed in the spine'
    if marker not in text:
        text+='\n\n'+marker+'\n\nThe installed application studies and their authoritative placement and capability crosswalk are recorded in [recent-studies.json](../recent-studies.json). Read the [integration review](../iterations/2026-10-02-studies-in-the-spine/index.html) for current native museum captures and verification. Earlier entries below or above describe the companion stage of the work; they no longer describe installation status. Sequence order is unchanged. The later tube-painting lesson adds sweep to the existing capability lineage.\n'
        p.write_text(text,encoding='utf-8')
for s in manifest['studies']:
    p=ROOT/s['review'];readme=p.parent/'README.md'
    if readme.exists():
        text=readme.read_text(encoding='utf-8-sig');marker='## Museum placement, 2 October 2026'
        if marker not in text:
            text+='\n\n'+marker+'\n\nThe study now has an installed museum adapter and an application passage in the book. See the [current spine integration](../2026-10-02-studies-in-the-spine/index.html). This page preserves the earlier companion evidence.\n'
            readme.write_text(text,encoding='utf-8')

E=html.escape
def companion_snapshot(source, destination, as_markdown=False):
    raw=(ROOT/source).read_bytes()
    text=raw.decode('utf-8-sig')
    body=markdown.markdown(text,extensions=['fenced_code','tables','footnotes']) if as_markdown else '<pre><code>'+E(text)+'</code></pre>'
    style='body{max-width:900px;margin:40px auto;padding:0 24px;background:#f3f0e9;color:#252328;font:18px/1.65 system-ui}h1,h2,h3{line-height:1.2}h1{font:42px/1.2 Georgia}a{color:#883c5b}pre{background:#252328;color:#ffe6ef;padding:22px;white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.6 Consolas,monospace}code{font-size:.9em}img{max-width:100%}.caption{font-size:13px;color:#68606a}'
    dest=OUT/destination;dest.parent.mkdir(parents=True,exist_ok=True)
    dest.write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="source-sha256" content="'+hashlib.sha256(raw).hexdigest()+'"><title>'+E(source)+'</title><style>'+style+'</style><body><nav><a href="../index.html">Back to the installed studies</a></nav><p class="caption">2 October 2026 · Source snapshot: '+E(source)+'</p>'+body+'</body></html>',encoding='utf-8')

cards=[];rows=[]
for s in manifest['studies']:
    rows.append('<tr><td><a href="#'+s['id']+'">'+E(s['reference'])+'</a></td><td>'+E(s['map'])+'</td><td>'+E(s['student_edit'])+'</td></tr>')
    source,code,instruction=edits[s['id']]
    companion_snapshot(source,'sources/'+s['id']+'.html')
    companion_snapshot('commons/maps/'+s['map']+'/tutorial.md','making/'+s['map']+'.html',True)
    reading=markdown.markdown(READINGS[s['id']] + ('\n\n'+TIME_FOOTNOTE if s['id']=='paired_time' else ''),extensions=['footnotes'])
    cards.append('<section id="'+s['id']+'"><div class="eyebrow">'+E(s['sequence'])+' / '+E(s['map'])+'</div><h2>'+E(s['title'])+'</h2><p class="reference">Original response after '+E(s['reference'])+'</p><figure><img loading="lazy" src="figures/'+s['id']+'.png" alt="'+E(s['title'])+' installed inside the museum"><figcaption>Native Godot capture inside '+E(s['map'])+'. Main-player controls are on the plinth.</figcaption></figure><div class="reading">'+reading+'</div><details><summary>Make one change · '+E(', '.join(s['requires']))+'</summary><p>'+E(instruction)+'</p><pre><code>'+E(code)+'</code></pre><p>'+E(s['borrow'])+'</p><p><a href="/book-review/'+source+'">Source</a> · <a href="/book-review/commons/maps/'+s['map']+'/tutorial.md">Current tutorial</a> · <a href="/tutorial-lineage#hall='+s['map']+'">Lineage</a></p></details><p><a href="/book-review/commons/maps/'+s['map']+'/final.md">Whole current chapter</a> · <a href="/book-review/'+s['review']+'">Earlier study and references</a></p></section>')
reports=[]
for p in (OUT/'figures').glob('*-report.json'):
    d=json.loads(p.read_text());reports.append(d)
count=sum(len(d['checks']) for d in reports);passed=sum(sum(c['passed'] for c in d['checks']) for d in reports)
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f3f0e9;color:#252328;font:17px/1.65 system-ui,sans-serif}header,main,footer{max-width:1160px;margin:auto;padding:45px 32px}h1{font:clamp(45px,7vw,86px)/1.02 Georgia,serif;max-width:900px;letter-spacing:-.035em}h2{font:42px/1.13 Georgia,serif;margin:8px 0 10px}.intro{font:25px/1.5 Georgia,serif;max-width:840px}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.12em;color:#895067}a{color:#883c5b;text-underline-offset:4px}table{width:100%;border-collapse:collapse;font-size:14px}td,th{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #cfc8bf}section{padding:65px 0;border-top:1px solid #cfc8bf;scroll-margin-top:25px}figure{margin:28px 0}img{display:block;width:100%;height:auto;background:#29242d}figcaption,.reference{font-size:13px;color:#68606a}.reading{font:23px/1.65 Georgia,serif;max-width:760px;margin:40px auto}.reading p{margin:0 0 25px}details{max-width:850px;background:#e9e4dc;padding:22px;margin:30px auto}summary{cursor:pointer;font-weight:600}pre{white-space:pre-wrap;overflow-wrap:anywhere;padding:20px;background:#252328;color:#ffe6ef}nav{display:flex;gap:24px;flex-wrap:wrap}.evidence{padding:25px;background:#e5e9de}@media(max-width:680px){header,main,footer{padding:25px 18px}.reading{font-size:21px}td,th{padding:8px}h2{font-size:34px}}'''
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Studies enter the spine</title><style>'+css+'</style><header><div class="eyebrow">Ada / 2 October 2026</div><h1>The work returns<br>with what we know.</h1><p class="intro">Sixteen recent artist studies now have a place in thirteen existing halls. A familiar operation meets a different demand: a panel makes a room, a count becomes a surrounding, a cut lets one space look into another.</p><p>The artist studies apply existing capabilities; the later tube-painting workbench adds sweep, carrying rings along a retained path. The encounter stays short; the first source edit is available separately. The earlier Boolean eggs and Turrell-informed light rooms remain installed.</p><nav><a href="#placements">Placements</a><a href="#colour_assembly">Colour / gathering</a><a href="/tutorial-lineage#node=array">Capability lineage</a><a href="#evidence">Verification</a></nav></header><main><div id="placements"><table><thead><tr><th>Reference</th><th>Hall</th><th>First useful edit</th></tr></thead><tbody>'+''.join(rows)+'</tbody></table></div>'+''.join(cards)+'<section id="evidence"><h2>What was checked</h2><div class="evidence"><p>'+str(passed)+' / '+str(count)+' recorded native checks pass across '+str(len(reports))+' halls.</p><p>Actual endless_museum assembly, museum pointer-event dispatch, state changes, reset, occupied-area guards, floor support and sampled standing clearance along both side routes. Private runtime state; the author’s running game and save were not used.</p><p>These are desktop checks and native screenshots. Full human traversal, physical XR controls, Quest performance and independent student use remain untested.</p><p><a href="verification.json">Publication and integration checks</a> · <a href="provenance.json">Source hashes</a> · <a href="README.md">Reproduce this pass</a></p></div></section></main><footer><a href="/book-review/doc/book/recent-studies.json">Placement manifest</a> · <a href="/tutorial-lineage">Tutorial lineage</a></footer></html>'
for s in manifest['studies']:
    page=page.replace('/book-review/'+edits[s['id']][0],'sources/'+s['id']+'.html')
    page=page.replace('/book-review/commons/maps/'+s['map']+'/tutorial.md','making/'+s['map']+'.html')
page=page.replace('/book-review/doc/book/recent-studies.json','placements.json')
page=page.replace('Sixteen recent artist studies now have a place in thirteen existing halls.',f'{len(manifest["studies"])} studies now have a place in {len(set(s["map"] for s in manifest["studies"]))} existing halls.')
(OUT/'placements.json').write_bytes((ROOT/'doc/book/recent-studies.json').read_bytes())
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'README.md').write_text(f'''# Studies in the spine

{len(manifest['studies'])} artist and geometry studies installed in {len(set(s['map'] for s in manifest['studies']))} existing halls. The manifest is `doc/book/recent-studies.json`. Existing egg and light-room installations remain.

`tools/integrate_recent_studies.py` installs idempotent bays, tokens, registry records and initial passages. `tools/publish_spine_studies.py` reconciles reading order and the publication. `tools/capture_spine_studies.py` runs actual museum assemblies in private runtime projects; optional arguments restrict it to hall IDs. `tools/verify_spine_studies.py` checks the installation and publication. `tools/build_tutorial_lineage.py` publishes application links under the existing capabilities.

Before snapshots preserve files changed by this pass. Screenshots are unedited native Godot output. Runtime reports record pointer-event and sampled collision tests; no physical headset or learner certification is implied. The mounted works borrow the main museum player; their standalone viewers remain useful companion projects.
''',encoding='utf-8')
print(f'Published {len(manifest["studies"])} applications and reconciled canonical reading, tutorials, roles and hashes.')
