<<<ADA_BUNDLE>>>
sequence: wavefunctions
file: summary.md
maps: 13
skipped_passing: 0
created: 2026-04-23T19:06:48
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: WaveFunctions_Intro>>>
# WaveFunctions Intro — Summary

The Wavefunctions sequence opens in a small control room. The walls carry four oscilloscopes, each sweeping a different signature of the same principle: sine, square, sawtooth, and a Lissajous curve. Green traces move left to right. The room is dim. The effect is laboratory rather than gallery.

The centre of the room holds three interactive demos. A harmonic motion rig puts a ball on a track and exposes sliders for amplitude, angular frequency, phase, and damping. A spring demo lets you pull a mass against Hooke's law and watch the restoring force bring it back. An additive wave station lets you pile harmonics on top of one another and see the compound waveform assemble in real time.

A set of clipboards along one wall carries the oscillation axioms the sequence will lean on — periodicity, amplitude, frequency, phase — written in plain language next to their symbols.

Within the sequence, this map is the glossary. Every later map assumes you can read a waveform and name its parameters. Pendulums will make oscillation physical, the unit circle will make it rotational, the sine-space corridor will make it architectural, and the Synthesis Lab will reassemble signals from their Fourier components. Before any of that, the control room hands you the vocabulary and lets you turn each dial until it means something in your body.

<<<MAP: WaveFunctions_Pendulum>>>
# WaveFunctions Pendulum — Summary

A weight on a string swings in a wide arc. Gravity pulls it back toward vertical; momentum carries it past. The oscillation repeats. Pendulum is the canonical harmonic oscillator, and this map treats it as the physical ground under the sine function introduced in the control room.

The space is open, with a tall ceiling so the strings can hang long enough for the period to be legible. A single pendulum dominates the centre. A Foucault rig rotates slowly around its own axis, showing that a steady oscillation sampled by a turning earth reads as precession. Off to one side, a double pendulum demonstrates what changes when the second bob hangs from the first: the system becomes chaotic, sensitive to the third decimal of its initial angle.

A trace lays the bob's position down as a sine curve against time, so the equation and the motion share one display. Sliders adjust length, gravity, damping, and drive frequency; resonance appears when the drive matches the natural period.

Within the sequence, Pendulum is the second map. It grounds oscillation in mechanism before the next maps abstract it back upward — into circular motion, spatial geometry, and propagation. The learner leaves with a body-level sense that sin is not just a function but a shape that gravity, tension, and mass produce for free.

<<<MAP: WaveFunctions_Unit_Circle>>>
# WaveFunctions Unit Circle — Summary

A point travels around a circle at a steady angular rate. Seen from the side, its shadow traces a sine wave. The unit circle is where trigonometry starts, and this map stages that identity as a small amphitheatre so the relationship between rotation and oscillation is visible from the seats.

At the centre, a rotating marker moves around a ring of radius one. Two projections are drawn live: the vertical drop becomes sin, the horizontal drop becomes cos. The two curves scroll past the edge of the ring as the marker turns, so the angle, its sine, and its cosine all share one frame.

Around the amphitheatre, oscillating bridges rise and fall according to those same functions. Walking across them puts the wave under your feet. A tangent line flicks out from the marker at each moment and shows why tan runs to infinity every ninety degrees. Sliders adjust radius, angular frequency, and phase offset.

Within the sequence, this is the keystone. Every earlier map has shown sine in one form — equation, swinging mass, walkable surface — and every later map assumes you know where sine comes from. Unit Circle is the answer: uniform circular motion, projected onto a line. Rotation and oscillation are the same event watched from different sides.

<<<MAP: WaveFunctions_Sine_Space>>>
# WaveFunctions Sine Space — Summary

The sine wave is usually drawn on a chart. Here it is built at architectural scale and walked through. A corridor undulates ahead of the learner: the floor and ceiling follow a frozen sin(x) curve, and the walls rise and fall with it. Amplitude is height. Frequency is the rate at which the waves pass under you. Phase is where the first crest lands relative to the entrance.

Three sections of the corridor show the same function with different parameters. The first is a long, slow wave with high amplitude. The second compresses to a rapid ripple. The third holds constant amplitude and frequency but shifts phase, so the crests land in different places against a painted reference line. A bank of sliders at the entrance lets you rebuild the corridor live.

The floor is marked with a numeric axis so you can read off position at each crest and trough. A vertical strip on one wall shows the waveform on a chart for cross-reference, keeping the equation tethered to the architecture.

Within the sequence, Sine_Space is the third map. Pendulum showed sine in time; this map shows sine in space. After it, the learner is ready for circular motion as the source of both.

<<<MAP: WaveFunctions_3D_Wave_Propagation>>>
# WaveFunctions 3D Wave Propagation — Summary

A stone drops into water and a ring spreads from the point of impact. The same thing happens with sound leaving a speaker and light leaving a star, only in three dimensions. This map is a field where waves leave sources, travel through space, weaken with distance, and interfere where they meet.

Several emitters sit in an open volume. Each radiates a spherical wave at a chosen frequency and amplitude. Around them, a lattice of small markers pulses in step with the local phase, so the wavefronts are visible as they expand. Distance attenuates amplitude by an inverse-square law; the field is brightest near the source and fades smoothly outward.

Where two sources overlap, their fields add. In places the crests align and amplitude doubles; in others a crest meets a trough and the field cancels. The resulting interference pattern is drawn directly into the lattice, so you can walk through loud bands and quiet ones. Sliders change each emitter's frequency, amplitude, and position.

Within the sequence, this is the first intermediate map. Sine had been a local shape; now it moves. The vocabulary of sources, wavefronts, attenuation, and interference sets up the sound maps that follow and the synthesis lab at the end.

<<<MAP: WaveFunctions_Effect_Sound>>>
# WaveFunctions Effect Sound — Summary

Sound is oscillation made audible. This map converts the waveforms of the control room into pressure waves you can hear. The room is laid out as a small audio lab. Four synthesizer stations sit on tables, each with a different mode: square, sawtooth, triangle, and sine. Playing a station drives a simple oscillator at a selected frequency; a waveform display above each bench shows the signal being produced.

At the back wall, an FFT monitor decomposes whatever is playing into its frequency components in real time. A chord struck on one of the synths blossoms into a bar graph of partials. A white-noise bench shows the full spectrum flattened; a pure tone shows a single spike.

A small clip-style controller lets you load short sequences and hear them played back as chiptune melodies. Latency and quantisation noise are not hidden: the map names them, and a display next to the FFT tracks the gap between the mathematical waveform and the rendered output.

Within the sequence, Effect Sound is the pivot from seeing to hearing. The next maps — Bernini, Cage, AirMusic, Sky Stairs, the walking path, and the Synthesis Lab — all assume the learner can now move between waveform and sound without losing track of which is which.

<<<MAP: Wavefunctions_Bernini>>>
# Wavefunctions Bernini — Summary

Bernini's solomonic columns twist as they rise. The spiral is not decorative relief on a straight column; it is the column. This map treats those columns as sine functions wrapped around cylinders — a sculptural reading of oscillation that connects the wave mathematics of the earlier maps to procedural geometry.

A colonnade stands in the space. Each column is generated at run time by displacing the vertices of a base cylinder according to a helical rule: offset the lateral position by a sine of the vertical coordinate, modulate the radius by another sine at a different frequency, layer a small amount of noise for stone-like imperfection. The result is a twisting form that reads as carved marble but is computed, not modelled.

A pair of benches at the front of the space expose the parameters: twist rate, amplitude, radius modulation, and noise scale. Turning the dials reshapes the colonnade live. A reference panel shows the original Saint Peter's Baldachin so the procedural version can be held against its source.

Within the sequence, Bernini is the first art-historical map. It shifts the reader from mechanism to form and argues that the baroque was already doing vertex displacement, just in stone.

<<<MAP: WaveFunctions_John_Cage>>>
# WaveFunctions John Cage — Summary

Cage's 4'33" instructs the performer to play nothing. The piece claims the silence that results, the coughs, the ventilation, the traffic outside. This map takes that claim seriously and builds a space in which oscillation has been removed in order to reveal what remains.

The room is quiet. A small stage holds a closed piano and a stopwatch. On a low table, three aleatoric devices compose by chance: a set of dice tied to pitch, a coin chained to rhythm, a spinner that selects duration. A noise floor readout on the wall shows the ambient signal of the space itself, which never settles to zero.

A second station lets the learner switch between two modes. In "play" mode, a synthesized tone fills the room. In "pause" mode, the tone stops and the noise-floor readout becomes the only sound. Toggling between them demonstrates that silence is not the absence of signal but a reassignment of attention.

Within the sequence, Cage is the philosophical counter-weight. After six maps that accumulate oscillation, this map withdraws it and asks what frequency-zero actually contains. The answer — that there is always something — sets up the ambient and generative sound of AirMusic next.

<<<MAP: WaveFunctions_AirMusic>>>
# WaveFunctions AirMusic — Summary

Brian Eno's ambient loops drift past one another at slightly different rates. Each loop is simple. Their intersection is never the same twice. This map builds a small laboratory around that principle: sound as spatial event, harmony as emergent, composition as the arrangement of slow independent cycles.

The space is a single room with three stations. An FM piano plays a pattern on a fixed interval. A second loop plays a complementary pattern on a nearby but non-identical interval, so the two patterns phase in and out of alignment. A third voice shifts its own interval when approached, so walking near it changes the combined result.

A set of position-triggered notes lines the floor. Standing on a tile plays a tone; moving across the tiles plays a melody determined by the path. The room rewards slow movement: long enough to hear the loops cross, short enough to change your contribution to the chord.

Within the sequence, AirMusic follows Cage's silence and precedes the sequence's vertical and horizontal wave-walks. Sound returns, but not as composition in the traditional sense. The harmony is a property of the room and the people in it.

<<<MAP: Wavefunctions_Sky_Stairs>>>
# Wavefunctions Sky Stairs — Summary

Climbing a staircase is already tracing a waveform: each step is a sample, the tread is the period, the height is the amplitude. This map takes that metaphor literally. A tall vertical amphitheatre launches the learner up through open space. Stairs spiral around the central column in a helix whose step heights follow a sine curve.

Three staircases climb in parallel, each bound to a different function. One follows sin, another cos, a third a higher-frequency harmonic. The three diverge and converge at predictable intervals, so the phase relationship is visible as a spatial gap between the treads.

Floating cube fields drift at different altitudes around the tower, sampling the wave equation at that height. Their density thins with elevation and thickens at the nodes. A reference panel at the landing reads out your current height as a value of sin(angle), where angle is the distance traveled around the helix.

Within the sequence, Sky Stairs returns to embodied wave experience after the conceptual pause of Cage and AirMusic. Where Sine_Space put the wave under your feet horizontally, this map puts it under your feet vertically and asks you to climb it.

<<<MAP: WaveFunctions_TrigWalkingPath>>>
# WaveFunctions TrigWalkingPath — Summary

Sine and cosine are the same function, offset by ninety degrees. This map makes that offset physical. Two parallel walkways run side by side across the space. The left lane's steps rise and fall according to sin; the right lane follows cos. The learner can walk either lane or hop between them.

Each step is a computed block; the path generates itself a few steps ahead of the walker. A reference panel on one wall shows the two functions on a shared chart, with a marker indicating the walker's current horizontal position. The marker moves as you walk, so the graph and the footing stay synchronised.

At the midpoint, a cross-bridge connects the two lanes so the ninety-degree offset is walkable in one move. Sliders at the entrance adjust frequency and amplitude; raising the frequency compresses the period, shortening the path between peaks. Raising the amplitude deepens the troughs and lifts the crests.

Within the sequence, the walking path is the penultimate map. After Sky Stairs, the verticality returns to ground; after the sound and silence maps, the geometry returns to the foreground. The map trains the body to read sin and cos as paired, displaced, and equivalent before the Synthesis Lab asks you to decompose everything.

<<<MAP: WaveFunctions_Synthesis_Lab>>>
# WaveFunctions Synthesis Lab — Summary

Fourier's theorem claims that any signal, no matter how jagged, is a sum of sine waves. This map is the room where that claim becomes material. A central bench holds an additive synthesiser with sliders for the first sixteen harmonics. Raising each slider adds a scaled sine at that harmonic's frequency into the output waveform and the rendered sound.

A large display above the bench shows the resulting wave and the corresponding frequency spectrum side by side. Presets reconstruct a square wave, a sawtooth, a triangle, and a rough approximation of the vowel "a". Each preset lands the sliders in a recognisable pattern, so the relationship between spectrum and shape stays legible.

Around the room, smaller stations extend the thesis. One shows a heartbeat decomposed into its dominant frequencies. Another shows a day–night cycle reduced to a low-frequency carrier. A third shows DNA rotation as an oscillator. The claim is that biology is full of oscillators, and Fourier is how they can be read.

Within the sequence, Synthesis Lab is the synthesis in more than one sense. Every earlier concept is used here: sine as shape, circle as source, propagation as distance, sound as translation, silence as baseline. The sequence ends by handing the learner the operation that takes them apart and puts them back together.

<<<MAP: Chamber_Waves>>>
# Chamber Waves — Summary

Chamber_Waves is the catalyst chamber for Wavefunctions. It is the last map before the learner returns to the Lab and the first map in which oscillation becomes a relationship with another creature rather than a standalone demonstration.

The space is enclosed and lit from the waveform itself. A waterbomb enemy bounces around the chamber at a steady rate; each bounce marks a beat. The learner holds a helix emitter that fires spiralling projectiles at a chosen frequency. The science screen on one wall reads out both frequencies and draws their product.

When the learner's frequency matches the creature's, the two waveforms align on the screen, the projectiles synchronise with the bounces, and a short resonance plays. A mismatch shows as a beating pattern: the two waves slide in and out of phase, amplitude rising and falling as they interfere. The screen labels the behaviour.

Within the sequence, Chamber_Waves is where the mathematics of the previous maps becomes contact. Catalyst, creature, and screen together make the lesson — wave-particle duality, resonance, entrainment — a matter of finding the right rhythm with something that is not you. The chamber closes Wavefunctions and hands the learner back to the Lab with a tuned ear.
