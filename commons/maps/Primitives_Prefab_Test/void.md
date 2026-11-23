# Primitives_Prefab_Test — A Floor to Try the Hand On

*Reached from the Portals floor through the door PREFAB TEST; its own doors lead on to Melencolia or back. The floor's text (`void.md`), written 22 November 2026 from the floor as it stands.*

---

## 1. What this floor is for

Nothing is taught here. The floor is room: two taped grounds to build on, a board that says which button does what, and one block that shows what a wall is in this world.

## 2. The board

To the left of the arrival stands a board, **HOW THE MENU WORKS**. Six sticker notes: how to open the board (headset: right A or left Y; desktop: I), what its tabs hold, how to choose a thing (click the left stick; desktop: Tab), how to place it (trigger; desktop: F) and take it back (grip; desktop: X), how the belt works, and what stands on this floor.

Beside the notes hang four badges: **PICK**, **TRANSLATE**, **ROTATE**, **SCALE**. Each says what the verb does and how, and whether it is yours. Until a verb's coin is collected, a placed thing can only be placed and taken back.

## 3. Two grounds and two belts

In each wing a rectangle of tape, **TEST AREA A** and **TEST AREA B**, 6.6 by 13.6 m. In the middle of each stands a pile of twenty prefabs stuck into each other, drawn from the catalogue. Step over the tape and that pile clears: the ground is yours. The other pile stays until you step into its area too.

South of each area stands a **prefab belt**: four trays of the prefab timeline between two housings. The STEP keys move it one tray, the lever rolls it. Take a thing off its tray and it is in the hand.

This floor does not remember. What you place here stands while you play, and the next game starts without it. Everywhere else in the tower, what you build is kept.

## 4. The white block

In the middle of the floor stands a white block, ten metres on a side and 5.4 m tall. It is made of fifty-three wall slabs stood face to face, each 18 cm thick. There is no room inside it, and there is no collider anywhere in it.

A small pagoda stands half in its south wall, with a carpet running under it into the block and a sign: **WALK IN / this wall stops nobody**.

Inside, the eye is in a slab, then in a joint, then in the next slab. Each face it crosses cuts the view.

Hidden in the slabs are things from the catalogue, the same prefabs the belts carry, hidden five ways at once. A few stand four to six times their size, so a tyre is walked through for a dozen slabs. Crates and pallets are sheared and stretched. Boards and signs lie almost in a slab's face, a few degrees out of it, and rock by less than a degree, so the line where one leaves the slab runs metres while the eye moves centimetres. A tyre, a board and a pallet turn slowly. One small thing, a dice or a tin, is repeated in rows through the whole block, every other one mirrored and drawn inside out, and the rows drift by half a slab.

In here red is pink. The beach ball, the bowling pin, the warning triangle and the tin cans' bands are hot pink, while the same things stay red on the belts and the plinths outside.

Inside, the view is blurred. The blur begins at the face and is whole less than a metre in, and it lifts as you step out. The board's words and the hud stay sharp.

So every step cuts every hidden thing somewhere else, and each eye of a headset is shown a different cut. Measured while walking the carpet line 4 cm at a time, the view changes five times as much per step as it did with the seventy-two primitives that stood here first, and the two eyes disagree five times as much. Small things at their own size were the least strange, because they fall between two slabs and are missed.

Seeing a wall and being stopped by it are two things. Only one of them was built here.

## 5. The doors

Two doors stand to the right of the arrival: **ON TO MELENCOLIA** and **BACK TO PORTALS**. The door that leads here stands on the Portals floor, near its south-west corner.

## 6. Things on plinths

Fourteen prefabs stand on plinths round the two grounds. North of area A: a text tape, a black spray can, a cone, a tyre (the torus), a wooden box. Beside its belt: a rubber ball and a beach ball. North of area B: an oil drum, a gem, a dice, a cardboard box, a bowling pin. Beside its belt: a sticker pad and a graffiti pen.

Pick one up and it is in the hand; the example goes back on its plinth. The black can stays black in the hand, and the tape keeps its text, PREFAB TEST.

## 7. The edges

Round the block the edges are marked, not closed. Blue police barricades, **POLICE LINE DO NOT CROSS**, stand along the north edge, behind the arrival, and on the side of each shaft that faces the block. A few short white walls stand between them. Each stops a body. There are gaps between them wide enough to walk through, on purpose: safer is not safe.

A fall is not free any more. One floor down, the tower's own way, costs nothing. A body that falls past a floor is set down on the floor it missed, and its charge pays for it. Under this last floor nothing is left to catch a fall, and that costs the same.

---

*Checked by `tools/probes/prefab_test_floor.gd`: 34 checks, among them that stepping over the tape clears that area's pile and not the other, that a body 0.6 m wide and 1.8 m tall walks in under the pagoda and out of the far wall, that 95 % of that walk is inside a slab, that nothing hidden in the block is solid or reaches out of it, that no red is left in it, that the view inside is blurred and outside is not, that a barricade stops a body and a gap lets it through, and the round trip Portals, Prefab Test, Melencolia through the three doors. The fall rule has its own probe, `tools/probes/fall_past_a_floor.gd`. The ways of hiding things in the block were measured against each other by `tools/probes/white_block_glitch.gd`.*
