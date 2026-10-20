from pathlib import Path
import json

root=Path(__file__).resolve().parents[4]
here=Path(__file__).parent
folder=root/'commons/maps/Random_Entropies'

def replace(path, pairs):
    text=path.read_text(encoding='utf-8')
    for old,new in pairs:
        assert old in text, (path,old)
        text=text.replace(old,new)
    path.write_text(text,encoding='utf-8')

replace(folder/'final.md',[
('Beyond the glass, chairs return small enough to gather on four tables. At the first, eight are pink and eight black.', 'Beyond the glass, chairs rise in four pyramids. Nine stand on the floor, four rest above them, then two, then one. The seat that held a body now takes the feet of another chair. In the first pyramid, eight are pink and eight black.'),
('At the next table, half the black chairs have arms.', 'In the next pyramid, half the black chairs have arms.'),
('The third table has twelve pink chairs and four black.', 'The third pyramid has twelve pink chairs and four black.'),
('At the last table all sixteen are pink. We lift a chair, turn it, place it among the others. Positions change. Another composition becomes possible. The best colour guess remains certain, its min-entropy zero.', 'In the last pyramid all sixteen are pink. A chair near the floor carries more than its own weight. We can grip it and draw it out, or press into the stack as we walk. Whatever falls must find another support. Each chair keeps its letter and number as it moves; the draw still chooses among the same sixteen. The best colour guess remains certain, its min-entropy zero.'),
('Everything on the table can move. Nothing in that movement can surprise the colour record. What the arrangement does to its neighbours is still available to another account.', 'An upright pyramid and a fallen pile can give the same answer. Nothing in that movement can surprise the colour record. What the arrangement does to its neighbours is still available to another account.')])
replace(root/'commons/maps/Random_Entropy/final.md', [('At the last table, every chair was pink; moving them gave the colour question nothing new to answer.', 'In the last pyramid, every chair was pink; changing their supports gave the colour question nothing new to answer.')])

replace(folder/'tutorial.md',[
('the last four tables let us', 'the last four chair pyramids let us'),
('the guessing tables have horizontal front rails', 'the guessing pyramids have horizontal front rails'),
('Four sixteen-chair tables:', 'Four sixteen-chair pyramids:'),
('Every table contains sixteen miniature chairs.', 'Each pyramid contains sixteen full-size chairs, in layers of 9, 4, 2 and 1.'),
('At D, pick up, turn and place the chairs. Released chairs settle upright on their own tabletop and retain their turn. RESET restores their places; release a held chair first. The colour prediction remains certain. Propose a record that would notice one of the changes just made, without treating spatial change itself as entropy.', 'All four pyramids use physical chairs. In VR, grip a chair with the pickup hand and release it to let gravity act. On desktop, right-click a chair to carry it, use the wheel to change its distance, and right-click again to release. Walking into a chair can nudge the stack. The seat, back, legs and armrests have separate colliders; there is no automatic upright snap. At D, remove a support, rebuild or stack chairs differently and compare the unchanged colour prediction. A collapse is a possible physical consequence, not a scripted animation.\n\nEach chair keeps its group letter and ID when carried elsewhere. DRAW selects one of that group\'s sixteen IDs; it does not select by current location, accessibility or visible surface area. Moving a chair into another group does not transfer its category. CHANGE ONE alters a category while retaining poses; RESET restores that group\'s pyramid, original counts and seed 435. Release held chairs before either action. Propose a record of height, orientation or support relations that would notice the spatial change, rather than calling the colour reading a measure of the pile.'),
('`guess_table.capture()` stores sixteen category IDs, original counts, current choice/result, draw count, generator state and chair positions/turns (`one-guess-table/1`).', '`guess_table.capture()` stores sixteen category IDs, original counts, current choice/result, draw count, generator state, group letter, full positions/rotations, linear/angular velocities and sleeping flags (`one-guess-floor/2`).'),
('Chair pose comparisons allow floating-point tolerance; the next seeded IDs must agree exactly.', 'Chair pose comparisons allow floating-point tolerance; the next seeded IDs must agree exactly. Restoring poses and velocities supplies a physical beginning, not a guarantee of bit-identical subsequent collisions across machines or engine versions. The old `one-guess-table/1` receipts remain usable with `guess_table.gd` in its historical `floor_mode=false`; the floor study rejects them rather than silently changing their scale.'),
('The final guessing studies intentionally use miniature chairs on reachable 0.75 m tables.', 'The final guessing studies now use full-size physical pyramids on the floor, with a clear central route. The reference chair is also pickable and pushable; the earlier counting arrangements and glass specimens remain prepared comparisons.')])

for name in ['summary.md','artifacts.md','technical.md']:
    path=folder/name
    text=path.read_text(encoding='utf-8')
    text=text.replace('four tables of miniature chairs','four full-size chair pyramids').replace('Sixteen chairs per table','Sixteen physical chairs per pyramid').replace('the last tables','the last pyramids').replace('movable all-pink ending','physical, stackable all-pink ending')
    text=text.replace('`guess_table.gd` builds four sixteen-chair tables.', '`guess_table.gd` builds four sixteen-chair pyramids with 9 + 4 + 2 + 1 chairs. All are XR pickables with compound colliders, released under gravity; the desktop museum supplies a bounded, horizontal walking-contact force through `pushable_walk.gd`. VR uses the existing player-body rigid-body push.')
    text=text.replace('D has sixteen pickable pink chairs.', 'D has sixteen pink chairs. Group membership stays with the labelled ID, independent of location. Spatial disturbance leaves the category distribution unchanged.')
    text=text.replace('`one-guess-table/1` retains category IDs, full generator state and poses.', '`one-guess-floor/2` retains group/category IDs, full generator state, 3D poses, velocities and sleeping flags. Held bodies block reset/restore. Historical `one-guess-table/1` records require the old miniature mode. Physics continuations are not claimed bit-reproducible.')
    path.write_text(text,encoding='utf-8')

plan=folder/'plan.md'
replace(plan,[('## Current apparatus · 16 October 2026','## Prior apparatus checks · 16 October 2026'),('The final guessing studies intentionally use miniature chairs on reachable 0.75 m tables.','The miniature version was superseded on 17 October by full-size physical chair pyramids.')])
text=plan.read_text(encoding='utf-8')
text=text.replace('## Length and attention','''## Chair pyramids · 17 October 2026

Palle clarified that “mini” meant **min-entropy**, and proposed pyramids of chairs. The last stop now starts with four full-size pyramids, each containing 9 + 4 + 2 + 1 chairs. The distributions remain 8/8, 8/4/4, 12/4 and 16/0. All 64 chairs, plus the entrance reference chair, can be grabbed and released under gravity. Walking can disturb them. Earlier prepared comparisons remain fixed. The layout keeps a central route and the same seven-stop final order.

Acceptance: the pyramids stand without frozen bodies; a carried chair falls when released; walking contact moves a chair; chair-on-chair contact supports a stack; rearrangement leaves category readings unchanged; CHANGE ONE retains poses; RESET and restore refuse held chairs. Floor receipts retain full pose/motion and reproduce subsequent seeded IDs, without promising identical future physics. Check native results in the [pyramid review](../../../doc/book/iterations/2026-10-17-physical-guess-chairs/index.html).

Next human test: approach a pyramid without first reading the controls. What seems possible to change? Remove a support or nudge a chair, then predict what the colour gauge will do. Record the actual spatial consequence, any missed grab target, and whether the unchanged number invites a different measurement. Test grip reach, leg/seat snagging, support removal, re-stacking and frame rate in the headset. A supplied-input physics test does not establish these experiential results.

## Length and attention''',1)
plan.write_text(text,encoding='utf-8')

def update_json(path, action):
    data=json.loads(path.read_text(encoding='utf-8'));action(data)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def wall(data):
    item=next(m for m in data['magnets'] if m['id']=='entropy_ball_pit')
    item['brief']='Min-entropy: four chair pyramids'
    item['question']='What can collapse while the best colour guess stays the same?'
    item['tutorial']='Four physical pyramids of 16 chairs, in layers 9/4/2/1. Grab a support, push, drop or rebuild. Labelled IDs retain group membership. A 8/8 and B 8/4/4 share Hmin=1, Shannon 1 vs 1.5. C is 12/4; D all pink. CHANGE ONE alters a type; RESET rebuilds. Preserve full pose/motion plus generator state with a floor receipt.'
    item['final']='A seat becomes a support for another chair. The pyramids compare category predictions; armrests split a less likely answer. At the all-pink ending a support can leave and the arrangement can fall without surprising the colour record. What happens to neighbours requires another account.'
update_json(folder/'writing_wall.json',wall)

path=folder/'map_data.json'
replace(path,[('four tables of miniature chairs for the best-guess comparison.', 'four physical chair pyramids for the best-guess comparison, with a clear central route.')])

def registry(data):
    entries=data.get('artifacts',data)
    item=entries['entropy_ball_pit']
    item['description']='Min-entropy: four physical pyramids of sixteen full-size chairs (9 + 4 + 2 + 1). Grab, stack, release or walk into them; gravity and contacts determine what falls. Groups compare 8/8, 8/4/4 types, 12/4 and all pink. Group letters and IDs stay with the chairs. Uniform ID draws with replacement use private seed 435; spatial rearrangement does not alter the category probabilities. CHANGE ONE changes a type and RESET rebuilds a pyramid.'
    item['parameters']['footprint']=[17,3,10]
    item['interactions']=['Grip and release a chair in VR; desktop right-click carries/drops and wheel changes distance. Walking nudges the physical stack.', 'Choose a type before DRAW. All 16 group IDs remain equally likely wherever the chairs move. CHANGE ONE alters a category; RESET rebuilds after held chairs are released.', 'Compare A/B at the same 50% best guess but different Shannon entropy. At all-pink D, observe what collapses while the colour answer stays certain.', 'Research floor receipts retain full pose, velocity and generator state; no promise of identical future collisions.']
    entries['entropy_chair_reference']['description']='A full-size pink chair on the visitor floor, in front of a wall label. Pick it up or nudge it by walking; release resumes gravity. It introduces colour versus arrangement before the prepared Shannon/Boltzmann comparisons.'
update_json(root/'commons/artifacts/registry/ordinary_entropies.json',registry)
print('Updated the current encounter, texts, writing wall and plan; order retained.')
