from pathlib import Path
import re

root = Path(__file__).resolve().parents[4] / 'commons/maps/Point_Trace'
def read(name): return (root/name).read_text(encoding='utf-8-sig')
def write(name, text): (root/name).write_text(text, encoding='utf-8')

s = read('final.md')
archive = []
for title in ['Move the place that draws', 'A line you did not hold', 'The pause leaves a line']:
    match = re.search(r'## '+re.escape(title)+r'\n.*?(?=\n## |\Z)', s, re.S)
    assert match, title
    archive.append(match.group())
    s = s[:match.start()]+s[match.end():]
write('trace-retired-encounters.md', '# Encounters removed from the Trace hall — 29 September 2026\n\nPreserved manuscript passages for the stick, head projection and automatic-writing desk. These artifacts are no longer placed in Point_Trace; their source scenes remain available for later use.\n\n'+'\n\n'.join(archive))
s = s.replace('The drawing points wait on their plinths. Take the first dot', 'Three coloured pens wait on their plinths. Take the red pen')
s = s.replace('release the dot.', 'release the pen.')
s = s.replace('The other dots give the line a coarser grain. From red through green to blue, their grids grow wider. The first dot adds no such grid.', 'The other pens give the line a coarser grain. From red through green to blue, their grids grow wider.')
s = s.replace('with the blue dot', 'with the blue pen').replace('positions a dot can keep', 'positions a pen can keep').replace('first dot', 'red pen').replace('drawing dot or stick', 'drawing pen')
s = s.replace("A dot or stick must retain at least two positions to send a copy onward. The whiteboard's image, the ball's path, the head trace and the desk's page stay in this hall.", "A drawing pen must retain at least two positions to send a copy onward. The whiteboard's image and the ball's path stay in this hall.")
s = s.replace('Watch during the pause.', 'The nib is the point being followed. Turn your wrist while keeping your hand almost still: the tip can travel while your grip barely moves.\n\nWatch during the pause.')
s = s.replace('beneath the whiteboard.', 'beneath the wall-mounted whiteboard.')
write('final.md', re.sub(r'\n{4,}', '\n\n\n', s))

s = read('intent.md')
a = s.index('The primary tokens'); b = s.index('The recording rules')
s = s[:a]+'''Three drawing pens share the draw_dot recorder and a 5 mm movement gate, with red, green and blue grids of 10, 40 and 80 mm. The plain nib is the sampled point; the grip aligns forward on pickup. The wall-mounted whiteboard keeps four surface-writing pens and an eraser. The ball ramp offers a movement continued by gravity. Telemetry and the science screen remain secondary.

The neutral dot, draw_stick, head_trace_projection and automatic_writing_desk have been removed from this hall at the author's request. Their code is retained; [retired encounter passages](trace-retired-encounters.md) preserve the former manuscript material.

'''+s[b:]
write('intent.md', s.replace('Release a dot or stick', 'Release a drawing pen'))

s = read('tutorial.md').replace('first dot', 'red pen').replace('The red pen adds no lattice. The red, green and blue dots use', 'The red, green and blue pens use').replace('four original dots and stick', 'three drawing pens').replace('Releasing a dot or stick', 'Releasing a drawing pen')
a = s.index('The stick uses'); b = s.index('At the whiteboard', a)
s = s[:a]+'''The pen uses the same recorder and threshold, but `WritingTip` is the observed point. Turning the barrel moves its nib even when the grip changes position very little. Its fixed XRTools grab point aligns the nib with the hand's forward direction on pickup.

'''+s[b:]
a = s.find('### A body writes')
if a >= 0: s = s[:a].rstrip()+'\n'
write('tutorial.md', s)

s = read('technical.md')
s = '> Current arrangement, 29 September 2026: three plain drawing pens (10/40/80 mm), their plinth readouts, a whiteboard mounted on the uninterrupted east wall, and the ball ramp. The neutral dot, stick, head projection and writing desk are no longer placed. The dated implementation notes below retain the removed studies\' history.\n\n'+s
s = s.replace('The four dot placements use no added lattice, 10 mm, 40 mm and 80 mm spacing.', 'The three drawing pens use 10 mm, 40 mm and 80 mm spacing.').replace('The panel anchors beside the trace and remains readable after release.', 'The three panels are fixed to their plinths and stay visible at zero points and after release.')
a = s.index('The four drawing dots and the stick occupy'); b = s.index('Released shelf tools', a)
s = s[:a]+'''Three drawing pens occupy plinths at source cells (3,5), (4,5) and (5,5). Each readout stays seated on its 0.90 m support. `#pen_style:simple` replaces the held sphere with a 22.5 cm pen; the recorder follows its nib. A fixed, hand-independent XRTools grab point aligns local -Z with the pickup's forward direction. Recording waits for the grip to arrive, so the pickup approach is not drawn. Other draw_dot placements keep their original sphere.

The whiteboard is at source cell (7,2), with its lower edge 0.95 m above the floor, facing west into the hall. Its two-metre width lies entirely on the solid wall before the side-bay opening. `#pen_style:simple` opts this board into plain barrels with forward-aligned grips; its four resolutions, eraser, shelf and return behavior are retained. The same pen body helper serves both drawing in space and drawing on the board.

'''+s[b:]
s = s.replace("Point_Trace now selects the automatic-writing desk's", 'The removed automatic-writing desk used the').replace('The original four dots and stick retain their configurations.', 'The three remaining drawing pens retain their recording resolutions.').replace('On release, the dot or stick calls', 'On release, the drawing pen calls')
write('technical.md', s)
for name in ['detours.md', 'encounter-reference.md']:
    s = read(name)
    write(name, '> Arrangement update — 29 September 2026: the desk, head projection, stick and neutral dot have been removed from Point_Trace. This document retains earlier comparisons; see [current intent](intent.md) and [preserved passages](trace-retired-encounters.md) for their status.\n\n'+s)
print('Aligned current text with the requested cleanup; retired passages preserved.')
