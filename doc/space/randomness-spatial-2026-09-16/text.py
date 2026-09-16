"""Keep the book and tutorial aware of the larger, actually implemented encounters."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]

ADDITIONS={
'Random_Entropy': '''<!-- @entropy_axiom -->

Beyond the ledger, enter the square glass enclosure. Start at the blue end. The points sit in rows; toward the other end their positions stray further from those rows. Walk sideways as well as forward. The same field can look lined up from one direction and tangled from another.

Here the random offset grows with a point's position along z. The plan stays square; the rule still has a direction. This is a field of displaced points, not a spatial picture of the ledger's number. The meter counted symbol shares. This work moves bodies away from lattice addresses. Putting them in one hall gives us something to compare, and a reason to resist calling every visible irregularity the same entropy.

''',
'Random_Walk': '''<!-- @random_walk_128 -->

Now enter the larger glass frame. Its ten-metre field keeps another account of a walk: a visited cell rises. Four possible directions are enough to change the ground. The working lattice has thirty-two cells on each side, despite the older name `random_walk_128`.

Look at a high place. It records repeated visits; it was not selected as a destination. A small rule has become a spatial obstacle through what the surface retained. Compare this ground with the trails in the instrument. Both keep something of movement, and neither keeps everything. The surrounding glass names a boundary of the experiment; the openings let you pass through or watch from outside.

''',
'Random_Remove': '''<!-- @random_removal_arena -->

Behind the board, the set becomes a floor. Ninety-nine cubes span a basin inside a glass frame. Pause on the dark edge before entering. That edge is permanent. The amber cells are not.

Entry asks for one removal. As you walk, each further sixty centimetres of accumulated horizontal movement can ask for another; a pending draw must finish first. One cell turns red for eight-tenths of a second. Then its mesh disappears and its collider is disabled. The gap is now something your body can fall through. Fire burns at the base of the basin.

The board hid a drawing while leaving its little slot plate. This version connects the same selection to support:

```gdscript
func _removed(index: int) -> void:
    colliders[index].set_deferred("disabled", true)
```

The draw chooses from the floor's remaining cells, not from the cube nearest your foot. Walking makes a choice happen; it does not tell the choice where to land. Try the permanent apron and look back. A disappearance becomes a fall only because the code also withdraws support.

REPLAY restores the cells and their colliders, and starts the same seeded order again. NEW SEED restores them with another order. Both controls stand together outside the entrance. Keep the distinction between the small board and the floor: here removal has acquired a consequence because another piece of code joined it to collision.

''',
}

GAME='''<!-- @random_removal_arena -->

The next glass enclosure carries the removal rule under your feet. Here there are eighty-one cells. Entering selects one; walking farther asks for more. Red gives a short warning, then both the visible cell and its support disappear. The basin below burns. The dark apron remains a route around the changing set, and the console outside the entrance can restore it. This is a deliberate return to Random Remove: the rule you inspected there now participates in a crossing.

<!-- @random_doors -->

Beyond it, three doors face you. Stay at the console behind the amber line and choose one. A door lifts. It might remain a passage. It might announce fire, wait one second, then send a short jet toward the line. Watch before moving forward.

One door is assigned passage at the beginning of the round:

```gdscript
rng.seed = run_seed
safe_door = rng.randi_range(0, 2)
```

The other two are assigned fire. Pressing a button reveals an existing choice; it does not redraw the outcome. A jet reaches 2.7 metres and then stops. That door closes again. The passage stays open until reset. There is always one passage in this construction, because we wrote that guarantee before drawing its index.

REPLAY restores the same assignment. NEW SEED makes another seeded round, which may choose the same passage. After looking once, your next attempt is different even when the doors are not. Memory belongs to the player as well as to the machine.

'''

def main():
 for name,addition in ADDITIONS.items():
  p=ROOT/'commons/maps'/name/'final.md';s=p.read_text(encoding='utf-8')
  marker=addition.splitlines()[0]
  if marker not in s: s=s.replace('<!-- @ -->',addition+'<!-- @ -->',1)
  if name=='Random_Remove':
   s=s.replace('Its controls stand to the right; a cased account of the set stands to the left, both turned toward the visitor.', 'Its controls sit together on the console in front; a cased account of the set stands to the left.')
   s=s.replace('The surface your feet stand on belongs to the museum; these disappearances make no holes in it.', 'At this board, the surface your feet stand on belongs to the museum; these small disappearances make no holes in it.')
  if name=='Random_Walk': s=s.replace('The wing beside the tank carries the logbook. ONE and ALL', 'The wing beside the tank carries the logbook; its buttons now share the front console with the mode controls. ONE and ALL')
  p.write_bytes(s.encode())
 p=ROOT/'commons/maps/Random_Game/final.md';s=p.read_text(encoding='utf-8')
 if '<!-- @random_doors -->' not in s: s=s.replace('<!-- @cube_projectile_spawner -->',GAME+'<!-- @cube_projectile_spawner -->',1)
 s=s.replace('Further into the hall, cubes arrive from above.', 'After the doors, cubes arrive from above.')
 p.write_bytes(s.encode())
 p=ROOT/'commons/maps/Random_Mushrooms/final.md';s=p.read_text(encoding='utf-8')
 if 'glass enclosure around the bed' not in s:
  s=s.replace('<!-- @mushrooms -->','<!-- @mushrooms -->\n\nThe glass enclosure around the bed makes a population into a place you can enter. Its front opening leaves room beside the specimen table; another opening is opposite. Begin at the compact console, then move among the mushrooms. The cage holds an experiment, not a claim that these bodies exhaust what a mushroom could be.',1)
 p.write_bytes(s.encode())
 # A short implementation note in each tutorial records precisely where staging lives.
 manifest=json.loads((ROOT/'doc/space/randomness-spatial-2026-09-16/manifest.json').read_text())
 bookpath=ROOT/'commons/data/book/randomness.json';book=json.loads(bookpath.read_text(encoding='utf-8-sig'))
 captions={'random_removal_arena':'Walk to trigger removal without replacement. Red warns before a cell loses its collider; a permanent apron and replay console remain.', 'random_doors':'One seeded door is a passage; two reveal timed fire jets. Replay restores the same assignment.'}
 for room in manifest:
  p=ROOT/'commons/maps'/room['map']/'tutorial.md';s=p.read_text(encoding='utf-8') if p.exists() else ''
  if 'Spatial staging — 16 September 2026' not in s:
   s+='\n\n## Spatial staging — 16 September 2026\n\nThe map keeps a reachable instrument alongside its spatial applications. `map_data.json` is authoritative for placements. `#controls:compact` gathers the existing Rack panels, preserving their callbacks, into an 80 cm console. `#glass_width` opts into an enclosure with open entrances; its grid marks are not floor colliders.\n'
   if room['map'] in ['Random_Remove','Random_Game']: s+='\n`random_removal_arena` uses the existing owned-set `RemoveRandom` algorithm and one collider per cell. Entry and accumulated walking request draws; a reset restores both drawings and support. The basin fire uses the museum death/respawn path.\n'
   p.write_bytes(s.encode())
  for pearl in book['pearls']:
   if pearl.get('map')!=room['map']: continue
   keys={line['token'] for line in pearl['lines']}
   for placement in room['placements']:
    key=placement['lookup']
    if key not in keys: pearl['lines'].append(dict(token=key,text=captions.get(key,key),by='spatial-staging-2026-09-16'))
 bookpath.write_bytes((json.dumps(book,ensure_ascii=False,indent=1)+'\n').encode())

if __name__=='__main__': main()
