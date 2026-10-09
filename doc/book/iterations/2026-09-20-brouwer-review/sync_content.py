from pathlib import Path
import hashlib, json
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
ROOM='Brouwer_Intuitionism'
def read(p): return json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
def write(p,d): (ROOT/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

p='commons/artifacts/registry/foundations.json';d=read(p)
a=d['artifacts']['brouwer_choice_sequence']
a['description']='Opt-in visitor choice bench: CHOOSE 0 / CHOOSE 1 append to a finite binary prefix; RESET clears it. Shows the latest ten terms, stores at most 256, and leaves the next term unchosen. Without visitor_choices the earlier fixed-dot horizon studies remain.'
a['qfep_connection']='Compare chosen and rule-driven continuation, then question who supplied the available choices. A finite instrument does not establish mathematical lawlessness.'
a['signals']=['term_chosen(index, value)']
a['interactions']=['Press CHOOSE 0 or CHOOSE 1 to append; wait to leave the next term open; RESET starts another finite prefix.']
a['parameters']['visitor_choices']='Opt-in physical controls and finite prefix display; on in Brouwer_Intuitionism. No timer appends a term.'
a['parameters']['visitor_choice_clearance']='Allow 1.5 m of display width above a reachable console. Earlier measurements describe the legacy dot illustration.'
a=d['artifacts']['constructive_proof']
a['description']='A static specimen illustrates a witness: constructive existence requires supplying x and establishing P(x). The cube does not prove an arbitrary proposition.'
a['qfep_connection']='Ask what has been supplied and what property has actually been established.'
a['interactions']=['Observe the specimen and compare it with an explicit witness in the choice sequence or diagonal workbench.']
a=d['artifacts']['excluded_middle_demo']
a['description']='Two spheres illustrate P and not-P. The slider changes the caption between classical and constructive readings of excluded middle; it does not decide P or introduce a third truth value.'
a['qfep_connection']='Distinguish an assertion from the evidence required to make it. Intuitionistic negation still permits deriving a contradiction from an assumption.'
a['parameters']['show_rejection']='Select the constructive explanation rather than the classical explanation.'
write(p,d)
p='commons/artifacts/registry/foundations_crisis.json';d=read(p)
d['artifacts']['constructive_staircase']['description']='A timed model builds seven steps, resets and repeats. Compare this supplied finite construction with visitor-chosen continuation. Its treads have no player-supporting collision; an unbuilt step is not a third truth value.'
write(p,d)
p='commons/artifacts/registry/qfep.json';d=read(p)
a=d['artifacts']['cantor_diagonal_workbench']
a['description']='A slider selects N in {4, 8, 16, 24, 32}. The monitor shows N finite N-bit rows, a gold diagonal and a red string d with d[i] = 1 - list[i][i]. Thus d differs from every displayed row at its diagonal bit. Earlier bits persist when N increases. This finite illustration supports discussion of the infinite-sequence argument; it does not display a completed infinity.'
a['capacity']='Construct and inspect a finite diagonal string'
a['parameters']['display_offset_x']='Optional lateral monitor position, in metres; 1.1 in Brouwer_Intuitionism keeps the red constructed row visible beside the console.'
write(p,d)

primary=['brouwer_choice_sequence','constructive_proof','cantor_diagonal_workbench']
secondary=['excluded_middle_demo','constructive_staircase','angle_sum_triangle','parallel_lines','intractable_evidence']
p='commons/data/artifact_roles.json';d=read(p)
d['roles'][ROOM]={**{t:'primary' for t in primary},**{t:'secondary' for t in secondary}}
d['order'][ROOM]={'primary':primary,'secondary':secondary,'decoration':[]}
write(p,d)
p='commons/data/museum_core_encounters.json';d=read(p);r=d['rooms'][ROOM]
r.update(primary_tokens=primary,reason='Choose a finite prefix, identify a witness, then construct one by a diagonal rule. Promote the existing Cantor bench; keep the other five families as distinct comparisons.',status='encounter_and_text_revised',learner_verified=False,review_evidence=HERE.relative_to(ROOT).as_posix()+'/SUMMARY.md')
for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[key]=hashlib.sha256((ROOT/'commons/maps'/ROOM/f).read_bytes()).hexdigest()
write(p,d)
lines={
 'brouwer_choice_sequence':'The clock continues. The next term waits for your choice.',
 'constructive_proof':'Show which thing, then show that it has the property.',
 'cantor_diagonal_workbench':'Follow the gold diagonal. Where does the red row disagree?',
 'excluded_middle_demo':'A proof of which side? The slider changes the explanation, not P.',
 'constructive_staircase':'This model builds on a timer. Compare it with the row that waits.',
 'angle_sum_triangle':'Someone supplied these coordinates. What general claim do they support?',
 'parallel_lines':'A preset is a construction. What else would a proof need?',
 'intractable_evidence':'A specified procedure can still cost too much to run.'}
p='commons/data/book/foundationscrisis.json';d=read(p);pearl=next(p for p in d['pearls'] if p['map']==ROOM)
pearl.update(hero='brouwer_choice_sequence',lines=[{'token':t,'text':s,'by':'hand'} for t,s in lines.items()]);write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='foundationscrisis')
 for pearl in node['pearls']+d.get('hand_pearls',{}).get('foundationscrisis',[]):
  if pearl.get('map')==ROOM:pearl.update(hero='brouwer_choice_sequence',says=lines,says_by={t:'hand' for t in lines})
 write(p,d)
