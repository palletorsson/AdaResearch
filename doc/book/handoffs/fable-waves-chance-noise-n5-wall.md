# N5 — Noise_6_Wall: six scales, and the one you are looking at (Fable, 12 September 2026)

Astra's card asked for the immersive interior kept but the entrance given a stable, readable sample panel; 1, 2, 4 and 6 layers compared under one seed, one coordinate frame, one contrast, one colour and one clock; an actual octave control or contribution views added to the shader, reusing frozen mode; basis kept as a separate comparison, with six walls not conflated with six isolated octaves; a clear entrance and an unobstructed margin; bounded shader cost; and material instances prevented from changing other halls.

## What was there

A room lined with a sum of six spatial scales, written `for (int i = 0; i < 6; i++)`. The room's own final proposed isolating an octave, and nothing in the room could isolate anything. The scene's wall and room `ShaderMaterial`s were shared resources, so a uniform set in one placement was set in all of them. Three separate things animated: the shader's clock, the colour cycling, the density breathing.

## What it is now

`shader_noise_space:180#stand:panel` at (9,2), with the room artifact at (6,6):

- **The loop's bound is a uniform.** `layers`, default 6 — the shipped picture. A second uniform, `show_term`, opens the accumulation on its own, without the turbulence and the colour the room paints over it. Both default to what shipped.
- **Four patches, one field.** 1, 2, 4 and 6 layers at one seed, one coordinate frame, one contrast, one colour and one clock. The probe reads all four materials back and fails if any parameter but `layers` differs.
- **The weights are declared, not normalised away.** 0.5, 0.75, 0.9375, 0.984375, printed on the plate. The left patch is darker, and that series is the whole of the difference. All four are shown at one display gain, stated on the plate too, because a comparison patch in a dark interior photographs black and an undeclared gain is a lie about a measurement.
- **A freeze that covers every animated term.** `animation`, `animation_enabled`, `color_cycling`, `cloud_density_animation`, and `time_scale` on the room's materials and on all four patches. Five facts, all checked.
- **BASIS is its own comparison.** It changes the generator and leaves the layer count alone; the probe presses it and checks the count does not move, and the plate names which was touched last.
- **Every instance its own materials**, duplicated with `resource_local_to_scene`, and the layer control scoped to the nearest ancestor that owns a hall — the same boundary Noise_Voxel needed a room earlier.

## Evidence

| lane | result |
|---|---|
| bare (`run_wcn_probe.sh wall`) | 35 checks, 0 failures |
| live (`run_wcn_probe.sh wall live`) | 40 checks, 0 failures, exit 0 |

## Two things the live lane found that no design pass would have

**A board across a corridor is a wall, and the museum said so in its own log.** The first staging put the board at (7,3), in the one-cell entrance corridor:

    [em-seal] shader_noise_space seals 2 cell(s) — the route is severed, and it stands where the map put it
    [em-walk] Noise_6_Wall: the walk was severed — reopened it (slid shader_noise_space by (2,-1))

The board is 2.02 m wide. It sealed the only route onward and the museum's reach repair slid the body two cells east and one north to reopen the walk — correctly, and invisibly to every text, all of which still said (7,3). `artifact_placement: "map"` was never the problem; the map's cell was refused because the board really would have blocked the hall.

It stands at (9,2) now, beside the path rather than across it, with a reading landing laid from holes at row 1 cols 8-10 and at (8,2) — before that, a reader stood over a hole, which is how the failure surfaced: the desktop rig fell, its eye dropped 16 cm between the aim and the click, and the second press's ray passed under the button. The probe now counts the button's emissions, so a press that changes nothing says whether it fired zero times or twice, and it checks the built position against the cell the map named, so a slide can never again be invisible.

**The room is larger than the hall it stands in.** Measured, not fixed: the scene's enclosure is 18.1 × 13.6 × 27.1 m and this hall is 13 cells across with 3 m walls, so its walls stand outside the hall's walls and its ceiling above the hall's ceiling. A visitor in the museum does not enter the cloud; they pass a board about it, and the room's whole visible contribution is a sphere of radius 0.5. The scene is placed in twelve maps, so resizing it is a decision for those twelve rather than something to slip into a panel pass. What changed instead is `final.md`, which said "stand inside it" and now says what is actually there — a wall text promising an interior nobody can enter is the worse error. **This is the open question for Palle and Astra: resize the enclosure to the hall, or let the hall be a room about a room.**

`stand:panel` also stopped dragging the enclosure behind the board. It used to place the whole scene and hang the board on it; the enclosure leaves the tree now, after `_setup_materials` has taken its references, so the staged body is a board. Removed rather than hidden, because an extent is measured from the tree.

## Not done, said plainly

- No headset walk, and nobody has stood at the board and pressed anything by hand.
- Shader compilation and frame cost are unmeasured beyond the runs completing. The room compiles and renders in both lanes; that is all this pass claims.
- Whether LAYERS visibly changes anything a visitor can see in this hall is unverified. The uniform provably reaches the room body's materials; the sphere that carries them is 1 m across and nobody has watched it.
- Shipped paths are untouched at `stand:none`: the other eleven placements build the interior they always built, six layers deep.
- Astra's review.

## Files

`algorithms/randomness/shadernoisespace/WallNoiseShader.gdshader`, `algorithms/randomness/shadernoisespace/noiseroom.gd`, `commons/maps/Noise_6_Wall/map_data.json`, `commons/maps/Noise_6_Wall/{final,summary,technical,tutorial,field_notes}.md`, `commons/testing/probe_wcn_wall.gd` and its live port, `tools/run_wcn_probe.sh` and `tools/port_wcn_probes_live.py` (the `wall` case), `tools/build_wcn_captures_page.py` (N5's views), and the captures page rebuilt and published. Forum: 260912-92g8g.
