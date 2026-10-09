from pathlib import Path
import json,hashlib
R=Path('.');H=R/'doc/book/iterations/2026-09-20-postcrisis-bias-review';B=H/'before';M='CriticalAlgorithms_Algorithmic_Bias_Visualization';D=R/'commons/maps'/M
text=(B/D/'final.md').read_text(encoding='utf-8').replace('while moving PERSPECTIVE','while moving COMPRESSION')
text=text.replace('Stop partway through the movement and notice which words are still easy to distinguish individually.','Stop partway through the movement and notice which words are still easy to distinguish individually. Keep the handle still and move your head. What changes now?')
text=text.replace('The words themselves remain, but the space available to tell them apart changes.','The words themselves remain. Their colours and brightness stay fixed while the space available to tell them apart changes.')
text=text.replace('The script calls this perspective, but it changes the represented geometry. It is not a camera command.','The handle changes the represented geometry. Moving your head gives you another view of it. Those are two different changes.')
text=text.replace('Now scrutinise the groups chosen for the sculpture.','Press READ when you are ready to consider the grouping. Both groups were chosen. Now scrutinise the groups chosen for the sculpture.')
(D/'final.md').write_text(text,encoding='utf-8')
(D/'technical.md').write_text('''# Distinguish — an arrangement changes

Synthesis asked which conditions a specimen receives. Here an array of indexed words receives positions. The transformation is the same linear interpolation encountered earlier; the question is what remains distinguishable when those positions converge.

The primary artifact is bias_from_inside. It retains two arrays of twelve terms and seed 42. Each term has an authored position in arrangement A and in arrangement B. The legacy export and map-token key remains perspective_blend; the visible handle is COMPRESSION. No camera, player transform, model training or measured embedding is involved.

```gdscript
var pos := _marginalized_positions_default[i].lerp(
    _marginalized_positions_compressed[i], blend
)
var xf := Transform3D.IDENTITY
xf.origin = pos
_marginalized_multimesh.multimesh.set_instance_transform(i, xf)
```

The tags follow those same indices. The warm points contract towards a cluster with a default radius of 0.15 m; the grey points move out to a seeded ring whose radii are 2.3–2.7 m. These are authored spatial coordinates. Neither arrangement is labelled fair or unfair by the interface.

The rail signal carries physical travel. The handler now obtains get_normalized_value() from the wrapper, so the full rail spans the whole 0–1 interpolation. The previous callback treated travel as blend; its upper endpoint supplied only 0.14. Author configuration now regenerates endpoints when radii change and synchronizes the handle. Repeated configuration clears the coordinate arrays first.

Warm emission and grey alpha are fixed throughout the comparison. The two groups still have different authored colours, and all tags face the viewer. Fixing their materials isolates one changing cause; it does not remove the interpretive choices already made by their grouping or their spatial arrangement.

READ / CLOSE reveals or hides a short project reading without changing geometry. The header names arrangement A, the interval or arrangement B; the handle gives the numerical setting. The stand keeps the handle near 1.1 m in this hall. The study is placed in the wider southern area with clearance for its expanded endpoint. The other three artifact families remain secondary.

The applied-ethics hall takes the next step: a furniture arrangement can distribute possible relations before anyone speaks. Headset reach, readability and learner understanding remain to be tested; the controlled museum probe checks a selected approach, the callbacks and actual coordinates.
''',encoding='utf-8')
for name in ['critical.md','tutorial.md']:
 s=(B/D/name).read_text(encoding='utf-8').replace('Perspective slider','COMPRESSION slider').replace('The script calls this perspective, but it changes the represented geometry. It is not a camera command.','The handle changes the represented geometry. Moving your head changes its projection from where you stand.')
 s=s.replace('## A question the next version can test','## A question to test in the encounter')
 (D/name).write_text(s,encoding='utf-8')
(D/'summary.md').write_text('''# Less room for a distinction

Move COMPRESSION and follow the same two warm labels, then two grey labels. Keep the handle fixed and move your head. The object changes its coordinates; your movement changes the view.

The study uses 24 indexed terms, two seeded arrangements and linear interpolation. Its materials remain fixed during the comparison. READ / CLOSE offers the maker's interpretation separately. The two colour groups are themselves an authored reduction, open to criticism.

This is an illustrative word-position study, not measured language-model data. The surrounding bias_visualizer, science_screen and situated_readout remain secondary. All four artifact families remain; the primary moves to the wider southern area at usable height. The sequence proceeds to Applied Ethics and the relations a furniture arrangement makes possible.
''',encoding='utf-8')
(D/'blurb.md').write_text('''*The words remain. How much room do their differences have?*

Hold one pair in view. Move COMPRESSION.

Then hold the handle still and move yourself.
''',encoding='utf-8')
def read(p):return json.loads((R/p).read_text(encoding='utf-8-sig'))
def write(p,d):(R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p='commons/data/museum_core_encounters.json';d=read(p);e=d['rooms'][M];e.update(status='encounter_and_text_revised',reason='Compare the same labels under spatial compression with fixed materials; separate moving the geometry from moving the observer.',review_evidence=H.as_posix()+'/SUMMARY.md',learner_verified=False)
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:e[k]=hashlib.sha256((D/n).read_bytes()).hexdigest()
write(p,d)
p='commons/data/book/postfoundationscrisis.json';d=read(p);e=next(x for x in d['pearls'] if x['map']==M);e['hero']='bias_from_inside';e['lines']=[{'token':'bias_from_inside','text':'The words remain. How much room do their differences have?','by':'hand'}];write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='postfoundationscrisis')
 for e in node['pearls']+d.get('hand_pearls',{}).get('postfoundationscrisis',[]):
  if e.get('map')==M:e.update(hero='bias_from_inside',says={'bias_from_inside':'The words remain. How much room do their differences have?'},says_by={'bias_from_inside':'hand'})
 write(p,d)
p='commons/artifacts/registry/algorithms_misc.json';d=read(p);e=d['artifacts']['bias_from_inside'];e['description']='A word-position study with 24 terms in two authored, seeded arrangements. COMPRESSION interpolates their coordinates with materials held fixed; READ reveals the project interpretation. The visitor can move around the study. No camera movement or empirical embedding measurement is implied.';e['qfep_connection']='The same array can retain every word while making distinctions harder to see. The grouping, endpoint coordinates and available control are authored decisions; the encounter asks which of those decisions should be revisable.';write(p,d)
print('Manuscript revised locally; its code, category critique and limits retained')
