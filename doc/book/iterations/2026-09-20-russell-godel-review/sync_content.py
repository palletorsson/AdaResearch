from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
def read(p):return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d):(ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p='commons/artifacts/registry/qfep.json';d=read(p);a=d['artifacts']['russell_paradox_workbench']
a['description']='Six set descriptions, from subsets to unrestricted Russell comprehension and finite separation. Opt-in physical IN / OUT buttons let visitors test both self-membership assumptions. At cell 5 both answers contradict the rule. Cell 6 filters the existing set of finite ordinals U={0,1,2,3}; the result equals U but is not a member of U, so OUT agrees. Dots and orbit illustrate the argument; the workbench does not decide arbitrary set formulas.'
a['capacity']='Test the membership rule, then change its domain'
a['parameters'].update(membership_controls='Opt-in physical IN / OUT buttons; on in Russell_Paradox',initial_cell='1..6; cell 5 begins with an unanswered membership question when controls are on')
write(p,d)
p='commons/artifacts/registry/foundations_crisis.json';d=read(p)
d['artifacts']['godel_sentence_machine']['description']='A timed sculpture of the Godel argument, visibly labelled as an illustration, not a proof search. For a sound, effectively axiomatized theory with sufficient arithmetic, the constructed G is true in the intended natural numbers and unprovable in that theory. The mechanism does not establish this theorem by jamming.'
d['artifacts']['provability_sorter']['description']='A nested illustration of provability within truth, assuming a sound, effective theory with sufficient arithmetic. Tokens have destinations chosen in advance; ring areas and token counts measure no proportion of mathematical truths.'
write(p,d)
p='commons/data/artifact_roles.json';d=read(p)
d['roles']['Russell_Paradox'].update(russell_paradox_workbench='primary',hilbert_hotel='primary')
write(p,d)
p='commons/data/museum_core_encounters.json';d=read(p)
for room in ['Russell_Paradox','Godel_Incompleteness']:
 r=d['rooms'][room]
 if room=='Russell_Paradox':
  r['primary_tokens']=['russell_paradox_workbench','russell_set_box','barber_paradox','hilbert_hotel']
  r['reason']='Test unrestricted membership, then finite separation. Preserve the box and barber; promote the hotel as a resolved counterexample to contradiction.'
  r['status']='encounter_and_text_revised'
 else:
  r['reason']='Preserve the mature chapter; label its two primary machines as illustrations and state the limits of their evidence.'
  r['status']='text_preserved_exhibit_labels_revised'
 r['learner_verified']=False
 r['review_evidence']='doc/book/iterations/2026-09-20-russell-godel-review/SUMMARY.md'
 for k,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[k]=hashlib.sha256((ROOT/'commons/maps'/room/f).read_bytes()).hexdigest()
write(p,d)
speech={
 'Russell_Paradox':('russell_paradox_workbench',{
  'russell_paradox_workbench':'Choose IN. Now try OUT. What changes when the rule begins within an existing set?',
  'russell_set_box':'An inside with another inside. Does drawing another box answer the membership question?',
  'barber_paradox':'The barber belongs to the group. Who shaves the barber?',
  'hilbert_hotel':'Everyone moves from n to n + 1. This surprise has an answer.',
  'liar_loop':'The lamp stages a difficulty about truth. A timer supplies its rhythm.',
  'self_membership_set':'Does a brace inside a brace depict another set, or the very same set?',
  'euclid_postulates_plaque':'A changed axiom, a different geometry. Which permission is being reconsidered here?'}),
 'Godel_Incompleteness':('godel_sentence_machine',{
  'godel_sentence_machine':'Does a machine failing to find a proof show that no proof exists?',
  'provability_sorter':'Assume a sound arithmetic theory. The gap illustrates a relation; its size does not count truths.'})}
p='commons/data/book/foundationscrisis.json';d=read(p)
for pearl in d['pearls']:
 if pearl['map'] not in speech:continue
 hero,lines=speech[pearl['map']];pearl['hero']=hero
 for ln in pearl['lines']:
  if ln.get('token') in lines:
   ln.update(text=lines[ln['token']],by='hand');ln.pop('note',None);ln.pop('note_src',None)
 for token,text in lines.items():
  if not any(ln.get('token')==token for ln in pearl['lines']):pearl['lines'].insert(0,dict(token=token,text=text,by='hand'))
write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='foundationscrisis')
 for pearl in node['pearls']+d.get('hand_pearls',{}).get('foundationscrisis',[]):
  if pearl.get('map') in speech:
   hero,lines=speech[pearl['map']];pearl.update(hero=hero,says=lines,says_by={t:'hand' for t in lines})
 write(p,d)
