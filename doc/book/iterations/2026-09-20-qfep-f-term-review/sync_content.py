from pathlib import Path
import json, hashlib
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; ROOM='QFEP_F_Term'; BASE=ROOT/'commons/maps'/ROOM
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def md(name,text): (BASE/name).write_text(text,encoding='utf-8',newline='\n')

archive='''# Earlier F hall proposals — historical draft

Preserved on 20 September 2026. These drafts are not a description of the current implementation. Their scientific and philosophical claims require separate review. In particular, the lambda rail is not locked, the dark sphere does not implement the dark-room problem, and matching a puzzle target is not a measurement of variational free energy.

Retain the useful development question: when does a system alter its expectation, and when does it alter its surroundings to make the expectation come true? A future comparison should implement both actions against one specified objective. The present encounter implements changing a constant prediction while holding the bit sample fixed.
'''
for name in ['technical.md','critical.md']:
    archive+='\n---\n\n## Preserved '+name+'\n\n'+(HERE/'before/commons/maps'/ROOM/name).read_text(encoding='utf-8-sig')
md('design-proposals.md',archive)
md('technical.md','''# A source and an expectation

The Introduction showed different arrangements returning the same total. Here two sources can have the same entropy while one predictor fares very differently against them.

The Shannon workbench keeps a seeded array of random draws. Its p rail sets the probability of a one by thresholding each stored draw:

```gdscript
var bit: bool = _draws[i] < _p
```

Moving the rail changes this threshold. It does not replace the stored draws. The normal sample has 256 cells; smaller and larger evidence presets remain available in the artifact configuration.

The source readout computes binary Shannon entropy from p. It does not run a compressor on the grid. The previous claim that this particular grid was incompressible has been removed. A chosen probability and one finite realisation are different things to inspect.

In this hall, `prediction_study:on` adds EXPECT 0 and EXPECT 1. Each button chooses one constant prediction for every cell. Amber underlines identify the cells that disagree. Expected error is p for EXPECT 0 and 1−p for EXPECT 1. Observed error counts mismatches in the displayed sample. At p = 0.1 and p = 0.9 the source entropy is the same, but EXPECT 0 has different expected error.

```gdscript
if int(_draws[i] < _p) != _prediction:
    errors += 1
```

Leave p at 0.9 and change the prediction. The stored draws, threshold, bit colours and source entropy stay fixed. Only the mismatch marks and predictor readout change. This is a deliberately small comparison: improvement can come from changing an expectation without changing the observed world. It does not establish that this mistake count is variational free energy.

The none preset reports no observed sample, even though the source formula and expected error are still defined. Changing sample size or seed updates the observed count and marks together. Other placements keep their single-control interface unless prediction study is explicitly enabled.

The snap puzzles and crystal remain secondary comparisons. The old snap_cube_puzzle and snap_tetra_puzzle aliases were disabled in the museum registry; this map now uses the active octahedron and tetrahedron names for the same scene files. The independent lambda rail is movable. The legacy dark sphere retains its decorative role.

Next, the E hall asks which alternatives enter a model’s distribution. Before counting uncertainty, we must decide what is counted as an outcome.
''')
md('critical.md','''# Whose mistake?

The bit remains blue. Under EXPECT 0 it was a mistake; under EXPECT 1 it is a success. Nothing inside that cell has become more obedient. You have changed what meets it.

This small switch places a limit on a familiar description: the world is difficult. Difficult for which expectation? Two source settings can occupy the same height on the entropy curve while defeating opposite guesses. The source’s uncertainty alone does not tell the whole story of a relation to it.

The comparison should not promise that every mismatch can be resolved by changing your mind. Here the available predictors are only two buttons. A different task would need different capacities. A learner might ask for a predictor that attends to a neighbour, remembers a sequence or admits uncertainty. That request already exceeds the present machine’s idea of a guess.

Ada’s question about possible bodies returns through this restriction. What could a body notice with these controls? Which differences does the apparatus call error, and what would let those differences change its model? The amber marks make one convention visible enough to contest.

The nearby puzzles offer a return to fitting points to targets. Their targets are authored; their satisfaction does not prove that order is always desirable or that deviation is pathological. Preserve them as places to investigate a different relation between an instruction and a body, without making them certify the workbench’s arithmetic.

There is also another possible experiment: keep the expectation fixed and change the world until it agrees. That is retained as development work. For now, stay with the change we can actually make. The bits keep their places. The judgment moves.
''')
md('summary.md','''# F Term — predictable according to what model?

Second of eight declared QFEP Laboratory halls, restored to the authored museum route between Introduction and E Term.

The primary Shannon workbench compares source entropy with a constant predictor’s errors. Move p, compare 0.1 and 0.9, then hold p fixed and switch EXPECT 0/1. Amber underlines mark actual misses. The display distinguishes expected error from the counted errors in one finite sample. No variational free energy is computed.

The 10 by 12 gallery has level floor, perimeter walls and open entrance/exit. The workbench at (4,4) faces the entrance. Eight existing works remain in the map. Two retired puzzle aliases are replaced with their active names for the same scene files. Puzzles, crystal and separate lambda rail remain secondary; the dark sphere remains decoration.

The earlier proposals survive in design-proposals.md. Headset interaction and learner understanding remain to be checked.
''')
md('blurb.md','''*The bits stay. Your mistakes change sides.*

Make a guess, then look for the cells that refuse it. Leave the world where it is and change the guess.

What was difficult: the source, or your way of meeting it?
''')

p='commons/artifacts/registry/qfep.json';d=read(p);a=d['artifacts']['shannon_workbench']
a.update(description='Binary source entropy H(p) and a finite fixed-seed sample. Moving p re-thresholds stored draws. The readout reports source uncertainty, not an exact encoding length for this grid. Optional prediction_study adds EXPECT 0/1, expected error and counted misses with amber cell underlines.',interaction='grab_slide; EXPECT 0/1 buttons in prediction study',capacity='Compare source uncertainty with predictor fit')
a['parameters']['prediction_study']='on/off; default off. Adds two constant-predictor buttons and error marks without changing the sampled bits.'
write(p,d)
p='commons/data/artifact_roles.json';d=read(p);aliases={'snap_cube_puzzle':'snap_octahedron_puzzle','snap_tetra_puzzle':'snap_tetrahedron_puzzle'}
d['roles'][ROOM]={aliases.get(k,k):v for k,v in d['roles'][ROOM].items()}
d['order'][ROOM]={k:[aliases.get(t,t) for t in v] for k,v in d['order'][ROOM].items()};write(p,d)
p='commons/data/museum_core_encounters.json';d=read(p);r=d['rooms'][ROOM]
r.update(reason='Compare equal source entropy with unequal predictor error, then change EXPECT 0/1 while keeping the observed bits fixed.',status='encounter_and_text_revised',learner_verified=False,review_evidence=HERE.relative_to(ROOT).as_posix()+'/SUMMARY.md')
for key,name in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[key]=hashlib.sha256((BASE/name).read_bytes()).hexdigest()
write(p,d)
lines={'shannon_workbench':'The bits stay. Your mistakes change sides. What changes when you change the guess?',
       'snap_octahedron_puzzle':'Six points meet a set of targets. Whose arrangement are you completing?',
       'snap_tetrahedron_puzzle':'Four corners can enclose a volume. A target gives your movement a destination.',
       'crystal_cluster':'A seed makes an arrangement repeatable. What would make it expected?'}
p='commons/data/book/qfeplaboratory.json';d=read(p);pearl=next(x for x in d['pearls'] if x['map']==ROOM)
pearl.update(hero='shannon_workbench',lines=[{'token':t,'text':s,'by':'hand'} for t,s in lines.items()]);write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='qfeplaboratory')
 for pearl in node['pearls']+d.get('hand_pearls',{}).get('qfeplaboratory',[]):
  if pearl.get('map')==ROOM:pearl.update(hero='shannon_workbench',says=lines,says_by={t:'hand' for t in lines})
 write(p,d)
p='commons/maps/sequences/qfeplaboratory.json';d=read(p);s=d['sequences']['qfeplaboratory']
s['content'][1]='QFEP_F_Term: Predictable according to what model?'
g=next(g for g in s['artifact_groups'] if g['map']==ROOM)
g.update(artifacts=list(read('commons/data/artifact_roles.json')['roles'][ROOM]),rationale='Restore the source/predictor workbench, with eight existing placements retained. The two puzzles use active scene aliases. Lambda is independent and movable; the decorative sphere is not a dark-room demonstration.')
write(p,d)
print('F hall manuscript, supporting notes, roles and primary speech aligned.')
