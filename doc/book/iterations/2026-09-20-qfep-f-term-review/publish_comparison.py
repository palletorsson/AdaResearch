from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];PAGE=HERE.parent/'2026-09-19-review-comparison';PREFIX=HERE.relative_to(ROOT).as_posix()
def para(start,old=False):
 p=(HERE/'before' if old else ROOT)/'commons/maps/QFEP_F_Term/final.md'
 return next(s for s in p.read_text(encoding='utf-8-sig').split('\n\n') if s.startswith(start))
review=json.loads((HERE/'before/doc/book/iterations/2026-09-19-review-comparison/qfeplaboratory.json').read_text(encoding='utf-8'))
review['status']='Introduction and F Term reviewed; E Term next'
review['summary']='The introduction keeps two arrangements with the same total. The restored F hall takes the comparison further: equal source uncertainty can meet very different predictor performance. Change the expectation while the bits remain fixed. Seven of eight declared laboratory halls are now authored; Sandbox remains to restore.'
review['items'][2]['title']='Preserve the introduction’s ecology'
review['items'][2]['description']='The workbench and formula face the entrance, with the blocked exit cleared. All eleven placed artifact families remain. Supporting notes distinguish implemented behaviour from retained proposals for memory projections and a responsive room. The existing large wave screen and synthesis stand still need later attention. The following F hall has now been restored, as shown below.'
review['items'] += [
 {'title':'F Term: same uncertainty, whose mistake?',
  'description':'A fixed seed gives 256 stored draws. Changing p re-thresholds them. EXPECT 0 marks each one as a miss. The entropy curve gives the same height at p=0.1 and p=0.9; this particular predictor does very differently. The main chapter’s proposed experiment now exists in the museum.',
  'images':[PREFIX+'/predict-low-zero.png',PREFIX+'/predict-high-zero.png'],
  'captions':['p=0.1, EXPECT 0: source H≈0.469; 27 observed misses in 256 cells.','p=0.9, EXPECT 0: source H≈0.469; 230 observed misses in 256 cells.'],
  'image_note':'Same camera, actual Godot museum. Amber underlines mark errors in the displayed sample. Expected percentages and observed counts are shown separately. H is a source quantity, not the measured encoding length of this grid.',
  'text_kind':'book — the proposed predictor becomes an encounter',
  'before':para('Imagine a predictor',True),'after':para('Press EXPECT 0.'),
  'report':PREFIX+'/final.diff','report_label':'Exact F Term manuscript diff'},
 {'title':'Improve the prediction without changing the world',
  'description':'Keep p at 0.9 and press EXPECT 1. The bit colours and positions stay fixed. Their amber marks change sides, and observed misses fall from 230 to 26. This is an explicit mismatch count for a simple predictor; the screen does not claim to measure variational free energy.',
  'images':[PREFIX+'/predict-high-zero.png',PREFIX+'/predict-high-one.png'],
  'captions':['EXPECT 0: 230 misses. The source and sample are held fixed for the next image.','EXPECT 1: 26 misses. The same bits meet a different expectation.'],
  'image_note':'26 runtime assertions and five selected walking routes pass. 70 content/preservation checks pass. This tests the control signals and calculations in the museum, not tracked hands or learner understanding.',
  'text_kind':'book — the critical question grows from the comparison',
  'before':para('The next useful addition',True),
  'after':para('Leave p near')+'\n\n'+para('The screen distinguishes')+'\n\n'+para('Here you can'),
  'report':PREFIX+'/QFEP_F_Term-runtime.json','report_label':'Controls, sample counts and route evidence'},
 {'title':'The missing hall returns, with its puzzles',
  'description':'F Term now stands between Introduction and E Term in both museum plans. All eight map works are retained. Two old puzzle names were preventing their scenes from loading; active names restore the same octahedron and tetrahedron works. The decorative dark sphere remains outside the chapter’s argument. E Term is next; Sandbox is the remaining route gap.',
  'report':PREFIX+'/SUMMARY.md','report_label':'Findings, decisions, full-hall image and limits'}
]
(PAGE/'qfeplaboratory.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print('Added F hall images and prose to the existing laboratory review.')
