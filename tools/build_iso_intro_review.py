from pathlib import Path
import json,re,shutil,markdown,hashlib
R=Path.cwd();O=R/'doc/research/possible-bodies';E=R/'doc/space/iso-introduction-2026-09-15'
rows=[
('ISO_Introduction','A boundary made from values','Keep a field fixed; vary level and sampling.','voxel_noise_demo','Developed and desktop-tested'),
('ISO_LookupTable','Eight samples, one local decision','Compare corner signs, edge crossings and table choices.','fifteen_cases_demo','Next hall'),
('ISO_ShapesGallery','Different descriptions, one extractor','Compare fields while keeping the extraction method legible.','mc_shapes_gallery; mc_torus_sculpture; gyroid_demo','Existing collection; develop comparisons'),
('ISO_TorusGyroid','A hole and a repeating passage','Separate a familiar handle from a periodic field; inspect actual clearance.','GyroidDemo; mc_torus_sculpture','Existing collection; inspect mechanisms'),
('ISO_Sculpting','Write into the field','Make a local edit and observe what the extracted surface keeps.','mc_sculpt_vr; fountain_demo','Awaiting museum restoration and control audit'),
('ISO_FlatTerrain','Beyond a height at each position','Compare a height surface with volume, overhang and enclosure.','mc_flat_landscape; mc_overhang_landscape; rhizome_cave_system','Existing collection; develop comparison'),
('ISO_PortalLandscape','An opening becomes a route','Ask whether a visible aperture connects places a body can reach.','marchingcubes_portal_landscape','Awaiting museum restoration and traversal audit'),
('ISO_Caves','Inhabit the negative space','Enter the complement: which boundaries become walls, floors or traps?','mc_inside_cave; queer_marching_cave; rhizome_cave_demo','Existing collection; inspect clearance'),
('ISO_CaveGeneration','Return to the rule that made the cave','After the encounter, expose its sampling and extraction decisions.','marchingcave; marchingcubes_cave','Awaiting museum restoration and source comparison'),
('ISO_AnimatedNoise','The boundary does not stay still','Follow a field through time; compare visible and collision updates.','animated_noise_explorer; mc_base','Awaiting museum restoration and timing audit'),
('ISO_Metaballs','When bodies share a field','Compare influence overlap with the joining of rigid objects.','metaballs; raymarched_metaballs; metaball_world','Existing collection; distinguish renderers and physics'),
('ISO_ImplicitModeling','Combine descriptions before meshing','Inspect the actual field operations and where their signs come from.','implicit_surface_modeling','Awaiting museum restoration and operation audit'),
('ISO_RhizomeBody','A connected form is not yet a possible life','Synthesize branch, field, surface and bodily passage; test where each account fails.','rhizome_inside','Awaiting museum restoration and interior review')]
arc='''# Isosurfaces — values, boundaries, passages

15 September 2026 · Pedagogical order for the first traverse

Soft Bodies ended with a field mapped into visible form. Isosurfaces makes that mapping inspectable: **values → local decisions → surfaces → edits → inhabited space → changing and combined bodies**.

Keep the existing thirteen-hall curriculum order for this traverse. It begins with an observable boundary, opens its local construction, and tests applications before returning to generation rules. The later halls separate animation, merging fields and explicit field composition. Each proposed primary below already exists in its map; those beyond the Introduction remain candidates to confirm against their implementation and room.

| Hall | New question or capability | Relevant existing works | Status |
|---|---|---|---|
'''
for m,t,q,a,status in rows:arc+=f'| {m} — {t} | {q} | {a} | {status} |\n'
arc+='''
The museum contained six of these thirteen halls. This step restores the Introduction before the lookup table, bringing the active route to seven. The other six missing halls are recorded above for restoration as their encounters are developed. Their absence is a migration gap, not a decision to discard them.

One thread should remain recognizable in each room: a field assigns numbers, a comparison classifies samples, interpolation estimates crossings, and an extractor joins them. A renderer makes the result visible; a collider separately decides contact. A surface that appears connected need not have suitable clearance for the player. A model named “entropy” does not thereby measure entropy, and crossing an isovalue does not establish an edge-of-chaos transition.

Build the critical question from a controlled difference. Preserve the seed while varying level; preserve the domain while varying sample spacing; hold a mesh while the live field changes; compare an apparent route with a bodily crossing. Let the learner discover where these accounts disagree before naming a general theory of the space.

The number of primary artifacts can grow when a comparison needs it. Retain the inherited collection and earlier writing; do not force every room to teach one isolated object. The Introduction's science_screen remains secondary because its generic field mode has not been demonstrated to read this specimen.

Next: **ISO_LookupTable**. Its earlier book passage already distinguishes sign choices from interpolation. Develop that distinction as an action: hold the eight signs fixed while changing their magnitudes, then inspect an ambiguous configuration without claiming the fifteen displayed examples resolve every case.
'''
(O/'iso-learning-arc.md').write_text(arc,encoding='utf-8',newline='\n')
css=re.search(r'<style>(.*?)</style>',(O/'soft-bodies.html').read_text(),re.S)[1]
def page(title,body):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+' · Ada Research</title><style>'+css+'</style><main><nav><a href="iso-introduction.html">Introduction</a><a href="iso-learning-arc.html">Learning arc</a><a href="soft-bodies.html">Soft Bodies</a><a href="/museum-progress?sequence=isosurfaces">Museum progress</a></nav>'+body+'</main></html>'
(O/'iso-learning-arc.html').write_text(page('Isosurfaces learning arc',markdown.markdown(arc,extensions=['tables'])),encoding='utf-8')
run=R/'ada_run/iso-intro-review-2026-09-15';receipt=json.loads((run/'run.json').read_text());assert receipt['exit']==0 and receipt['sources_unchanged'];assert all(hashlib.sha256((R/p).read_bytes()).hexdigest()==h for p,h in receipt['source_sha256'].items())
assets=['iso-learning-arc.md','iso-learning-arc.html','spine-iteration.md','spine-iteration.html'];figures=''
for name in ['entrance','encounter','specimen','overview']:
 src=run/'ISO_Introduction'/f'{name}.png';out=f'iso-introduction-{name}.png';shutil.copyfile(src,O/out);assets.append(out)
 figures+=f'<figure><img src="{out}" alt="Actual Godot Introduction: {name}" loading="lazy"><figcaption>Actual Godot museum capture · {name}. Desktop review; human headset review remains pending.</figcaption></figure>'
links=[]
for kind in ['final','technical','critical']:
 for before in [False,True]:
  src=(E/'before' if before else R)/f'commons/maps/ISO_Introduction/{kind}.md'
  if src.exists():
   out='iso-introduction-'+('previous-' if before else '')+kind+'.md';shutil.copyfile(src,O/out);assets.append(out);links.append(f'<a href="{out}">{"Previous" if before else "Current"} {kind}</a>')
shutil.copyfile(run/'run.json',O/'iso-introduction-verification.json');assets.append('iso-introduction-verification.json')
body='<p class="date">Isosurfaces · First hall · 15 September 2026</p><h1>A boundary made from values</h1><p class="lead">The values stay. A different surface appears.</p><p>The missing Introduction is back in the museum, before the lookup table. LEVEL changes the cutoff; SAMPLES changes the lattice. HOLD keeps a display copy while RESET rebuilds the live specimen.</p><p><a href="iso-learning-arc.html">Follow the thirteen-hall pedagogical order</a> · <a href="/necklace/thread?map=ISO_Introduction&role=primary">Primary artifact and book</a></p><details><summary>Read this hall’s book passage</summary>'+markdown.markdown((R/'commons/maps/ISO_Introduction/final.md').read_text(),extensions=['fenced_code'])+'</details>'+figures+'<h2>What the comparison establishes</h2><p>Changing level preserves all 13,824 samples while changing triangle geometry. Sampling keeps seed and domain fixed. HOLD is an independent mesh without a collider; RESET leaves it intact. The source volume is displayed at 0.18 scale, spanning 5.76m.</p><p>33 desktop checks passed, including actual pointer presses, fixed-field comparisons, held-copy preservation, physical aisle support and the onward exit. No human headset, Quest performance or generated-interior clearance claim is made. The original science screen remains as a secondary work; it is not presented as a synchronized field view.</p><p><a href="iso-introduction-verification.json">Runtime receipt</a></p><p>'+' · '.join(links)+'</p><p>Next: <strong>ISO_LookupTable</strong> — hold the signs, change the magnitudes, inspect what the table chooses.</p>'
(O/'iso-introduction.html').write_text(page('A boundary made from values',body),encoding='utf-8');assets.append('iso-introduction.html')
for src,name in [(run/'run.json','receipt.json'),(run/'ISO_Introduction/probe_ca_edge_live.json','runtime-report.json'),(run/'ISO_Introduction/engine.log','engine.log')]:shutil.copyfile(src,E/name)
manifest=['possible-bodies/'+a for a in assets];(E/'publish-targets.json').write_text(json.dumps(manifest,indent=2));(E/'publish-hashes.json').write_text(json.dumps({a:hashlib.sha256((R/'doc/research'/a).read_bytes()).hexdigest() for a in manifest},indent=2))
(R/'ada_run/publish_iso_intro.ps1').write_text((R/'ada_run/publish_soft_sequence.ps1').read_text().replace('soft-sequence-2026-09-15','iso-introduction-2026-09-15'),encoding='utf-8')
print('Built',len(assets),'review assets, including all thirteen planned encounters.')
