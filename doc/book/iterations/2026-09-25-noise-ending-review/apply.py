from pathlib import Path
import hashlib,json
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-noise-ending-review'
maps=['Noise_Perlin_Simplex','Lab_Path']
files=[p.relative_to(r).as_posix() for m in maps for p in (r/'commons/maps'/m).iterdir() if p.suffix in ['.md','.json']]
files += [p.relative_to(r).as_posix() for folder in ['algorithms/randomness/simplexnoise','algorithms/randomness/perlinnoise'] for p in (r/folder).iterdir() if p.suffix in ['.gd','.tscn','.gdshader']]
files += ['commons/maps/sequences/noise.json','commons/data/book/noise.json','commons/data/museum_core_encounters.json','doc/tasks/book_noise.json','doc/book/captures/noise/noise-book.md','doc/book/captures/noise/noise-book.manifest.json','ada_run/em_plan.json']
assert not (o/'baseline.json').exists()
hashes={}
for rel in files:
    p=r/rel;dest=o/'before'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes());hashes[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
(o/'baseline.json').write_bytes((json.dumps(hashes,indent=2)+'\n').encode())
def write(rel,s):(r/rel).write_bytes(s.encode('utf-8'))
def replace(rel,a,b):
    p=r/rel;s=p.read_text(encoding='utf-8-sig');assert s.count(a)==1,(rel,a);write(rel,s.replace(a,b))
rel='algorithms/randomness/simplexnoise/SimplexNoise.gd'
s=(r/rel).read_text();start=s.index('func apply_grid_config(');end=s.index('# ── the measurement contract',start);f=s[start:end]
f=f.replace('var changed: bool = false','var changed: bool = false\n\tvar contract_changed: bool = false')
f=f.replace('_placement_params[key] = config[key]\n\t\t\tchanged = true','_placement_params[key] = config[key]\n\t\t\tchanged = true\n\t\t\tcontract_changed = true')
for assignment in ['seed_value = s','ramp = m','size = n']:
    a=assignment+'\n\t\t\tchanged = true';assert a in f;f=f.replace(a,a+'\n\t\t\tcontract_changed = true')
a='if changed and noise_field != null:\n\t\t_apply_contract()\n\t\t_update_noise_parameters()';assert a in f
f=f.replace(a,'if changed and noise_field != null:\n\t\t# Changing the display must not restore a seed chosen before REGEN.\n\t\tif contract_changed:\n\t\t\t_apply_contract()\n\t\t_update_noise_parameters()')
write(rel,s[:start]+f+s[end:])
rel='commons/maps/Noise_Perlin_Simplex/final.md'
replace(rel,'The seed stays where you left it, even after REGEN; only the way a value occupies space has changed.','VIEW leaves the seed alone. If you used REGEN, you keep that new field; only the way its values occupy space has changed.')
replace(rel,'The library has folded a longer calculation into the small call above; the call has not made that calculation disappear. [The engine\'s noise definitions](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html#enumerations).','The library has folded a longer calculation into the small call above; the call has not made that calculation disappear.[^engine-noise]')
replace(rel,'The small sheet keeps changing. A little noise, and something begins to feel organic.',
    'Try two tellings of the encounter: what you saw, and the operation you learned to recognise. Where they do not quite meet, you have a reason to return. Hold a seed. Change a threshold. Look at an edge after the veining is gone.\n\nThe small sheet keeps changing. A little noise, and something begins to feel organic.')
p=r/rel;write(rel,p.read_text().rstrip()+'\n\n[^engine-noise]: The [Godot 4.6 FastNoiseLite reference](https://docs.godotengine.org/en/4.6/classes/class_fastnoiselite.html#enumerations) distinguishes TYPE_PERLIN from TYPE_SIMPLEX, which uses OpenSimplex2, and TYPE_SIMPLEX_SMOOTH, which uses OpenSimplex2S.\n')
rel='commons/maps/Lab_Path/final.md'
replace(rel,'What has followed you out of the room?\n','# What has followed you out of the room?\n\n*An optional return to the Noise rooms.*\n')
replace(rel,"In the cellular-automata rooms, a cell's next state will depend on what its neighbours were doing in the previous step. That previous step has to be kept while the next one is written. The neighbourhood we have been learning to recognise acquires another task. What kinds of bodies could come from that dependence?\n\n",'')
write('commons/maps/Lab_Path/intent.md','''# Lab Path — an optional return

Lab_Path remains a small grid-lane corridor and an optional reflection after Noise. It is listed in the sequence source and complete text capture, but its book pearl stays drop:true; the museum goes from Noise_Perlin_Simplex directly to Cellular Automata. It is not the shared endpoint of every sequence.

Keep the question of two tellings: what happened in the encounter, and what the operation did. Their strongest invitation now also belongs to the main Perlin/Simplex ending, where every spine reader can meet it. The optional coda can invite a return without sending the reader into Cellular Automata a second time.

The existing dark sphere gives the corridor a quiet continuing process. No new primary lesson or artifact is promoted here. Spatial correlation in a noise field is not stored memory of a previous state; the next main sequence introduces that different relation explicitly.

Retain the grid, teleporter and existing scene. A future decision to build this pause into the museum would require spatial work, not simply changing its prose or clearing the drop flag.
''')
write('commons/maps/Lab_Path/summary.md','''# Lab Path — Summary

An optional reflection on the Noise encounters: a changed colour, a broken connection, a ridge that caught a foot. The text asks for two tellings of an encounter, one from perception and another from the operation, so an unfinished question can guide a return.

The source map retains its 5 × 5 grid, teleporter and dark sphere. It remains available in the grid lane and in the complete sequence capture. The museum/book pearl is dropped; the main spine goes from Noise_Perlin_Simplex to Cellular Automata. The coda is not a second required handover or a shared endpoint for every sequence.

The main chapter now carries the coda's invitation to hold a seed, change a threshold and inspect an edge after its finish is removed. The corridor preserves room for a longer pause without adding a new algorithm to learn.
''')
write('commons/maps/Lab_Path/blurb.md','''A patch brightened. A connection broke. A ridge caught your foot. Which encounter has followed you out of the room?

The sphere keeps turning while you give it two tellings: what you met, and the operation you began to recognise. Where the accounts do not quite meet, there may be a reason to go back.
''')
rel='commons/maps/Lab_Path/map_data.json';s=(r/rel).read_text();a='Transition corridor back to the lab. Shared endpoint for all sequences.';assert a in s;write(rel,s.replace(a,'Optional return corridor for reflecting on the Noise encounters. Available in the grid lane; the museum spine continues directly from Perlin/Simplex to Cellular Automata.'))
rel='commons/maps/sequences/noise.json';d=json.loads((r/rel).read_text(encoding='utf-8-sig'));n=d['sequences']['noise']
n.update(name='Noise: Fields and Possible Bodies',truth='A field can be read as colour, relief, an address or a threshold. Each use makes different bodies and passages possible.',qfep_term='λE(S)',qfep_connection='The QFEP vocabulary invites us to ask how variation is weighted and what a chosen representation makes possible or withholds. These halls do not calculate QFE, equate spatial coherence with memory, or measure political freedom through noise.',formula='Layered example: f(p) = Σᵢ aᵢ n(fᵢ p). Receiving operations turn sampled values into colour, displacement, warped addresses or occupancy.',description='Follow a value from a column to a surface, from a threshold into an occupied volume, and from a borrowed address into a room you can enter. Hold a field steady while changing what receives it. Walk its ground, return with another body, and compare Perlin with OpenSimplex2 under shared conditions. Noise can lend an object an organic gesture; its ease can also let a familiar blob arrive before a different form has been imagined. The main spine continues to Cellular Automata, where stored states and neighbours take on another role. Lab Path remains an optional return.')
n['learning_objectives']=['Distinguish spatial relationships, repeated sampling and stored state','Follow one field through colour, relief and thresholded occupancy','Compare layered contributions and the mappings that display their sum','Use a coordinate field to change where another field is sampled','Relate a sampled surface to collision, route and body scale','Compare Perlin and OpenSimplex2 without confusing the display grid with either generator','Investigate the pleasure and limits of noise as an easy organic gesture']
n['content']=[m+': '+(r/'commons/maps'/m/'final.md').read_text(encoding='utf-8-sig').splitlines()[0].removeprefix('# ')+(' (optional return; outside the museum spine)' if m=='Lab_Path' else '') for m in n['maps']]
rationales={
'Noise_One':'One field received as relief or colour; a basin isolates and combines retained terrain contributions.',
'Noise_Voxel':'The same threshold decisions at model and body scale; occupied connectivity does not guarantee a usable route.',
'Noise_6_Wall':'A layered sum dresses an enclosure; colour, apparent depth and collision can answer differently.',
'Noise_Inside_Noise':'Domain warping borrows another address; values shape an enclosing surface while its floor and doors stay pinned.',
'Noise_Space_10':'A fixed terrain meets proposed routes, recorded walks and reversible changes of visitor scale.',
'Noise_Perlin_Simplex':'Matched fields and walk-through arches expose which conditions change; the organic shortcut leads into Cellular Automata.',
'Lab_Path':'Optional grid-lane reflection outside the museum spine; the main Perlin/Simplex ending carries its invitation to return.'}
for group in n['artifact_groups']:
    if group['map'] in rationales:group['rationale']=rationales[group['map']]
n['local_review_history']=n.get('local_review_history',[])+[{'date':'2026-09-25','path':o.relative_to(r).as_posix()+'/DECISIONS.md','scope':'Readable sequence description, corrected encoding, current chapter purposes and explicit optional coda; map order and routing retained.'}]
write(rel,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print('Frozen baseline; targeted display reset fix, chapter ending and sequence metadata applied.')
