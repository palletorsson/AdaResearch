from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
PAGE=HERE.parent/'2026-09-19-review-comparison';PREFIX=HERE.relative_to(ROOT).as_posix()
def para(start,old=False):
 p=(HERE/'before' if old else ROOT)/'commons/maps/Brouwer_Intuitionism/final.md'
 return next(s for s in p.read_text(encoding='utf-8').split('\n\n') if s.startswith(start))
p=PAGE/'foundationscrisis.json'
review=json.loads((HERE/'before'/p.relative_to(ROOT)).read_text(encoding='utf-8'))
review['status']='Brouwer: the next term waits for a choice; all eight artifacts retained'
review['summary']+=' Brouwer now begins with actual visitor choices. Its existing Cantor workbench becomes a third primary, supplying a finite witness the reader can check. Eight artifact families remain, the authored placements reach the museum, and the chapter distinguishes construction, illustration and proof. Florensky and Crisis Synthesis remain.'
review['items']=review['items'][:-1]+[
 {'title':'Brouwer: the clock is no longer the author',
  'description':'The old dots were fixed: time made them bob but did not choose a term. The opt-in bench now records exactly what the visitor presses. CHOOSE 0, CHOOSE 1 and RESET replace an absent interaction with an encounter the chapter can follow. The next value remains unchosen.',
  'images':[PREFIX+'/brouwer-empty.png',PREFIX+'/brouwer-chosen.png'],
  'captions':['No terms chosen. Waiting leaves the row empty.','Five button presses: 0, 1, 1, 0, 1. The next term waits.'],
  'image_note':'Current Godot museum captures from the same camera at 1.65 m. Two states of the revised bench, not before/after software images. Button signals are exercised; tracked hands and headset reading are not yet tested.',
  'text_kind':'book — give the reader the choice the earlier text could only discuss',
  'before':para('I would not repair',True),
  'after':para('And who chose'),
  'report':PREFIX+'/final.diff','report_label':'Exact Brouwer manuscript diff'},
 {'title':'Invite the existing artifact that supplies the evidence',
  'description':'Cantor is promoted from secondary to primary. Its gold diagonal and red constructed string make disagreement inspectable, while the first bench supplies a contrast between chosen and rule-driven continuation. A lateral monitor position exposes the red row that the console previously obscured.',
  'images':[PREFIX+'/cantor-four.png',PREFIX+'/cantor-sixteen.png'],
  'captions':['Four rows of four bits. The red string disagrees with each row at its diagonal bit.','Sixteen rows of sixteen bits. Earlier bits persist as the display grows.'],
  'image_note':'Current Godot captures at N=4 and N=16. The instrument displays finite bit strings, not complete real numbers or a completed infinity. Model assertions checked all five supported sizes; see the report for the standalone-runner shutdown limitation.',
  'text_kind':'book — a finite construction supports a carefully scoped argument',
  'before':para('Cantor\'s diagonal argument',True),
  'after':para('This is a finite stage'),
  'report':PREFIX+'/SUMMARY.md','report_label':'Findings, decisions and evidence limits'},
 {'title':'Eight works, three primaries, one comparison that can be walked',
  'description':'The earlier museum placement setting hid four of the eight map artifacts. The hall now follows the map, with the choice bench at the entrance and comparison bays along a clear aisle. Optional template piers and the entry gate are omitted here. The excluded-middle caption no longer describes an unproved claim as a third truth value; the staircase is labelled as a timed model.',
  'images':[PREFIX+'/brouwer-overview.png'],
  'captions':['Existing witness, diagonal, logic, staircase and geometric comparisons remain in the hall.'],
  'image_note':'Five selected collision-body walks pass, including the aisle beside the first bench. This is controlled museum evidence, not a continuous headset playthrough. No live museum restart or bake replacement was performed.',
  'text_kind':'book — compare what is produced with what its caption claims',
  'before':para('In a room about constructive proof',True),
  'after':para('The triangle and parallel lines return'),
  'report':PREFIX+'/content-checks.json','report_label':'58 integration and preservation checks'},
 {'title':'Next: Florensky, then the synthesis',
  'description':'Florensky still lacks an authored museum hall. Inspect its existing objects and manuscript before building the missing encounter. Then revisit Crisis Synthesis with the actual distinctions made by these rooms. Seven of eight declared halls are authored; the sequence is not marked complete.',
  'report':PREFIX+'/SUMMARY.md','report_label':'Current handoff and deferred work'}]
p.write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
