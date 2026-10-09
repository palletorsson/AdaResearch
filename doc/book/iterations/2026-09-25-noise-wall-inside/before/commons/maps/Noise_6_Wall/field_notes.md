# Noise_6_Wall — field notes

## 2026-09-12 — N5: which layer of a surface are you attending to (Fable, the fifth hall of Astra's noise arc, after Noise_Voxel; Astra's card: "keep the immersive interior but give the entrance a stable, readable sample panel; compare 1, 2, 4 and 6 layers under fixed seed/coordinates, contrast, colour and time; add an actual octave control or contribution views to the shader, reusing frozen mode; keep basis changes as a separate comparison and do not conflate six walls with six isolated octaves; stage the room with a clear entrance/exit and an unobstructed margin; use bounded shader cost and prevent material instances from changing other halls")

**The ruling.** The room is lined with a sum of six spatial scales and the loop that makes it was written `for (int i = 0; i < 6; i++)`. The existing final proposed isolating an octave and nothing in the room could do it. So the bound is a uniform now (`layers`, default 6 — the shipped picture), a second uniform (`show_term`, default 0) opens the accumulation on its own without the turbulence and the colour the room paints over it, and the entrance carries a board with four patches at 1, 2, 4 and 6 layers of one field, one seed, one coordinate frame, one contrast and one clock.

**The weights are declared rather than normalised away.** Each term is half the amplitude and twice the frequency of the one before, so one layer carries 0.5 of the weight and six carry 0.984375. The left patch IS darker, and that is the whole of the difference. Renormalising the four to look equally bright would have hidden the only thing the comparison is about, so the plate prints the series instead. All four are shown at one display gain (2.0), stated on the plate too, because a comparison patch in a dark interior photographs black and a gain nobody declares is a lie about a measurement.

**A freeze that covers every animated term.** Astra's card asks for exactly this and the room had three separate movers: the shader's own clock (`time_scale`), the colour cycling and the density breathing. FREEZE sets the room's `animation` to frozen, disables all three, and zeroes `time_scale` on the walls AND on every patch. The probe checks all five facts, because "a material parameter at zero" was the failure mode named in the card.

**Basis is kept as its own comparison.** LAYERS changes how many terms are summed; BASIS changes the generator underneath (simplex, perlin, value, cellular) and leaves the count alone. The probe presses BASIS and checks the layer count does not move, and the plate names which was touched last. Six walls and six octaves are not the same six.

**Every instance gets its own materials.** The scene's wall and room `ShaderMaterial`s were shared resources: every placement of this room pointed at the same ones, so a uniform set in one hall was set in all of them. They are duplicated per instance now (`resource_local_to_scene`), which changes no pixel and stops the leak. The layer control is scoped the same way as the broadcast in Noise_Voxel a room earlier — the nearest ancestor that owns a hall is the boundary, and the reach is recorded.

**The panel stands at the entrance, not in a doorway.** The token is at (7,3), in the corridor a visitor walks in through, with the immersive room left where it was at (6,6). The probe reads the museum's own tile for both door rows and checks the panel is in neither. The map had no museum block at all before this pass; it has wall height, gate depth, the map's placement authority and one clear rect now.

**Exactness decisions.** Four patches rather than six: 1, 2, 4 and 6 show the doubling without a row of near-identical squares. The patches show the accumulation alone rather than the room's full mix, so the turbulence term (four octaves of its own) cannot muddy a comparison that is about the cloud term. The board is at the entrance because that is where a visitor can read before the interior takes over, which is Astra's staging note read literally.

**Rejected.** An octave slider: the comparison needs four surfaces in one glance, and a slider gives one surface over time, which is a memory test. Rejected too: normalising the patches to equal brightness, for the reason above.

**Pending (first pass).** A headset walk, and a body standing inside the room at one layer and at six — which is the comparison the board can only point at. Shader compilation and frame cost are unmeasured beyond the run completing: the room compiles and renders in both lanes, and that is all this pass can honestly claim. Astra's review.

## 2026-09-12, later — what the live lane made me measure

**A board across a corridor is a wall, and the museum said so.** The first staging put the board at (7,3), in the one-cell entrance corridor. Two lines in the engine log, which no text had read:

    [em-seal] shader_noise_space seals 2 cell(s) — the route is severed, and it stands where the map put it
    [em-walk] Noise_6_Wall: the walk was severed — reopened it (slid shader_noise_space by (2,-1))

The board is 2.02 m wide. It sealed the only route onward, and the museum's reach repair slid the body two cells east and one north to reopen the walk — correctly, and silently as far as every text was concerned. Nothing was wrong with `artifact_placement: "map"`. The map's cell was refused because the board really would have blocked the hall.

So the board stands at (9,2) now, beside the path rather than across it, and the entrance has a reading landing: four cells laid from holes at row 1, cols 8-10, and (8,2). Before that a reader stood over a hole — which is exactly how the failure showed itself. The desktop rig FELL, its eye dropped 16 cm between the aim and the click, and the second press's ray passed under the button. The probe now counts the button's emissions (0, not 2) so a press that changes nothing says which of the two it was, and it checks the body's final position against the cell the map named, so a slide can never again be invisible to the text.

**The room is larger than the hall it stands in.** Measured, not fixed. The scene's enclosure measures 18.1 x 13.6 x 27.1 m; this hall is 13 cells across with 3 m walls. In the museum its walls stand outside the hall's walls and its ceiling above the hall's ceiling, so a visitor here does not enter the cloud — they pass a board about it. The captures show it: from a standing eye you see the museum's own hall, and from above the room's whole visible contribution is its half-metre-radius sphere. The scene is placed in twelve maps; resizing it is a decision for those twelve, not something to slip into a panel pass. It is written into final.md instead, because a wall text that promises an interior nobody can enter is the worse error.

**`stand:panel` no longer drags the room behind it.** It used to place the whole scene and hang the board on it, so a 27 m enclosure stood invisibly around the entrance and the museum's repair had a body far larger than anything a visitor can see. The enclosure leaves the tree now (`_strip_enclosure_for_panel`), after `_setup_materials` has taken its references: the staged body is a board. Removed rather than hidden, because an extent is measured from the tree.

## 2026-09-13 — an enclosure the desktop body can enter

Current review: doc/space/wall-review-2026-09-13/README.md. Illustrated page: /research/possible-bodies/noise-six-wall.html. Two primary tokens, three retained placements; the room's original internal sphere is part of shader_noise_space. Book and artifact roles agree. Next: Noise_Inside_Noise.

The earlier field notes above are historical. Their claimed "one seed" was not an exposed seed control; fixed shader hash constants are used. Weight sums alone do not explain the patches' brightness. Setting time_scale to zero did not hold the current moment. The original panel also failed to send basis and freeze state to the enclosure, and the sphere did not draw with the controlled material. The accepted review corrects those claims and mechanisms.

An opt-in room mode stages the retained enclosure inside a five-metre floor with two side doors, keeping original scene geometry available elsewhere. The map's structure and utilities remain unchanged; the artifact floor bridges the central opening and the orb moves onto solid floor at (10,10). A cased, supported panel controls count, basis, held/resumed state and finish across the local room and sphere. Patches share the phase and basis with fixed term counts. DRESS changes no collision shapes. UV charts restart on each quad; the room is not continuously world-mapped.

Final run: 39 checks, no failures, PID 26032, 12:52:11–12:52:37 +02:00. Actual shader readback, four pointer controls, cross-hall exclusion, current-time hold/resume and a desktop body crossing both doors pass. Source fingerprints and the original saved hand remain unchanged. Headset reach, comfort and Quest performance remain pending. The shared normal-map repair can change other consumers' shading.

The chapter follows discovery through apparent depth, abs accumulation, display clipping, material dressing and coordinate seams. The independent orb keeps another clock and another way to receive a scalar. Future world-space mapping, editable weights and actual displacement remain proposals.
