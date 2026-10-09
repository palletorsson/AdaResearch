"""Keep the existing museum visible and bind the additional hall check."""
import shutil
import json
from prepare import HERE, ROOT, sha, save, write

run=ROOT/'ada_run/encounter_pilot/Point_Line_Grid_learner_grid_20261006'
report=json.loads((run/'report.json').read_text())
assert report['passed'] and len(report['checks'])==12
for name in ['museum-pitch-025.png','museum-pitch-050.png','museum-workplace.png']:
    shutil.copyfile(run/name,HERE/name)
shutil.copyfile(run/'stdout.log',HERE/'museum-engine.log')
report['source_pins']={p.relative_to(ROOT).as_posix():sha(p) for p in [HERE/'grid.gd',HERE/'point_body.gd',HERE/'line_skin.gd',HERE/'museum-check.gd',HERE/'run_museum.py',ROOT/'commons/maps/Point_Line_Grid/map_data.json',ROOT/'commons/scenes/endless_museum.gd',ROOT/'tools/probes/transformation_encounters.gd',ROOT/'tools/run_encounter_probe.py']}
report['capture_pins']={name:sha(HERE/name) for name in ['museum-pitch-025.png','museum-pitch-050.png','museum-workplace.png']}
report['host_setup']='PointStudy is a direct child of the generated Point_Line_Grid hall, local position (8.5,0,8.5), unit scale. The probe supplies only the host, controller input and inspection camera; the printed grid.gd creates all lesson objects.'
report['diagnostics']='The full project log includes an unresolved UID and legacy material warnings. No lesson script error occurred. The 12 passing assertions are a bounded hall-integration check, not a clean full-project health verdict.'
save(HERE/'museum-report.json',report)

path=HERE/'index.html'
html=path.read_text(encoding='utf-8')
html=html.replace('Keep what the hand recorded. Change the rule that gives those positions a place on the grid.','Work in the Grid hall of the Endless Museum. Keep what the hand recorded; change the rule that places its trace.')
insertion='''<section id="workplace"><h2>Our workplace is the museum.</h2><figure><img src="museum-workplace.png" alt="The student point and its two traces beside the glass field in the real Endless Museum Grid hall"><figcaption>Current Grid hall, with the exact learner script placed temporarily beside its existing exhibits. The room, materials, light and neighbouring works belong to the museum.</figcaption></figure><p>Begin with the museum’s ruled field and snapping sphere. Your own PointBody continues in PointStudy on the clear floor beside the glass field. The checked placement is a child of the Grid hall at local <code>(8.5, 0, 8.5)</code>, scale <code>(1, 1, 1)</code>. All three lesson scripts are unchanged from the native test.</p><p>The placement is part of this checked tutorial run, not a permanent addition to the museum map. <a href="museum-check.gd">Placement and interaction check</a> · <a href="museum-report.json">12 passing hall checks</a>.</p></section>'''
html=html.replace('<section id="comparison">',insertion+'<section id="comparison">')
html=html.replace('src="pitch-025.png"','src="museum-pitch-025.png"').replace('src="pitch-050.png"','src="museum-pitch-050.png"')
html=html.replace('Actual renders of the unchanged tested learner script, driven by a fixed example gesture. The camera, lights and floor grid are a capture fixture. They are not a new museum installation. The floor ruling remains 0.25 metres in both views; the second derivation uses every other interval. <a href="capture.gd">Capture source</a>.','Actual renders inside the museum. A synthetic controller moves the sphere through the same fixed gesture; the real XRTools pickup action switches pitch. The original drawing remains. The museum supplies the surroundings; an inspection camera records the view. These captures do not claim a physical headset test.')
html=html.replace('<p class="proof">71 native Godot assertions pass. Three deliberate faults are detected by the same normal checks.</p>','<p class="proof">71 isolated native assertions pass, including three detected fault controls. An additional 12 checks pass with the same script inside the actual Grid hall.</p>')
write(path,html)

p=ROOT/'doc/book/course/storyboards/CONTEXT.md'
text=p.read_text(encoding='utf-8-sig')
entry='6 October author reminder — WE ARE WORKING INSIDE ENDLESS MUSEUM. The hall is the working environment, not just a reference image. Existing artifacts supply encounters; the learner develops owned code beside them. Isolated test fixtures are evidence, never a replacement course destination. Grid now has 12 additional real-hall checks and current in-museum screenshots; PointStudy is temporarily hosted at hall-local (8.5,0,8.5). Report this separately from 71 isolated assertions. No permanent map edit or headset verification.\n\n'
if entry not in text:text=text.replace('## Keep in memory\n\n','## Keep in memory\n\n'+entry)
write(p,text)
p=ROOT/'doc/book/course/COURSE_WORLD.md'
text=p.read_text(encoding='utf-8-sig')
entry='''## Current Grid continuation — 6 October

The author reaffirmed: we are working **inside the existing museum**. The current full-code Grid lesson continues the 5 October PointBody/Trace program. Its 71 isolated assertions are supplemented by 12 checks with the same three learner scripts placed inside the real Grid hall, beside the glass field. The museum supplies its actual room, materials, lighting and surrounding artifacts. The learner owns the point, recorder and derivation. [Current workplace and evidence](../iterations/2026-10-06-trace-to-grid/index.html#workplace).

This is a temporary tutorial placement, not a permanent map addition. It records and compares one gesture in a running PointStudy; it does not reuse the older pilot's file transport. Earlier examples listed below remain historical snapshots of the evolving course.

'''
if entry not in text:text=text.replace('## Day Zero establishes the environment\n',entry+'## Day Zero establishes the environment\n')
write(p,text)
print('Published real-museum images, 12 hall checks and durable author correction.')
