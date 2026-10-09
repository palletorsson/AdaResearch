from pathlib import Path
import json,hashlib
R=Path.cwd(); H=R/'doc/book/iterations/2026-09-24-door-timing'
def read(p):return p.read_text(encoding='utf-8-sig')
def load(p):return json.loads(read(p))
def save(p,d):p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/'commons/maps/Random_Game/map_data.json';d=load(p)
assert len(d['layers']['structure'])==52
for name,rows in d['layers'].items():
 template=['w']+['1']*17+['w'] if name=='structure' else [' ']*19
 rows[32:32]=[template.copy() for _ in range(14)]
d['layers']['interactables'][38][9]='door_timing_trials'
d['map_info']['dimensions']['depth']=66
d['map_info']['museum']['sculpture_clear_rects'][0][3]=64
d['map_info']['metadata']['learning_objectives'].append('Compare draw timing with reveal timing by walking matched direct and detour passages')
save(p,d)
p=R/'commons/artifacts/registry/randomness.json';d=load(p);d['artifacts']['door_timing_trials']={
'lookup_name':'door_timing_trials','name':'When did the door decide?','scene':'res://commons/artifacts/door_timing_trials/door_timing_trials.tscn','category':'randomness','sequence':'randomness','map_sequences':['randomness'],'map_ready':True,'include_in_map_data':True,'parameters':{'footprint':[15,6,7],'size_group':'room_scale'},'description':'Three matched walk-through trials: draw-reveal-choose, choose-draw-reveal, and draw-choose-reveal. Floor plates select a lane; its result opens a direct shortcut or leaves a longer path around a wall. Seeded algorithmic assignment, not physical entropy. Independent replay controls reject resets while a player occupies the route.','interactions':['Step on A or B to choose','Walk the direct passage or the longer route','Read the retained event order','Replay from outside or start a new seeded round'],'tags':['uncertainty','decision','disclosure','timing','spatial_consequence'],'qfep_connection':'A decision and access to that decision are separate events. Changing disclosure changes what a visitor can act upon even with the same possible routes.'};save(p,d)
primaries=['r_c','random_removal_arena','random_doors','door_timing_trials','cube_projectile_spawner']
p=R/'commons/maps/sequences/randomness.json';d=load(p)
for group in d['sequences']['randomness']['artifact_groups']:
 if group['map']=='Random_Game':
  group['artifacts']=primaries
  group['rationale']='Sampled waits, removal, concealed assignment and matched decision/disclosure trials give uncertainty distinct bodily consequences before the regular falling field.'
save(p,d)
passage='''<!-- @door_timing_trials -->

Farther along, three small passages repeat the same plan. Two lettered plates lie before each entrance. A wall waits behind each door. One lane will open straight through; the other asks you to turn and go around it. Both reach the far side. Here the cost of a choice is a piece of walking.

At SHOWN FIRST, one letter already says DIRECT. The other says AROUND. Step onto a plate. Your entrance lifts. You can choose the shorter passage, or choose the longer one because you want to see where it goes. Knowing does not prescribe what you must want.

At DRAWN AFTER, both letters carry a question mark. Step forward and watch the three signs above you fill: CHOOSE, DRAW, REVEAL. The program waits for your foot before assigning the shortcut. Your chosen letter stays chosen while its meaning arrives.

The third passage looks equally undecided. But HIDDEN FIRST already carries a DRAW in its first sign. Something has happened without becoming available to you. Step onto a plate: CHOOSE, then REVEAL. Perhaps you turn a corner. Perhaps you walk straight through. Could the walk alone have told you whether the assignment came before your step or after it?

The walls have the same dimensions. The drawing rule has the same two possible answers. What changes is the order:

```text
draw → reveal → choose
a choice → a draw → its revelation
draw → choose → reveal
```

We needed separate instructions for making a decision and making it visible. A question mark could mean that the program has not decided yet. It could mean that it is keeping its decision from you. On the face of the door, these can look the same.

Walk back to the controls outside. REPLAY restores this passage's seed. Now an answer withheld by its sign may still be present in your memory. NEW ROUND chooses a different seed, which can still assign the same shortcut. Each passage has its own seed; the first one does not give away the others.

Take the longer way once. What arrived as a letter becomes a turn of the body, a wall passing close to your shoulder, a few more steps. The draw did not make the distance. We built that consequence around it.

'''
p=R/'commons/maps/Random_Game/final.md';s=read(p);assert '<!-- @door_timing_trials -->' not in s
s=s.replace('<!-- @cube_projectile_spawner -->',passage+'<!-- @cube_projectile_spawner -->')
s=s.replace('These doors arrange the order differently: the assignment precedes your choice, though its disclosure waits for it.','The fire doors arrange the order differently: the assignment precedes your choice, though its disclosure waits for it. The three passages let us separate those events and walk what follows.')
p.write_text(s,encoding='utf-8');(H/'new-passage.md').write_text(passage,encoding='utf-8')
p=R/'commons/maps/Random_Game/intent.md';p.write_text('''Concept: Specify what is uncertain, when it is drawn, when it becomes knowable, and what a choice changes for the body.

Sequence role: Random_Game closes the active fourteen-map randomness route after Random_Space and prepares for Noise_Types. Sequence order is preserved.

Primary thread: r_c → random_removal_arena → random_doors → door_timing_trials → cube_projectile_spawner. The waiting_profile remains a closing companion. Multiple encounters contribute distinct comparisons; none is removed to enforce a primary count.

Critical question: Which decisions are already made, which are still to come, and what lets the visitor know the difference? Knowledge can guide a choice without determining what the visitor wants.

Staging, 24 September 2026: 19×66 hall. Existing crossing at (9,6), removal enclosure at (9,17) and fire doors at (9,29) retained. Fourteen solid-floor rows inserted before the former row 32 create a bay for three matched passages at (9,38). Falling field moves from (9,37) to (9,51); waiting profile from (9,47) to (9,61); exit moves to row 65. All original rows and artifact configuration strings are preserved. The three passages occupy fifteen metres across the seventeen-metre interior, leaving side bypasses. The new comparison has no fire: DIRECT or AROUND changes the walking route. Opaque gates conceal shortcuts until selection; each route can be exited or backed out of. Reset is refused while a player occupies the passage. Headset reach, comfort and learner acceptance remain open.
''',encoding='utf-8')
p=R/'commons/maps/Random_Game/technical.md';s=read(p);s+='''

## Current staging and door timing — 24 September 2026

This note supersedes the earlier placement and creature-inventory notes above; those describe an older hall. The current 19×66 source map has the crossing (9,6), removal arena (9,17), original fire doors (9,29), door_timing_trials (9,38), falling field (9,51), and waiting_profile (9,61). Fourteen floor rows were inserted before old row 32, retaining every former row and token. The incomplete Monte Carlo display and folding creatures are not current placements.

The new trials share geometry and the binary uniform `randi_range(0, 1)` draw law, but use distinct local seeds. SHOWN FIRST draws and reveals on reset. DRAWN AFTER draws after the first accepted plate entry. HIDDEN FIRST draws on reset but reveals only after plate entry. Each accepted choice records an immutable DRAW/CHOOSE/REVEAL event order for that round. Re-entry cannot draw again. This comparison separates assignment from disclosure; it does not claim a visitor can infer timing from outcome statistics alone.

Each plate is a player-filtered Area3D, usable by the museum CharacterBody or registered VR player bodies. Initially both entry panels and both shortcut panels are closed. Selection lifts the chosen entry, and its shortcut only if it is the direct lane; the unchosen entry stays closed. This prevents the hidden assignment being exposed by different pre-choice geometry. The other lane has a 1.2 m side opening and one-metre outer corridor. Both routes meet at the rear. The visitor may retreat through the chosen entrance. Reset/new-round controls are outside the route and reject requests while player occupancy is detected. An accepted reset kills any opening tween before restoring collision. No draw forces a particular face or switches passage after selection.

The printed seed belongs to that trial only. REPLAY repeats its assignment, not the visitor's knowledge or the rest of the hall. NEW ROUND excludes the present seed but can still give the same binary result. The existing fire-door artifact is unchanged and remains a separate earlier encounter.
''';p.write_text(s,encoding='utf-8')
p=R/'commons/data/museum_core_encounters.json';d=load(p);room=d['rooms']['Random_Game'];room['primary_tokens']=primaries;room['reason']='Waits, removal, hidden assignment and matched decision/disclosure passages make distinct uncertainty visible through support, fire and walking distance.'
for kind,file in [('text','final.md'),('map','map_data.json')]:room[kind+'_sha256']=hashlib.sha256((R/'commons/maps/Random_Game'/file).read_bytes()).hexdigest()
room['local_review']='doc/book/iterations/2026-09-24-door-timing/DECISIONS.md';save(p,d)
print('Placed trials; extended 52 to 66 rows; added book encounter and aligned current roles.')
