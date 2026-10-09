from pathlib import Path
import json,re,hashlib
R=Path.cwd();H=R/'doc/book/iterations/2026-09-24-continuing-die'
passage='''<!-- @continuing_die -->

## The six that does not finish

A single die waits beside another column base. Throw it into the felt tray. Its number becomes a section of the column, one thin block for each pip. A three leaves three blocks and closes the chain. A six leaves six, but the flag stays raised. Throw again.

This time the first section remains. Another six gives you twelve and another turn. A three after that makes fifteen and closes the chain. The small sculpture beside your tray keeps this example visible: six, six, three. Its label says WORKED EXAMPLE. It is there to show a possibility, not to tell you what you threw.

The first die in this hall made a six into a larger rain of rewards. Here the same face does something else. It keeps an instruction open. Nothing inside the cube knows that six means again:

```gdscript
total += face
closed = face != 6
```

The number enters twice: once as an amount, once as a condition. From the same six faces, the rule can build a body taller than any single throw. Look at the joins in the column. Its height has a history, and the sections still let you read it.

The amber lid marks this display's limit: five throws. If the fifth is another six, the case reads CHAIN UNFINISHED. The rule would permit more; this apparatus has run out of room. That is a different ending from a die landing three.

RETURN DIE recovers it without adding a throw. NEW CHAIN clears the live column. Until then, a closed or limited chain stays as it is even if you throw again. Before clearing it, walk around what those few landings have made. Where did the permission to keep growing reside?

<!-- @ -->

'''
p=R/'commons/maps/Random_Cubes/final.md';s=p.read_text(encoding='utf-8-sig');assert '<!-- @continuing_die -->' not in s;s=s.replace('<!-- @coin_toss -->',passage+'<!-- @coin_toss -->',1);p.write_text(s,encoding='utf-8');(H/'new-passage.md').write_text(passage,encoding='utf-8')
p=R/'commons/maps/Random_Cubes/map_data.json';s=p.read_text(encoding='utf-8-sig');d=json.loads(s);assert d['layers']['interactables'][5][2].strip()==''
o=s.index('"interactables"');m=list(re.finditer(r'"(?:\\.|[^"\\])*"',s[o:]))[1+5*12+2];assert m.group()=='" "';s=s[:o+m.start()]+'"continuing_die:180"'+s[o+m.end():];p.write_text(s,encoding='utf-8')
p=R/'commons/artifacts/registry/randomness.json';d=json.loads(p.read_text(encoding='utf-8-sig'));assert 'continuing_die' not in d['artifacts']
d['artifacts']['continuing_die']={'lookup_name':'continuing_die','name':'The six that does not finish','scene':'res://commons/artifacts/continuing_die/continuing_die.tscn','category':'randomness','sequence':'randomness','map_sequences':['randomness'],'map_ready':True,'include_in_map_data':True,'parameters':{'footprint':[3,3,3],'size_group':'room_scale'},'description':'A grabbable physical die adds each settled face to a labelled column. Six permits another throw; a non-six closes the chain. Five throws is a visible display limit, with unfinished chains marked. Separate worked example: 6+6+3.', 'qfep_connection':'A result is both an amount and permission to continue. Distinguish the rule that permits further growth from the resource limit that interrupts it; retain the difference rather than naming both completion.', 'interactions':['Throw the die into its felt tray','Throw again after a six','Return a fallen die without changing the chain','NEW CHAIN clears the live column'], 'tags':['dice','conditional','accumulation','physical_outcome','continuation','exploding_dice'],'complexity':'beginner'}
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/'commons/maps/sequences/randomness.json';d=json.loads(p.read_text(encoding='utf-8-sig'))
for g in d['sequences']['randomness']['artifact_groups']:
 if g.get('map')=='Random_Cubes':
  assert 'continuing_die' not in g['artifacts'];g['artifacts'].insert(g['artifacts'].index('paired_dice_column')+1,'continuing_die')
  g['rationale']='One die rewards a face; paired dice compose a height; the continuing die turns six into permission for another throw. Coin, changing heap and bounded field retain different consequences.'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=R/'commons/maps/Random_Cubes/intent.md';s=p.read_text(encoding='utf-8-sig');s+='''

## Continuation encounter — 24 September 2026

Retain the existing encounters and add continuing_die at (2,5), facing into the first chamber. Book order: original die → paired sum → continuing die → coin → heap → bounded edge field. A six grants a further throw in the same additive chain; a non-six completes it. The fifth six reaches a visible display limit and is explicitly unfinished. A fixed, labelled 6+6+3 sculpture is a worked example, never live evidence. Compare a face, its reward, its contribution to a sum and its power to continue an instruction. No claim of fair independent throws is made from a visitor's physical release.
''';p.write_text(s,encoding='utf-8')
p=R/'commons/maps/Random_Cubes/technical.md';s=p.read_text(encoding='utf-8-sig');s+='''

## The continuing die — 24 September 2026

`continuing_die` at (2,5), yaw 180, uses the unmodified `paired_die.gd` tray and its settled-orientation reader. The die is a production XRToolsPickable with desktop grab/drop hooks. No RNG picks a face, and no automatic reroll is performed. One fresh release arms one valid result; recovery alone never arms it.

Each accepted face appends to a chain and adds to total. A face other than six closes the chain. A six permits another accepted throw unless five throws have already been retained. Five sixes produce total 30, a 2.7m column on a 0.14m base, and an explicit UNFINISHED state. A non-six on the fifth throw completes normally. Further results cannot change a closed or capped column until NEW CHAIN. The cap is a display budget, not a natural end or a claim about an unbounded stochastic process.

One 9cm unit represents each pip; seams and labels retain individual throws. A separate fixed 6+6+3 column is marked WORKED EXAMPLE / NOT LIVE THROWS. It is not sampled, not a remembered player outcome and not mixed into live state. Column support collision follows the live sum. RETURN DIE preserves the chain. NEW CHAIN cancels pending results and clears the live column, retaining ownership if a hand holds the die. Fallen unattended dice return through the existing tray recovery.

Evidence: `doc/book/iterations/2026-09-24-continuing-die/`. Controlled face-up physics drops exercise the production reader; event-only transaction cases are separately identified. These establish behavior, not uniformity, independence or a measured outcome distribution. Tracked-hand throwing and comfort remain pending.
''';p.write_text(s,encoding='utf-8')
p=R/'commons/maps/Random_Game/final.md';s=p.read_text(encoding='utf-8-sig');return_line='At the continuing die, a six kept a chain open. The face was already on the felt when the instruction gave it that power. These doors arrange the order differently: the assignment precedes your choice, though its disclosure waits for it.\n\n';needle='The room leaves a more specific question than whether a world is predictable.';assert needle in s;s=s.replace(needle,return_line+needle,1);p.write_text(s,encoding='utf-8');(H/'game-return.md').write_text(return_line,encoding='utf-8')
p=R/'commons/data/museum_core_encounters.json';d=json.loads(p.read_text(encoding='utf-8-sig'));room=d['rooms']['Random_Cubes'];room['primary_tokens'].insert(room['primary_tokens'].index('paired_dice_column')+1,'continuing_die')
room['reason']='A physical face becomes reward, part of a sum or permission to continue. Coin, heap and bounded field retain other consequences.'
room['text_sha256']=hashlib.sha256((R/'commons/maps/Random_Cubes/final.md').read_bytes()).hexdigest();room['map_sha256']=hashlib.sha256((R/'commons/maps/Random_Cubes/map_data.json').read_bytes()).hexdigest()
room['verification_scope']+=' Continuing-die checks and isolated museum evidence: doc/book/iterations/2026-09-24-continuing-die/; controlled physical faces, fresh-release ownership, continuation, closure and explicit unfinished cap. No headset or fairness claim.'
room['local_review']='doc/book/iterations/2026-09-24-continuing-die/index.html'
d['rooms']['Random_Game']['text_sha256']=hashlib.sha256((R/'commons/maps/Random_Game/final.md').read_bytes()).hexdigest()
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Encounter placed; primary/book order aligned; previous prose and placements retained.')
