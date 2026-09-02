# Trans_Scale — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## The pill

Palle: "the Alice scale me pill". `scale_me.gd` measured: on pickup it finds a
node named DarkSphere in the current scene (or the given world node, or its
parent) and tweens its scale ×100 over `scale_up_time` 5 s; it sets the
player's position to y = 5 with x and z multiplied by scale_amount/5 = 20;
after `scale_duration` 20 s it reverts over 5 s (auto_revert). The registry's
"rescales the world around the player" and the first draft's "the world
rescales around you" are not what the code does. The text now says the dark
sphere grows a hundred times and you are lifted five metres and carried
outward. **Flag:** x,z × 20 on the player's world position is a teleport far
outside a museum hall; in the grid map it is far outside the map. Worth fixing
before anyone takes the sphere in VR.

## Exactness decisions

- **Seven prisms, three cubes** (first draft said eight): prism_block at r8 c5,
  r11 c1, r11 c2, r12 c4, r13 c3, c4, c5; cube_scene at r10 c5, r11 c3, c4.
- **science_screen `#mode:bars` is not a mode**; falls back to the plain
  projection. The text describes that. Token should be corrected.
- **chair_assembly_puzzle**: model_scale 0.3 → final_scale 1.0, grow 1.5 s,
  grow_on_complete true.
- **clipboard** placed with `vr_scale_controls` config; "the scale controls on
  it" from the token.
- Volume ×8 at factor 2: probe item 7.

## Verified critique (2026-09-02) — APPLIED

A ten-agent panel (seven room critics, an arc reader, an exactness sweep, one
adversarial editor) judged this text against the primitives rooms and against the
artifact scripts. **12 findings survived the editor, 11 of them factually wrong.**
Twenty-two findings across the chapter were rejected as taste. Every finding below
was applied in the whole-chapter rewrite of 2026-09-02; the quotes are what the
text used to say.

The chapter-wide error: **a `pick_up_cube` cannot be carried.** No pickable, no
rigid body, no grab. An `Area3D` whose `body_entered` fires `collect()`, adds a
point, chirps and frees the cube. Its own header: "collected by walking into it."

The trap: **the `.tscn` overrides the `.gd` exports.** Reading `@export` defaults
without opening the scene produced wrong numbers twice in this chapter.

### [wrong] Take it, and the dark sphere across the hall grows a hundred times over five seconds, from something you could

**Problem.** Every number here comes from the script's export defaults, and the scene the map instantiates overrides all of them: scale_amount 10.0 and scale_up_time 2.0. The target sphere is 0.35 m in radius, so ten times is a 7 m ball, not the size of the building. And the player is not carried: the origin's global position is written once, instantly, at pickup and before the tween is created, to x and z doubled and y set to five. You are at the new viewpoint before anything starts growing.

**Fix.** Take it, and the sphere it finds grows ten times over two seconds. You do not travel with it. At the moment you close your hand the machine sets your height to five metres and doubles your distance from the room's origin, so you arrive at the new view before anything has started to move.

**Evidence.** Verified: scale_me.tscn:8 and :10 override scale_me.gd:15 and :17; scale_me.gd:118-126 writes the position before the tween at :129-132; dark_sphere.gd:453 gives sphere_radius 0.35.

### [wrong] Twenty seconds later it shrinks back over five, and so do you.

**Problem.** Three errors. The scene sets scale_duration to 1000.0, so the revert timer is a thousand seconds and nobody walking this hall will see it fire. It sets scale_down_time to 2.0, not five. And "and so do you" is contradicted in the plainest terms: the timeout reads the player's position, prints it, and deliberately leaves it alone under the comment "Don't move player when scaling down - let them stay at current position and fall". Only the world node is tweened.

**Fix.** It does not come back while you are here. The timer is set to a thousand seconds, and even when it fires it shrinks only the sphere, over two, and leaves you exactly where it put you.

**Evidence.** Verified: scale_me.tscn:9 and :11; scale_me.gd:174-187, comment and no-op at :178-181.

### [wrong] The screen projects what stands near it into a flat diagram, every thing reduced to its outline on a plane. Ta

**Problem.** None of this happens. The map token is #mode:bars, which is a real recognised mode: it labels the screen BAR CHART and locks the mode, and a locked mode makes the first scan return before any scan runs, so the screen never looks at what stands near it and can never draw an outline of anything. It then hunts for an artifact exposing _current_heights or _array; nothing in this hall has either, so it hits the branch commented "Demo: generate bars if no data" and fills the chart with twenty values from a fixed seed. The visitor is instructed to watch an event the code forbids.

**Fix.** A screen on the wall, and it is the one thing here that is not looking at the room. Its token locks it to a bar chart before it can scan, and nothing in this hall feeds a bar chart, so it draws twenty bars from a fixed seed. Take the sphere and it will not notice. A measuring instrument that has been told what to measure is not measuring.

**Evidence.** Verified: map token science_screen:180:1.5#mode:bars; science_screen.gd:446-449 and :453 (bars sets _generic_mode and locks), :466-477 (locked skips the scan), :521-528 (hunts _current_heights or _array), :2786-2791 (rng.seed 12345, twenty bars).

### [wrong] Move, turn and scale the parts into the ghosts, and when the last one aligns the whole chair grows to full siz

**Problem.** Nothing grows. _grow_to_final_size contains no tween: it frees every assembled piece and every spare cube, instantiates the premade wooden_chair_reward.tscn, drops it at the centre of where the pieces stood and sets its scale to reward_scale, which the scene fixes at 1.2. The exports the sentence is built on, model_scale, final_scale and grow_duration, are declared and never read anywhere in the file.

**Fix.** Move, turn and scale the cubes into the ghosts, and when the sixth one lands the puzzle does something stranger than finishing. Every cube you placed is deleted, and a solid wooden chair appears where they were, a fifth larger than the ghosts you were matching. You did not build that chair. You proved it could be built, and the room took the proof and handed you the object.

**Evidence.** Verified: furniture_assembly_puzzle.gd:388-445, with the frees at :410-418, the instantiate at :417-418 and scale set at :439; grow_duration, model_scale and final_scale declared at :74-77 and read nowhere; chair_assembly_puzzle.tscn sets reward_scale 1.2.

### [wrong] Parts of a chair at a third of their size, and ghost guides showing where each should go.

**Problem.** There are no chair parts. _spawn_pieces instantiates copies of one scene, grab_cube_scalable.tscn, six for the targets and four spares because extra_pieces is 4, every one an identical cube set to scale 0.1, not a third. The whole argument of the artifact is that the pieces are undifferentiated cubes, and calling them parts of a chair gives the puzzle its answer away in the first clause.

**Fix.** Ten identical cubes on a bench, each shrunk to a tenth, and six cyan ghosts standing at full size where a seat, four legs and a back should go. Six of the cubes have a ghost waiting for them and four are spares.

**Evidence.** Verified: furniture_assembly_puzzle.gd:293-320 (one piece_scene, piece.scale = Vector3.ONE * 0.1); chair_assembly_puzzle.tscn sets piece_scene to grab_cube_scalable.tscn and extra_pieces to 4.

### [wrong] A document you have to hold to read, with the scale controls on it. Reading it is an interaction, and the cont

**Problem.** The first clause is the registry's description, not the code's behaviour: clipboard.gd reveals the page purely by camera distance, fading in between 2.0 and 1.5 metres, with no reference to whether it is held. Holding only matters for turning pages. The second clause is worse: there are no controls on the clipboard. The token loads the page vr_scale_controls, which is an ASCII drawing of the right-hand controller with one button labelled "B = Cycle Scale" and a line saying scale snaps to fixed sizes. The same token also sets uniform scale 0.5, so the card is placed at half size, which the room never uses and should.

**Fix.** A clipboard at half size, turned to face you. Walk within a metre and a half and the page fades up: a drawing of the right-hand controller with one button marked, and a line saying that scale snaps to fixed sizes. It is the only writing in the hall, and it is printed at half the size of the thing it describes.

**Evidence.** Verified: clipboard.gd:51-52 and :62-77 (distance-driven reveal only); commons/context/clipboard/tutorial_text/vr_scale_controls.gd; the token clipboard:0:0#vr_scale_controls:180:0:0.5 parses through the shorthand branch to uniform_scale 0.5.

### [wrong] Seven triangular prisms and three cubes, laid out in a row like a scale bar, all the same family and all at on

**Problem.** The count is right and "all at one size" is right, but there is no row. The ten pieces occupy five different rows and five different columns across the far chamber, with a single prism left behind on the near side of the low wall that crosses the hall at row 10. "Laid out in a row like a scale bar" is the arrangement the paragraph needs, not the one the map has, and it is the one claim in the room a visitor can falsify by standing still and looking. The prism region is also empty: every sentence about the prisms sits inside the cube region.

**Fix.** Split the two regions. Under @prism_block: "Seven triangular prisms, every one a metre on a side, scattered across the floor of the far chamber, with a single one left behind on the near side of the low wall that crosses the hall." Under @cube_scene: "Three cubes among them, the same metre, seated two-tenths higher off the floor. They are the comparison. Without them the hall is a room, and with them it is a room of a known size, and when the sphere changes you it is against these that you know it."

**Evidence.** Verified from the parsed structure and interactables: prisms at rows 8, 11 (twice), 12, 13 (three times); cubes at rows 10, 11 (twice); structure row 10 is height 2 at columns 1 to 4 and floor at 5 and 6, so it is a low wall with a gap, not a full divider. I softened the critic's "stranded" and "solid" accordingly.

### [wrong] turn a prism or grow it and a different face dominates, so aspect and orientation are readable in a way a box

**Problem.** This is the registry description transcribed, and the scaling half is false. Uniform scaling changes no face's share of the silhouette at all, which is the point the room makes twenty lines earlier with the ruler. Only rotation, or a non-uniform scale, redistributes the faces, and nothing in this hall rotates or non-uniformly scales a prism: all seven carry the same 90.

**Fix.** turn a prism and a different face takes the light, which is a thing a cube will never show you

**Evidence.** Verified: all seven prism tokens in Trans_Scale/map_data.json are prism_block:90:0, and the registry's prism_block description is the source of the wording. The room contradicts itself otherwise.

### [wrong] When your body is the thing being scaled, what you notice is not that anything got bigger.

**Problem.** Nothing in this hall scales your body. The XR origin's scale is never written anywhere in scale_me.gd; the only thing done to the player is a single write to global_position at pickup. The room's closing paragraph rests its conclusion on an experience the hall does not provide, and it does not need to, because the displacement it does provide makes the same point.

**Fix.** Nothing here scales you. The pill moves you instead, and moving you is enough: from five metres up and twice as far out, the room is the same shape and none of it is the size it was.

**Evidence.** Verified: scale_me.gd:118-126 writes global_position only, and :174-205 writes nothing at all to the origin. There is no scale assignment on the XR origin in the file.

### [wrong] the world is full of things that break when their weight grows eight times faster than their bones

**Problem.** The arithmetic the sentence has just stated correctly is then reported wrongly. At factor two, volume and so weight go up eight times while the load-bearing cross-section, an area, goes up four. Weight outruns strength by two, not by eight. The square-cube law is the one piece of real physics in the room and the number is wrong by a factor of four.

**Fix.** and a body at double the size is eight times heavier standing on four times the bone, which is why nothing shaped like a mouse is ever the size of a horse

**Evidence.** The error is internal to final.md line 10, which states "areas as its square, volumes as its cube" in the immediately preceding clause and then divides them wrongly.

### [wrong] The dark sphere, at its one size. When you have changed, it is the thing that has not.

**Problem.** The room has already told the visitor, twenty lines above, that the pill grows this sphere. Both cannot be true, and with the revert timer at a thousand seconds it would keep any new size for the rest of the visit. The room's most quotable closing beat is built on a contradiction with its own opening one.

**Fix.** The dark sphere, where the prisms end. It turns on itself the whole time you are here and never leaves its cell, and it is the one thing in this hall the pill goes looking for.

**Evidence.** Verified: scale_me.gd:67 searches the running scene for a node named DarkSphere, and dark_sphere.tscn's root carries that name. I deliberately wrote "goes looking for" rather than "is the pill's target", because of the resolution race described in the next finding.

### [weak] What has changed is the comparison, and that is enough to make the same hall intimate, then monumental, withou

**Problem.** "Without a wall moving" is the room's best claim and the code does not guarantee it. scale_me resolves its target inside _ready, by searching the live scene for a node named DarkSphere. Interactables are placed in ascending row order and added to a parent already in the tree, so _ready fires at placement: scale_me is at row 8 and dark_sphere at row 13, meaning the search runs five rows before the sphere exists. The fallback is _world_node = get_parent(), which is the grid parent that also holds GridMultiMesh and GridCollisions. On that path the pill scales the entire map, walls included.

**Fix.** Cut "without a wall moving". Leave the sentence at "What has changed is the comparison, and that is enough to make the same hall intimate, then monumental." Restore the clause only if someone walks the hall and confirms the pill takes hold of the sphere and not the grid.

**Evidence.** I verified every link: scale_me.gd:29-40, :67, :75; GridInteractablesComponent.gd:588 iterates z ascending and :1294 adds the artifact to parent_node, which is the same node GridStructureComponent.gd:82-90 hangs GridMultiMesh and GridCollisions from. This is a claim the prose should not make from a desk. Note that Trans_Introduction is the other way round, sphere at row 7 and pill at row 12, so there the search succeeds.
