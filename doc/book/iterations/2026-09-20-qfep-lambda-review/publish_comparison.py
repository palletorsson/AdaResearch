from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];PAGE=HERE.parent/'2026-09-19-review-comparison';PREFIX=HERE.relative_to(ROOT).as_posix()
def para(start,old=False):
 p=(HERE/'before' if old else ROOT)/'commons/maps/QFEP_Lambda_Spectrum/final.md'
 return next(s for s in p.read_text(encoding='utf-8-sig').split('\n\n') if s.startswith(start))
review=json.loads((HERE/'before/doc/book/iterations/2026-09-19-review-comparison/qfeplaboratory.json').read_text(encoding='utf-8'))
review['status']='Introduction, F, E and Lambda reviewed; Phi next'
review['summary']='QFEP asks who may revise the terms. Introduction keeps different arrangements with a similar total; F changes a prediction while its bits stay fixed; E closes and reopens branches; Lambda now moves a glowing recommendation while leaving the surrounding spectrum unchanged. Four laboratory halls have received this pass. Seven of eight declared halls remain authored; Sandbox is still to restore.'
review['items'] += [
 {'title':'Lambda: the light moves; the forms keep their places',
  'description':'A new entrance rail moves only the lit floor strip and its inscriptions. The repeated cubes, dispersed forms, row colours and animation settings do not follow. The original authored preference remains visible in the way the rows stand aside and take on green. A suggestion can change while its inherited conditions stay in place.',
  'images':[PREFIX+'/recommendation-left.png',PREFIX+'/recommendation-right.png'],
  'captions':['Suggested λ=0.20: the light lies towards the repeated side.','Suggested λ=0.80: the light lies beneath the more dispersed forms.'],
  'image_note':'Same camera and held animation instant in the actual Godot museum. Runtime assertions compare every row/wall MultiMesh buffer, material emphasis and drifter transform before and after the control signal. Normal animation remains independent and was checked separately.',
  'text_kind':'book — the existing proposed experiment becomes an action',
  'before':para('For a future comparison',True),
  'after':para('Return to the small console')+'\n\n'+para('Watch for disagreement.'),
  'report':PREFIX+'/final.diff','report_label':'Exact Lambda manuscript diff'},
 {'title':'Two invitations now occupy the same room',
  'description':'RETURN restores the first recommendation without reseeding or rearranging the spectrum. The chapter’s opening and main argument are preserved exactly. Its addition asks what else a visitor would need to change before this felt like their decision. The full-size hall is now centred inside a larger gallery, and its map placements override an older stamp that omitted it.',
  'images':[PREFIX+'/recommendation-return.png',PREFIX+'/lambda-console.png'],
  'captions':['RETURN: the lit strip again agrees with the gap prepared for it.','LIT STRIP and RETURN at the entrance to the full-size hall.'],
  'image_note':'28 interaction/state checks, six selected walking routes and 71 content checks pass. The rendered process saved its report and all five images, then crashed on shutdown. An independent headless run on the final source passes and exits 0. Headset comfort and visitor preference remain unverified.',
  'text_kind':'book — the QFEP question follows the action',
  'before':para('The entropy fan',True),
  'after':para('There are two kinds')+'\n\n'+para('QFEP asks'),
  'report':PREFIX+'/SUMMARY.md','report_label':'Findings, preservation decisions and runtime limits'},
 {'title':'Retain the comparisons; name what still needs work',
  'description':'All ten artifact families remain in the map; nine instantiate. The bifurcation walkway is still disabled in its registry and is recorded as a restoration task, not silently removed. The dissolving form’s malformed shader hash is repaired. Earlier supporting drafts are preserved as historical proposals. Phi is next: giving change a sign.',
  'report':PREFIX+'/QFEP_Lambda_Spectrum-headless-runtime.json','report_label':'Final source: controls, unchanged geometry and walking evidence'}
]
(PAGE/'qfeplaboratory.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Lambda comparison added, preserving all earlier laboratory cards.')
