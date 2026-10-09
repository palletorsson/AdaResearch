from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];PAGE=HERE.parent/'2026-09-19-review-comparison';PREFIX=HERE.relative_to(ROOT).as_posix()
def para(start,old=False,room='QFEP_E_Term'):
 p=(HERE/'before' if old else ROOT)/'commons/maps'/room/'final.md'
 return next(s for s in p.read_text(encoding='utf-8-sig').split('\n\n') if s.startswith(start))
review=json.loads((HERE/'before/doc/book/iterations/2026-09-19-review-comparison/qfeplaboratory.json').read_text(encoding='utf-8'))
review['status']='Introduction, F and E reviewed; Lambda next'
review['summary']='The laboratory now names Queer Free Energy Principle and Self-Q from the research documents. Introduction keeps different arrangements with a similar total; F changes a prediction while its bits remain fixed; E closes and reopens branches while exposing what its count includes. Q asks who may revise those terms. These are inspectable encounters and an ethical research proposal, not a numerical proof of freedom. Seven of eight declared halls remain authored; Sandbox is still to restore.'
review['items'][5]['description']=review['items'][5]['description'].replace('E Term is next; Sandbox is the remaining route gap.','The E hall is reviewed below; Sandbox remains the route gap.')
review['items'] += [
 {'title':'What QFEP means — from the project documents',
  'description':'QFEP means Queer Free Energy Principle. The research notes ask that a model’s terms remain revisable while what it leaves out retains the capacity to act. Self-Q brings the question back to the maker and the museum: what do our own structures teach us to notice? The introduction now includes both, with document footnotes. The reading note links the sources and separates the ethical proposal from the teaching arithmetic.',
  'text_kind':'Introduction — the project’s definition enters the book',
  'before':para('This is an operational',True,'QFEP_Introduction'),
  'after':para('QFEP stands',False,'QFEP_Introduction')+'\n\n'+para('The documents call',False,'QFEP_Introduction'),
  'report':'doc/book/iterations/QFEP_READING.md','report_label':'Read the QFEP definition and source guide'},
 {'title':'E Term: a closure has consequences upstream of the count',
  'description':'OPEN holds 81 endings. PRUNE closes 18 branches at the third level, removing 54 later endings and leaving 27. Amber caps mark where continuation stops. The existing pruned prospect is now visitor-selectable. The gallery retains its seven placed works, with a level approach and side passages.',
  'images':[PREFIX+'/fan-open.png',PREFIX+'/fan-pruned.png'],
  'captions':['OPEN: 81 leaves; H≈4.39 nats under equal leaf weights.','PRUNE: 27 leaves; 18 branch closures remove 54 endings.'],
  'image_note':'Same camera, actual Godot museum. Thinner branches and separated leaf markers make the count visible. The fan assumes equal weights; it does not measure visits or moral value.',
  'text_kind':'E Term — the proposed extension becomes an encounter',
  'before':para('Now choose',True)+'\n\n'+para('For a proposed extension',True),
  'after':para('Press PRUNE.')+'\n\n'+para('This is where QFEP'),
  'report':PREFIX+'/final.diff','report_label':'Exact E Term manuscript diff'},
 {'title':'Reopening is easy here. Changing the rule is still another question.',
  'description':'OPEN restores the same authored fan. It does not let a visitor invent a new kind of ending, and it models none of the losses that real closure can leave behind. The chapter keeps that limit as an invitation. A protective boundary may sustain a vulnerable body; counting more leaves cannot decide what care requires.',
  'images':[PREFIX+'/fan-pruned.png',PREFIX+'/fan-reopened.png'],
  'captions':['A visible stop carries the trace of an excluded continuation.','The same 81 endings return at a button press.'],
  'image_note':'31 runtime checks, five selected walking routes and 78 content/preservation checks pass. Headset reach, reading comfort and learner understanding remain pending. A pre-existing secondary microstate-counter formatting error is recorded for follow-up.',
  'text_kind':'E Term — an easy reset meets a harder question',
  'before':para('For a proposed extension',True),
  'after':para('Press OPEN again.')+'\n\n'+para('Keeping every branch'),
  'report':PREFIX+'/SUMMARY.md','report_label':'Findings, full-hall image, exact Introduction diff and limits'}
]
(PAGE/'qfeplaboratory.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Published QFEP definition and E Term encounter in the existing comparison.')
