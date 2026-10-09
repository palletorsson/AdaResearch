from pathlib import Path
import json

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
PAGE=HERE.parent/'2026-09-19-review-comparison'
PREFIX=HERE.relative_to(ROOT).as_posix()

def para(start, old=False):
    base=HERE/'before' if old else ROOT
    return next(p for p in (base/'commons/maps/QFEP_Introduction/final.md').read_text(encoding='utf-8-sig').split('\n\n') if p.startswith(start))

review={
 'status':'Introduction reviewed; F Term next',
 'summary':'The laboratory starts with an existing question worth keeping: can different arrangements give the same total? KEEP now makes their difference visible. The main manuscript is preserved and extended around that comparison. All eleven placed families remain. Two declared halls still need restoration to the museum route.',
 'items':[
  {'title':'The outline remembers what the total cannot',
   'description':'KEEP retains one arrangement while you move the four controls. A pale outline stays beside the current coloured shape, and the readout shows the retained total and difference. The diagram can disagree while the number agrees.',
   'images':[PREFIX+'/balance-kept-a.png',PREFIX+'/balance-current-b.png'],
   'captions':['Keep A: F 0.4, E 0.2, lambda 0.5, phi 0.5. Total 0.450.','Change to B: F 0.6, E 0.6. Total 0.450 again; A remains as a pale outline.'],
   'image_note':'Same camera, two states of the actual revised Godot museum. These are not before/after software versions. The test operates the existing KEEP button signal and slider components; tracked hands remain untested.',
   'text_kind':'book — preserve the question, strengthen its encounter',
   'before':para('Move one control',True),
   'after':para('Move one control')+'\n\n'+para('Now try changing'),
   'report':PREFIX+'/final.diff','report_label':'Exact introduction manuscript diff'},
  {'title':'A handle can move without changing this total',
   'description':'The chapter’s existing zero-weight experiment stays. With lambda at zero, the E vertex moves but its contribution to the total is zero. The saved shape makes the movement visible. The controls also state their domains; the colour names a nearest authored example rather than a detected physical phase.',
   'images':[PREFIX+'/balance-zero-low.png',PREFIX+'/balance-zero-high.png'],
   'captions':['Lambda zero, E 0.1. Keep this arrangement: total 0.550.','Lambda still zero, E 0.9. Another shape; total still 0.550.'],
   'image_note':'The unchanged total is a property of this expression. It does not establish that entropy or change has disappeared from the surrounding room.',
   'text_kind':'book — names and ranges belong to particular instruments',
   'before':'',
   'after':para('All four rails')+'\n\n'+para('The display says'),
   'report':PREFIX+'/QFEP_Introduction-runtime.json','report_label':'21 control checks and five walking routes'},
  {'title':'Preserve the hall’s ecology; restore the next encounter',
   'description':'The workbench and formula face the entrance, with the blocked exit cleared. All eleven placed artifact families remain. Supporting notes distinguish implemented behaviour from retained proposals for memory projections and a responsive room. The existing large wave screen and synthesis stand still need later attention. Next is restoring QFEP_F_Term in its declared position; QFEP_Sandbox is the other missing hall.',
   'report':PREFIX+'/SUMMARY.md','report_label':'Findings, decisions, full-hall image and limits'}
 ]}
# Select the exact old phase paragraph, without relying on its full wording.
old=(HERE/'before/commons/maps/QFEP_Introduction/final.md').read_text(encoding='utf-8-sig')
review['items'][1]['before']=next(p for p in old.split('\n\n') if 'phase' in p and 'reference' in p)
(PAGE/'qfeplaboratory.json').write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=PAGE/'build.py'
s=p.read_text(encoding='utf-8')
if "('qfeplaboratory'," not in s:
    s=s.replace("('foundationscrisis', 'What did the measurement depend on?')]", "('foundationscrisis', 'What did the measurement depend on?'), ('qfeplaboratory', 'What does one number leave out?')]")
    s=s.replace("'graphtheory', 'foundationscrisis']", "'graphtheory', 'foundationscrisis', 'qfeplaboratory']")
p.write_text(s,encoding='utf-8')
print('Published laboratory comparison data and added chapter to the page builder.')
