"""Keep room inventories, spatial reading directions and book captions in step."""
import json
from stage import ROOT, OUT, ROOMS, load, save, lookup

DESCRIPTIONS = {
    'seed_replay_demo': 'Replay two colour grids, then discard one draw before the RGB assignments. Same seed, different grouping.',
    'prng_crank_machine': 'Step a deterministic generator and inspect the successive states behind its outputs.',
    'slot_machine': 'Draw symbols repeatedly and watch their counts accumulate.',
    'trng_vs_prng': 'Compare the two labelled sources and inspect what the apparatus calls random.',
    'random_number_book_page_1955': 'A historical table makes a generated sequence into a durable record that can be read again.',
    'catalyst_pickup': 'One Randomness catalyst remains available on the route; it is a progression object, not another explanation of the seed.',
    'shannon_entropy_meter': 'Sort the same sample, then compare a second source. The ledger exposes what changes the measured symbol entropy.',
    'entropy_jar': 'A small mixing apparatus beside the ledger. Compare its visible arrangement with the measurement contract of the central instrument.',
    'hardware_entropy_decay': 'An arrangement of built forms undergoing disorder. Its visible changes are a comparison for the ledger, not proof that all disorder has one measure.',
    'entropy_axiom': 'A point cloud varies displacement along its length. Ask which properties this visual order-to-disorder gradient actually changes.',
    'random_butterflies': 'The butterflies can find landing points in the neighbouring entropy cloud: one shared setting rather than a second copy of that setting.',
    'remove_random': 'The owned eight-by-eight bench already contains the eligible set, the draw, the removal and its surviving addresses. No extra support is needed for this first encounter.',
    'random_walk_terrarium': 'Follow proposed steps, reflected endpoints and a limited record inside the glass. Compare the named walk rules and replay at equal step counts.',
    'random_walk_collection': 'Six small, grabbable sheets compare traces produced by different walk rules. They now rest above a reachable plinth.',
    'random_walk_leash': 'A hand-held relation gives the sampled motion another constraint.',
    'random_walk_128': 'A low floor study gives the accumulated path a spatial footprint.',
    'pixel_cloud': 'One compact self-avoiding, upward-biased walk in cubes. Its size keeps the supporting study inside the room.',
    'distribution_sampler': 'Gather draws, compare laws at equal sample counts, then rebin the values already stored.',
    'galton_board': 'Falling beads give repeated choices a visible accumulation.',
    'distribution_comparator': 'Compare three sampling laws using the same number of draws.',
    'GaussianPaintSplatter': 'Gaussian draws become marks; the protected central region rejects some of them. The painting is not an unfiltered picture of the sampling law.',
    'mushrooms': 'The central six-metre bed compares template copies, transform variation, filtered placement and explicit rings or clusters.',
    'bubbles_random': 'A small bubble dish offers another population of similar but varied bodies without competing with the specimen bed.',
    'r_c': 'Three stones follow a fixed state order with sampled waits. Test the advance cue, cross the basin or take the side route.',
    'cube_projectile_spawner': 'A separate eight-by-eight field samples launch positions and velocities on a regular clock. Its control stand is outside the launch region.',
}

def backup(path):
    if not path.exists(): return
    destination = OUT / 'before' / path.relative_to(ROOT)
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.exists(): destination.write_bytes(path.read_bytes())

def edit(relative, old, new):
    path = ROOT / relative
    text = path.read_text(encoding='utf-8')
    if new in text: return
    assert old in text, relative
    backup(path)
    path.write_text(text.replace(old, new), encoding='utf-8')

edit('commons/maps/Random_Definition/tutorial.md',
     'The primary is `seed_replay_demo:-90#comparison:replicas#stand:table`, at (8,11), facing the visitor in the open east half of Random_Definition.',
     'The primary is `seed_replay_demo:180#comparison:replicas#stand:table`, at (5,6), in the middle of Random_Definition. Its controls face −Z, toward the entrance.')
edit('commons/maps/Random_Definition/intent.md',
     'Primary: seed_replay_demo:-90#comparison:replicas#stand:table at (8,11), facing west.',
     'Primary: seed_replay_demo:180#comparison:replicas#stand:table at (5,6), facing −Z in the middle of the hall.')
edit('commons/maps/Random_Definition/intent.md',
     "Supporting space: Preserve all 15 placements, Claude's table and clear east approach, west entropy cloud and restored raised platforms. Secondary apparatus can extend the visit; it does not become additional primary book content by proximity.",
     'Supporting space: An 11×13 hall contains the central replay table, crank, slot machine, TRNG/PRNG comparison, historical number page and one catalyst. The entropy cloud, jar and butterflies belong to Random_Entropy. Original placements are archived; supports extend the visit without becoming primary book content by proximity.')
edit('commons/maps/Random_Entropy/final.md',
     'A gauge hangs on a post at the west side of the corridor, its number glowing over a desk.',
     'A gauge hangs on a post in the middle of the hall, its number glowing over a desk.')
edit('commons/maps/Random_Entropy/intent.md',
     'shannon_entropy_meter:90#stand:ledger#disclosure:ledger at (5,6), facing east.',
     'shannon_entropy_meter:180#stand:ledger#disclosure:ledger at (6,6), facing −Z.')
edit('commons/maps/Random_Entropy/intent.md',
     'Preserved material: All nine declared artifacts, the existing desk, raised gauge, west/east orientation, clear approach rectangles [[4,4,7,9],[7,0,10,11]], and the prior ghost/build/lift repairs.',
     'Preserved material: The existing desk, raised gauge and prior ghost/build/lift repairs. The 13×13 hall retains the jar, hardware decay study, point cloud and butterflies as four distinct supports. The repeated TRNG comparison stays in Definition; the unavailable replay_casino and generic screen are archived.')
edit('commons/maps/Random_Remove/intent.md',
     'Primary: remove_random:90#local_grid:true at (6,7). Preserve the existing owned 8×8 bench, controls at right, cased status at left, all three artifacts and clear rectangle [[3,4,10,11]].',
     'Primary: remove_random:180#local_grid:true at (4,5), facing −Z. The 9×10 hall holds the existing owned 8×8 bench, its controls and cased status. The repeated reference sphere and unrelated hazards are archived; the bench supplies the complete first encounter.')
edit('commons/maps/Random_Walk/intent.md',
     'Primary: random_walk_terrarium alone is the book hero. Other existing studies and catalysts remain. The lab_room mounts a Monte Carlo apparatus; its shared boolean parser is repaired so its east observation window is read correctly.',
     'Primary: random_walk_terrarium alone is the book hero, at (5,6), facing −Z. The 11×13 hall retains the sheet collection, leash, floor path and one compact pixel cloud. The two extra pixel clouds, repeated catalyst, apparatus launchers and Monte Carlo pavilion are archived.')
edit('commons/maps/Random_Gaussian/final.md',
     'The cabinet stands in the south-east of the hall, beyond the other distribution studies.',
     'The cabinet stands in the middle of the hall, its controls facing you as you approach. The other distribution studies stand around it.')
edit('commons/maps/Random_Gaussian/intent.md',
     'Secondary comparator, Galton board, mound, applications and reference body remain.',
     'The comparator, Galton board and paint application support the central cabinet in an 11×13 hall. The blur demonstrations, second mound and repeated reference sphere are archived.')
edit('commons/maps/Random_Mushrooms/intent.md',
     'Preserve the specimen table, six-metre raised bed and three edible mushrooms, plus the existing secondary company.',
     'Preserve the specimen table, six-metre raised bed and three edible mushrooms. A 13×14 hall gives the bed a clear margin; one small bubble dish remains as supporting company. The second bubble system, duplicate historical page, reference sphere and later reaction-diffusion lesson are archived.')
edit('commons/maps/Random_Game/final.md',
     'Nor can this field explain every threat in the hall: the folding creatures execute other routines. Keep track of which encounter supplied your evidence.',
     'Keep track of which encounter supplied your evidence: a sampled wait at the crossing, or a sampled launch in the field.')
edit('commons/maps/Random_Game/intent.md',
     'Open work: Headset traversal, controlled activation/separation of the folding creatures, and the incomplete Monte Carlo interface. No score controller or distribution-mode controls are inferred.',
     'Staging: A 15×20 hall puts the crossing on the centre line at (7,5), with its original five-by-three-metre pit, and the falling field in a separate rear bay at (7,13). Both controls already face −Z. The folding creatures and incomplete Monte Carlo display are archived from this teaching route. Open work: headset traversal and comfort. No score controller or distribution-mode controls are inferred.')

manifest = load(OUT/'manifest.json')
for row in manifest:
    name = row['map']
    items = ROOMS[name][2]
    path = ROOT/'commons/maps'/name/'artifacts.md'
    backup(path)
    text = f'# {name.replace("_", " ")} — room inventory\n\nRevised 16 September 2026. {row["count"]} placed artifacts in a {row["size"]["width"]}×{row["size"]["depth"]} m source grid.\n\n'
    text += row['purpose']+'\n\n'
    for x,z,token in items:
        key = lookup(token)
        role = 'Central hero / primary' if key==row['hero'] else ('Second book encounter / primary' if name=='Random_Game' else 'Supporting / secondary')
        text += f'## {key}\n\n{role} · ({x}, {z})\n\n{DESCRIPTIONS[key]}\n\nPlacement: `{token}`\n\n'
    text += '## Retained archive\n\nThe previous layout and removed placements are preserved in `doc/space/randomness-staging-2026-09-16/before/`. No artifact scenes were deleted. The seven active rooms have no repeated artifact lookup; the wider stored map library remains available for later curation.\n'
    path.write_text(text, encoding='utf-8')
    notes = ROOT/'commons/maps'/name/'field_notes.md'
    backup(notes)
    current = notes.read_text(encoding='utf-8')
    marker = '## 2026-09-16 — central hero and supporting studies'
    if marker not in current:
        notes.write_text(current.rstrip()+'\n\n'+marker+'\n\n'+row['purpose']+' Current placements and sizes are listed in artifacts.md. The staging manifest and desktop runtime evidence are in doc/space/randomness-staging-2026-09-16/. This pass supersedes older placement/count descriptions in these notes; tracked-hand reach, headset comfort and performance remain to be checked.\n', encoding='utf-8')

path = ROOT/'commons/maps/sequences/randomness.json'
backup(path)
seq = load(path)
groups = seq['sequences']['randomness']['artifact_groups']
for row in manifest:
    group = next((g for g in groups if g.get('map')==row['map']), None)
    if group is None:
        group = {'map':row['map'],'position':'exploration','size_budget':'mixed'};groups.append(group)
    group['artifacts'] = [lookup(token) for _,_,token in ROOMS[row['map']][2]]
    group['rationale'] = row['purpose']
    group['grammar'] = 'central_hero'
save(path, seq, indent=1)

path = ROOT/'commons/data/book/randomness.json'
backup(path)
book = load(path)
for pearl in book['pearls']:
    name = pearl.get('map')
    if name not in ROOMS: continue
    existing = {line.get('token'):line for line in pearl.get('lines',[])}
    pearl['lines'] = []
    for _,_,token in ROOMS[name][2]:
        key = lookup(token)
        # Keep the hand-written primary captions; rewrite stale support claims.
        line = existing.get(key, {'token':key})
        if key != ROOMS[name][2][0][2].split('#')[0].split(':')[0] and key != 'cube_projectile_spawner':
            line = {'token':key,'text':DESCRIPTIONS[key],'by':'curated-2026-09-16'}
        pearl['lines'].append(line)
save(path, book, indent=1)
print('Synchronized seven inventories, spatial references, sequence artifact groups and book captions.')
