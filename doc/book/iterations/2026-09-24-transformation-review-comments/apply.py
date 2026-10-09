from pathlib import Path
import hashlib,json,shutil,sys
sys.stdout.reconfigure(encoding='utf-8')
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-transformation-review-comments';changed=[]
def edit(rel,pairs):
 p=root/rel;s=p.read_text(encoding='utf-8-sig')
 for a,b in pairs:
  assert s.count(a)==1,(rel,a,s.count(a))
  s=s.replace(a,b)
 p.write_text(s,encoding='utf-8');changed.append(rel)
edit('commons/maps/Trans_Pre/final.md',[(
'The small markers beside the examples help you recognise each operation.',
'Beside each moving example, a smaller marker isolates the operation just added: one moves up and down, one turns in place, one grows and shrinks.')])
edit('commons/maps/Trans_Introduction/final.md',[(
'This cube changes from half a metre to three metres on each side, about a fixed centre. The visible mesh begins as a one-metre cube. The script gives all three dimensions the same factor:',
'The cube grows from half a metre to three metres on each side, about a fixed centre. Its mesh is built one metre on a side; the script multiplies all three dimensions by the same factor, from a half to three:'),(
'The readout measures the seam. It cannot settle what your body can do with it.',
'The readout measures the seam. It cannot settle what your body can do with it.\n\n![The aligned plank overlaps the landing at BANK +0.00 m.](/book-review/doc/book/figures/Trans_Introduction/bank-at-crossing.png)\n\n![A gap opens beyond the same plank at BANK +1.00 m.](/book-review/doc/book/figures/Trans_Introduction/bank-gap.png)\n\n*The same crossing at two bank settings: thirty centimetres of overlap, then seventy centimetres of gap. The plank holds the same quarter-turn in both views. The camera has not moved.*'),(
'For now, take the experience of crossing into the next hall. Trans_Translation will give displacement more work to do.',
'For now, take the experience of crossing into the next hall, where displacement has more work to do.')])
edit('commons/maps/Trans_Translation/final.md',[(
'move it outwards.','move it sideways.'),('travel up and out.','travel up and across.'),('In Point_Trace,','In the trace hall,'),(
'The existing door mechanisms leave different traces for different permitted paths.','Two door mechanisms leave different traces for different permitted paths.'),(
'The same door studies used in the museum: a guided bend, a direct diagonal, and a curved route to the same relative endpoint. Each panel shows a separate supplied gesture recorded by the live artifact.',
'A guided bend, a direct diagonal, and a curved route to the same relative endpoint. Each panel records a separate gesture at the handle.'),(
'In Trans_Rotation, the turn itself will become the question.','In the next hall, the turn itself will become the question.')])
edit('commons/maps/Trans_Rotation/final.md',[(
'Watch the cyan bodies begin: each is 0.44 metres wide. Pink bodies follow from the same places, now 1.20 metres wide.',
'At the near end of the bands, a small stand occupies the still central aisle. Watch the cyan bodies set off along all four bands at once: each is 0.44 metres wide. Pink bodies follow from the same places, now 1.20 metres wide. The study repeats on its own; REPLAY on the stand begins it again.'),(
'Two paused moments of the museum study, seen from one place.','Two paused moments, seen from one place.'),(
'The rotating cube inside its cylindrical boundary and the triangular face inside its conical boundary, captured from the museum study.',
'The rotating cube inside its cylindrical boundary and the triangular face inside its conical boundary.'),(
'<!-- @carousel_cake -->\n\nStep out', '<!-- @carousel_cake -->\n\n## A rate instead of an angle\n\nStep out')])
edit('commons/maps/Trans_Scale/final.md',[(
'in the actual museum, viewed','viewed')])
edit('commons/maps/Trans_Body/final.md',[(
'left by the museum body, photographed','left by a body, photographed'),(
'These elevated museum views show the missing cells;','These elevated views show the missing cells;'),(
'The caption asks you to step clear;', 'The floor caption beyond the last row asks you to step clear;')])
edit('commons/maps/Trans_Pit/final.md',[(
'A fraction marks its place along the journey: zero at the start, one at the far end. The script places the block between those endpoints:',
'The script keeps a fraction, `_t`, for its place along the journey: zero at the start, one at the far end. It places the block between those endpoints:'),(
'The eastern passage lets you walk around.', 'Open floor along the side wall lets you walk around the lanes.'),(
'The same museum door closed,','The same door closed,'),(
' You can return from the other side and open it again. No pickup count decides whether you may enter.',
' You can return from the other side and open it again.')])
# Remove stale fire utilities, preserving every other cell and placement.
rel='commons/maps/Trans_Pit/map_data.json';p=root/rel;s=p.read_text(encoding='utf-8-sig');d=json.loads(s);removed=[]
for z,row in enumerate(d['layers']['utilities']):
 for x,v in enumerate(row):
  if v=='h:fire':removed.append([x,z])
assert len(removed)==28
s=s.replace('"h:fire"','" "')
s=s.replace('Source fire tokens are disarmed by the current embedded museum; text describes observed obstacles, not a forced death trial.', 'Legacy fire utilities removed 2026-09-24: all 28 cells cleared, including the middle route and observation floor beside the rotating slabs. Timed bodies remain; this is an optional observation and crossing study.')
p.write_text(s,encoding='utf-8');changed.append(rel)
(out/'removed-fire-cells.json').write_text(json.dumps(removed,indent=2)+'\n',encoding='utf-8')
edit('commons/maps/Trans_Pit/intent.md',[(
'Legacy fire tokens are currently disarmed by the embedded museum, so no lethal consequence is claimed.',
'Legacy fire utilities were removed on 24 September 2026, including those on the observation floor. The timed bodies remain available to approach or watch from beside them.'),(
', or the current museum\'s fire/death policy.', '.')])
edit('commons/maps/Trans_Pit/summary.md',[(
'The current embedded museum disarms the legacy fire tokens.', 'The legacy fire utilities have been removed from the observation floor and routes.')])
edit('commons/maps/Trans_Pit/technical.md',[(
'Current museum configuration, 23 September 2026.', 'Current museum configuration, 24 September 2026.'),(
'Its legacy fire tokens are disarmed by the embedded museum.',
'All 28 legacy fire utilities were removed on 24 September 2026. Disarming their Area3D detection had left their flame visuals in place, including across the middle route and the floor beside the rotation slabs.')])
edit('commons/maps/Trans_Pit/tutorial.md',[(
'The map retains legacy fire utility tokens, which the current embedded museum disarms.',
'The legacy fire utilities have been removed, so their flames no longer occupy the observation floor.')])
figures=[]
for name in ['bank-at-crossing.png','bank-gap.png']:
 src=root/'doc/book/iterations/2026-09-23-transformation-encounters'/name;dst=root/'doc/book/figures/Trans_Introduction'/name
 dst.parent.mkdir(parents=True,exist_ok=True);assert not dst.exists();shutil.copy2(src,dst)
 figures.append({'map':'Trans_Introduction','source':src.relative_to(root).as_posix(),'canonical':dst.relative_to(root).as_posix(),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'kind':'Byte-identical native Godot capture; same camera and aligned plank pose in both views.'})
(out/'figure-provenance.json').write_text(json.dumps(figures,indent=2)+'\n',encoding='utf-8')
(out/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
print('Updated',len(changed),'files; removed',len(removed),'legacy fire utilities; copied two native figures unchanged.')
