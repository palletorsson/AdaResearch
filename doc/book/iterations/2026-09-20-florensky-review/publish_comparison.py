from pathlib import Path
import json
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
PAGE=HERE.parent/'2026-09-19-review-comparison';PREFIX=HERE.relative_to(ROOT).as_posix()
def para(start,old=False):
 p=(HERE/'before' if old else ROOT)/'commons/maps/Florensky_Paraconsistent/final.md'
 return next(s for s in p.read_text(encoding='utf-8').split('\n\n') if s.startswith(start))
p=PAGE/'foundationscrisis.json'
review=json.loads((HERE/'before'/p.relative_to(ROOT)).read_text(encoding='utf-8'))
review['status']='Florensky: two reports, one walkable threshold; all four works retained'
review['summary']=review['summary'].removesuffix(' Florensky and Crisis Synthesis remain.')+' Florensky now has an authored hall: independently controlled reports share a full-size threshold, followed by a sphere that keeps both readings. Both quantum visual toys remain as comparisons, with their limits made explicit. All eight declared halls are now authored; Crisis Synthesis remains the next review pass.'
review['items']=review['items'][:-1]+[
 {'title':'Florensky: the doorway becomes an encounter',
  'description':'The manuscript promised a walkable door, but the earlier artifact was under a metre high and this map was absent from the authored museum route. A full-size frame now holds two ghost leaves. OPEN, CLOSED and CLEAR buttons let the visitor change independent reports while the passage remains open. The original small illustration remains available outside this opt-in study.',
  'images':[PREFIX+'/florensky-both.png',PREFIX+'/florensky-open.png'],
  'captions':['Both reports are present. The closed leaf is visible; the passage is open.','Only the open report remains. The same frame and camera.'],
  'image_note':'Two states of the revised Godot museum encounter, not before/after software versions. Button signals are exercised through the existing interaction component. Tracked hands and headset reading remain untested.',
  'text_kind':'book — begin with a passage the reader can test',
  'before':para('The gate makes',True),
  'after':para('And your passage?'),
  'report':PREFIX+'/final.diff','report_label':'Exact Florensky manuscript diff'},
 {'title':'Keep the contradiction local; keep the claims precise',
  'description':'The console stores support for two opposed reports. Their coexistence supplies no support for an unrelated alarm claim. This is a finite information model, not a complete logical calculus. The sphere holds A AND not-A without the old observation-collapse or BOTH/NEITHER flicker. The chapter distinguishes paraconsistency, dialetheism and Florensky-inspired antinomy.',
  'images':[PREFIX+'/florensky-console.png',PREFIX+'/florensky-sphere.png'],
  'captions':['The report console. NO SUPPORT does not mean the alarm has been proved silent.','The colour changes; both readings remain. Plain words avoid a missing conjunction glyph in the baked font.'],
  'image_note':'Actual Godot captures. The console text is fixed to its casing so it no longer clips when viewed from an angle. The sphere remains a visual study; rendering both faces of a mesh is not a proof of a true contradiction.',
  'text_kind':'book — let the unresolved account lead to a bodily question',
  'before':para('Read the parameter carefully',True),
  'after':para('There is a desire here'),
  'report':PREFIX+'/SUMMARY.md','report_label':'Findings, decisions and evidence limits'},
 {'title':'Four works remain; resemblance becomes a question',
  'description':'The Schrödinger box and superposition display remain secondary comparisons at the back. Their captions and lookup descriptions now identify a random-outcome toy and an opacity animation. The display has no measurement operation. The chapter no longer calls quantum superposition a logical contradiction with an expiry. An automatic statue that blocked the exit approach is excluded in this hall.',
  'images':[PREFIX+'/florensky-comparisons.png'],
  'captions':['The retained quantum pair, on either side of the rear approach.'],
  'image_note':'Six selected collision-body walks and 24 behavior/geometry assertions pass in the actual museum probe; process exit 0. This does not certify continuous museum travel, tracked-hand operation or learner understanding. No live museum restart or bake replacement was performed.',
  'text_kind':'book — distinguish concepts without discarding their visual relation',
  'before':para('The cat is both',True),
  'after':para('Quantum superposition describes'),
  'report':PREFIX+'/content-checks.json','report_label':'Integration and preservation checks'},
 {'title':'Next: Crisis Synthesis',
  'description':'All eight Foundations Crisis halls are now authored. The synthesis still needs a focused review: bring these different responses together without treating incompleteness, construction, antinomy and quantum superposition as the same gap. Earlier supporting critical prose and the box’s missing tracked-hand opening remain named follow-ups.',
  'report':PREFIX+'/SUMMARY.md','report_label':'Current handoff and deferred work'}]
p.write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
