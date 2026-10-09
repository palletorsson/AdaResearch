from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[5]
OUT = Path(__file__).resolve().parent
records = []

def propose(path, keys, new):
    d = json.loads((ROOT / path).read_text(encoding='utf-8-sig'))
    old = d
    for k in keys: old = old[k]
    if old != new: records.append({'path': path, 'keys': keys, 'old': old, 'new': new})

def objectives(hall, values):
    propose(f'commons/maps/{hall}/map_data.json', ['map_info','metadata','learning_objectives'], values)

objectives('WaveFunctions_Intro', [
    'Distinguish two returns to the same position by the sign of angular velocity',
    'Read a restoring acceleration, velocity update and angle update as a state loop',
    'Compare release position and tangent hand velocity with the standard prediction',
    'Compare integrated pendulum motion with prescribed cube motion and a signal-driven cube',
])
objectives('WaveFunctions_Pendulum', [
    'Read sample age as spatial depth rather than motion of the original bob',
    'Compare target intervals with actual physics-tick sample gaps',
    'Compare FINE, COARSE and STROBE under point-count and age limits',
    'Relate the pendulum record to the secondary drum, canvas and point recorders',
])
objectives('WaveFunctions_Sine_Space', [
    'Compare sphere size and relief on one stationary colliding sine surface',
    'Interpret outlet, other-exit and still-in counts at a stated deadline',
    'Compare a moving layered wall with walking past its frozen form',
    'Distinguish relative phase, local-X gap and collision support',
])
objectives('WaveFunctions_Unit_Circle', [
    'Predict horizontal and vertical coordinate projections at four reference angles',
    'Read sine and cosine as projections of angular progression on a unit circle',
    'Distinguish a graph axis from the physical path of the rotating point',
    'Recognise the finite sampled construction without assuming it is a verified walking route',
])

p = 'commons/maps/WaveFunctions_Intro/map_data.json'
d = json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
old = d['documentation']['key_elements']
new = [x.replace('rotating_cube / rotating_cube_demo - constant angular velocity, no return',
                 'rotating_cube / rotating_cube_demo - constant angular velocity; orientation returns while the accumulated angle can continue increasing') for x in old]
propose(p, ['documentation','key_elements'], new)
p = 'commons/maps/WaveFunctions_Pendulum/map_data.json'
d = json.loads((ROOT/p).read_text(encoding='utf-8-sig'))
propose(p, ['map_info','description'], d['map_info']['description'].replace('every 25 ms its position is kept', 'at a target interval of 25 ms, serviced on physics ticks, its position is kept'))

p = 'commons/maps/WaveFunctions_Unit_Circle/map_data.json'
propose(p, ['map_info','description'], 'A turning point and its two coordinate projections reveal one construction of sine and cosine after the preceding encounters with motion, records and sine-shaped space. A finite sequence of colliding steps unfolds the selected coordinate into a graph. Supporting wave artifacts remain; their resemblance to bridges does not establish a verified walking route.')
propose(p, ['documentation','layout'], 'The unit-circle construction and supporting oscillating bridge and curve occupy the entry end of the authored platform-and-basin plan. The teleporter is at (10,2); the cube and colour balls remain at (1,11) and (2,11).')
propose(p, ['documentation','objective'], 'Follow four positions around the circle, predict a quarter of the adjacent graph, then distinguish coordinate projection from physical motion through the room.')
propose(p, ['documentation','key_elements'], [
    'Spawn token sp at (0,0)',
    'unit_circle_advanced at (1,1), with a rotating point, coordinate rods and finite sampled graph',
    'SimpleOscillatingBridge at (5,1) and OscillationCurve at (11,1) remain supporting works',
    'Teleporter t at (10,2)',
])

propose('commons/artifacts/registry/commons_artifacts.json', ['artifacts','control_pendulum','description'],
        'A grabbable pendulum integrates the nonlinear restoring term -(g/L)sin(angle), damping and optional drive. Release position and tangent hand velocity set its next swing. Configured plumb/trace evidence can expose signed centre crossings and a prediction from the standard start; length sets the small-angle period only with gravity fixed.')
propose('commons/artifacts/registry/wavefunctions.json', ['artifacts','PendulumWave','description'],
        'One integrated pendulum leaves a timestamped position record: sample age becomes depth. FINE, COARSE and measured-period STROBE expose physics-tick sampling, a 300-mark budget and a ten-second age limit; RESET restarts this experiment.')
propose('commons/artifacts/registry/wavefunctions.json', ['artifacts','sine_wall_corridor','description'],
        'Layered sine displacements shape two walls. The shipped seven-metre scene has animated, noncolliding walls over a supporting floor; AMP, PHASE, FREEZE and RESET compare running and frozen folds and display the local-X gap. Script defaults differ from this configured scene.')
propose('commons/artifacts/registry/wavefunctions.json', ['artifacts','unit_circle_advanced','description'],
        'A point progresses around a circle with horizontal and vertical projection rods while a finite sampled graph builds beside it. The default graph reads the sine coordinate; configured alternatives expose other correspondences. Collision boxes do not by themselves establish a verified walking route.')
propose('commons/artifacts/registry/wavefunctions.json', ['artifacts','unit_circle_advanced','qfep_connection'],
        'One angle supplies two coordinate projections. Their graph depends on which coordinate is retained and how angular progression is placed on a new axis; this construction does not imply that every oscillation is physically driven by rotation.')

transition = {
    'path': 'commons/maps/WaveFunctions_Sine_Space/final.md',
    'old': "In the next room a sine enters another sine's phase. There will be no gap to walk through. We will listen for what their relation has made possible.",
    'new': 'Ahead, a point travels around a circle while a graph grows beside it. Follow the point and try to predict the graph. After walking among these folds, we can look at one way their returning values are made.',
    'reason': 'Restores the intended Sine Space → Unit Circle reveal; the previous sentence followed the shortened route to Effect Sound.'
}
assert transition['old'] in (ROOT/transition['path']).read_text(encoding='utf-8-sig')
(OUT/'metadata-proposals.json').write_text(json.dumps(records, ensure_ascii=False, indent=2), encoding='utf-8')
(OUT/'manuscript-proposals.json').write_text(json.dumps([transition], ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'metadata_proposals':len(records), 'manuscript_proposals':1, 'production_files_changed':0}))
