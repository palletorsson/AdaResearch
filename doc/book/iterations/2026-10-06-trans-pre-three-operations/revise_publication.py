from write_lesson import HERE, ROOT, put
import re

p = HERE/'publish.py'
s = p.read_text(encoding='utf-8')
summary = 'Use one MeshInstance3D displaying a BoxMesh. Translate, rotate and scale the whole cube; keep its mesh fixed. Add elapsed time for a simple upward journey. Then attach an Area3D and a box collision shape, connect body_entered, recognise the supplied museum player and collect the cube by walking into it. No face lists, edge renderer or companion geometry scripts. Carry the same simple object from visual transformation to overlap detection and a signal-driven response.'
s = re.sub(r'^SUMMARY = .*$', lambda m: 'SUMMARY = '+repr(summary), s, flags=re.M)
s = re.sub(r'^SUBJECTS = .*$', "SUBJECTS = ['Translation', 'Rotation', 'Scale', 'Timed movement', 'Overlap detection', 'Signals', 'Collect on contact']", s, flags=re.M)
replacements = {
    'All three returning CubeBody support files are printed unchanged. The lesson creates its visible cube; installed pickup/collision behaviour remains supplied.': 'One complete script creates a BoxMesh cube and its Area3D sensor. The museum supplies player bodies, groups and collision layers; the lesson implements collection on overlap.',
    '38 native checks; eight value-edited variants; three deliberate faults rejected.': '46 native checks; eight value-edited variants; five deliberate faults rejected.',
    'Complete printed example and unchanged returning helpers; 38 native checks and three fault controls.': 'One-file BoxMesh example, including collection; 46 native checks and five fault controls.',
    'BRING CubeBody. CHANGE position / Y turn / uniform size, separately. KEEP construction. ORIGIN bottom-centre. THEN clock one upward journey; same endpoint, new duration. TEST corners + distances + time. CARRY three transforms. GIVEN museum + installed pickups.': 'OBJECT one BoxMesh instance. TEACH translate → rotate → scale → collect by walking in. ADD Area3D + BoxShape3D + body_entered; filter player. KEEP geometry simple. GIVEN museum player/layers/groups. TEST transforms + real overlaps.',
    'Author-approved transformation-first plan; first tutorial rewritten with complete CubeBody study, unchanged inherited helpers, native checks and deliberate faults.': 'Author correction: use one whole BoxMesh, then teach walking-over pickup through overlap detection. One complete script, native checks and deliberate faults.',
    '38 native checks, eight variants and three deliberate faults.': '46 native checks, eight variants and five deliberate faults.',
    'CubeBody construction, three transforms, one finite timed translation.': 'One BoxMesh cube, three transforms, timed movement, Area3D overlap collection.',
    'Unchanged CubeBody construction used in Cube and Melencolia.': 'The familiar cube as one BoxMesh instance.',
    'Three static changes, then one timed translation.': 'Translate, rotate, scale; then detect the player and collect.',
    'Museum host; printed returning geometry files.': 'Museum player, camera and light; one complete script.',
    '38 native checks, eight variants, three deliberate faults.': '46 native checks, eight variants, five deliberate faults.',
    'Continuous turning, pulsing, crossing collision and rider transport.': 'Score, sound, pickup effects and physical rider transport.',
    'CubeBody and its geometry helpers are byte-identical to their printed Cube versions. Class reuse is not a claim that one live node persists across halls.': 'The author chose Godot BoxMesh for this study. Its geometry is supplied by the engine; no custom face helpers are required. The code adds its own overlap sensor.',
    "dependencies = {p.relative_to(ROOT).as_posix(): sha(p) for p in helpers}": "dependencies = {(HERE/'native-project.godot').relative_to(ROOT).as_posix(): sha(HERE/'native-project.godot')}",
    "before = (HERE/'before/commons/maps/Trans_Pre/tutorial.md').read_text(encoding='utf-8')": "before = (HERE/'before-boxmesh/tutorial.md').read_text(encoding='utf-8')",
    'Download all four code files': 'Download the one script',
    'Keep the cube built in Primitives; change its position, orientation and size separately. Then give one translation a duration.': 'Use one BoxMesh cube: translate it, rotate it, scale it, then collect it by walking into it.',
    '38 native Godot checks pass. Three deliberate faults are rejected.': '46 native Godot checks pass. Five deliberate faults are rejected.',
    'Eight code variants, unchanged returning geometry files, one explicit museum study host.': 'One complete script, eight variants and an explicit museum host. No face or edge helpers.',
    'Bottom-centre origin stays fixed.': 'Its centre stays fixed.',
    'The earlier tutorial began with stages, a clock and cumulative animation. The revised lesson begins with the three transformations and what each preserves. The 22-line main is complete; CubeBody and its two support files return unchanged and are printed in full. Scaling is explicitly anchored at the bottom centre.': 'The author asked for the cube as a whole mesh. The revised example uses BoxMesh and removes the three geometry helpers and their listings. The lesson teaches position, rotation and scale on the instance, then adds an Area3D to collect it when the player enters.',
    'Continuous turning and pulsing remain visible in the museum and become subjects in later halls.': 'Walking into the detection box emits body_entered; a player check leads to queue_free. The player and its layers/groups come from the museum.',
    'complete four-file version': 'complete single-file version',
    'Separate wrong-axis, frame-clock and accumulating-position mutations must fail those same checks.': 'Real physics bodies test collection, ignored props, the XR player layer and detection at a changed position. Wrong-axis, frame-clock, accumulating-position, disconnected-signal and missing-player-filter mutations fail the ordinary checks.',
    '>38 assertions<': '>46 assertions<',
}
for before, after in replacements.items():
    assert before in s, before
    s = s.replace(before, after)
# Show collection in the same review, using the existing museum player.
needle = "    body += '</div><h2>What changed in the writing"
assert needle in s
s = s.replace(needle, "    body += '</div><h2>Walk into it</h2><div class=\"gallery\"><figure><img src=\"museum/pickup-before.png\" alt=\"Cube before the museum walker enters\"><figcaption>Player outside: cube remains.</figcaption></figure><figure><img src=\"museum/pickup-after.png\" alt=\"Same view after the player collects the cube\"><figcaption>Player overlaps: the learner cube is removed.</figcaption></figure></div><h2>What changed in the writing")
put(p, s)
