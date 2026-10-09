from pathlib import Path
import json,hashlib
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];ROOM='QFEP_Lambda_Spectrum';BASE=ROOT/'commons/maps'/ROOM
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d):(ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def md(n,s):(BASE/n).write_text(s,encoding='utf-8',newline='\n')
archive='''# Earlier Lambda hall proposals — historical drafts

Preserved on 20 September 2026. These drafts imagine a corridor that changes its parameters with the visitor's position. That is not the current implementation. The actual artifact distributes an authored spectrum across its width, with a separate movable floor recommendation. Neither the green band nor the kinetic forms measure an empirical interval in which life appears. The project's lambda weight is not simply interchangeable with Langton's parameter for cellular-automaton rules.

Keep the questions about continuous modulation, architecture as persuasion and bodily orientation. The older named theoretical associations remain research material; the current encounter cannot establish the scientific claims attached to them.
'''
for n in ['technical.md','critical.md']:
 archive+='\n---\n\n## Preserved '+n+'\n\n'+(HERE/'before/commons/maps'/ROOM/n).read_text(encoding='utf-8-sig')
md('design-proposals.md',archive)
md('technical.md','''# A recommendation independent of its surroundings

In the Introduction, lambda weights the E contribution to an arithmetic total. Here it becomes a spatial analogy: an authored spectrum has repeated cubes on one side, jittered and animated cubes on the other, and six intermediate rows. No entropy distribution is measured to assign their places.

The existing lambda_value configuration controls the corridor's initial clearance and the colour/emission emphasis of its rows. It remains at 0.35 in this hall. Previously changing it also moved the lit floor, so a comparison could not distinguish a changed recommendation from changed surroundings.

The optional recommendation_control:on adds a LIT STRIP rail and RETURN button at the entrance. Its recommendation_position ranges from 0.20 to 0.80. The lit strip has no separate collider. It moves above a continuous floor:

```gdscript
_recommendation.position.x = (value - 0.5) * hall_width
```

The recommendation node contains the lit floor mesh, its two bright edge strips and its inscriptions. Changing this value moves that node and updates the suggested-value labels and console reading. It does not rebuild the spectrum, move its rows, recolour their materials, reseed them, move the capture camera or reset animation time. RETURN restores the initial authored recommendation without rebuilding the environment.

The slider interval keeps the 1.4 m strip inside the side kerbs of the seven-metre hall. Those bounds are interface choices. They are not claims about optimal lambda. The kerbs have taller invisible containment colliders than their visible mesh. The cube rows themselves are rendered forms without individual solid collision; the continuous floor carries the walker. A glowing strip under a cube is therefore a visual contradiction, not a newly computed traversable route.

The full fourteen-metre-long artifact now fits inside a seventeen-by-twenty-four gallery. Nine secondary placements remain in the outer bays. The bifurcation_walkway token is retained but its registry still disables it; enabling that comparison is separate development work. The other works do not receive this rail's value. A malformed noise hash in the dissolving form's shader is corrected so that retained comparison can render again. The map's older along-z/body-as-slider captions are removed because no such player-position coupling is implemented. artifact_placement:map makes these placements authoritative over an older stamped necklace that omitted the main hall. The central encounter is kept clear of automatically added sculptures.

Default placements without recommendation_control keep their original coupling between configured lambda, geometry and floor placement, without the new console. Configuration rebuilds now free only nodes made by the artifact, preserving external framing.

The comparison asks whether moving a recommendation changes a visitor's preference. The runtime checks establish that the controls keep the intended variables fixed; a response from visitors is still needed to investigate the question.
''')
md('critical.md','''# The invitation can move

The light has moved. The room has not made room for it.

At first the green strip fits an arrangement that seems to welcome it: rows stand aside and nearby forms take on its colour. Move the recommendation and the agreement comes apart. One suggestion travels with your hand; another remains in the disposition of the cubes.

This is a small distinction with consequences. Moving a label is easier than redistributing the conditions that made its old location persuasive. A new invitation can leave the old arrangement intact. It may even recommend standing where a form already appears to be.

The repeated side also deserves more than the role of a dead opposite. Its intervals make comparisons possible. Something can be relied on long enough to notice a small difference. The dispersed side can draw attention and unsettle that expectation. Neither effect supplies a verdict about what a body ought to prefer.

In the project's QFEP documents, keeping a model revisable includes asking who has the capacity to change its terms. This encounter grants a limited version of that authority. You may move the suggestion. You cannot alter its green, extend the rail past its stops, or rearrange the rows through this interface. Self-Q also turns the question on the maker: how much has the original glowing middle trained our own idea of what a good place should look like?

Keep the hall's pleasure. Its attraction gives the investigation something to work with. The question is whether we can feel a preference taking shape and still find handles for changing the conditions that produced it.

Source framing: [QFEP development notes](../../../doc/research/qfep/README.md) and [Self-Q](../../../doc/ENTRY.md#the-self-q-recursive-qfep). The claims about visitor preference remain questions for an encounter, not established findings.
''')
md('summary.md','''# Lambda — the path the hall recommends

Fourth of eight declared QFEP Laboratory halls. The primary lambda_hall presents a fixed authored spectrum across its width, from repeated to dispersed forms. A compact entrance console moves only its glowing floor recommendation and inscriptions. Its rows, colours and animation keep their own settings.

Try recommendations at different positions, then press RETURN. Compare what the movable light invites with what the existing geometry and colours already favour. The control does not measure entropy, move the visitor or reveal a universal interval for life.

The 17 by 24 level gallery contains the full-size 7 by 14 artifact and all nine existing secondary works. Entry, the original clear passage and exit are retained. The older supporting drafts survive as historical proposals. Visitor preference, tracked-hand reach and headset comfort remain to be tested.
''')
md('blurb.md','''*The light has moved. Has the invitation?*

Slide the recommended path to another part of the hall. The forms keep their places.

Which do you follow: the light, the gap, or the preference you brought with you?
''')
p='commons/artifacts/registry/concept_architecture.json';d=read(p);a=d['artifacts']['lambda_hall']
a.update(description='A full-size authored spectrum between regular and dispersed forms. Optional recommendation_control adds an entrance rail that moves only the lit floor strip and inscriptions; the rows, their colours and animation are independent of that suggestion.',qfep_connection='Who sets the relative weight, and who can revise its spatial recommendation? The green band is an authored preference, not a measured condition for life.',parameters={'recommendation_control':'on/off; default off. Adds LIT STRIP and RETURN.', 'recommendation_position':'0.20–0.80; movable floor recommendation independent of lambda_value.', 'lambda_value':'Authored structure/colour preference; controls the original geometry at build time.'})
write(p,d)
p='commons/data/museum_core_encounters.json';d=read(p);r=d['rooms'][ROOM]
r.update(reason='Move the lit recommendation while keeping the authored spectrum and its animation independent; compare the invitation with the arrangement it inherits.',status='encounter_and_text_revised',learner_verified=False,review_evidence=HERE.relative_to(ROOT).as_posix()+'/SUMMARY.md')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[k]=hashlib.sha256((BASE/n).read_bytes()).hexdigest()
write(p,d)
lines={'lambda_hall':'The light has moved. Has the invitation?','bifurcation_walkway':'One rule, many outcomes. Which parameter are you following?'}
p='commons/data/book/qfeplaboratory.json';d=read(p);pearl=next(x for x in d['pearls'] if x['map']==ROOM);pearl.update(hero='lambda_hall',lines=[{'token':t,'text':s,'by':'hand'} for t,s in lines.items()]);write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='qfeplaboratory')
 for pearl in node['pearls']+d.get('hand_pearls',{}).get('qfeplaboratory',[]):
  if pearl.get('map')==ROOM:pearl.update(hero='lambda_hall',says=lines,says_by={t:'hand' for t in lines})
 write(p,d)
p='commons/maps/sequences/qfeplaboratory.json';d=read(p);s=d['sequences']['qfeplaboratory'];s['content'][3]='QFEP_Lambda_Spectrum: The path the hall recommends'
g=next(g for g in s['artifact_groups'] if g['map']==ROOM);g.update(artifacts=list(read('commons/data/artifact_roles.json')['roles'][ROOM]),rationale='Retain the authored spectrum and all ten works; move only the lit recommendation to compare its invitation with the geometry and colours already in place.')
write(p,d)
print('Lambda manuscript, supporting notes and museum speech aligned; original mature opening retained.')
