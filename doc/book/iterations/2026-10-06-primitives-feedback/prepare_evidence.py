from pathlib import Path
import re, json

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
GRID=HERE.parent/'2026-10-06-trace-saved-to-grid'
PREVIOUS=HERE.parent/'2026-10-06-primitives-tutorial-lineage'

def put(p,s):p.write_text(s,encoding='utf-8',newline='\n')

# Keep the prose source of the saved-trace lesson in step with its canonical text.
old=(HERE/'before/commons/maps/Point_Line_Grid/tutorial.md').read_text(encoding='utf-8')
new=(ROOT/'commons/maps/Point_Line_Grid/tutorial.md').read_text(encoding='utf-8')
p=GRID/'build.py';source=p.read_text(encoding='utf-8')
old_intro=old.split('## Bring your drawing')[0]
new_intro=new.split('## Bring your drawing')[0]
assert old_intro in source
put(p,source.replace(old_intro,new_intro,1))

summaries={
'Point_Triangle_Context':'Bring the original saved Trace positions through Grid. Lines already connected positions; now choose three entries and store their ordered connection as a face recipe. Reuse PointBody handles, move a corner, reverse the front and collapse the face to test its guard. Preserve the archive. Carry positions and connectivity into the first enclosure.',
'Primitives_Ignorance':'Return to the authored position lists from Cube. Generate an octahedron list with a named function and a radius: positive and negative multiples of three axes. Render the supplied face recipe, call the function again and modify one independent result. Explain which choice belongs to the generating rule and which to a returned position. Carry parameters, return values and rule/output separation.',
'Primitives_Godot':'Return to PointBody to study resolution as a construction parameter. Compare rings-only and segments-only changes on independent spheres while radius, appearance and spherical collision stay fixed. Pickup and the fully printed held-time controller support the comparison: holding reduces resolution, release pauses, and reset restores. Stop at valid lower bounds. Carry controllable construction into Columns and later abilities.',
'Primitives_Profiles':'Return to Columns: a ring section carried through heights made a body. Borrow an O outline, including its hole, and carry that section through five parallel placements. Change sideways travel first; then compare width, depth and a C section. Preserve the supplied outline. Font extraction, triangulation and general curved-path frames stay supplied or deferred. Carry section and route as separate choices; visible hollow geometry does not supply collision.',
'Primitives_Portals':'Reuse the supplied circle sampler and LineSkin to measure a closed polygon. Sum neighbour lengths, including last to first, and compare with the finite TAU-based circumference reference. Increase sides until the metre tolerance is met or the sample budget is spent. Trigonometric derivation stays supplied. Test a tighter tolerance and an unattainable request; carry a stopping rule that names both error and cost.',
'Primitives_Melencolia':'Compose with learned CubeBody instances and the familiar PointBody. Change placements without changing construction data; reconstruct a second arrangement from script values. Scale and rotation wait for Transformation. Then attempt an independent arrangement: generate positions, retain a source and alter a copy, reuse a valid face and compare two sphere resolutions. Explain the construction choices and the arrangement; automated checks alone cannot establish that understanding.'}
p=PREVIOUS/'publish.py';source=p.read_text(encoding='utf-8')
for hall,summary in summaries.items():
    pattern=r"^"+re.escape(repr(hall))+r":'.*'([,}])$"
    source,n=re.subn(pattern,lambda m:repr(hall)+':'+repr(summary)+m[1],source,flags=re.M)
    assert n==1,hall
put(p,source)
put(HERE/'summaries.json',json.dumps(summaries,ensure_ascii=False,indent=2)+'\n')
print('Prose generators and lesson summaries synchronized; no executable lesson changes.')
