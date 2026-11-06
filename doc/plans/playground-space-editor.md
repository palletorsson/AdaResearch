# The space editor and the vending machines

Palle, 2026-11-06: *"We need to simplify the playground editor; it is not working in its current form. Remove the
editor table for now. Instead use the glass box 3d space as the editing space. When we enter (remove the blocking of
the wall) we can add nodes edge to a grid that is visible in the space. Make the space non blocking for editing so we
can walk around and the floor plane at one meter, it is a bit holographic. What is a good way to add the select tool
in this case, should we use the hand menu, it must be separated or integrated in the inventory principal, make it as
simple as possible. We take on the vr glasses and we enter the space as the space. 2. We also need to attend to the
relation between prefab objects and how they are. We should have one interface to pick up the prefabs and it should
look like a vending machine with just holographic items or items. Look at the tape examples when we pick a tape that
config should be the one we use. We should have another vending machine for the planks and measuring rod etc."*

Design, not yet built. Companion to [playground-stack.md](playground-stack.md) (the one record, the node editor,
the built look) and the forum thread on the three playground grids (261106-godli).

## What exists, and what each part is for

| Part | Where | Keep? |
|---|---|---|
| The record: integer addresses x a step; the grammar (`add`, `candidates`, dependencies, `fit_record`) | `scaffold_workstation/model.gd`, `contract.gd`, `geometry.gd` | **keep** - it is the thing being edited |
| The table: worktop, the 0.74 m pad with the 0.2 m grid, the parts arc of tools, the two console housings, BUILD / UNDO / DROP TEST, the discard basket | `workstation.gd::_ready`, `shop_furniture.gd::table`, `parts_arc.gd` | **remove for now** |
| The glass box: 6.6 m chamber at quarter scale (1.65 m), metre lattice on its base, four panes **with colliders**, closed since 30 Oct | `display.gd`, `shop_furniture.gd::glass_cube` | **becomes the editor** |
| The visor: wear it, the visitor shrinks to 1/4 and stands inside the box at 1:1 | `model_visit.gd`, `model_headset.gd` | **keep** - "we take on the vr glasses and we enter the space as the space" |
| The Output bay: BUILD 1:1 copies the model full size beside the station | `workstation.gd::build_copy` | out of the way for now (the visor is the way in) |
| The kit node editor: a piece in the hand, the trigger fires at the nodes of a 6 x 4 x 6 box of dots; a rod is two hits; the first shot sets the box down; grip takes a piece back | `commons/player/kit_node_editor.gd` (the-unit, today) | **the grammar of adding**, reused |
| The belt: thumbstick click steps through the empty hand and every item collected; picking up an association example collects it (`InventoryHand.collect`) | `commons/player/inventory_hand.gd` | **keep** - it is the inventory principle |
| The prefab board: the earned AND assembly, placed as a session copy (desktop I) | `commons/void/prefab_inventory.gd`, `inventory_board.gd` | folds into the prefab machine later (forum 261104-99fhx) |

The stations stand on floors 1, 3, 5, 6, 7 (tiers: points, rods, surfaces, solids, quads, at 1:10 on the table) and
on floor 20 (the display edition with the glass box and the visor) and 39.

## 1. The space editor

**The box is the space.** The glass chamber stays where the Output bay was, but it is the whole station now: no
table, no arc, no buttons. Its base plane stands at **1.0 m** over the slab - hand height, where the table's grid
was - and is drawn as the holographic metre lattice it already has (`glass_cube` draws it), with the edit nodes as
dots over it in the kit editor's look. The four panes keep their glass but **lose their colliders** (`Kit.box(...,
collision=false)`); the base is a hologram, not a floor. A visitor walks through the box, reaches into it from any
side, and sees the model from above as well. The chamber's corner posts stay, so the box reads as a room.

**Scale.** The box is the quarter-scale copy, so one world step (2 m) is 0.5 m in the box and the 6.6 m chamber
holds 3 x 3 steps - too few. Two choices, Palle's to make: (a) keep quarter scale and widen the chamber to the
domain (the 8 m rod question is open on the forum); (b) **half scale** (`model_scale` 0.5): the 6 m domain is a 3 m
box with 1 m nodes, the hand's own metre, and the visor enters at 1/2 body size. I would start with (b): the grid in
the box is then the same metre grid the hand kit uses, which is the harmonisation the-unit asked for.

**Adding = the node editor's grammar, on the workstation's record.** A piece in the hand (from the machine, below);
the trigger fires at a node for a point, at two nodes for a rod or an edge, at three or four for a face; the
workstation's `model.add(candidate, tier)` says yes or no (its contract: legal grammar, dependencies, the tier). The
piece is drawn holographic in the box at the box's scale. Nothing is built 1:1 until the visor: wearing it, the
visitor is inside the model at 1:1 (`model_visit` does this today), so "BUILD" is the act of entering.

**Select = the empty hand.** Not a menu, not a tool. The recommendation, and why:

- The hand has one principle already: *what you hold decides what the trigger does*. A held piece adds. The
  worn rubber erases. The **empty hand selects**: pointing at a placed piece lights it; the trigger takes it into
  the hand (it is now a held piece; fire at nodes to put it back, as the-unit's editor already does for the kit on
  grip); grip lets go. The thumbstick click, which already walks the belt, is the only "menu" and it exists.
- A hand menu (a radial on the wrist with select / move / delete) is a second grammar to learn and duplicates the
  belt. The workstation tried "touch is the tool" on 31 Oct (the bare hand on a socket paints the kind, the rubber
  erases); this is the same rule carried into the space.
- Desktop: click = trigger, right click = grip, the belt on the wheel, as the wand does now.

**What is foreclosed.** The parts arc let a visitor see every kind at once; the belt shows one at a time. The
vending machine (below) takes that job - all the kinds on its shelves, in the room.

## 2. The vending machines

**One interface for prefabs.** A cabinet with a glass front and shelves (the picture's machine E: the one with the
rows of cans). Every shelf slot holds a **holographic miniature** of one item - the hand's own miniature maker
(`InventoryHand` makes one from the item's scene, inert, scaled to its longest side) - and under it the **tape
line**: `rubber_ball = association(config(point))`, the words the association tape writes in the hall where the
form was first met. The config the slot hands over **is the tape's**: the item's `defaults` in
`commons/data/inventory/items.json`, which are the term's config in `commons/modular/terms.json`. Pointing at a slot
and pulling the trigger (or touching it) calls `hand.collect(id)`: the item is on the belt and in the hand with
that config, exactly as picking up the example in the hall does. The slot stays lit; a machine never runs out. The
shelves show what the floor has unlocked (`Items.unlocked`), the rest dark.

**A second machine for the tools:** the tape roll, the rubber, the pin, the test weight, the measuring stick, the
planks (1 m and 2 m), the clock. Same cabinet, a poster face instead of shelves if the picture's F or G is wanted (the
poster is where the tool's line prints), a tray below where the thing appears.

**The picture.** Yes - the five machines came through. E (glass front, cans on rows) is the prefab machine; F and G
(a screen with a poster, a keypad, a tray) are the tool machine. There is no vending-machine model in the repo
(`assets/models` holds the IK arm only), so the cabinets would be built the way the Void builds its furniture
(`shop_furniture.gd` boxes and tubes), unless you have the pack - then its glb goes in `assets/models` and the
artifact loads it.

**Where they stand.** One pair beside every station (floors 1, 3, 5, 6, 7, 20), the prefab machine stocked by the
floor's unlocks. The earned prefabs (the AND assembly) become one more slot on the prefab machine, which answers the
board question without a third list.

## The plan, in order

1. **The vending machine** (additive, new files only): `commons/artifacts/vending_machine/` with `kind: prefabs |
   tools` as config, registry `vending_machine.json`, two placements on floor 20 beside the station; a bench probe
   (point, trigger, the item is on the belt with the tape's config; the shelves follow the floor's unlocks) and a
   tower check. Half a day.
2. **The space editor pilot on floor 20**, the display edition: table, arc, buttons and the 1:1 bay off; the box at
   1 m, panes without colliders; the kit editor's firing on the workstation's record; the empty hand selects; the
   visor unchanged. `workstation.gd` / `display.gd` are Codex's untracked files - heads-up on the forum first, the
   edits additive (a `space` flag in config; the old editions build as before without it). A day.
3. **Floors 1, 3, 5, 6, 7 follow** with `space: true` once floor 20 reads well in the headset, and the prefab board
   joins the machine.
4. **Quest export** after 2.

Not in this plan: changing the record (261106-godli), the web editor, the Output bay's 1:1 build (kept in the code,
no button).

## Step 1, built (2026-11-06): the two machines on floor 20

`commons/artifacts/vending_machine/vending_machine.gd` (+ `.tscn`, registry `vending_machine.json`; config `kind
prefabs|tools`, `columns`, `mini`, `title`). The cabinet is built from boxes (no pack in the repo): a dark body, a lit
interior, shelves with a pale lip, a glass front **without a collider**, one collider that leaves the front 22 cm free
for the hands, a name plate. The stock is `items.json`: eight tools (tape, rubber, pin, test weight, measuring stick,
the two planks, the clock) in one machine and the other 42 items in the other.

A slot is three things:
- **the miniature, in its own colours** (Palle: "normal color") - the item's own scene with the label's config
  (`Items.config_for(it, knobs)`: the defaults, which are the term's config, and the configuration's knobs over them),
  made inert the hand's way, on a slow turntable; a kit ball or rod keeps its own meshes hidden (the kit draws them by
  multimesh), so a miniature without a visible mesh shows them; a locked one is dimmed to a shade;
- **the tape label** on the shelf's lip: the name, the configuration (`printed (words), hazard`), the association
  line `rubber_ball = association(config(point))` (from `terms.json`), and for a locked item its floor;
- **the pick**: an invisible XR Tools pickable shell, frozen on the shelf. Grabbed (an XR hand, the desktop grab), it
  sets the slot's knobs on every `inventory_hands` node (`set_knob_for`), collects - `Items.collect`, `collect(id)`,
  the game's notice - and goes straight back to its local home. The association plinth's pattern, unchanged.

**All the configurations of tape** (Palle, same day): an item can stand in every configuration, one slot each. The
machine's `VARIANTS` table (and the config `variants`, JSON) lists them; the tape has nine - printed plain, printed in
each of its five designs (hazard, survey, blueprint, chevron, dotted), masking, pink, barrier - so the tool machine
shows 16 slots for its eight items. Taking the masking tape puts the tape on the belt with `kind: masking` set on the
hand, so what is laid is what was taken.

An item marked `collect` is unlocked in the machine (the machine is its plinth); floor and sequence gates still apply,
locked slots show dark.

Measured: `commons/testing/probe_vending_machine.tscn` 11/11 (a scene, since a `--script` probe cannot compile XR
pickables): 42 + 16 slots, 58 shells, 58 miniatures with meshes and no shade on an unlocked one, the rubber ball's line
and the tapes' configuration lines, the grab collects and the shell returns to 0.000 m, the masking tape's grab sets
`tape.kind = masking` on the hand, the glass free. `tools/test_vending_machine.py --beside-play` on floor 20: 10/10, both machines
on the slab, inside the edges, cutting into no other work's box (prefabs 1.68 x 2.46 m at (-12.6, 7.9); tools 1.20 x
1.90 m at (-7.4, 7.9), both facing the station's table). Pictures: `ada_run/vending/bench.png`,
`ada_run/vending/tower/floor20_*.png`.

`rooms.json` carried CRLF line endings by the afternoon (another session's save), so the two rows went in as text;
`json.dumps` of the whole file no longer round-trips it. Nothing committed.

## Step 2, built (2026-11-06, Palle: "go"): the space editor pilot on floor 20

Behind `space: true` in the display workstation's config (`rooms.json` floor 20, `scaffold-workstation`); every other
edition builds as before without it. `display.gd` (`_enter_space`, `_redraw_space`, the `space_*` API) and a nine-line
hook in `inventory_wand.gd` (`_space_editor`: a node in group `space_editors` whose `space_active(hand, aim)` is true
takes the wand's update, press and grip before the kit node editor).

- **The box is the station.** The table, the parts arc, the control plate, the basket and the hand model are dark;
  the visor's dock stays. The glass box stands **on the slab** (Palle, same evening: "the player has a floor in the
  editing space that is on one meter but lets put the glass cube back on floor for now"); inside it a holographic
  **player's floor at 1 m**, where the construction's ground also lies, so the hall visitor reaches in at hand height
  and the visor arrives standing on it. The panes have no colliders; the player floor's collider is on only during
  the visit.
- **Half scale.** `model_scale` and `visitor_scale` 0.5: one address is 1 m in the box, the visor enters at half
  body size. The construction is drawn live in the box on every change: no BUILD button.
- **Adding.** A kit ball from the vending machine is a point, a kit rod a rod (two units: the long rod); the lit
  sockets are the record's own candidates (`model.candidates`), the trigger fires at the one under the aim line
  (within 22 cm), `model.add` decides. The ghost shows the piece before the pull.
- **Select = the empty hand.** Pointing at a placed piece lights it amber; the trigger takes it out of the record
  and into the hand (`set_current`); firing it at a socket puts it back. The worn rubber erases it instead.
- **The Void applies the editor's parts after `_ready`**: a position set in `_ready` is overwritten when the
  Output part's position arrives (caught by the tower check the first time round, when the whole box was raised).

Measured: `commons/testing/probe_space_editor.tscn` 6/6 (cube at 0.00 m, player floor at 1.00 m, 0 pane colliders, a point fired, a rod
fired, the rod taken back into the hand, aimed away not claimed, visor docked and the construction counted as
built). `tools/test_space_editor.py --beside-play` floor 20: 6/6, 12 sockets lit, photographs
`ada_run/space-editor/tower/floor20_space_*.png`. Not yet: a brace (no diagonal in the record), panels and quads from
the hand (the machine sells no face), the real hand on the headset. Floors 1, 3, 5, 6, 7 untouched (step 3).

## Step 3, built (2026-11-06, Palle: "do the same on floors 1, 3, 5, 6 and 7")

The five stations keep their tiers (points 0, rods 1, surfaces 2, solids 2 with prefabs, quads 3) and become display
editions in space mode: `rooms.json` rows `scaffold-workstation` on floors 1, 3, 5, 6, 7 now carry `artifact:
scaffold_workstation_display` with config `space: true`, `tier: N`, `chamber_height: 5.4` (the ordinary storey is
5.64 m; floor 20 keeps its 6.6) and `space_from: <the old token>` for the record. The five editions differed from the
display one only by `tier` and `prefabs_enabled`, so nothing of the record or the grammar changes; the box stands
where each 1:1 output bay stood (same 6.6 m footprint). `display.gd` reads `config_chamber_height` on entering space
mode. Tower check `python tools/test_space_editor.py --beside-play --floors=1,3,5,6,7,20`: 36/36 (each cube on the
slab, player floor at 1.00 m, top under the ceiling where it must be, panes free, 12 sockets lit, visor docked).
Pictures `ada_run/space-editor/tower/floorNN_space_*.png`.

## Step 4 (2026-11-06, Palle: "add the vending machines on floors 1, 3, 5, 6 and 7")

A PREFABS and a TOOLS machine beside every space editor, on the hall side of its cube with the fronts toward it:
floors 1, 5 and 7 on the south strip at (-12.6, 7.9) and (-7.4, 7.9) facing 180, floor 3 at (-14.0, 7.9) and (-6.2, 7.9) so they flank the museum's DO NOT CROSS tape at (-9.75, 7.25) instead of standing behind it (the station on 5 and 7 faces 90,
so its cube also stands at (-10, 0)); floor 6 at (7.0, 7.9) and (12.2, 7.9). `rooms.json` rows `vending-prefabs` /
`vending-tools` as on floor 20. The tower check (`tools/test_vending_machine.py --floors=1,3,5,6,7`) tests cuts
against a work area's PARTS, not its merged box - the triangle floor's `surfaces` group spans most of the slab as a
box and has free floor between its parts. A first try east of the cube on 5 and 7 cut the arrival and hall works. The cut check also skips laser works (`void_source` contains "laser": a diagonal beam boxes most of the floor) and beam-shaped boxes. 60/60 on floors 1, 3, 5, 6, 7.

## Inside on the visor, and what can be built (2026-11-06)

Palle: *"when entering the glass box vr space how do I add node edge etc I did not see any possibilities"*. Two
causes: `space_active` returned false while the visit was on (the editor was switched off inside), and an empty hand
lit no sockets with nothing saying why. Both fixed: the editor works inside on the visor exactly as from the hall, and
a guide board (`SpaceGuide`, billboard over the box) says what to hold, what the trigger does, and - its last line,
updated each frame - what is in the hand now. Bench probe check G: inside on the visor a ball fires and places.

**The gallery** (`commons/testing/probe_space_gallery.tscn`, Palle: *"show me all possibilities in images, build some
good playgrounds"*): seven playgrounds assembled piece by piece through `model.add`, every piece accepted -
a catalogue of every kind, a 2 m climbing frame with a deck and a lookout, a bridge between two towers, a pavilion
under the 4 m plate (its far posts reached by long rods), a screen and roof of half faces, a garden of wedges and
pyramids with a climbing post, a stair tower beside a half-metre cage. Pictures from the hall and from inside at
visitor size: `ada_run/space-gallery/contact_sheet.png` and the fourteen frames beside it.

What the gallery taught about the grammar, for the visitor: a ball needs a neighbour one step or half a step away, so
a far corner is reached by a long rod (it lays a ball every metre) or by growing a line of balls; a face needs its four
(or three) edges first; solids stand in a 1 x 0.5 x 1 envelope and stack. The build volume is 3 m a side plus half
steps, and the box is mostly air around it.

## The interface, state by state (2026-11-06, Palle: "show me the interface of the editor")

`commons/testing/probe_space_interface.tscn` photographs what a visitor sees, sheet at
`ada_run/space-interface/interface_sheet.png`: arriving between the machines with the box and its guide board ahead;
the machines themselves; the guide board close; a ball in the hand (lit dots, the ghost ball, the ray); a rod in the
hand (the ghost rod between two balls); the empty hand on a piece (amber); the rubber on a piece (red); inside on the
visor at half size. Fixed while shooting: **the hand's ray** - the wand hides its own line while the box has the aim,
and nothing replaced it, so the editor now draws a 6 mm rod from the controller to the socket or piece it would fill or
take (amber, orange, red; pale along the aim when nothing is under it); and **the guide board** is dark ink on a pale
outline, readable against the glass.

## The jumbotron editor (Palle, 2026-11-06: "build it")

Palle, after playing: he built with the hand's own node editor (a ball or rod from the menu, the pink first node) and
liked it; the glass box gave him no way in ("I did not find out how to edit them"). His direction:

- **Edit at zero.** The playground is built on the floor of the box, not on a raised floor.
- **A strict progression per floor.** Point floor: balls only. Point Lines: balls and edges. Triangle floor:
  triangles and quads. Full quads open a chosen set of things to place on them (health, danger, then more) - not every
  artifact. An icon for each thing allowed at that level.
- **Two menus.** One for building the playground; one for adding things to the general environment.
- **The jumbotron** (Palle: "a jumbotron monitor editor menu that shows the option on each screen in the ceiling of the
  glass. We click pick and can add the element"): a four-faced screen drum hung from the box ceiling, faces tilted
  down, the same tiles on every face - one per element allowed on this floor, later ones dark with the floor that
  opens them, plus the rubber. Ray + trigger on a tile picks the tool; ray + trigger into the space places it.
- **Entering the box hides the hand menu** (prism, belt and the hand's node editor); leaving restores it. Inside:
  the jumbotron builds the playground. Outside: the hand menu and the vending machines place things in the environment.
- **The grid is always on** (Palle: "the playground editor always have a grid on"): the floor lattice at zero and a
  faint dot at every node of the build volume whatever the hand holds; the nodes the current tool can fill lit
  brighter; the ghost and the ray on the one under the aim.

One table per floor drives both the jumbotron's tiles and what the editor accepts. The record's own four steps
(points, rods, half faces, quads) are the progression's first four. Open: keep the visor (half-size view) or drop it
and build at full scale; the first floor to pilot (proposed: Point Lines, floor 3).

### Built (same evening)

`display.gd`'s space section is now the playground editor; `commons/data/inventory/space_editor.json` is the table
(BALL 0, EDGE 3, TRIANGLE + QUAD + HEALTH + DANGER 5, WEDGE + PYRAMID 6, BOX + CRATE 7, PLANK 20). Each station row
carries `space_floor` (1, 3, 5, 6, 7, 20).

- **Full scale on the floor at zero**: one address 2 m, a half address 1 m (the hand's metre); the box's base is the
  floor; the visor dock is dark (the visit code stays).
- **The jumbotron**: four screens tilted down, meeting at the corners (closer in, a screen's outer tiles stood in front
  of its neighbour's and the aim picked the wrong tool), five tiles across; SELECT, RUBBER, then the table's tools with
  their icons (the record at icon size, an item's own miniature); dark with "FLOOR n" until opened. Builds and grid dots
  stay below the drum where they stand under it.
- **The grid always on**: 343 node dots (fewer under the drum and on 5.4 m storeys); the nodes the tool can fill lit.
- **Tools**: a tile is picked by ray + trigger; the space by ray + trigger; an item only onto a finished horizontal
  quad, one per quad (they live in `user://void_space_items_<floor>.json`); SELECT takes a piece back and its kind
  becomes the tool; RUBBER erases; GRIP puts the tool down (SELECT).
- **Inside / outside**: the player body inside the box footprint = inside. `inventory_prism.gd` hides the prism and
  ignores the belt (`in_space_editor()`), routes grip to the wand; `inventory_desktop.gd` ignores Tab inside; the wand
  hook routes trigger/grip/update to the box. Outside, everything is as before.
- **A shared blueprint**: one construction across all stations (the workstation's design); a station shows only the
  kinds its floor has opened.

Measured: `probe_space_editor.tscn` 8/8 (box at 0, grid 343 dots, jumbotron 52 tiles, outside/inside, pick, ball /
edge / quad, health once per quad, select, a locked tile refused with its floor). `probe_space_interface.tscn`: eight
states, sheet `ada_run/space-interface/interface_sheet.png`. Tower check on floors 1, 3, 5, 6, 7, 20 (see the run).
Known: on floor 5 the floor's own folded-triangle work stands partly inside the box (as it did beside the old output
bay); the boxes on floors 1, 3, 5, 7 stand over shaft A, as the stations' output bays always did.

