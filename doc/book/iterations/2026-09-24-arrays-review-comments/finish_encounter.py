from pathlib import Path
import json,hashlib,sys
sys.stdout.reconfigure(encoding='utf-8')
r=Path.cwd();o=r/'doc/book/iterations/2026-09-24-arrays-review-comments'
base=json.loads((o/'baseline.json').read_text(encoding='utf-8'));changed=json.loads((o/'changed-files.json').read_text(encoding='utf-8'))
def snapshot(rel):
 p=r/rel
 if rel not in base:
  base[rel]=hashlib.sha256(p.read_bytes()).hexdigest();q=o/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(p.read_bytes())
def save(rel,s):
 snapshot(rel);(r/rel).write_text(s,encoding='utf-8')
 if rel not in changed:changed.append(rel)
def jsave(rel,d):save(rel,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
rel='commons/maps/Array/final.md';s=(r/rel).read_text(encoding='utf-8');anchor='<!-- @molnar_cube_study -->'
assert s.count(anchor)==1 and '@array_floor_writer' not in s
passage='''<!-- @array_floor_writer -->

A light-blue sphere moves low over the floor. Wait near it and watch the cells beneath it. A copy can rise into your route; a consumed cell leaves a hollow. There is still a surface a metre below. What looked like an address on a diagram has become a place where your body can drop.

The sphere is writing into the hall’s own grid. Its label names the last cell it copied or consumed. The small pickup tables keep their separate records: collecting their cubes and changing this floor are different acts. Here the program changes both what you see and what supports you.

Near the entrance, PAUSE / RESUME holds the floor where it is. Pause after a change and walk around it. The gaps and raised cells remain, while the perimeter and thresholds stay outside the sphere’s reach. RESTORE FLOOR returns the changed cells to their starting arrangement, waiting wherever a body occupies one. The sphere stays paused until you release it again.

An empty slot was something we could point to. Underfoot, absence asks something of our balance. The address remains available to the program even when it no longer offers our feet a place to rest.

![The hall’s floor after cells have been copied and consumed.](/book-review/doc/book/figures/Array/the-written-floor.png)

![The same floor after restoration, seen from the same position.](/book-review/doc/book/figures/Array/floor-restored.png)

*The same part of the working museum before and after RESTORE FLOOR. These views hold a supplied set of copy and consume operations for comparison.*

'''
save(rel,s.replace(anchor,passage+anchor))
rel='commons/maps/Array/intent.md';s=(r/rel).read_text(encoding='utf-8-sig')
s=s.replace('The transparent cube study then varies the form at each fixed site.','The changing floor gives occupancy a bodily consequence; the transparent cube study then varies form at each fixed site.')
s=s.replace('Compare row_3_x with grid_2d_4x4, then visit molnar_cube_study:', 'Compare row_3_x with grid_2d_4x4, encounter array_floor_writer changing the actual hall floor, then visit molnar_cube_study:')
s=s.replace('Keep column_3_z, xyz_coordinates, gridagent and pulsar_visualizer as supporting work.','Keep column_3_z, xyz_coordinates and pulsar_visualizer as supporting work. The generic gridagent placement is replaced in this hall by array_floor_writer; its shared source remains available elsewhere.')
s+='\n24 September 2026: The author chose to develop the changing floor rather than isolate the agent on a spare patch. Readable autonomous operations, entry-side pause/restore controls, protected perimeter/threshold cells and restoration that waits for an occupying body are now present. The remaining surface is one metre below a consumed cell. Native checks and review decisions: doc/book/iterations/2026-09-24-arrays-review-comments. Headset comfort and learner acceptance remain untested.\n';save(rel,s)
rel='commons/maps/Array/technical.md';s=(r/rel).read_text(encoding='utf-8-sig')
s=s.replace('## Three encounters','## Four encounters').replace('row_3_x → grid_2d_4x4 → molnar_cube_study','row_3_x → grid_2d_4x4 → array_floor_writer → molnar_cube_study')
s+='''
## Changing floor — 24 September 2026

Source: commons/artifacts/array_floor_writer/array_floor_writer.gd and .tscn; registry: commons/artifacts/registry/array_floor_writer.json. The new placement replaces gridagent:copy at (15,17) without moving other artifacts or changing authored floor cells. It subclasses the shared agent; other halls keep their existing agent behavior.

The host binds to its containing GridStructureComponent and snapshots editable occupied cells. The sphere consumes or copies one cell per operation state, with a 2.5-second wandering interval and a one-second operation state. Copies and removals use the live grid's add_cube_at/remove_cube_at methods, including its collision. The original generic agent could mutate once per physics frame while feeding/working; an eight-second observation removed 38 floor cells. The new timed observation wrote three cells in eight seconds.

The edit domain is interior X 2..width-3, Z 3..depth-4, Y 0..2; original upper cells are not candidates. The surrounding perimeter and thresholds remain unchanged. Candidate cells are within three horizontal grid cells of the agent. A copy is rejected where its physical volume overlaps a CharacterBody3D. This encounter uses this map's one-metre cells.

Two shared physical buttons stand at (12,2), with controls around 1.2 m above the deck: PAUSE / RESUME and RESTORE FLOOR. Restore pauses the agent, repairs only changed cells, and retries every 0.2 seconds where a character occupies a changed volume. It resumes only by explicit input. The row and two-dimensional pickup arrays are separate records; the agent does not update their tables.

Removing a floor cube exposes a separate existing museum surface one metre below. An actual museum body descends onto it; this is a depression, not a hole into nothing. Restoration waited while the body occupied that cell and filled it after departure. A complete headset traverse, recovery from a depression and comfort remain to be tested; no claim of learner acceptance or Quest performance is made.

Evidence: doc/book/iterations/2026-09-24-arrays-review-comments/floor/report.json, floor-probe.gd and source hashes. Twenty-four controlled native checks cover timed writing, once-per-state mutation, pause/resume, copy/consume, protected cells, support removal, actual-body descent, occupancy-aware restoration and native captures. Photographs use explicitly supplied mutations after the timed test, paused for comparison. The earlier Molnár evidence above is preserved and was not rerun in this pass.
''';save(rel,s)
rel='commons/data/artifact_roles.json';d=json.loads((r/rel).read_text(encoding='utf-8-sig'));snapshot(rel)
tokens=['row_3_x','grid_2d_4x4','array_floor_writer','molnar_cube_study']
d['roles']['Array'].pop('gridagent',None)
for token in tokens:d['roles']['Array'][token]='primary'
d['order']['Array']['primary']=tokens;d['order']['Array']['secondary']=[t for t in d['order']['Array']['secondary'] if t!='gridagent']
d['notes']['Array'].append({'id':'array-changing-floor-2026-09-24','role':'primary','text':'Author decision, 24 September 2026: develop the changing floor. array_floor_writer replaces the old gridagent placement, making actual grid occupancy alter support underfoot. Primary reading order follows the current five-hall sequence and includes the existing Molnár study. The older overture note above is retained as history.'});jsave(rel,d)
rel='commons/maps/sequences/array_tutorial.json';d=json.loads((r/rel).read_text(encoding='utf-8-sig'))
for groups in [d['artifact_groups'],d['sequences']['array_tutorial']['artifact_groups']]:
 for group in groups:
  if group['map']=='Array':group['artifacts']=tokens
jsave(rel,d)
rel='commons/maps/Array/map_data.json';d=json.loads((r/rel).read_text(encoding='utf-8-sig'))
note='24 September 2026: array_floor_writer replaces gridagent:copy at (15,17). The author chose a changing-floor encounter. One write per operation, entry-side pause/restore, perimeter and threshold cells protected; restoration waits for an occupying body. Authored floor cells remain unchanged.'
if isinstance(d.get('dev_notes'),list):d['dev_notes'].append(note)
elif isinstance(d.get('dev_notes'),str):d['dev_notes']+='\n'+note
elif d.get('dev_notes') is None:d['dev_notes']=[note]
else:raise AssertionError(type(d['dev_notes']))
jsave(rel,d)
rel='commons/data/museum_core_encounters.json';d=json.loads((r/rel).read_text(encoding='utf-8-sig'))
for m in ['Array','Tutorial_3D','Tutorial_Tiling_Floor','Tutorial_Tiling_Walls','Tutorial_Disco']:
 room=d['rooms'][m];room['text_sha256']=hashlib.sha256((r/'commons/maps'/m/'final.md').read_bytes()).hexdigest();room['local_review']='doc/book/iterations/2026-09-24-arrays-review-comments/index.html'
 if m=='Array':
  room['primary_tokens']=tokens;room['reason']='Row and grid introduce indexed occupancy; the changing floor gives a write a bodily consequence; the Molnár-inspired transparent cube study varies transforms at fixed sites before the full-scale third-index hall.';room['map_sha256']=hashlib.sha256((r/'commons/maps'/m/'map_data.json').read_bytes()).hexdigest()
  room['floor_runtime_check']={'evidence':'doc/book/iterations/2026-09-24-arrays-review-comments/floor/report.json','scope':'24 controlled native checks: live grid writes, once-per-state pacing, protected cells, pause/resume, support removal, actual-body descent and occupancy-aware restoration. Not a headset traverse, recovery/comfort or learner test.'}
jsave(rel,d)
rel='doc/book/figures/README.md';s=(r/rel).read_text(encoding='utf-8-sig');s+='''

## Arrays — review comments, 24 September 2026

`Array/the-written-floor.png` and `Array/floor-restored.png` show the same viewpoint before and after RESTORE FLOOR. Native production Godot captures of array_floor_writer after explicitly supplied copy/consume operations, paused for comparison. The encounter edits the hall's actual GridStructureComponent. Its physical drop and restoration are separately tested, not inferred from the images.

`Tutorial_Tiling_Walls/two-turns.png`, `Tutorial_Disco/fixed-addresses-changing-values.png` and `Tutorial_Disco/triangle-combinations.png` are fresh native captures with MushroomHand's desktop-only count overlay hidden by the isolated capture probe. Composite assembly runs in Godot from its viewport frames; no scene geometry is substituted. Earlier iteration images remain intact.

Provenance, hashes and checks: `doc/book/iterations/2026-09-24-arrays-review-comments/figure-provenance.json`, `wall/`, `disco/`, `floor/`. No headset or learner acceptance is claimed.
''';save(rel,s)
(o/'baseline.json').write_text(json.dumps(base,indent=2)+'\n',encoding='utf-8');(o/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
print('Added floor encounter to final.md; updated Array roles, companion notes and sequence metadata. All other chapter roles and map order preserved.')
