"""Prepare an editorial comparison; preserve every live chapter and artifact."""
from pathlib import Path
import difflib,hashlib,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return p.read_text(encoding='utf-8')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
maps=json.loads(read(ROOT/'commons/maps/sequences/noise.json'))['sequences']['noise']['maps']
(HERE/'before').mkdir(parents=True,exist_ok=True);(HERE/'proposed').mkdir(exist_ok=True);(HERE/'diffs').mkdir(exist_ok=True)
originals={};hashes={}
for name in maps:
 source=ROOT/f'commons/maps/{name}/final.md';saved=HERE/'before'/f'{name}.md'
 if not saved.exists():saved.write_bytes(source.read_bytes())
 originals[name]=read(saved);hashes[name]=sha(saved)
changes=[]
def replace(name,title,reason,old,new):
 assert originals[name].count(old)==1,(name,old[:70])
 changes.append(dict(map=name,title=title,reason=reason,before=old,after=new))
notes={}

replace('Random_Noise_Types','Carry the first question between the works',
 'The review identifies a strong four-part opening whose common question can become hard to follow. Keep its discoveries and give the transition a remembered action. Preserve the seed limitation in an optional note.',
 'The seed repeats this local construction when its settings and calls repeat. It does not replay the museum. The left cloud consumes the first part of one generator\'s stream; the right continues it, so these are not identical candidates subjected to different rules. There are still two works in this hall we have not approached. Their thin bars and their sounds offer other ways to meet a neighbour.',
 'The red shells could register your alteration without undoing it. That is a different kind of rule from the zero that kept reclaiming the first point\'s depth. Carry the difference to the field of needles: what does a neighbour get to decide here?[^cloud-replay]')
notes['Random_Noise_Types']=[('cloud-replay',"The seed repeats this local construction when its settings and calls repeat; it does not replay the museum. The left cloud consumes the first part of one generator's stream and the right continues it. These are not identical candidates subjected to different rules.")]

replace('Noise_Voxel','Let a connection break before giving its count',
 'Keep the distinction between occupied amount and separate pieces. The exact recorded sequence remains available in a dated note, so it supports the encounter without becoming a list to memorise.',
 'The counter for separate pieces has another rhythm. With the starting seed, 31415, it reads 4, 15, 25, 21, 32 across those five thresholds. At +0.10 there are fewer cells and fewer pieces than at zero. A connection can break and leave two pieces; a small piece can vanish entirely. Counting bodies asks a different question from counting how much is occupied.',
 'The counter for separate pieces has another rhythm. As the threshold rises, a thin connection can break and leave two pieces. A small island can vanish entirely. Less occupied space can mean more pieces, or fewer.[^voxel-pieces] Counting bodies asks a different question from counting how much is occupied.')
replace('Noise_Voxel','Keep the decision in view; put the data record in a note',
 'The threshold return statement already lets the reader follow the operation. This longer record-building line mainly documents the screen connection. Keep that detail available without interrupting the two views.',
 'This excerpt is the screen asking the bench for the stored answer:\n\n```gdscript\nrow.append({"value":value,"score":value-PerlinTerrainSculptor.contract_bias(v),"occupied":source.get("_voxels")[x][cell.y][z]})\n```',
 'The screen reads the bench\'s stored decision and sets it beside the value from which that decision was made. One view can show a difference that the other has put on the same side of the line.[^voxel-screen]')
notes['Noise_Voxel']=[
 ('voxel-pieces','In the recorded desktop comparison of 13 September 2026, seed 31415 produced 4, 15, 25, 21 and 32 face-connected pieces at thresholds −0.20, −0.10, 0, +0.10 and +0.20. Occupied counts fell throughout. These are observations of that configuration, not required outcomes for every seed.'),
 ('voxel-screen','The screen keeps the value, biased score and stored occupancy together: `row.append({"value":value,"score":value-PerlinTerrainSculptor.contract_bias(v),"occupied":source.get("_voxels")[x][cell.y][z]})`. The short threshold function earlier in the chapter makes the decision; this line gathers its two readings for display.')]

replace('Noise_Space_10','Hold a landscape still enough to feel one change',
 'Keep HEIGHT and the signed multiplication in the main text. Move the fixed generator recipe into a note; those constants are useful for returning to the experiment, but do not all need to arrive during the walk.',
 'One generator supplies this encounter: OpenSimplex2S, with seed zero, four fBM octaves, gain 0.5 and lacunarity 2. Its frequency is 0.1 and the input coordinates are multiplied by five. Those choices remain fixed while we change HEIGHT. This is one slice through the possibilities of the existing terrain, narrow enough for a difference to become attributable.',
 'The seed and the field\'s other settings stay fixed while HEIGHT changes how much of the same variation reaches the ground. We have held the source still enough to feel what one multiplication changes.[^walk-recipe]')
replace('Noise_Space_10','A detour makes another proposal',
 'Preserve the important refusal to equate a longer route with an easier one. Keep the decimal measurements in the accompanying note.',
 'The display gives a section length and its steepest sampled segment. At 0.25, route A is about 8.13 metres along the surface; B is about 10.40. B also has a slightly steeper sampled segment. Taking a detour has not automatically made this route easier. It has changed which features the proposal meets.',
 'The display gives the length and steepest sampled stretch of each proposed route. At the lower setting, B is longer and includes a slightly steeper stretch. The detour has changed what the body would meet. It has not promised an easier passage.')
replace('Noise_Space_10','Make the controller\'s limit a bodily question',
 'Keep the forty-five-degree rule because it makes computational permission specific. Move the other measured angles into the dated record, and preserve the distinction between a stalled walk and an impossible landscape.',
 'These readings leave work for the body. The section samples a line; your body has width. A capsule can meet a neighbouring slope the line does not touch. A controller\'s speed, step and slope rules also enter the encounter. The tested desktop body accepts floor angles up to 45 degrees, while route A\'s steepest sampled segment rises from about 24 degrees at 0.25 to about 58 at 0.90. The measurement helps us investigate the stalled walk without declaring the whole landscape impassable.',
 'The section follows a line; your body has width. It can meet a slope beside the line, and its controller brings rules of its own. The recorded desktop body accepted floor angles up to forty-five degrees. Increasing HEIGHT took the steepest sampled stretch of route A from below that limit to above it.[^walk-measurements] That helps us ask why this walk stopped. It does not tell us that no body could pass.')
notes['Noise_Space_10']=[
 ('walk-recipe','The fixed recipe uses OpenSimplex2S, seed zero, four fBM octaves, gain 0.5 and lacunarity 2. Generator frequency is 0.1 and input coordinates are multiplied by five. HEIGHT changes the later multiplier.'),
 ('walk-measurements','The desktop record of 13 September 2026 measured routes A/B at approximately 8.13/10.40 metres for HEIGHT 0.25; their steepest sampled segments were about 24.18°/25.22°. Route A reached about 58.26° at HEIGHT 0.90. The tested controller used a 45° floor-angle limit. Forward input crossed at 0.25 and stopped partway at 0.90. A sampled line and one desktop trajectory do not establish every route or body\'s possibilities.')]

lab='''What has followed you out of the room?

A dark patch that returned with REMAP. A connection that broke when the threshold moved. A ridge that caught your foot. Let one encounter come back before you try to explain the whole sequence.

<!-- @dark_sphere -->

The dark sphere keeps turning. For a moment, there is no new control to learn. Stay with the change you remember. What happened there, before you knew what to call it?

You might begin with what you saw: the patch brightened, the gap widened, the column turned. Then give it another telling, following the operation you learned to recognise. Did a different value arrive, or did the same value find another use?

The two tellings need each other. A name can help us return to what happened; it can also hurry us past something we have not understood. If you are unsure whether a surface changed or only its colour, keep both explanations for a moment. Which small alteration would let you tell them apart?

Hold a seed. Change a threshold. Look at an edge after the veining is gone. One question can give you a reason to return to a room you thought you had finished.

The sphere offers no verdict. Its pulse continues while you choose what to attend to. We have been learning how to make a difference visible, and how much must be held aside for that difference to become clear.

Perhaps what stays with you is the swelling surface itself. You wanted to remain near it, or to make a body that could live in its folds. Knowing its operation gives you something to change. It need not settle what the encounter was worth to you.

<!-- @ -->

In the cellular-automata rooms, a cell's next state will depend on what its neighbours were doing in the previous step. The neighbourhood we have been learning to recognise acquires another task. What kinds of bodies could come from that dependence?

Bring one of your unfinished questions with you.
'''
replace('Lab_Path','Let the coda hold curiosity as well as understanding',
 'The online review values this reflective corridor. My additional editorial concern is its examiner-like voice: name, predict, give your explanation twice, identify, state. Retain observation, explanation and a discriminating experiment, while making space for attachment and an unfinished question.',originals['Lab_Path'].rstrip('\n'),lab.rstrip('\n'))

for name in maps:
 selected=[p for p in changes if p['map']==name]
 if not selected:continue
 text=originals[name]
 for p in selected:text=text.replace(p['before'],p['after'],1)
 if name in notes:
  text=text.rstrip()+'\n\n'+'\n\n'.join('[^'+key+']: '+value for key,value in notes[name])+'\n'
 (HERE/'proposed'/f'{name}.md').write_text(text,encoding='utf-8')
 (HERE/'diffs'/f'{name}.diff').write_text(''.join(difflib.unified_diff(originals[name].splitlines(True),text.splitlines(True),fromfile='current/'+name+'/final.md',tofile='proposed/'+name+'/final.md')),encoding='utf-8')
assert all(sha(ROOT/f'commons/maps/{name}/final.md')==hashes[name] for name in maps)
(HERE/'proposals.json').write_text(json.dumps(changes,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
(HERE/'notes.json').write_text(json.dumps(notes,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
(HERE/'before-sha256.json').write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8')
print('Read9 chapters; proposed4 editorial interventions across7 passages. All live chapters preserved.')
