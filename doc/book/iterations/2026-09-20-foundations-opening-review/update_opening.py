"""Bounded map and manuscript edits, replayed from this pass's frozen inputs."""
from pathlib import Path
import json, re
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def load(rel):
    return json.loads((HERE / 'before' / rel).read_text(encoding='utf-8'))
def save(rel, data):
    (ROOT / rel).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

rel = 'commons/maps/Euclid_Parallel/map_data.json'
d = load(rel)
d['map_info']['museum'].update(piers=False, plinths=False, artifact_placement='map', sculpture_clear_rects=[[3,4,7,12]])
grid = d['layers']['interactables']
for row in grid:
    for i in range(len(row)): row[i] = ' '
for x,z,token in [(5,7,'euclid_postulates_plaque:180:1.7:1#lesson_controls:on'),
                  (3,5,'science_screen:180:1.5#mode:grid'),
                  (3,9,'parallel_lines:0:1.2'),(7,9,'angle_sum_triangle:180:1.2')]:
    grid[z][x] = token
d['layers']['utilities'][1][5] = 's'
d['layers']['structure'][13][5] = '1'
save(rel,d)

rel = 'commons/maps/NonEuclidean_Spaces/map_data.json'
d=load(rel)
d['map_info']['museum'].update(artifact_placement='map', sculpture_clear_rects=[[9,1,12,3]])
d['layers']['interactables'][2][14]=' '
d['layers']['interactables'][2][11]='triangle_curvature_workbench:180:0#model:plane'
d['layers']['utilities'][1][8]='s'
save(rel,d)

rel='commons/maps/Euclid_Parallel/final.md'
s=(HERE/'before'/rel).read_text(encoding='utf-8')
s=s.replace('Click the plaque five times', 'Press NEXT on the plaque five times').replace('Five clicks, five postulates','Five presses, five postulates')
s=s.replace('That is the whole principle, and you can repeat it after one walk: this space is flat because the room says so, not because anyone measured it.', 'Before measuring anything, we have agreed to begin here. The room gives us flat coordinates; the plaque gives us sentences about what can be done in them. Walk between the columns. How much of that agreement already feels like the world?')
s=s.replace('Twenty-three centuries of checking failed, and the failure was read as a gap in the mathematicians.', 'For centuries, attempts to derive the fifth from the others failed. A rule can feel inevitable long before we have established that it follows.')
s=s.replace('repeated on every click','repeated on every press')
s=s.replace("So let's break the branch. `highlight_fifth` is an exported bool. Set it false and the fifth reads", "Now press GOLD. It switches `highlight_fifth` off: the fifth reads")
s=s.replace('So they run forever', 'So their supporting lines would extend')
old='The parallelism survives. All three share a basis, so they run forever without meeting, whatever the spacing. Equidistance is a consequence the fifth postulate guarantees, and it is the part the declaration asserted instead of building. The word carried what the numbers did not.'
new='The parallelism survives. All three share a basis: extend the segments along those directions and their supporting lines do not meet. Each pair keeps a constant perpendicular separation. That does not require the gap between the first and second to equal the gap between the second and third. Uneven spacing breaks an evenly spaced pattern; it does not break parallelism. We have to decide which regularity we were looking for.'
assert old in s;s=s.replace(old,new)
s=s.replace("Try it yourself: move Line3's offset out to 0.4 and count the gaps again.", "In the source, move Line3's offset out to 0.4 and count the gaps again.")
s=s.replace('## 5 — The setting you cannot reach from here','## 5 — Bowing a line is not enough')
s=s.replace('The shipped artifact has a real axis:', 'The shipped artifact has three named settings:')
a=s.index('Every placement here ships the bare token,');b=s.index('\n## 6',a)
s=s[:a]+'''The triangle here receives no `opening` setting, so its edges remain segments. In the source, selecting `elliptic` bows the edges outward; `hyperbolic` bows them inward. The corner labels change because the directions at the corners change.

But the drawing still lies in one flat plane. Curved sides can make a triangle-shaped outline whose corner sum is not 180°. That alone does not demonstrate spherical or hyperbolic geometry: we have changed the lines without specifying a different way of measuring space.

This is a useful limit to meet before the next room. A name can promise a world; a bend can make the promise look convincing. What else must change for a line to count as straight there?
''' +s[b:]
s=s.replace('The plaque offers `apply_grid_config`, two signals and three exports;', 'The plaque offers configuration and selection signals;')
a=s.index('We can see that absence from inside the code.');b=s.index('\nCount once more:',a)
s=s[:a]+'''The plaque now lets you cycle the sentences and remove their gold emphasis. The lines and triangle remain comparisons to look at; they do not yet offer a handhold for changing their geometry. A control for reading is not a control for bending space.

What stands here is a plaque, three lines, a triangle, a screen — and the building itself: an eleven by fifteen floor, a colonnade along the approach, a walkway between its repeated uprights. Walk that walkway and the assumption acquires the size of a body.

You can follow the path without agreeing that it is the only possible one. Carry that distinction through the exit. In the next room, the triangle gets a different host, and we can ask its corners again.
''' +s[b:]
s=s.replace(' at line 163','')
s=re.sub(r'(# \w+\.gd):\d+',r'\1',s)
(ROOT/rel).write_text(s,encoding='utf-8')
