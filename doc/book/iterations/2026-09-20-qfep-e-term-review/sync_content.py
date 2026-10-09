from pathlib import Path
import json, hashlib

HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; ROOM='QFEP_E_Term'; BASE=ROOT/'commons/maps'/ROOM
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
def md(name,text): (BASE/name).write_text(text,encoding='utf-8',newline='\n')

archive='''# Earlier E hall proposals — historical draft

Preserved on 20 September 2026. These drafts contain conceptual proposals alongside descriptions that do not hold for the current hall. In particular, QFEP means Queer Free Energy Principle; the independent lambda rail is not fixed at 1; particle spread is not a measurement of entropy; and the fan uses natural logarithms in nats. Keep the questions about who specifies the state space and how an apparent freedom depends on its conditions. The current manuscript and technical note describe the implemented encounter.
'''
for name in ['technical.md','critical.md']:
    archive+='\n---\n\n## Preserved '+name+'\n\n'+(HERE/'before/commons/maps'/ROOM/name).read_text(encoding='utf-8-sig')
md('design-proposals.md',archive)
md('technical.md','''# Count the endings before weighting them

The previous hall varied a binary source probability while preserving its two possible symbols. Here the entropy fan varies the number of available endings.

Four levels, each offering b continuations, produce b^4 leaves: 1, 16 or 81 for b=1, 2 or 3. The running CYCLE visits those three branching factors. ONE holds a single continuous stem. OPEN holds the full ternary tree. PRUNE uses the existing pruned prospect: at the third level, each of nine parents retains one child instead of three. Eighteen amber branch caps remain visible; their removed subtrees would have contributed fifty-four leaves. Twenty-seven leaves survive.

The implementation counts leaf meshes as it builds them. Its readout then uses:

```gdscript
var s_val: float = log(float(futures))
```

This is H=ln(N), the Shannon entropy of a uniform distribution over N leaves, in nats. It is not a measured distribution of visits. For 1, 16, 81 and 27 leaves the readings are approximately 0, 2.77, 4.39 and 3.30 nats. Unequal probabilities would require a different calculation, -sum(p*ln(p)). The display now states its equal-weight assumption and distinguishes branch closures from missing leaf outcomes.

This map enables visitor_control:on. Four canonical physical buttons select CYCLE, ONE, OPEN and PRUNE. The console remains alive while the diagram rebuilds, so pressing a button does not free the node emitting its signal. The fan and adjacent readout are raised on a stand; the control surface is at 0.95 m above the map floor. Placements without the option retain automatic cycling and no console. Existing prospect and emissive configurations remain supported.

The fourteen-by-fourteen hall has a level floor and clear side passages. Seven placed works remain. Counter, cloud, particles, cubes and the independent lambda rail are secondary comparisons; none supplies the fan with probabilities. The legacy tt text token remains in the map but does not currently instantiate as a museum artifact. Lambda's ignored value:1.0 configuration and the dissolution caption are removed. Its rail remains movable with no preferred-band marking here.

OPEN restores an authored diagram. It does not model ecological repair or give the visitor authority to invent another branching rule. That difference is the chapter's next research question, connected to QFEP's revisable terms in the project documents.
''')
md('critical.md','''# Who may add a branch?

The fan can count what it has been allowed to draw. It cannot count the request it never received.

At first the amber caps make absence unusually legible. A branch reaches a point and stops; its neighbours continue. The remaining leaves are no longer an innocent picture of everything that could happen. Someone has intervened upstream.

Yet the visitor's apparent authority is also bounded. Four buttons, four authored responses. Reopening the tree restores the same alternatives, not an alternative to the tree. The machine cannot hear a request for another kind of ending.

This is a concrete place for the project's Queer Free Energy Principle. In the QFEP research documents, Q asks that models remain revisable while the beings and capacities they leave out can continue to act and change those terms. Self-Q returns that question to the maker: which future habits of thought does this apparatus train in us? We may become very good at choosing among branches and forget to ask who drew them.

The older draft's question about who specifies a state survives. Its equation of high entropy with freedom does not. A protective closure can sustain a vulnerable life; an abundance of offered choices can leave the conditions of choosing untouched. Neither amber nor green settles the matter. Entropy is computed over specified alternatives. Care involves consequences for others that this count does not contain.

Keep the pleasure of the returning fan. Then ask what OPEN has made too easy. A restored diagram carries no debt for its missing time. Bodies may.

Sources: [QFEP development notes](../../../doc/research/qfep/README.md), [Entropic morality](../../../doc/research/qfep/entropic-morality.md), and [Self-Q](../../../doc/ENTRY.md#the-self-q-recursive-qfep). These formulate the project's ethical proposal; the artifact does not prove it.
''')
md('summary.md','''# E Term — counting what could happen

Third of eight declared QFEP Laboratory halls. Seven of those halls currently appear in the authored route; Sandbox remains a later restoration task.

The primary entropy fan now has CYCLE, ONE, OPEN and PRUNE controls. Compare one, sixteen and eighty-one leaves, then hold the open tree and close eighteen branches, leaving twenty-seven leaves. The readout reports equal-weight entropy in nats and distinguishes closures from removed endings. OPEN returns the authored tree.

A level fourteen-by-fourteen gallery holds all seven existing placements. The independent lambda rail and other secondary comparisons remain. The main text keeps its shared-history/counting argument and brings the research documents' QFEP question into the encounter: who can revise the alternatives, and what capacities survive exclusion? Headset interaction and learner understanding remain to be checked.
''')
md('blurb.md','''*The branch stops. Its neighbours continue.*

Watch a few continuations multiply into a crown. Close some branches. Reopen them.

Who gave you these choices? Could you ask for another kind of ending?
''')

p='commons/artifacts/registry/qfep.json';d=read(p);a=d['artifacts']['entropy_fan']
a.update(description='A branching diagram counts its leaves and reports H=ln(N) in nats under equal leaf weights. Optional visitor controls compare the cycling, single-path, open and pruned prospects. Closures remain as amber caps; the count is not a measure of freedom.',interaction='observe; CYCLE/ONE/OPEN/PRUNE buttons when visitor_control is on',capacity='Compare counted alternatives with visible branch closures')
a['parameters']['visitor_control']='on/off; default off. Adds a reachable four-button console and raised fan/readout.'
write(p,d)
p='commons/data/museum_core_encounters.json';d=read(p)
r=d['rooms'][ROOM];r.update(reason='Count equally weighted endings; prune and reopen the fan, then ask who may revise its authored alternatives.',status='encounter_and_text_revised',learner_verified=False,review_evidence=HERE.relative_to(ROOT).as_posix()+'/SUMMARY.md')
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[k]=hashlib.sha256((BASE/n).read_bytes()).hexdigest()
d['rooms']['QFEP_Introduction']['text_sha256']=hashlib.sha256((ROOT/'commons/maps/QFEP_Introduction/final.md').read_bytes()).hexdigest()
write(p,d)
lines={'entropy_fan':'The branch stops. Its neighbours continue. Who can ask for another kind of ending?', 'microstate_counter':'Which differences enter the count?', 'possibility_space_cloud':'An offered space has a boundary. What lies beyond its offer?'}
p='commons/data/book/qfeplaboratory.json';d=read(p);pearl=next(x for x in d['pearls'] if x['map']==ROOM)
pearl.update(hero='entropy_fan',lines=[{'token':t,'text':s,'by':'hand'} for t,s in lines.items()]);write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='qfeplaboratory')
 for pearl in node['pearls']+d.get('hand_pearls',{}).get('qfeplaboratory',[]):
  if pearl.get('map')==ROOM:pearl.update(hero='entropy_fan',says=lines,says_by={t:'hand' for t in lines})
 write(p,d)
p='commons/maps/sequences/qfeplaboratory.json';d=read(p);s=d['sequences']['qfeplaboratory']
s['content'][2]='QFEP_E_Term: Counting what could happen'
g=next(g for g in s['artifact_groups'] if g['map']==ROOM)
g.update(artifacts=list(read('commons/data/artifact_roles.json')['roles'][ROOM]),rationale='The visitor-controlled entropy fan counts endings and exposes branch closures. All seven placed works remain. Secondary comparisons are not inputs to the count; lambda is independent and movable.')
write(p,d)
print('E manuscript, supporting notes, registry and museum speech aligned; introduction hash refreshed.')
