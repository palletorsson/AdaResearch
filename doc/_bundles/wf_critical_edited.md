<<<ADA_BUNDLE>>>
sequence: wavefunctions
file: critical.md
maps: 12
skipped_passing: 1
created: 2026-04-23T22:21:08
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: WaveFunctions_Pendulum>>>
# Gravity is a conservative politics — restoring force, the return to equilibrium, and the pendulum's refusal to remember

The pendulum always comes home. Displace it, release it, and it passes through rest on the way to the other side, overshooting and returning until friction wears down the amplitude and the bob settles. This return is not a choice. It is a consequence of the restoring force, which is proportional to displacement and always points toward equilibrium. The pendulum is a body that cannot hold an eccentric position. The farther it travels from rest, the harder the force pulls it back.

Sara Ahmed writes about orientations — the directions a body is pointed in by the arrangements of the world around it. The pendulum is a body with a single orientation, and that orientation is vertical. Every other position is a departure. Ahmed's insight is that orientations feel natural precisely because the world is built to maintain them; the pendulum feels natural in its vertical rest because gravity, geometry, and the string's attachment point have been arranged to return it there.

The Foucault pendulum extends the argument. It swings in a plane, but the plane appears to rotate as the Earth turns beneath it. The pendulum is not rotating. The observer is. The apparent rotation is an artifact of the measurement frame, not a property of the bob. The map stages this carefully: the pendulum's swing is indifferent to the rotation it inscribes, and the rotation becomes legible only because a sand tray or a ring of markers registers the pendulum's oblivious straight-line motion as a curved trace.

The double pendulum refuses this composure. A second bob hanging from the first introduces a second degree of freedom, and the system becomes chaotic: tiny changes in initial angle produce divergent trajectories within seconds. The equations are deterministic; the behaviour is not predictable. This is Lorenz's chapter of the argument, played out on a rig that looks innocuous. The double pendulum is the point where gravity's conservative logic breaks down into sensitivity-dependent history.

Within the sequence, Pendulum stages oscillation as both restoring and unstable. The simple pendulum is the map's thesis: oscillation is return, and sine is what return looks like when plotted against time. The double pendulum is the map's antithesis: coupling two oscillators produces behaviour neither can contain. The learner leaves with a body-level sense that the restoring force is neither neutral nor guaranteed.

The politics are in the drive. The drive parameter is what turns a damped oscillator into a resonant one. At the right frequency, small drives accumulate into large amplitudes. The pendulum learns, in effect, which inputs match its own rhythm and which do not. This is a body that cannot be persuaded at the wrong frequency and cannot resist at the right one. Resonance is a politics of timing: what you can push depends on when you push, and the pendulum rewards only the patient or the lucky.

<<<MAP: WaveFunctions_Unit_Circle>>>
# The angle is a choice about where to measure from — the unit circle as a standpoint rather than a truth

The unit circle is usually introduced as a self-evident object: a circle of radius one centred at the origin, with angles measured from the positive x-axis. Sine and cosine are defined as projections of a rotating point onto two perpendicular lines. The definitions feel like discoveries, as though the functions were there in the geometry waiting to be named.

Donna Haraway's situated knowledge insists otherwise. There is no view from nowhere. Every coordinate system is a standpoint, and the unit circle is a standpoint made to look universal. The choice of origin, the choice of radius, the choice to measure angles counter-clockwise from east — these are conventions, and the conventions encode a particular tradition. Greek geometry set some of them. Eighteenth-century analysis set others. The unit circle the learner walks around in the map is the inheritance of a long set of decisions none of which were inevitable.

The amphitheatre staging makes the convention visible. A rotating marker moves around a ring; its vertical drop is projected onto one axis as sin; its horizontal drop is projected onto the other as cos. Reversing the direction of rotation flips the sign of sin. Rotating the frame ninety degrees swaps the two functions. The map lets the learner run these permutations and watch the definitions rewrite themselves under the new conventions. Sin and cos are not properties of the circle. They are properties of a circle with a chosen frame.

The oscillating bridges extend the lesson into the walker's body. Stepping from one side of the amphitheatre to the other puts the wave under the learner's feet: the bridges rise and fall according to the projections the central marker generates. Walking them is reading the sine curve from inside. The learner's movement and the marker's rotation synchronise, and the unit circle stops being an external object and becomes the apparatus that decides what the learner's own trajectory looks like on the wall.

This is the keystone map in the sequence because it makes the sequence's single assumption visible. Every later demonstration — wave propagation, interference, Fourier synthesis — takes sine and cosine as given. This map asks where they come from. The answer is: from a rotating point projected onto chosen lines, and every piece of that sentence is a choice.

The political register follows immediately. If sin is a projection, then the question of which projection to take is a question about which information to discard. The radial distance is erased; only the vertical component survives. Trigonometry is a discipline of selective forgetting, and the forgetting is exactly what makes the functions tractable. The map does not hide this cost; it stages it as the procedure by which the cost is incurred.

Within the sequence, Unit_Circle is where the learner learns to locate their own sine function. After this, every wave in the later maps is a particular projection chosen from inside a particular frame, and the learner carries the knowledge of the choice forward.

<<<MAP: WaveFunctions_Sine_Space>>>
# The corridor is the function — sine as architecture and the politics of continuous form

Walking through a sine curve is different from reading one. The chart on the wall collapses the function into two dimensions; the corridor lifts it into three. The learner enters at the first crest and walks through successive peaks and troughs of height equal to the wave's amplitude. The floor under their feet is the graph.

Henri Lefebvre argued that space is produced rather than given. It is the sedimented result of practices, representations, and lived experience. The sine corridor is space produced explicitly from a function. Its architecture is a numerical sampling of sin(x) at chosen intervals, extruded into height. Nothing about the corridor is natural. Every wall, every dip, every crest is the output of an equation and a set of design decisions about how to render it at walkable scale.

This production becomes visible when the parameters change. Raising the amplitude deepens the troughs and lifts the crests. Raising the frequency compresses the period, shortening the distance between peaks. Shifting the phase moves the first crest toward or away from the entrance. The corridor is continuously being produced while the learner walks it, and the production is instrumented: a bank of sliders exposes each parameter and a display redraws the corridor live.

The argument inside the map is that continuous form is expensive. Every sample the renderer takes of the sine function is a decision about resolution. Too few samples and the corridor reads as a stepped approximation rather than as a curve. Too many and the frame rate collapses. The smoothness the learner feels under their feet is an achievement rather than a property, and the achievement is paid for in geometry.

Lefebvre would push further. The corridor's smoothness is ideological. A sine function has no corners, no breaks, no discontinuities — and the corridor presents this as a virtue, as though smoothness were a natural goal of form. But smoothness is a choice among many possible choices. A sawtooth function produces a different corridor; a step function produces a different corridor again. The map holds sine up as the default, and the default carries a claim about what a well-made shape looks like.

Within the sequence, Sine_Space is where oscillation becomes inhabitable. The previous map grounded sine in motion; this map grounds it in architecture. The next map will ask where sine came from in the first place, and the corridor will still be standing as the demonstration that any answer that arrives will have to live with the particular kind of space that sine produces when it is walked rather than read.

<<<MAP: WaveFunctions_3D_Wave_Propagation>>>
# Distance is the carrier — inverse-square law, interference, and the politics of the commons

A wave leaves a source and spreads. The energy packed into the first wavefront is the same energy spread over a larger sphere one second later, so the amplitude at any given point drops as the square of the distance. This is the inverse-square law, and it is the first thing the map makes physical: the field is bright near the emitter and fades smoothly outward.

Donna Haraway's situated knowledge meets its physical analogue here. A wave does not impose itself on an empty space. It negotiates with distance. The learner standing near the emitter receives a strong signal; the learner standing at the far wall receives a weak one. What counts as the same wave is relative to position, and the map refuses to flatten the difference. Every spatial location is its own reading.

Interference is where the politics become acute. When two sources share a space, their fields superpose: at some locations the crests align and amplitude doubles; at others a crest meets a trough and the field cancels. The lattice of small markers pulses in step with the local phase, and walking through the field means walking through loud bands and quiet ones. No single source produced the cancellation. It emerges from the meeting.

This is a model for a commons rather than for a signal. Neither source owns the interference pattern. Both contributed; neither can remove it without also removing their own field. The pattern is a shared condition, and the map argues that this is the normal case rather than the exception. Isolated signals are the anomaly; interference is what happens whenever signals coexist.

The attenuation parameter makes the commons political. When the inverse-square falloff is steep, the sources' fields barely overlap and the interference pattern is localised. When the falloff is shallow, the fields reach across the whole volume and the interference pattern fills it. The map lets the learner adjust the parameter and feel the difference. A shallow falloff produces a thicker commons; a steep falloff produces a privatised one.

The phase relationship compounds the effect. Two sources at the same frequency produce stable interference; two sources at slightly different frequencies produce beating — amplitude rising and falling in a slow envelope. The map lets the learner tune frequency offset and watch the commons breathe. The beating is a temporal signature of disagreement rather than a spatial one, and the sources are still the same sources; only their timing has changed.

Within the sequence, 3D_Wave_Propagation is where oscillation moves. Sine existed as a local shape in the earlier maps; now it travels, weakens, and meets other sines. The sequence's later maps — sound, Bernini, Cage, AirMusic — all work with fields that obey these same rules. The commons the map demonstrates is the medium of the remaining sequence.

<<<MAP: WaveFunctions_Effect_Sound>>>
# Sound is an infrastructure — latency, quantisation, and the politics of what can be heard

The waveform on the oscilloscope and the sound in the room are not the same thing. The waveform is a continuous mathematical object; the sound is a sequence of pressure differences transmitted through air, sampled by transducers, reconstructed by speakers, and heard by ears. Between the function and the experience is a full stack of infrastructure, and this map refuses to hide any of it.

Wendy Chun argues that software's power is the power to make infrastructure invisible. When a system works, the learner hears the note; when it fails, they hear nothing, or noise, or a glitch. Chun's insight is that the invisibility is not neutral. It is a political achievement: a claim that the translation from waveform to sound is a trustworthy process, and that the translation's costs can be ignored.

This map unhides the infrastructure. The four synthesiser stations each run a different waveform — square, sawtooth, triangle, sine — and a display above each bench tracks the signal at multiple stages. The ideal waveform; the quantised waveform after sampling; the filtered waveform after the DAC reconstruction filter; the measured waveform recovered from the speaker output. The gap between the first and the last is the infrastructure made visible. Each stage subtracts information that the next stage cannot recover.

The FFT monitor extends the argument. The learner plays a chord, and the monitor decomposes the signal into its frequency components in real time. What looks like one sound is actually a handful of dominant frequencies plus a noise floor that never settles to zero. The chord is a spatial claim as well as a temporal one: it occupies a region of the spectrum rather than a single point. Chun would note that the chord's richness is available only because the spectrum is infrastructure — a set of decisions about how to decompose signal into component frequencies, made long before the learner struck the chord.

The latency display is the politics of the stack. Every stage adds delay: the sampling, the buffer, the DAC, the speaker, the air, the ear. The map tracks the delay as a running measurement, and the number sits at some non-trivial value even at the fastest settings. Real-time is a claim, not a property. Audio infrastructure is fast, but it is not free. The gap between striking a key and hearing a tone is the time the infrastructure takes to do its work.

Within the sequence, Effect_Sound is the pivot from visible oscillation to audible oscillation. The maps before this treated the wave as something to see or walk; this map treats it as something to hear. The later maps — Bernini's twisted columns, Cage's silence, AirMusic's phasing loops — all depend on the infrastructure this map makes visible. The learner leaves knowing that hearing is as constructed as seeing, and that the construction is always political.

<<<MAP: Wavefunctions_Bernini>>>
# The column is the wave — procedural baroque and the politics of excess

Baroque architecture was accused of excess. Its critics called it overwrought, undisciplined, a break with classical restraint. Bernini's solomonic columns — the twisting spirals that support the Baldachin at Saint Peter's — were the most-accused examples of this excess. They did not behave like columns. They wavered. They turned as they rose. They refused the straight vertical line.

This map takes the accusation seriously and converts it. A procedural colonnade stands in the space; each column is generated at run time from a base cylinder whose vertices have been displaced according to a helical rule. The rule is a sine function wrapped around the cylinder's vertical axis. The excess the baroque was accused of is here shown to be a small amount of code.

Gilles Deleuze's reading of the baroque in *The Fold* argues that the fold is what the baroque contributed to ontology. Classical form is discrete and planar; baroque form is continuous and folded. The twisted column is not a stack of separate shapes but a single surface curving around itself. Deleuze argues that the fold generalises beyond architecture: it is a mode of thought, a way of producing complexity without breaking continuity.

The procedural implementation confirms Deleuze at the level of vertex arithmetic. A cylinder is a flat sheet rolled into a tube; the twist is another fold applied to that sheet; the noise layer is a third fold that breaks the twist's regularity without breaking the surface. Each fold is a small operation on the vertex buffer, and the combination produces the finely detailed form that reads to the eye as baroque excess. The excess is not waste. It is composition.

The politics of the map are visible in the parameter bench. The twist rate, the amplitude, the radius modulation, and the noise scale are all sliders, and turning them reshapes the colonnade live. The baroque is legible as a particular region of this parameter space, and neighbouring regions produce classical colonnades, modernist abstractions, or incoherent distortion. The map does not claim that the baroque is better than the others; it claims that all of them are points in a shared space and that choosing one is a political act rather than an aesthetic given.

A reference panel at the entrance holds a photograph of the Baldachin so the procedural version can be compared with its source. The comparison matters because the procedural column is not a reproduction. It is a generative reinterpretation: the source's silhouette reverse-engineered into a small set of parameters. Whether this reinterpretation is a homage or a colonisation is a question the map poses without answering. The baroque had its own politics; the procedural baroque inherits them and invents new ones.

Within the sequence, Bernini is the first art-historical map. It argues that sculptural form can be a wave, and that the baroque's contribution to architecture is a specific kind of folded continuity. The map is pitched between reverence and analysis, and the parameter sliders are what keep the reverence from becoming nostalgia.

<<<MAP: WaveFunctions_John_Cage>>>
# 4'33" is infrastructure — silence, the ambient, and the politics of the unmarked

Cage's 4'33" tells the performer to play nothing. What the audience hears is not nothing. They hear coughs, ventilation, traffic, the creak of chairs, the rustle of programmes. The piece claims these as the composition. It reframes the attention as the event and the performed absence as the occasion.

Trinh T. Minh-ha writes about the unmarked as the place where the politics of a frame become visible. The marked content is what a system presents as itself; the unmarked content is everything the system assumes as background. Cage's piece inverts the marking. What was background becomes foreground; what was content becomes frame. The map stages this inversion at walkable scale.

The room is deliberately quiet. A small stage holds a closed piano and a stopwatch. The stopwatch counts down the piece's duration. The piano's closed lid makes explicit that the performer's silence is not a lack of readiness but a structural feature. During the countdown, the room's own sounds become audible: the ventilation, the learner's own footsteps, the low hum of the space's lighting. A noise-floor readout on the wall tracks the ambient signal and confirms that it never settles to zero.

Three aleatoric devices sit on a low table. The dice assign pitches. The coin assigns rhythms. The spinner assigns durations. Cage's compositional practice used chance operations to remove authorial preference from the score, and the three devices reproduce the practice physically. The learner can run them and produce a small composition without making any creative decision about its content.

The toggle station completes the argument. In "play" mode, a synthesised tone fills the room. In "pause" mode, the tone stops and the noise floor becomes the only audible signal. Switching between the two demonstrates that silence is not the absence of signal but a reassignment of attention. The ambient was there in play mode too; the tone masked it. Turning the tone off unmasks what was always already present.

The philosophical stakes are in the noise floor. A purely silent room would be a room without infrastructure: no lights, no ventilation, no bodies, no computation. Such a room does not exist in any inhabited building. The noise floor is the signature of the infrastructure that makes inhabitation possible, and it can never reach zero because reaching zero would mean the infrastructure had stopped. The room's silence is always a relative silence, and the relation is political: who decides what level of ambient noise counts as silence is a power question.

Within the sequence, Cage is the philosophical counter-weight. The preceding maps accumulated oscillation into denser and more complex forms; this map withdraws oscillation and asks what frequency-zero actually contains. The answer — that there is always something, and the something has a structure — sets up the ambient and generative sound of AirMusic next.

<<<MAP: WaveFunctions_AirMusic>>>
# Harmony is a property of the room — phasing, emergence, and the politics of slow time

Brian Eno's ambient music runs loops of different lengths over each other. The loops are short and simple. Their intersection is never quite the same from one minute to the next, because the loop lengths do not share a common factor and the phase relationship drifts. The harmony the listener hears is an emergent property of the room rather than a decision made by a composer.

Steven Feld writes about acoustemology — the idea that sound is a way of knowing, and that knowing-through-sound is inseparable from the place the sound is made in. Eno's ambient work is acoustemology at the scale of a composition: the piece is a small place, and knowing it requires being inside it for long enough to register how its parts phase.

The map turns this structure into a walkable laboratory. Three stations occupy the room. An FM piano plays a short pattern on a fixed interval. A second loop plays a complementary pattern on a nearby but non-identical interval, so the two patterns phase in and out of alignment over several minutes. A third voice shifts its own interval when approached, so walking near it changes the combined result. The learner contributes to the composition by moving.

A floor of position-triggered notes extends the contribution. Standing on a tile plays a tone; moving across the tiles plays a melody determined by the path. The tiles do not score themselves; they only respond to footing. The learner's walk becomes part of the piece, and the piece is different for every walk because no two walks trace the same sequence of footings.

The politics of slow time are where the map earns its reading. A composition that requires minutes of patience to hear its structure is a composition that resists the attention economy. It cannot be skimmed. It cannot be consumed at double speed without losing its point. The map encodes this as a requirement: the room rewards walking slowly enough to hear the loops cross, and punishes impatient traversal with a flatter experience.

Feld would note that acoustemology is also an ethics. Knowing through sound requires listening, and listening requires giving time to what is not yet legible. The emergent harmony of the room is a claim that some kinds of knowledge can only be had slowly, and that the infrastructure for slow knowledge is worth building even when most other infrastructures reward speed.

Within the sequence, AirMusic follows Cage's silence and precedes the sequence's vertical and horizontal wave-walks. Sound returns after Cage's withdrawal, but it returns transformed: not as composition but as emergent condition. The harmony is a property of the room and the people in it, and the piece persists as long as the room is arranged to produce it.

<<<MAP: Wavefunctions_Sky_Stairs>>>
# The climb is the curve — verticality, labour, and the politics of ascent

Climbing a staircase is already tracing a waveform. Each step is a sample; the tread is the period; the rise is the amplitude. The map takes this literally. A tall vertical amphitheatre launches the learner up through open space, and the stairs spiral around the central column in a helix whose step heights follow a sine curve.

Sarah Ahmed's work on orientations extends to verticality. The staircase is a compulsory orientation: climbing is the only way up. The learner cannot fly and cannot teleport. The rise is paid for in footsteps, and the footsteps are exactly the samples of the sine curve the map is built from. Labour and wave are the same operation in this space, and the map makes the equation physical.

Three staircases climb in parallel, each bound to a different function. One follows sin, another cos, a third a higher-frequency harmonic. The three diverge and converge at predictable intervals, so the phase relationship is visible as a spatial gap between the treads. A learner on the sin staircase can look across and see the cos climber ninety degrees out of phase, sometimes higher, sometimes lower, always out by a quarter of a cycle.

The phase gap has a social valence. Two learners climbing the sin and cos staircases simultaneously are doing the same kind of work at different times. Neither is ahead of the other on any stable measure; the lead alternates as the phase drifts. The map refuses to stabilise a single hierarchy of altitude. The higher staircase is only momentarily higher, and the position will invert before the climb is done.

The floating cube fields drift at different altitudes around the tower, sampling the wave equation at that height. Their density thins with elevation and thickens at the nodes. A reference panel at the landing reads out the learner's current height as a value of sin(angle), where angle is the distance travelled around the helix. The reading is the labour receipted into a number.

The sequence's politics of ascent crystallise here. Climbing a sine wave is harder than climbing a straight staircase because the rises are non-uniform: steep where the curve is steep, gentle where the curve is gentle. The learner's body learns the derivative of the function as a fatigue distribution rather than as an abstract quantity. The map argues that the wave has a body when the wave is walked, and that the body is the surface on which the wave's shape is actually legible.

Within the sequence, Sky_Stairs returns to embodied wave experience after the conceptual pauses of Cage and AirMusic. Where Sine_Space put the wave under the learner's feet horizontally, this map puts it vertically and asks the learner to climb it. The climb is the proof.

<<<MAP: WaveFunctions_TrigWalkingPath>>>
# Ninety degrees is a relation — sin and cos, parallelism, and the politics of offset

Sin and cos are the same function displaced by ninety degrees. Every introductory trigonometry text says this; few make it feel physical. This map does. Two parallel walkways run side by side across the space. The left lane's steps rise and fall according to sin; the right lane follows cos. The two lanes are close enough that the learner can step between them at any time.

Luce Irigaray argues that the politics of identity lie in relation rather than in isolation. A subject defined alone, without reference, is an abstraction that erases the relational conditions of its definition. The sine function alone is similarly abstract; it gains its character from its relation to cos and to zero and to the other harmonics it can be composed with. The map stages the relation as a physical parallelism.

Each step along the lanes is a computed block. The path generates itself a few steps ahead of the walker, so the learner always sees a short runway of coming terrain. A reference panel on one wall shows the two functions on a shared chart, with a marker indicating the walker's current horizontal position. The marker moves as the learner walks, and the graph and the footing stay synchronised.

At the midpoint of the walk, a cross-bridge connects the two lanes. Stepping onto the bridge and crossing to the other lane translates the learner by ninety degrees of phase. The learner's elevation changes suddenly — the cos track is either a quarter-cycle ahead or behind the sin track at that point, depending on direction of travel. The move is a quiet demonstration: changing phase is easier on foot than in notation, because the notation writes the offset as an argument to the function while the walk writes it as a single step sideways.

The slider bench at the entrance exposes frequency and amplitude. Raising the frequency compresses the period, shortening the distance between peaks. Raising the amplitude deepens the troughs and lifts the crests. Both sliders affect both lanes identically, because the parameters are shared. What the sliders cannot decouple is the phase relationship: the ninety-degree offset is structural, not parametric, and the map does not pretend otherwise.

Irigaray's insight is political as well as metaphysical. A relation that cannot be dissolved into independent parts is a relation that resists the reduction to separate selves. The sin-cos pair is such a relation. Any attempt to treat sine as primary and cosine as derivative is immediately undermined by the symmetric alternative. The map argues that both functions are equally fundamental, and that the fundamentality is a property of their displacement rather than of either one considered alone.

Within the sequence, TrigWalkingPath is the penultimate map. It trains the body to read sin and cos as paired, displaced, and equivalent before the Synthesis Lab asks the learner to decompose everything into sine components. The pairing is the bridge to the final map's Fourier argument: you cannot decompose into sines without knowing that sine and cosine are the same function staggered.

<<<MAP: WaveFunctions_Synthesis_Lab>>>
# Decomposition is a politics — Fourier, the primitive basis, and the decision to call a signal a sum

Fourier's theorem makes an audacious claim: any periodic signal, no matter how jagged, can be written as a sum of sine waves. The jaggedness is an appearance. Underneath it is a decomposition into simple components, and the components are always the same components — sinusoids at integer multiples of the fundamental frequency.

Bruno Latour argues that scientific decomposition is always a political act. It decides what counts as primitive and what counts as composite. Fourier's theorem decides that sinusoids are primitive. Every other waveform — square, sawtooth, triangle, a heartbeat, a vowel — is composite and can be taken apart. The decision is not neutral. It makes a particular basis load-bearing, and once the basis is load-bearing, the whole rest of signal processing inherits its assumptions.

The map stages Fourier's decision as a working instrument. A central bench holds an additive synthesiser with sliders for the first sixteen harmonics. Raising each slider adds a scaled sine at that harmonic's frequency into the output. A large display above the bench shows the resulting waveform and its spectrum side by side. Presets reconstruct a square wave, a sawtooth, a triangle, and a rough approximation of the vowel "a" as particular configurations of the sliders.

The biology stations make the decomposition ambitious. A heartbeat trace is broken into its dominant frequencies; a day-night cycle is reduced to a low-frequency carrier with seasonal modulations; a DNA helix is described as a spatial oscillator. The claim is that biology is full of oscillators and that Fourier is how they can be read. Latour would note that this claim is simultaneously a description and a commitment: describing a heartbeat as a sum of sines commits the analyst to treating sine as the relevant basis for heartbeats.

The basis is not inevitable. Wavelets offer a different basis that trades frequency resolution for temporal resolution. Short-time Fourier transforms compromise between the two. Each alternative is a different political decision about what primitives a signal should be decomposed into, and each decision is better for some kinds of signal and worse for others. The map quietly admits this by holding the sixteen-harmonic synthesiser up as one option among many, rather than as the option.

Within the sequence, Synthesis Lab is the synthesis in more than one sense. Every earlier concept in Wavefunctions is used here: sine as shape, circle as source, propagation as distance, sound as translation, silence as baseline, parallelism as offset. The lab hands the learner the operation that takes waves apart and puts them back together, and it also hands the learner the question of whether the primitive basis it uses is the one the learner actually needs. The question stays open on the exit teleporter.

<<<MAP: Chamber_Waves>>>
# Resonance is care — tuning, mutual attention, and the politics of matching

Chamber_Waves is the catalyst chamber for the Wavefunctions sequence, and it stages oscillation as a practice of mutual attention between two bodies. The learner holds a helix-firing catalyst whose frequency is a tunable parameter. A waterbomb creature bounces around the chamber at its own frequency. The science screen plots both waves and draws their product.

Karen Barad's concept of intra-action is the framework the chamber operates in. For Barad, entities do not pre-exist their encounters; they are constituted in the encounter itself. The learner and the creature are not separately frequency-bearers who happen to meet. Their frequencies matter because they are being read against each other, and the reading is the encounter. Neither side's frequency is a private property; both are shared terms of a relation the chamber makes visible.

When the learner's frequency matches the creature's, the waveforms align on the screen, the projectiles synchronise with the bounces, and a short resonance plays. The match is not an abstract mathematical identity; it is a practice. The learner tunes; the creature continues its own cycle; the learner listens for the alignment. The tuning is care. It requires attention to something other than the learner's own state, and it requires adjustment on the learner's side even though the creature is the thing being matched to.

A mismatch produces a beating pattern. The two waves slide in and out of phase, amplitude rising and falling as they interfere. The beating is the sound of unmatched frequencies, and the chamber does not hide it. Most of the encounter plays out as beating rather than as resonance, because resonance is a narrow condition and the learner has to tune the catalyst slowly to approach it.

The political stakes are in what counts as success. A combat chamber would reward hits regardless of frequency; this chamber rewards only matched hits, because the waveform's alignment is the event the science screen records. The projectile's physical impact is secondary to the frequency's alignment. The chamber redefines success as tuning rather than as scoring.

Barad's intra-action becomes operational here. The learner's attention to the creature's rhythm is not instrumental — it is constitutive of the encounter's mode. Paying attention to the rhythm is how the learner becomes the kind of entity the creature can resonate with. Without the attention, the chamber devolves into mismatched beating; with the attention, it becomes a duet.

Within the sequence, Chamber_Waves closes Wavefunctions by making oscillation the shared variable of an encounter rather than a property of a standalone system. The catalyst, the creature, and the screen together make the lesson — wave-particle duality, resonance, entrainment — a matter of finding the right rhythm with something that is not the learner. The chamber hands the learner back to the Lab with the waveform catalyst in their kit and with a tuned ear.
