from pathlib import Path
import json,re,hashlib
R=Path.cwd(); H=R/'doc/book/iterations/2026-09-24-random-walk-rails'
passage='''<!-- @random_position_rails -->

## Somewhere to start

Two rails stretch beside the tank. Each carries a block. Slide the white marker to a place you think one will reach, then pull NEXT. Two empty frames appear before either body moves. The machine has made its choices. For a moment, you can see where it intends to put them.

The blue block can cross almost the whole rail. The pink one stays near where it was. Follow a few turns. Try another guess. What does knowing the last position give you?

Both receive the same new number, drawn between minus one and one. Blue uses it to choose a place along the rail. Pink uses it to propose a step of at most forty centimetres from its current place. The small addition carries a past into the next move. A walk needs somewhere to start.

At the rail ends, an outward step folds back, as it did at the terrarium glass. These bodies have not been offered an endless line. Their twelve most recent landing pairs collect below, newest at the top. Older marks disappear while the pink block keeps the position those movements helped it reach. Erase the record and that next step can still be taken.

Watch the journeys between the empty frames. Both motors take one second, with the same easing. Even blue's fresh destinations arrive by a smooth movement. Looking continuous is not enough to tell us what a process remembers.

RUN repeats the experiment; HOLD lets the revealed move finish and stops the next draw. REPLAY brings both bodies to the centre and repeats their choices. Your marker can move elsewhere. It changes neither rule. A prediction has entered the room, but the machine has no obligation to meet it.

'''
p=R/'commons/maps/Random_Walk/final.md';s=p.read_text(encoding='utf-8-sig');assert '<!-- @random_position_rails -->' not in s
s=s.replace('<!-- @random_draw_dot -->',passage+'<!-- @random_draw_dot -->',1);p.write_text(s,encoding='utf-8')
(H/'new-passage.md').write_text(passage,encoding='utf-8')
p=R/'commons/maps/Random_Walk/map_data.json';s=p.read_text(encoding='utf-8-sig');d=json.loads(s)
assert len(d['layers']['interactables'])==26 and len(d['layers']['interactables'][8])==19
assert d['layers']['interactables'][8][13].strip()==''
o=s.index('"interactables"');matches=list(re.finditer(r'"(?:\\.|[^"\\])*"',s[o:]));m=matches[1+8*19+13];assert m.group()=='" "'
s=s[:o+m.start()]+'"random_position_rails:180"'+s[o+m.end():];p.write_text(s,encoding='utf-8')
p=R/'commons/artifacts/registry/randomness.json';d=json.loads(p.read_text(encoding='utf-8-sig'));assert 'random_position_rails' not in d['artifacts']
d['artifacts']['random_position_rails']={'lookup_name':'random_position_rails','name':'Somewhere to start','scene':'res://commons/artifacts/random_position_rails/random_position_rails.tscn','category':'procedural','sequence':'randomness','map_sequences':['randomness'],'map_ready':True,'include_in_map_data':True,'parameters':{'footprint':[6,3,3],'size_group':'room_scale'},'description':'Paired rail carriages compare fresh positions with accumulated steps. Shared sampled input, advance targets, matched motor timing and a grabbable prediction marker.'}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/'commons/maps/sequences/randomness.json';d=json.loads(p.read_text(encoding='utf-8-sig'))
for g in d['sequences']['randomness']['artifact_groups']:
 if g.get('map')=='Random_Walk':
  g['artifacts']=['random_walk_terrarium','random_position_rails','random_draw_dot','random_walk_128','random_walk_collection','random_walk_leash','pixel_cloud']
  g['rationale']='Follow steps in the terrarium; compare fresh positions and accumulated steps on paired rails; carry a walking tip by hand, then enter a terrain that retains visits.'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/'commons/maps/Random_Walk/intent.md'
p.write_text('''Concept: A proposed step needs a current position. A stored drawing, a new target and an animated journey retain different things.
Sequence role: Active randomness hall 7 of 14, after Random_Rotate_Random_XYZ and before Random_Gaussian. Preserve the detailed terrarium encounter and add a bodily comparison of fresh positions with accumulated steps.
Encounter: Terrarium → paired rails → hand-carried drawing dot → terrain recording visits. The rails reveal targets before a shared-duration animation; a grabbable marker lets the visitor make a prediction without changing either generator rule.
Primary: random_walk_terrarium (9,5), random_position_rails (13,8), random_draw_dot (6,8), random_walk_128 (9,17), in that book order. Current hall is 19×26. Existing collection (3,5), leash (15,5), pixel cloud (3,9), floors, basin and bridges remain.
Technical angle: The terrarium retains five bounded walkers, its frame cap and a limited trail. The new rails share a PRNG draw in [-1,1]: blue chooses x=2.2u; pink folds its previous x+0.4u into ±2.2m. Targets appear for 0.65s before a 1s cubic-eased journey. Neither rule consults its twelve-row landing record. RUN repeats; HOLD finishes the active move; REPLAY cancels it and restores seed 79 and both centres.
Critical angle: A smooth visible journey does not prove that targets were correlated. The small addition gives the next step a relation to its past, while the animation can lend continuity to a fresh destination. Prediction does not obligate the rule. The terrarium's omitted wall contacts and vanishing early trail remain distinct, material questions.
Preservation: No earlier artifact or paragraph is removed. This is an additional comparison, not a new curriculum prerequisite. The same-input coupling is intentional; these are not independent experimental populations or physical entropy sources.
Next: Random_Gaussian gathers outcomes by frequency. Later noise can return to correlations across time with a different question.
Deferred: Tracked-hand reach, text visibility and comfort need headset review. Desktop/native checks and museum images are kept with the dated rail review.
''',encoding='utf-8')
p=R/'commons/maps/Random_Walk/technical.md';s=p.read_text(encoding='utf-8-sig')
s+='''

## Paired positions and steps — 2026-09-24

`random_position_rails` stands at (13,8), facing the first chamber. Its production source is `commons/artifacts/random_position_rails/random_position_rails.gd`.

One private RNG draw u in [-1,1] serves both rails per accepted NEXT. Blue's destination is 2.2u metres. Pink proposes previous_position + 0.4u metres, folded into [-2.2,2.2] at the ends. This intentionally coupled comparison is a bounded random walk versus fresh positions, not an unbounded Brownian process or a physical randomness source. The generator does not consult the record of twelve landing pairs or the prediction marker.

Targets appear immediately; a 0.65s reveal precedes a shared 1s cubic ease-in/out. Both use the same interpolation weight, not equal speeds. Pink's folded destination is joined directly to its previous position; the motor does not visit an omitted wall contact. NEXT is latched at 28 degrees and rearms below 8 degrees. Busy input cannot consume another draw. RUN requests every 2.8s. HOLD prevents future requests while letting the current move finish. REPLAY kills pending movement, stops RUN, clears the record, recentres the guess and restores seed 79.

The marker uses the existing horizontal slider with explicit metre-sized meshes, shapes and limits; its root is not scaled. Native grab handles and desktop pointer input share the production control. Stationary feet/posts/stands have collision; the carriage blocks and thin prediction needle are visual markers, not rideable transport or barriers.

Current book primaries: terrarium → paired rails → random drawing dot → visited-cell terrain. Original placements and map floor/utility layers are retained. Native checks, isolated actual-museum captures and remaining headset questions: `doc/book/iterations/2026-09-24-random-walk-rails/`.
'''
p.write_text(s,encoding='utf-8')
p=R/'commons/data/museum_core_encounters.json';d=json.loads(p.read_text(encoding='utf-8-sig'));room=d['rooms']['Random_Walk']
room.update(primary_tokens=['random_walk_terrarium','random_position_rails','random_draw_dot','random_walk_128'],reason='Compare a retained trail, fresh destinations, accumulated steps, a hand-carried origin and a ground that retains visits.',status='desktop_checked_headset_pending',text_sha256=hashlib.sha256((R/'commons/maps/Random_Walk/final.md').read_bytes()).hexdigest(),map_sha256=hashlib.sha256((R/'commons/maps/Random_Walk/map_data.json').read_bytes()).hexdigest(),learner_verified=False,verification_scope='Production rail controls, shared draw, revealed targets, matched easing, bounded record, replay and museum placement. Headset pending; see dated evidence.',local_review='doc/book/iterations/2026-09-24-random-walk-rails/DECISIONS.md')
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Added passage, placement, registry, current intent and book order.')
