from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3];PAGE=HERE.parent/'2026-09-19-review-comparison';PREFIX=HERE.relative_to(ROOT).as_posix()
def para(start,old=False):
 p=(HERE/'before' if old else ROOT)/'commons/maps/Russell_Paradox/final.md'
 return next(s for s in p.read_text(encoding='utf-8').split('\n\n') if s.startswith(start))
p=PAGE/'foundationscrisis.json'
# Extend the frozen opening-pair record; rerunning never duplicates entries.
review=json.loads((HERE/'before'/p.relative_to(ROOT)).read_text(encoding='utf-8'))
review['status']='Euclid and Non-Euclidean opening retained; Russell strengthened; Godel manuscript preserved'
review['summary']+=' Russell now asks for an answer before explaining the contradiction. An existing workbench returns with physical IN / OUT buttons and a finite separation comparison. Godel keeps its mature manuscript; its two principal exhibits now identify their animations as illustrations.'
review['items']=review['items'][:-1]+[
 {'title':'IN. OUT. It looks like enough choice.',
  'description':'A previously existing workbench joins the six earlier artifact families. Test both membership answers, then change the domain. The lamp accepts OUT in the finite restricted example. The hotel becomes primary again because it supplies a surprise with a constructive answer. A reserved centre passage keeps decorative plinths out of the walk.',
  'images':[PREFIX+'/russell-unrestricted.png',PREFIX+'/russell-restricted.png'],
  'captions':['Unrestricted rule: IN requires OUT. Trying OUT also contradicts the rule.','Within an existing set U: OUT agrees. The four numbered dots are the finite ordinal example.'],
  'image_note':'Two states of the current workbench inside the actual museum, with the same camera at 1.65 m. These are not before/after software versions. The test walker is hidden for photographs; museum artifacts remain visible. Physical button signals and selected collision-body walks pass; tracked hands and headset reading remain untested.',
  'text_kind':'book — Russell opening',
  'before':para('Four objects',True),
  'after':para('A rule stands'),
  'report':PREFIX+'/final.diff','report_label':'Exact Russell manuscript diff; Godel unchanged'},
 {'title':'Keep the objects. Ask what each one can establish.',
  'description':'The box remains an image of regress; the workbench supplies the two-case contradiction. The liar introduces truth rather than membership. Nested braces do not prove self-membership. The hotel supplies a valid reassignment. The revised text keeps these encounters and removes the claim that they are all the same contradiction.',
  'images':[PREFIX+'/russell-approach.png'],
  'captions':['The membership bench faces the entrance, with the earlier artifacts around and beyond it.'],
  'image_note':'Current Godot museum capture. A side approach and central passage were checked separately with the museum collision body. This is not a complete continuous headset route test.',
  'text_kind':'book — Russell comparison',
  'before':para('That is the difference',True),
  'after':para('Keep this surprise'),
  'report':PREFIX+'/SUMMARY.md','report_label':'Decisions, evidence and remaining work'},
 {'title':'Godel: let the existing text set the standard',
  'description':'The short chapter already distinguishes a failed search, a broken search and a theorem about proof. Its text and map are byte-preserved. The sentence machine now says ILLUSTRATION — NOT PROOF SEARCH, and the sorter states that its areas and tokens do not count truths. Source and registry descriptions state the mathematical assumptions. No proof-search implementation is claimed.',
  'images':[PREFIX+'/godel-illustration.png',PREFIX+'/godel-sorter.png'],
  'captions':['The sentence machine, with its new illustration label.','The sorter: an illustrated relation, with destinations chosen in advance.'],
  'image_note':'Current Godot museum captures. Both exhibits instantiate; these views do not certify access to every exhibit or continuous navigation of Godel’s hall. Its existing placement over gaps remains a later spatial review item.',
  'report':PREFIX+'/content-checks.json','report_label':'Preservation and integration checks'},
 {'title':'Next: a convincing connection that will not close',
  'description':'Escher is next, beginning with the existing climb action and what the visitor can actually traverse. Brouwer, the missing authored Florensky hall and Crisis Synthesis follow. Seven of eight declared halls remain authored; this pass does not declare the sequence complete.',
  'report':PREFIX+'/model-checks.json','report_label':'Membership tests and physical control signal checks'}]
p.write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
