# Which of these is the lamp?

No desks. A title in pink capitals floating above everything. Three lamps, pink, purple and pink again, and five things under them: a sagging sphere, a ring and a black cube, each on a low stage, an enormous sphere floating above the rest, and on the floor a sheet of water twelve metres square that you are already standing in.[^scene] The hall's own notes say that every number here has been pushed past its intended range. Hold that. First find the light.

<!-- @shader_12_pinkextravaganza -->

Start with the water, since you are in it. It comes to your ankles and it does not touch you; walk through it and it lifts through your shins as if you were not there. It is pink over purple, with pale glints that move. The notes say it refracts wrong on purpose. Look for the refraction: look at the floor through the water, at the edge where the sheet ends. Nothing is bent. The code has no refraction in it, wrong or right; it has three sines for the height, a noise for the glints, and a colour it partly emits itself.[^water] Stand still in it for half a minute. It jerks. All three of its waves are written straight on the clock, and the clock wraps.

Now the big sphere. It is the loudest thing in the room: hot pink swirling into magenta, a rainbow drifting over it, a glitter, and it breathes, five per cent larger and smaller, every second and a half. Walk round it. The rainbow comes with you; it is the rim again, the angle to your eye. Now try to find the lamps on it. There is a pink lamp to the left and a purple one to the right, so the sphere should be pinker on one side and bluer on the other. It is barely so. Most of what you see it makes itself:

```glsl
EMISSION = color * 0.4 * pulse;
EMISSION += hot_pink * rim * 0.8;
```

Four tenths of its own colour, pulsing, plus a hot pink at the rim, added to whatever the lamps manage. The lamps are there. They are outvoted.

The sagging sphere: bands of sag run across it, up to ten centimetres deep, and move. That is not a body deforming. It is every vertex asked, each frame, how far down to be:

```glsl
float melt_wave = sin(VERTEX.x * 5.0 + TIME * melt_speed) * 0.5 + 0.5;
VERTEX.y -= melt_wave * melt_amount;
```

It, too, emits a fifth of its own colour, and it tints its edges red and its centre blue by the angle to your eye, and calls that chromatic aberration in a comment that admits it cannot do the real thing without reading the screen.[^candy] The ring, crushed pearl, is a diffraction grating done with noise: a hue that runs round the ring by angle and drifts with the clock, and glints that are emission. The black cube is the oil slick of the pillar hall, rim and rainbow, emission, and on a cube the rim is not a band but a face: whichever face turns nearly edge-on to you takes the rainbow whole, and the face that squares up to you goes black.

So: which of these is the lamp? Every one of them. The five surfaces make most of their own light, and the three lamps hung above them add to it and are outvoted. A lamp is a thing that puts light on a surface. In a rule that writes EMISSION, the surface puts light on itself, and it does so at every pixel, from the angle to your eye and the clock, exactly as the rims did two halls ago, only louder.

Now the notes' claim. Every number pushed past its intended range. Read the script that builds this hall: it loads five shaders, hangs three lamps, sets a title, and sets no number at all. Not one slider value, not one uniform.[^defaults] Everything you see is what these rules do when nobody touches them. The excess is the default. Taste would be the thing you would have to add.

There is one motion in this hall with a past. The objects bob. Not from the clock: each frame adds a small amount to each object's height, and the amounts add up, so an object's height is the sum of everything that has been added since the hall was built.[^bob] Add faster and it bobs further: at ninety frames a second the bob is nine centimetres, at seventy-two it is seven. A surface asked from the clock is the same in any headset. A bob added up frame by frame is the headset's. The only thing here that remembers is also the only thing here that depends on who is looking.

<!-- @dark_sphere -->

The dark sphere, pulsing purple, in a room where everything pulses pink. It is the one thing in the hall you could mistake for a lamp that is not trying to be one.

<!-- @ -->

One hall left, and it is quiet. Take the emission with you: a surface that lights itself is answering to nothing but its own rule and your eye.

[^scene]: `shader_12_pinkextravaganza.gd` with the map's token `#bodies:1.5#shapes:sphere,torus,cube,plane,sphere_big#stage:0.35#water:12`: melted candy, a sphere of radius 1.17 m on a 0.35 m stage at x -4.5, turning at 0.25 rad/s; crushed pearl, a torus 2.3 m across at x -1.5; oil slick latex, a cube 1.8 m on a side at x 1.5; queer water, a plane 12 m square on the floor, centred on the hall's anchor, not turning; drag extravaganza, a sphere of radius 1.6 m at (0, 4, -2), neither scaled nor staged, turning at 0.3 rad/s. The script's own defaults, without the token, are smaller bodies at fixed heights, a capsule instead of the cube, and an 8 m water. Lamps: (1.0, 0.0, 0.5) at (-5, 5, 3), energy 8; (0.5, 0.0, 1.0) at (5, 5, 3), energy 8; (1.0, 0.1, 0.8) at (0, 6, -2), energy 6; range 10; no shadows. The title reads P I N K   E X T R A V A G A N Z A between two stars.

[^water]: `queer_water.gdshader`: `wave1 = sin(VERTEX.x * wave_scale + TIME * wave_speed) * 0.05`, `wave2 = cos(... TIME * wave_speed * 1.3) * 0.04`, `wave3 = sin(... TIME * wave_speed * 0.8) * 0.03`, so the crests reach 12 cm above the plane and the troughs 2 cm below the floor it lies on. `EMISSION = color * 0.15 * dream_intensity`, `ALPHA = 0.85`. No `SCREEN_TEXTURE`, no `refract`. At the wrap the three phases drop by 30, 39 and 24 radians, none a whole number of cycles.

[^candy]: `melted_candy.gdshader`: `melt_amount` = 0.1, `EMISSION = candy_color * 0.2`, `BACKLIGHT = candy_color`, and the comment "Hard to do real chromatic aberration in standard shader without screen reading. We can fake it by tinting based on normal angle." The big sphere's breathing is `VERTEX *= 1.0 + 0.05 * sin(TIME * pulse_speed * 2.0)` at `pulse_speed` 2: a period of 1.57 s.

[^defaults]: `shader_12_pinkextravaganza.gd` contains no `set_shader_parameter` call. Each material is `ShaderMaterial.new()` with its shader loaded and nothing else set; the shaders that declare a noise texture read a default white. `crushed_pearl`'s hue drifts by `TIME * 0.1` inside a `fract`, three whole cycles per wrap, so of the five it is the one that happens not to leap when the clock does.

[^bob]: `_process`: `objects[i].position.y += sin(Time.get_ticks_msec() * 0.001 + float(i) * 1.5) * 0.001`, for every turning object, every frame. Summed over frames at rate r this is a bob of about r x 0.001 m in amplitude: 0.09 m at 90 Hz, 0.072 m at 72 Hz, 0.06 m at 60 Hz. `Time.get_ticks_msec()` does not wrap with the shader clock.
