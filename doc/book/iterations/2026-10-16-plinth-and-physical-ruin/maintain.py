from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent

# Preserve the inherited museum wall's staged-model regression. The public ruin
# probe now tests the actual installed physical scene, shared by this review.
probe=ROOT/'commons/testing/probe_entropy_ruin.gd'
old=probe.read_text(encoding='utf8')
legacy=ROOT/'commons/testing/probe_entropy_weathering_base.gd'
assert not legacy.exists()
legacy.write_text(old.replace('load("res://commons/artifacts/randomness_space/entropy_ruin.tscn").instantiate()', 'load("res://commons/artifacts/randomness_space/entropy_ruin.gd").new()').replace('ENTROPY RUIN:', 'WEATHERING BASE:').replace('res://doc/space/entropy-ruin-2026-09-16/unit.json','res://doc/book/iterations/2026-10-16-plinth-and-physical-ruin/legacy-verification.json'),encoding='utf8')
full=(HERE/'verify.gd').read_text(encoding='utf8')
ruin=full.split('\tvar ruin=')[1].split('\n\tfinish()')[0]
prefix='''extends SceneTree
var checks: Array=[]
var failures: Array=[]
var observations: Dictionary={}
var report_path="res://ada_run/entropy_ruin_checks.json"
func _initialize() -> void:run.call_deferred()
func check(title: String,passed: bool) -> void:
	checks.append({"name":title,"passed":passed})
	if not passed:failures.append(title);print("FAIL ",title)
func run() -> void:
	await verify_ruin()
	finish()
func verify_ruin() -> void:
'''
finish=full[full.index('func finish()'):].replace('DIR+"verification.json"','report_path')
probe.write_text(prefix+'\tvar ruin='+ruin+'\n\n'+finish,encoding='utf8')
jar=full[full.index('func run()'):full.index('\tvar ruin=')]
(HERE/'verify.gd').write_text('extends "res://commons/testing/probe_entropy_ruin.gd"\n'+jar+'\tawait verify_ruin()\n\treport_path="res://doc/book/iterations/2026-10-16-plinth-and-physical-ruin/verification.json"\n\tfinish()\n',encoding='utf8')

def replace(path, before, after):
    p=ROOT/path
    text=p.read_text(encoding='utf8')
    assert before in text, (str(path),before[:60])
    p.write_text(text.replace(before,after),encoding='utf8')

replace('commons/maps/Random_Entropy/artifacts.md',
    'Seeded top-piece selection redistributes 116 pieces into bounded rubble, leaving the bottom two courses. Its replay is staged erosion, not a thermal or structural solver.',
    'ONE STONE extracts and releases one supporting drum; contact and gravity determine the fall of the other loose stones. Of 116 rigid bodies, 32 foundation stones remain anchored and 84 can move. Loose stones support VR and desktop carry. RESTORE rebuilds the authored arrangement after held stones are released. Seed 79 restarts selection, not an exact physics landing. This is loose masonry without mortar, fracture or a thermal model.')
replace('commons/maps/Random_Entropy/artifacts.md',
    'Its 144 blocks use the colonnade’s seeded top-course rule;',
    'Its 144 blocks retain the earlier authored top-course rule, separate from the now-physical colonnade;')
replace('commons/maps/Random_Entropy/artifacts.md',
    '`entropy_jar_states` at (3,2) adds four full-size columns beside the live jar.',
    '`entropy_jar_states` at (4,2) adds four broad jars on a shared 5.8 m plinth left of the entrance. Each glass body is 1.04 m across and 2.3 m tall, with rounded shoulders, a pale lid and metal collars.')
replace('commons/maps/Random_Entropy/plan.md','Installed at (3,2); original live jar retained at (3,5)','Installed at (4,2) on a shared plinth; original live jar retained at (3,5)')
replace('commons/maps/Random_Entropy/plan.md',
    'Column revision: equal two-metre glass volumes and a separate side panel now preserve every starting coordinate, then mix continuously at one-quarter of the first trial\'s speed, in lavender and warm coral. Use the [mixing review](../../../doc/book/iterations/2026-10-16-slow-lavender-columns/index.html) for current native views.',
    'Column revision: four equal 2.3 m tall, 1.04 m wide glass volumes now stand on one pale plinth, with a separate side panel. Source coordinates and the slow lavender/coral paths are preserved. Use the [plinth and physical ruin review](../../../doc/book/iterations/2026-10-16-plinth-and-physical-ruin/index.html) for current native views.')
p=ROOT/'commons/maps/Random_Entropy/plan.md'
text=p.read_text(encoding='utf8')
text=text.replace('| Test VR and reconstruction |', '| Make the ruin respond physically | One support is pulled out and released; unselected stones fall through contact and gravity; RESTORE respects held stones | Native model and installed XRTools/desktop checks pass; physical headset trial pending |\n| Compare chosen action with its consequences | Predict what will move after ONE STONE, then compare PULLED with MOVED; retain unexpected stability as well as collapse | Visitor trial pending; do not call the rubble a thermodynamic entropy reading |\n| Test VR and reconstruction |')
p.write_text(text,encoding='utf8')
p=ROOT/'commons/maps/Random_Entropy/writing_wall.json'
data=json.loads(p.read_text(encoding='utf8'))
for m in data['magnets']:
    if m['id']=='entropy_jar_states':
        m['brief']='Four broad lavender/coral jars on one plinth; different beginnings, slow continuous mixing.'
        m['final']='The names on the plinth begin to describe a past that is harder to find in the beads. Similar mixtures retain different positions; readings fluctuate.'
    if m['id']=='entropy_ruin':
        m['brief']='116 rigid stones; remove one support and let contact and gravity decide what else moves.'
        m['question']='How far does one removal travel through the structure, and what still holds?'
        m['tutorial']='Optional reconstruction: three colliding stones, fixed base, remove the lower loose support. Compare actual before/after transforms; RESTORE repeats the setup, not a saved physics trajectory.'
        m['final']='PULLED and MOVED diverge. The inventory stays while the relations that support it change.'
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Updated current notes, preserved staged-wall regression, and shared the physical ruin probe.')
