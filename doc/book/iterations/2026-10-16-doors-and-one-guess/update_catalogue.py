"""Update the two changed encounters, retaining placements and editorial order."""
import json
import shutil
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def save(path, text):
    target = ROOT / path
    before = HERE / 'before' / path
    if not before.exists():
        before.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(target, before)
    target.write_text(text, encoding='utf-8')

door = {
    'brief': 'Dynamical entropy: two starts, two rules',
    'question': 'Which initial differences disappear, grow or survive only in the record?',
    'tutorial': 'STEP advances both pairs; RESET and GAP restore a controlled beginning. Read both LOW/HIGH traces separately from the 1024-start ensemble. Eight symbols give 1 versus 8 bits; finite starts cap doubling records at 10. Reconstruct the rejoining pair.',
    'final': 'A shared step makes a small starting difference disappear or become visible. Wrapping can bring the expanding pair together again while its earlier differences remain in the record. The centre passage stays open.'
}
guess = {
    'brief': 'Min-entropy: one guess',
    'question': 'Can more alternatives leave the best prediction unchanged?',
    'tutorial': 'Guess then DRAW on four sixteen-chair tables. A has 8/8; B has 8/4/4 with armchairs: same Hmin=1, different Shannon H=1 and 1.5. C is 12/4; CHANGE ONE alters counts. Rearrange all-pink D without changing certainty. Record generator state for replay.',
    'final': 'The black half acquires another distinction but pink remains the best guess. At the all-pink table we lift, turn and place chairs. The composition changes while the colour record remains certain.'
}
path = 'commons/maps/Random_Entropies/writing_wall.json'
wall = json.loads((ROOT / path).read_text(encoding='utf-8'))
for magnet in wall['magnets']:
    if magnet['id'] == 'entropy_door_dynamics': magnet.update(door)
    if magnet['id'] == 'entropy_ball_pit': magnet.update(guess)
wall['hall_role'] = 'Compare distinct entropy questions; intervene in the door and best-guess studies, then reconstruct the recorded comparison.'
save(path, json.dumps(wall, ensure_ascii=False, indent=2) + '\n')

path = 'commons/artifacts/registry/ordinary_entropies.json'
registry = json.loads((ROOT / path).read_text(encoding='utf-8'))
for token, data, description in [
    ('entropy_door_dynamics', door, 'Two door pairs in one wall use x/2 and (2x) mod 1. Shared STEP, RESET and starting GAP; separate LOW/HIGH histories and finite ensemble readings. Central passage stays open. No random input or thermal claim.'),
    ('entropy_ball_pit', guess, 'One guess: four tables with sixteen miniature pink/black chairs. Uniform chair-ID draw with replacement after a category prediction; CHANGE ONE and RESET. Compare 8/8 with 8/4/4 types, then 12/4 and all pink. The last chairs can move and turn. Private seed-435 draws illustrate the declared probabilities, not cryptographic unpredictability.')
]:
    item = registry['artifacts'][token]
    item['name'] = data['brief']
    item['description'] = description
    item['interactions'] = [data['tutorial'], data['question']]
save(path, json.dumps(registry, ensure_ascii=False, indent=2) + '\n')

replacements = {
'commons/maps/Random_Entropies/summary.md': [
('Seven separately registered groups now show versions simultaneously, with no interface.', 'Seven separately registered groups show versions together; the door and best-guess studies also have compact controls.'),
('two driven pairs repeat contracting and expanding rules', 'two pairs advance contracting and expanding rules on a shared STEP'),
('Finally, three trays retain one colour-guess question while the pink/teal counts change from 8/8 through 12/4 to 16/0.', 'Finally, four tables of miniature chairs compare 8/8, 8/4/4 types, 12/4 and 16/0. Guess before DRAW; change one category or rearrange the all-pink ending.'),
('| 7 | Safest colour guess | (9,50) | Sixteen equal-sized balls: best chances 1/2, 3/4, 1; min-entropy 1, 0.415, 0 bits |', '| 7 | One guess | (9,50) | Sixteen chairs per table; A/B share Hmin=1 while Shannon differs; C best 75%; D colour certain and chairs movable |'),
('Chairs retain a 0.46 m seat and 0.93 m back.', 'The earlier chairs retain a 0.46 m seat and 0.93 m back; the final tables use half-scale chairs.'),
('No visitor state selection, draw, save or replay controls remain. Individual copies retain a reconstruction API for research tooling.', 'Doors have STEP/RESET/GAP, and chair tables have category choices, DRAW, CHANGE ONE and RESET. Receipts are available through the reconstruction API, with no in-room save gallery.')],
'commons/maps/Random_Entropies/artifacts.md': [
('| 4 | `entropy_door_dynamics` — Driven door | Contracting/expanding rule, step, held-open passage | Binary observation partition and 1,024 initial bins |', '| 4 | `entropy_door_dynamics` — Two starts, two rules | STEP/RESET/GAP; contracting and expanding pairs with retained histories | Binary observation partition, 1,024 equally likely midpoint starts; centre stays open |'),
('| 7 | `entropy_ball_pit` — Best guess | Pink/teal counts: 8/8, 12/4, 16/0 | Sixteen equal-sized balls; uniform-ball draw; colour answer throughout |', '| 7 | `entropy_ball_pit` — One guess (chairs) | Types 8/8, 8/4/4, 12/4, 16/0; guess/draw, change one, movable all-pink ending | Sixteen IDs; selection with replacement; categories defined by colour and arms |'),
('The versions now remain visible together with no controls.', 'Versions remain visible together. Doors and the last tables have small controls for the specific interventions described above.'),
('2026-10-16-entropy-coffee-glass/index.html', '2026-10-16-doors-and-one-guess/index.html')],
'commons/maps/Random_Entropies/technical.md': [
('Seven wrappers in `commons/artifacts/ordinary_entropies/` use the comparison host with control-free encounter copies while remaining independent registry entries and map placements.', 'Seven wrappers in `commons/artifacts/ordinary_entropies/` remain independent registry entries and placements. Five use the prepared comparison host; doors use `door_study.gd` and the last tables use `one_guess.gd`, `guess_table.gd` and `guess_model.gd`.'),
('The last comparison uses one uniform-ball sampling rule and changes only the colour counts.', 'The last comparison uniformly selects a chair ID with replacement using a private seed-435 generator. Categories include colour and arms; their distribution determines both Shannon and min-entropy. Position and rotation are separately retained.'),
('`best_guess.gd` builds three sixteen-ball inventories, with equal radii and a fixed colour question. Its probabilities come from actual colour counts. Its separate `colour-best-guess/1` record preserves the declared uniform draw and colour record; legacy pit receipts remain supported by the original encounter class. No draw animation is used as evidence.', '`guess_table.gd` builds four sixteen-chair tables. A/B compare two versus three types at the same 50% best guess; C is 12/4; D has sixteen pickable pink chairs. CHANGE ONE changes a category; RESET restores the baseline and generator. `one-guess-table/1` retains category IDs, full generator state and poses. Older `best_guess.gd` and `encounter.gd` receipt formats remain reconstructible through their original classes, not through the new table.'),
('at every driven step.', 'at steps 0–15. The initial observation is included, so step 7 contains eight symbols. Ensemble record entropy uses 1,024 equally likely midpoint starts and caps at 10 bits. Individual pair separation is not used to estimate this entropy; the default pair rejoins at step 9. These finite calculations do not measure an asymptotic entropy rate.'),
('2026-10-16-entropy-coffee-glass/README.md', '2026-10-16-doors-and-one-guess/README.md')],
'commons/maps/Random_Entropies/critical.md': [
('A large ball draws attention before its probability has been specified.', 'Splitting one category into two can increase average uncertainty without changing the best guess. Rearranging the all-pink chairs changes a composition without changing that colour prediction.'),
("the pit's sampler ignores the effort of reaching or lifting", "the chair-ID sampler ignores the effort of reaching or lifting"),
('a different way of selecting a ball', 'a different way of selecting a chair')],
'commons/maps/Random_Entropies/map_data.json': [
('Prepared ordinary-object comparisons: which question does each entropy answer?', 'Ordinary-object comparisons, stepped door pairs and a chair-guess experiment: which question does each entropy answer?')],
'commons/data/book/randomness.json': [
('"text": "Dynamical entropy: a door and its rule"', '"text": "Dynamical entropy: two starts, two rules"'),
('"text": "Min-entropy: the easiest guess"', '"text": "Min-entropy: one guess"')]
}
for path, pairs in replacements.items():
    text = (ROOT / path).read_text(encoding='utf-8')
    for old, new in pairs:
        assert old in text or new in text, (path, old)
        text = text.replace(old, new)
    save(path, text)
print('Updated catalogue, notes and current descriptions; placements and order retained.')
