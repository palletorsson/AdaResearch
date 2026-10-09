"""Prepare exact before/after paragraphs for review, then apply only that recorded change set."""
from pathlib import Path
import difflib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
changes = {}

def original(name):
    return (HERE / f'before/commons/maps/{name}/final.md').read_text(encoding='utf-8')

def record(name, current):
    old = original(name)
    changes[name] = [[old, current]]

# The two older middle chapters require correction of their mode of evidence.
# Keep their concrete imagery and move the code behind an encounter.
catenary = (HERE / 'structure/Catenary.proposed.md').read_text(encoding='utf-8')
catenary = catenary.replace('Thomas Machon, Gareth P. Alexander, Raymond E. Goldstein and Adriana I. Pesci', 'Gareth P. Alexander and Thomas Machon')
start = catenary.index('```gdscript')
end = catenary.index('## The chain')
code = catenary[start:end]
catenary = catenary[:start] + catenary[end:]
at = catenary.index('<!-- @helicoid -->')
catenary = catenary[:at] + code + catenary[at:]
record('FormFinding_Catenary', catenary)

equilibrium = (HERE / 'structure/Equilibrium.proposed.md').read_text(encoding='utf-8')
start = equilibrium.index('```gdscript')
end = equilibrium.index('## Balanced by arithmetic')
code = equilibrium[start:end]
equilibrium = equilibrium[:start] + equilibrium[end:]
needle = 'For each disc, the source multiplies'
at = equilibrium.index(needle)
equilibrium = equilibrium[:at] + 'Find one arm with a disc hanging from each end, and compare their nameplates. Which has the larger mass? Which is nearer its pivot? Follow that relation up one branch before reading the calculation.\n\n' + code + equilibrium[at:]
equilibrium = equilibrium.replace('In the last hall, an apparently impossible table', 'In the next hall, an apparently impossible table')
equilibrium = equilibrium.replace("The screen ends up drawing a radar scope and counting the tower's children, having matched the triangle by name and then declined it. It has found something countable, but not the quantity we came to check.", 'The screen has no live load measurement from these objects. Its generic scanner can classify a tower by the word “fractal” and count children, but neither quantity establishes a balance.')
record('FormFinding_Equilibrium', equilibrium)

name = 'FormFinding_Relaxation'
old = original(name)
current = old
replacements = []
def paragraph(starts, new):
    global current
    found = [p for p in current.split('\n\n') if p.startswith(starts)]
    assert len(found) == 1, starts
    replacements.append([found[0], new])
    current = current.replace(found[0], new, 1)

paragraph('The chain in the last hall', 'The last hall let us draw a sag and evaluate a formula. Here a connected shape keeps a history of being changed. A frame budget allows only so many corrections: nudge the points, move to the next constraint, begin another pass. The cloth continues; the lattice and the vessel keep the pose reached after a chosen number of steps. Their stopping times were supplied with their rules.')
paragraph('There is no velocity', 'There is no separately stored velocity in that code. In the position update used by Loup Verlet in 1967, where a point is going is implied by where it just was: keep two positions, and their difference carries the motion.[^verlet] The temporary variable called `vel` holds that difference after damping. A point at rest, released, falls gravity times a step squared on its first update. At sixty steps a second, this bench\'s gravity gives less than a millimetre. The constraints then correct those proposed positions.')
paragraph('A magenta cloth', 'A magenta cloth of ten by eight points hanging from its two top corners. It receives sixty settling steps before you arrive, then continues in fixed one-sixtieth-second steps. Watch it before touching the controls. A changing sideways gust keeps disturbing it; motion here does not mean that a single settling process has failed to finish.')
paragraph('On the panel below it', 'The panel now offers PASSES, RESET and WIND. PASSES cycles through nudged, worked, pressed and held: one, four, eight and twelve constraint passes per step. Each choice restarts the same grid and its sixty preliminary steps. Switch WIND off to compare the corrections under gravity alone. Try one pass, then four. Does the cloth hold the same outline? RESET lets you return to the beginning without changing the chosen settings.')
paragraph('Two things about the number', 'Now read MEAN and WORST. They report spring-length errors relative to the lengths we asked the cloth to keep. A pass corrects each spring in turn, moving a free endpoint by half the current error scaled by stiffness; a correction can disturb a neighbouring spring. More passes give those relations another chance to agree.\n\nIn a matched desktop calculation after 420 total undriven steps—sixty preliminary steps and 360 more—one pass leaves a mean absolute error of about 1.409% and a worst spring error of 34.276%. Four passes reduce both, to about 0.359% and 8.936%. The average has become small while one local relation is still far from its request. Look between those two numbers. What would we overlook if the bench reported only the reassuring one?')
paragraph('The lattice version', 'The lattice version stands on a bench: forty-eight pink masses, a hundred and seventy-nine cyan wires, rocking eight degrees either side on an eighteen-second cycle. Compare its movement with the cloth. Are the relations between its points still changing, or is one retained form being turned?')
paragraph('It is not settling.', 'All eighty of its solver steps ran before the room finished loading. The rocking carries a frozen result: a grid with a random hundredth-of-a-metre disturbance per particle, rest lengths, gravity and a fixed time to act. Nobody placed each vertex of the final slump by hand. Somebody did choose the conditions from which it came.')
paragraph('And here is where it stops', 'And here is where it stops being a demonstration. A sphere of glass, fifteen rings by twenty-two segments, three hundred and thirty particles, of which the eighty-eight above the top eighth are pinned as if gripped by a blowpipe. Every free vertex is pushed out by a fifth as an initial expansion. Spring rest lengths are made from that expanded shape, then the whole thing is dropped into gravity for two hundred steps of the same solver the cloth is running.')
paragraph('A screen, and the thing', 'A screen, and the thing this room is about is the one thing no still image can hold. Every shape here is a duration: eighty steps, two hundred steps, a cloth still taking another step. A picture of a vessel contains none of the falling that made it, which is exactly what a fossil is and exactly what the vessel is.')
paragraph('It runs once, when the room', 'It runs once, when the room loads, and stops. The pose it happens to be in at that moment is the vessel. The glass does not contain you: it has no collider, so your body can walk through its wall.')
paragraph('Change the stiffness', 'In the source, changing stiffness, gravity or the number of settling steps makes other vessels possible; those controls are not on this exhibit. A different duration keeps a different moment of the process. The clock is part of the genome here. The form records the conditions that acted on it and how long they were allowed to act.')
paragraph('The vessel in this room was never designed', 'The vessel in this room was designed through conditions rather than by placing its final vertices. What you see is the frozen output of a simulation, kept because it was interesting, in the same way a fossil is a shape that some process left behind and then stopped.')
paragraph('Next: forms that are not settling', 'Next: a balance written into the relations between parts. How can we tell an encoded equilibrium from a form that has physically found one?')
current += '\n\n[^verlet]: Loup Verlet, [“Computer Experiments on Classical Fluids. I”](https://journals.aps.org/pr/abstract/10.1103/PhysRev.159.98) (1967). The bench adds distance-constraint corrections to its position update; those corrections and their pass budget are part of this implementation.\n'
start = current.index('```gdscript')
end = current.index('## Nudged, not solved')
code = current[start:end]
current = current[:start] + current[end:]
at = current.index('Now read MEAN and WORST.')
current = current[:at] + code + current[at:]
record(name, current)

name = 'FormFinding_Annealing'
current = original(name)
proposal = json.loads((HERE / 'search/manuscript-proposals.json').read_text(encoding='utf-8'))
for item in proposal['replacements']:
    assert current.count(item['old']) == 1
    new = item['new'].replace('The surface is the Rastrigin function: a smooth bowl', 'The surface is the Rastrigin function, the particular cruelty here: a smooth bowl')
    current = current.replace(item['old'], new, 1)
current = current.replace('It descends into whichever basin it was dropped above and stays there, which is the first hall\'s marble again on a surface with more than one bottom, and it is here as the thing that needs fixing.', 'Gravity and local downhill nudges draw it toward lower parts of the surface; no rule surveys all the basins for the deepest one. The first hall\'s question returns in another body: what can a local move discover, and what can it miss?')
current = current.replace('two wells in a five-metre open tank, its rim just over a metre above the floor.', 'two wells in a low, open tank. Approach the narrow well from its outside edge and look down into it.')
current = current.replace('On one side a narrow pit 0.95 metres deep holds a static cube, 0.28 metres across. On the other a broad basin, 0.30 metres deep, holds something soft', 'On one side a deep, narrow pit holds a static cube. On the other a broad, shallow basin holds something soft')
start = current.index('```gdscript')
end = current.index('## Getting out')
code = current[start:end]
current = current[:start] + current[end:]
at = current.index('The numbers behind the gauge')
current = current[:at] + code + current[at:]
record(name, current)

# Forge retains its argument; one stop-condition sentence follows the repaired encounter.
name = 'FormFinding_Forge'
current = original(name)
proposal = json.loads((HERE / 'search/forge-manuscript-proposal.json').read_text(encoding='utf-8'))
assert current.count(proposal['old']) == 1
record(name, current.replace(proposal['old'], proposal['new'], 1))

(HERE / 'text-changes.json').write_text(json.dumps(changes, indent=2, ensure_ascii=False), encoding='utf-8')
(HERE / 'proposed').mkdir(exist_ok=True)
(HERE / 'diffs').mkdir(exist_ok=True)
for name, pairs in changes.items():
    before, after = pairs[0]
    (HERE / 'proposed' / f'{name}.md').write_text(after, encoding='utf-8')
    patch = ''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='before/' + name + '/final.md', tofile=name + '/final.md'))
    (HERE / 'diffs' / f'{name}.diff').write_text(patch, encoding='utf-8')
    print(name, len(before.split()), '->', len(after.split()), 'words; prepared, not applied')
