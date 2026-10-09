from pathlib import Path
import json
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]
PAGE=HERE.parent/'2026-09-19-review-comparison'; PREFIX=HERE.relative_to(ROOT).as_posix()
def para(start,old=False):
 p=(HERE/'before' if old else ROOT)/'commons/maps/Escher_Impossible/final.md'
 return next(s for s in p.read_text(encoding='utf-8').split('\n\n') if s.startswith(start))
p=PAGE/'foundationscrisis.json'
review=json.loads((HERE/'before'/p.relative_to(ROOT)).read_text(encoding='utf-8'))
review['status']='Opening pair and Godel preserved; Russell strengthened; Escher becomes an inspectable study'
review['summary']+=' Escher now lets the visitor follow a marker, measure tread heights and compare five constructions. Its triangle aligns separated endpoints to a marked camera position. All four artifact families remain; the manuscript distinguishes a persuasive image from a spatial connection and a geometric measurement from a theorem.'
review['items']=review['items'][:-1]+[
 {'title':'Escher: where does the rise return?',
  'description':'Physical STEP, BACK, FORM and RESET controls expose the existing staircase constructions. The light follows the selected tread. A side readout measures the displayed tread centres. The closed circuit gains and loses the same height; the open run stops at its cut end. The visitor stays on the floor.',
  'images':[PREFIX+'/escher-return.png',PREFIX+'/escher-gap.png'],
  'captions':['RETURN SIDE, after a circuit: 0.88 m up and 0.88 m down.','OPEN RUN: the marker stops at the cut end, 0.79 m above its start.'],
  'image_note':'Current Godot museum captures from the same camera at 1.70 m. Two settings of one artifact, not before/after software versions. The visible light, readout and physical button signals were checked. Tracked-hand use and headset legibility remain unverified.',
  'text_kind':'book — an encounter replaces an unsupported promise',
  'before':para('Check any corner',True),
  'after':para('Follow it around'),
  'report':PREFIX+'/final.diff','report_label':'Exact Escher manuscript diff'},
 {'title':'The body can leave the assigned viewpoint',
  'description':'The triangle had a depth gap, but its marked viewpoint did not align the ends and its detector had no active-camera caller. The back endpoint now lies on the correct viewing ray; optional camera tracking updates the alignment feedback. The chapter calls this a perspective study and does not claim it reproduces the complete Penrose tribar.',
  'images':[PREFIX+'/penrose-aligned.png',PREFIX+'/penrose-aside.png'],
  'captions':['At the marked eye position: top endpoint centres project together.','Camera shifted 0.55 m sideways: the separation becomes visible.'],
  'image_note':'Current single-camera Godot captures of the same unmoved artifact. Endpoint projection was independently checked with Camera3D.unproject_position. Beam thickness is still visible. These photographs do not establish the same illusion for two eyes in a headset.',
  'text_kind':'book — a connection in the image',
  'before':para('Which reframes',True),
  'after':para('The mark offers'),
  'report':PREFIX+'/model-checks.json','report_label':'Controls, visible marker, height and projection checks'},
 {'title':'Keep the comparison; make the claim testable',
  'description':'The pipe stays beside the first experiment and the trident remains at the rear. Two rods becoming three tines does not alone establish impossibility: the reader is invited to follow an edge. The book, wall speech, registry descriptions and current encounter hashes agree. Other Foundations manuscripts and maps are byte-preserved.',
  'images':[PREFIX+'/escher-approach.png',PREFIX+'/escher-drop.png'],
  'captions':['The entrance study and pipe, with the other comparisons beyond.','CLOSING DROP: the extra dark tread marks a continued rise; the marker returns to the actual first tread.'],
  'image_note':'Current Godot museum views. Five selected collision-body approaches pass. They do not constitute a continuous route test or learner verification. No live museum restart or bake replacement was performed.',
  'text_kind':'book — recognition and inspection',
  'before':para('Consistency is not compositional.',True),
  'after':para('Recognition is generous.'),
  'report':PREFIX+'/SUMMARY.md','report_label':'Decisions, preserved work and remaining limits'},
 {'title':'Next: what counts as a construction?',
  'description':'Brouwer is next. Inspect its constructive-evidence encounter before changing the text. Florensky still lacks an authored museum hall; Crisis Synthesis follows. Seven of eight declared halls are authored, so the sequence is not marked complete.',
  'report':PREFIX+'/content-checks.json','report_label':'Focused integration and preservation checks'}]
p.write_text(json.dumps(review,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
