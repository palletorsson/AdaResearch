from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];PAGE=HERE.parent/'2026-09-19-review-comparison';PREFIX=HERE.relative_to(ROOT).as_posix()
def para(start,old=False):
 p=(HERE/'before' if old else ROOT)/'commons/maps/Crisis_Synthesis/final.md'
 return next(s for s in p.read_text(encoding='utf-8-sig').split('\n\n') if s.startswith(start))
p=PAGE/'foundationscrisis.json';review=json.loads((HERE/'before'/p.relative_to(ROOT)).read_text(encoding='utf-8'))
review['status']='All eight halls reviewed: Crisis Synthesis asks who can answer the model'
review['summary']=review['summary'].replace('All eight declared halls are now authored; Crisis Synthesis remains the next review pass.','All eight declared halls are now authored and have received this encounter/manuscript review. Crisis Synthesis retains all ten works, connects its formula reading, adds an independent logistic-map control and gives the recursive room a walkable bay. QFEP remains a research proposal open to testing. Headset and learner verification remain pending.')
review['items']=review['items'][:-1]+[
 {'title':'Crisis Synthesis: a sentence with handles',
  'description':'The formula now receives the hall’s two slider signals. Three reachable term buttons reveal questions about prediction, variation and change. A readout distinguishes display weights from measured entropy. The chapter begins with curiosity about the equals sign, and no longer promises proximity selection or an effect on body weight. Six primary works carry the investigation; all ten existing works remain.',
  'images':[PREFIX+'/synthesis-formula-f.png',PREFIX+'/synthesis-formula-phi.png'],
  'captions':['F selected: what is being predicted? Lambda 0.15, phi -0.70.','Phi selected: for whom is change possible? Lambda 0.80, phi +0.80.'],
  'image_note':'Two states of the revised Godot hall, not before/after versions. Button and slider signals use the existing interaction components. This is a local reading apparatus, not a numerical QFE calculation.',
  'text_kind':'book — a proposal the reader can question',
  'before':para('The artifact\'s header',True),
  'after':para('These are questions Ada'),
  'report':PREFIX+'/final.diff','report_label':'Exact Crisis Synthesis manuscript diff'},
 {'title':'A steady state can also be a place to stand',
  'description':'The logistic map has its own r control. A yellow column shows 128 values after a 512-step settling interval. Its readout reports short repetitions found in that sample. The chapter replaces the claim that nothing rich happens below chaos with an encounter in which regularity disappears and returns. Neither this recurrence nor its period-doubling cascade proves QFEP.',
  'images':[PREFIX+'/synthesis-period-two.png',PREFIX+'/synthesis-period-three.png'],
  'captions':['r = 3.2: the selected sample repeats between two heights.','r = 3.83: three repeating heights return within the wider irregular region.'],
  'image_note':'Same camera, two selected parameters in the actual Godot museum. The r rail is independent of lambda and phi. Failing to find a short period does not prove chaos; the fixed initial condition also matters.',
  'text_kind':'book — discover a return instead of ranking disorder',
  'before':para('It is here because',True),
  'after':para('The coloured diagram'),
  'report':PREFIX+'/Crisis_Synthesis-runtime.json','report_label':'Runtime routes, controls and orbit checks'},
 {'title':'Enter the description; retain the differences',
  'description':'A level gallery replaces the mound that translated into an obstruction. The six-metre atrium now has a clear entrance and readable inscription. Its nested models make bodily scale available to attention. The Russell workbench remains an active comparison; plaque, box, staircase and held sphere remain nearby. Brouwer’s absence here no longer means that his constructive response has been rejected.',
  'images':[PREFIX+'/synthesis-atrium.png',PREFIX+'/synthesis-returns.png'],
  'captions':['A room contains a model of its own doorway. The caption identifies a finite spatial metaphor.','The smaller works return at the rear of the hall, with a clear route toward the exit.'],
  'image_note':'Six selected collision-body walks and 25 runtime assertions pass; museum process exit 0. 68 integration/preservation checks pass. The other seven hall manuscripts and maps are unchanged. Tracked hands and headset legibility remain untested; live bake data was not replaced.',
  'text_kind':'book — who can answer the model?',
  'before':para('That is a real asymmetry',True),
  'after':para('The sphere keeps both readings'),
  'report':PREFIX+'/SUMMARY.md','report_label':'Findings, decisions and limits'},
 {'title':'Next: QFEP Laboratory',
  'description':'The eight Foundations Crisis halls have received this pass. Next is QFEP_Introduction: move from reading a research proposal to testing particular implemented rules, without treating authored values as universal facts. QFEP_F_Term and QFEP_Sandbox are declared but absent from the authored museum list; resolve that placement question during the laboratory pass.',
  'report':PREFIX+'/SUMMARY.md','report_label':'Current handoff'}]
p.write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

