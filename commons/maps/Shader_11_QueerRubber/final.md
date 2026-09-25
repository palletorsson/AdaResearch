# What does a surface answer to?

The crossing leaves you in a hall with columns. Every other hall in this sequence has refused them; this one asked to keep them.[^piers] Down the lane between two rows of columns stand five bodies, each on a low round stage and each about the size of a person, turning slowly under three coloured lamps, with a name in capitals at its foot, and a pink line of text hangs over them all.[^stage] The pictures are behind you now. There are no desks. Nothing here is yours to adjust. What you have is your feet.

<!-- @shader_11_queerrubber -->

Go to the ring first, the black one with a rainbow at its edge. Walk a quarter of the way round it. The rainbow comes with you. It stays at the ring's rim, the part of the surface that turns away from you at a grazing angle, wherever you stand. The pink highlight from the lamp on the left does not come with you; it stays on the side that faces the lamp.

Two answers, then, on one surface. One is an answer to the lamp: where its light lands, and where the reflection would reach an eye. The other is an answer to you: how steeply the surface turns away from where you are. Here is the second, from the ring's own code:

```glsl
float NdotV = dot(normalize(NORMAL), normalize(VIEW));
float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
vec3 rainbow = spectrum(perturbed_rim * 2.0 + TIME * 0.1);
vec3 oil_sheen = rainbow * pow(rim, 2.0) * interference_strength;
EMISSION = oil_sheen;
```

NORMAL is which way the surface faces; VIEW is which way you are. Their product is large where the surface faces you and small where it turns away, and the rainbow is put where it is small. The last line is the one to hold on to. The rainbow is written into EMISSION: light the surface claims to make, not light it receives. Turn every lamp in the hall off and the rim would still glow.[^emission]

Now the two spheres. The dark one and the pink one both turn, one with the clock and one against it.[^spin] Watch the dark one, LEATHER: a grain crawls across it, folds pass, and you can see it turning. Watch the pink one, POP PLASTIC, for as long as you like. Nothing on it moves. It is turning at very nearly the same rate.

The dark sphere's skin is drawn from a coordinate painted onto it, so when the sphere turns the skin turns with it. The pink sphere's skin is drawn from NdotV alone, the angle between its surface and your eye, and from nothing painted on. A sphere turned by any amount presents the same angles to the same eye. It answers to you and to the lamps, and not at all to where it has got to in its own rotation. Its cyan edge is the rim you saw on the ring, cubed:

```glsl
float rim = 1.0 - clamp(NdotV, 0.0, 1.0);
rim = pow(rim, 3.0); // Sharp falloff
EMISSION = rim_color * rim * rim_width;
```

The capsule is fur, or says it is. Its code explains its sheen as light grazing the fibres. Read what it computes: the same NdotV, the same rim, roughened with a noise from its painted coordinate, and again written to EMISSION and added to the colour. The eye grazes the fibres, not the light. It is a velvet that glows at its own edges for whoever is looking, and because its grain is painted on, this one you can see turn.

The last body is a cube of a metal the header calls sad, with streaks that were meant to run down it like tears. The streaks are read from a texture that this hall never hands it.[^white] What you see is the alloy without its tears. And a cube cannot hide its turning the way the pink sphere does. It has corners, and they sweep past you; a cube turned by a few degrees presents new angles to the same eye, and its faces take the lamps one at a time. The rule is the same on both bodies. The shape decides what the rule can show.

Now the lamps. Pink on the left, blue on the right, purple above and behind, each with a reach of ten metres and none of them casting a shadow.[^lamps] Put your hand between the pink lamp and the leather. Nothing on the leather changes. Stand between the lamp and the ring: still nothing. The lamps here light everything they reach and are blocked by nothing, which is not how a lamp behaves and is exactly how a rule behaves. The surface asks each lamp where it is, what colour it is and how far away. It does not ask whether anything stands in between.

So, what a surface answers to. To the lamps: their direction, colour and distance, and no more. To you: the angle at which it turns from your eye, which is why the rims and the rainbow follow you round the room. To the clock: everything turns, and the ring's rainbow drifts, a tenth of a cycle a second.[^drift] To its own painted coordinate, if it has one. Not to the other four objects, which it cannot see. Not to its own past, of which it keeps none.

None of the five materials carries a body of its own. The spheres, the ring, the capsule and the cube are shapes this hall lent them, on the map's instruction, and the map could lend them others.

<!-- @dark_sphere -->

The dark sphere near the centre pulses on its own clock, kept on the processor. Stand where you can see it and the pink sphere together. One is turning and shows it; one is turning and cannot show it; one is pulsing from a number it remembers.

The columns stand through all this, the museum's own furniture on a four-metre beat, and the coloured light lands on them too. They are the one thing in the hall that answers to nothing. A column is placed, and stays.

<!-- @ -->

The next hall has water in it. Take the ring's rainbow with you, and the question of what it would take for a surface to notice that you are standing in front of a lamp.

[^piers]: `map_info.museum.piers` is `true` on this map and `false` on the sequence's other five. The plan tool (`tools/em_map_halls.py`, `normalize_row`) stamps the template colonnade into every bare hall of eight rows or more: a pier every fourth row from the third and every fourth column from the second, never on or beside a body. On this 14 x 14 floor that rule gives eight piers, the ninth falling on the artifact's own cell. The count is the dealt plan's to confirm.

[^stage]: The map token is `shader_11_queerrubber:0:0#layout:line#gap:2.2#bodies:1.35#shapes:sphere,torus,sphere,capsule,cube#stage:0.4` at cell (8, 7): the five bodies in a line 2.2 m apart down the lane at x 8.5, between the colonnade's pier columns at x 6 and x 10, each scaled 1.35 times the script's default and standing on a 0.4 m stage. The leather sphere is 1.94 m across, the pink one 1.78, the cube 1.35 on a side. Without these keys the script builds its original arc of smaller bodies floating at 1.5 m, which would have stood one of them on a pier. Palle, 25 September: "stages large spheres and cubes".

[^emission]: Godot's spatial shaders separate what a surface reflects (ALBEDO, ROUGHNESS, METALLIC, lit by the lamps) from what it emits (EMISSION, added whether or not any lamp reaches it). Every rim in this hall is written to EMISSION.

[^spin]: `shader_11_queerrubber.gd`: leather at 0.15 radians a second, pop plastic at -0.18, the ring at 0.2, the capsule at 0.12, the cube at -0.1 (a cylinder in the script's own defaults; the map asks for a cube), each turned in `_process`. Rotation is the one thing here that does keep a state: a node's transform, on the processor. `pop_plastic.gdshader` reads no UV and no texture; `leather.gdshader` reads `noise(UV * grain_scale)`; `fur_velvet.gdshader` reads `random(UV * noise_scale)`.

[^white]: `sad_metal.gdshader` declares `uniform sampler2D tear_noise : hint_default_white;` and the hall's script contains no `set_shader_parameter` call, so the sampler reads white everywhere and the tear term is a constant. The ring's `noise_tex` is declared the same way, so its "oil on water" perturbation is a constant too: the rainbow you see is the clean rim.

[^lamps]: Three `OmniLight3D` nodes: pink (1.0, 0.1, 0.5) at energy 8, blue (0.1, 0.3, 1.0) at 8, purple (0.8, 0.0, 1.0) at 6; `omni_range` 10; `shadow_enabled = false` on all three.

[^drift]: `spectrum(t)` is `0.5 + 0.5 * cos(6.28318 * (t + offsets))`, periodic in 1, and the drift is `TIME * 0.1`. Over the clock's thirty seconds that is exactly three cycles, so when the clock wraps the rainbow lands where it started. The first hall's wave leaps at the wrap; this rainbow does not, by an accident of arithmetic.
