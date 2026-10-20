"""Narrow updates to descriptions of the newly moving column bank."""
from pathlib import Path
import json
ROOT = Path(__file__).resolve().parents[4]
def replace(path, old, new):
    p = ROOT/path
    text = p.read_text(encoding='utf8')
    assert old in text, (path, old)
    p.write_text(text.replace(old, new), encoding='utf8')

p = ROOT/'commons/maps/Random_Entropy/writing_wall.json'
data = json.loads(p.read_text(encoding='utf8'))
for magnet in data['magnets']:
    if magnet['id'] == 'entropy_jar_states':
        magnet.update(brief='Four full-size columns / different beginnings, continuing mixing',
            question='When does the beginning become hard to recognise, and what can a different observation still reveal?',
            tutorial='Restart, inspect for eight seconds, watch, pause and compare height with core/rim. Preserve positions, time and source revision; reconstruct the seeded walk before changing one condition.',
            final='The names above the glass begin to describe a past that is harder to find in the beads. Similar mixtures retain different positions; the readings continue to fluctuate.')
    if magnet['id'] == 'entropy_jar':
        magnet['tutorial']='Shake and reset the original jar. Compare with four columns that start from prepared arrangements and continue mixing; pause their height/radius readings. Editable partitions remain a reconstruction task.'
p.write_text(json.dumps(data, indent=2, ensure_ascii=False)+'\n', encoding='utf8')

p = ROOT/'commons/artifacts/registry/ordinary_entropies.json'
data = json.loads(p.read_text(encoding='utf8'))
entry = data['artifacts']['entropy_jar_states']
entry['name']='Four columns: different beginnings, continuing mixing'
entry['description']='Four two-metre columns begin with the retained seed-435 jar coordinates: layers, interface, mixed and core/shell. Forty red and forty blue beads each. Approaching starts an eight-second inspection hold, then continuous bounded random walks with separate derived streams. Live height/core-rim readings, PAUSE and RESTART sit on a small side panel. Neutral materials, no forced shared endpoint or heat model. The original shakeable jar is a separate experiment.'
entry['interactions']=['Approach and watch all four starting arrangements mix.', 'PAUSE / RESUME freezes or continues the current comparison.', 'RESTART restores the starting records and seeded motion.']
p.write_text(json.dumps(data, indent=2, ensure_ascii=False)+'\n', encoding='utf8')

replace('commons/maps/Random_Entropy/artifacts.md',
    '`entropy_jar_states` at (3,2) adds four prepared specimens beside the existing live jar. All preserve eighty beads while height and core/rim records expose different distinctions.',
    '`entropy_jar_states` at (3,2) adds four full-size columns beside the live jar. Their prepared beginnings hold for eight seconds on approach, then mix continuously with forty beads of each colour. Height and core/rim readings track their current positions. PAUSE holds the comparison; RESTART reproduces the starts and their seeded paths.')
replace('commons/maps/Random_Entropy/summary.md',
    'Four prepared glass columns at (3,2) now expose layers, interface, mixed and core/shell states before the original shakeable jar at (3,5).',
    'Four glass columns at (3,2) start with layers, interface, mixed and core/shell arrangements. After an eight-second inspection hold on approach, they keep mixing under the same rule with separate seeded paths. PAUSE holds both live readings; RESTART restores all four beginnings. The original shakeable jar remains at (3,5).')
replace('commons/artifacts/ordinary_entropies/README.md',
    'Its snapshots reuse the live jar\'s generator and height measure, add a two-region radial record, and freeze pickup/physics.',
    'Its starting snapshots reuse the live jar\'s generator and height measure, add a two-region radial record, and disable pickup/rigid-body physics. A separate bounded-walk model now drives the column comparison.')
replace('commons/artifacts/ordinary_entropies/README.md',
    'It retains the unchanged small-jar coordinate records and measurements; display scaling alone changes. No table or broad backdrop remains. Current evidence: `doc/book/iterations/2026-10-16-entropy-columns/`.',
    'It retains the exact small-jar starting coordinates. On approach, eight seconds precede continuous mixing. `column_mixing.gd` proposes symmetric 0.11 m steps per axis every 0.12 s, rejecting moves outside the usable cylinder and interpolating accepted moves. No collisions, temperature or shared target state are imposed. Measurements and visible beads use the same current positions. PAUSE/RESUME and RESTART are on the side panel; restart also resets each derived stream. No table or broad backdrop remains. Current native states, coordinates and checks: `doc/book/iterations/2026-10-16-column-mixing/`. Human perceptual convergence remains an experiment.')
print('Updated column descriptions without moving artifacts or magnets.')
