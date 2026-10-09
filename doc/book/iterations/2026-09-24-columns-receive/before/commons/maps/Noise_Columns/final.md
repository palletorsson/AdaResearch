# What keeps a body changing?

Can you tell how a body changes just by looking at its strange shape?

<!-- @MeltingBerniniScene -->

Three marble columns stand in the east half of the room. Their shafts come from the same recipe, at the same resolution. The plates at their feet say nothing yet. Stand where you can see all three at once and watch for a while before you press anything.

One silhouette holds. The other two rise and sink. There may be a familiar movement among them, something the wave halls have already taught your body to expect. Choose one to follow. When it comes back, keep watching. Does the return arrive after the same interval?

FREEZE holds the columns' local clock. You can take time to walk around the shape that was passing. The rest of the museum continues. Even here, stopping has an address.

Try SPIN while the clock is held. The columns turn. A ridge slips out of sight and another arrives. The vertices of each shaft keep their local coordinates; their positions in the room change with the whole column. Transformation has returned as a way to inspect what we thought was deformation.

Stop SPIN and press MARBLE. The shaft loses its veining. The folds remain. The base and capital retain their own patterned materials. Look at the edge of the shaft, then at the surface inside that edge. The veining was never fixed to the stone. Its pattern is sampled from each point's position relative to your eyes, so on a frozen shaft the veins slide as you walk around it, and under SPIN they stayed nearly in place while the folds turned through them. A changing appearance has several places to happen, and a picture can encourage us to fold them together.

Put the veining back if you prefer it. The pleasure of the surface need not end when we learn how it works.

Now REVEAL names the three drivers. BASELINE holds a fixed value. PERIODIC follows a sine. FIELD follows a path through a seeded coherent field. Release FREEZE and compare the names with the movement you watched.

```gdscript
func driver_phase(kind: String, t: float) -> float:
	match kind:
		"periodic":
			return sin(t * melt_speed) * 0.5 + 0.5          # the shipped driver
		"field":
			return clampf(_noise.get_noise_2d(t * 0.55, 0.0) * 0.5 + 0.5, 0.0, 1.0)
		_:
			return TRIO_BASE_PHASE
```

The sine repeats after a fixed interval. At the room's speed of 0.9, that interval is about seven seconds. The field has a different history. Nearby sample coordinates give related values; the path does not carry the sine's promise of a seven-second return. That does not make it unknowable. With the same seed, settings and coordinate, this implementation gives the same value again.

Both drivers hand the shaft one number between zero and one. The code calls it a phase. For the sine, it is a remapped output rather than the angle inside `sin`. For the field, it is a sample remapped and bounded to the same range. The shared name makes the numbers interchangeable at the next operation, while their histories remain different.

In the previous hall, each bar received its own draw. Here a whole shaft receives one phase. The field is not being sampled separately at every vertex. It proposes a value; the column recipe decides where that value can go.

```gdscript
var melt_factor = pow(v, 0.5) * melt_strength * melt_phase
var height = v * column_height - melt_factor * 2.0
```

`v` marks progress up the shaft, from zero to one. The square root gives different heights different shares of the same phase. At the top, the mapped drop can reach 0.70 metres. The phase also enters a bulge further down the function. Ribs, twists and offsets were already there before the field arrived.

Look again at BASELINE. It is held at 0.10, and it is already strange. The fixed reference is itself a made body. We have chosen something to keep still so that another change can become legible.

This gives a practical answer to what bodies are possible with the tools we have acquired. A coherent field can supply variation, but it does not contain a column. Rings of vertices, a spiral, a height rule and a material make that variation into this body. Give the same values another recipient and another world can appear.

The recognisable column also brings an expectation: it should hold something up. These display columns have no supporting collision bodies. They carry the appearance of architecture without its load. Calling their movement melting names what we see; it does not establish that stone, heat or erosion is being simulated.

There is a smaller interruption inside the smooth movement. Each moving shaft is rebuilt at most twelve times a second. Between updates, the mesh holds its last shape. The readout reports that budget and the last phase actually used. Our earlier trace had gaps between samples; this surface has intervals between rebuilds. What looks continuous is again being afforded in portions.

<!-- @dark_sphere -->

Leave the columns frozen for a moment and turn to the dark orb. Its sheen shifts. Stay long enough to notice the pulse, and the pool of shadow beneath it slowly deepening and fading. The room has not stopped breathing just because one instrument has stopped counting.

This body uses another local clock. Its script also contains a sine:

```gdscript
var pulse_t := (sin(_time_elapsed * pulse_speed) + 1.0) * 0.5
```

This time the value enters brightness and emission. It does not rebuild the sphere's mesh. The body also turns slowly, and the pool beneath it pulses in opacity on a slower sine. A single appearance gathers several operations that our earlier halls let us separate.

The dark sphere was described as a neutral anchor. Looking for longer complicates that description. It is active, but its activity is easy to pass over beside the tall columns. The distinction between foreground and background is also a distribution of our attention.

You need not make it illustrate the columns perfectly. It can keep its quieter presence. It gives the local pause an outside: another process goes on while we concentrate on this one.

<!-- @synthesis_stand -->

Nearby, the darkness has become six small orbs. They turn together in a ring, at alternating heights. There is an empty middle. Walk far enough around them for the gaps to change.

This work belongs to the same dark-sphere family. The stand chooses `presence = hush` and `body = swarm` before the scene builds. The first setting makes the presence smaller and quieter. The second chooses a construction with six members. Their common motion is the rotation of their parent; they are not steering themselves around one another.

```gdscript
var count: int = 6
var ring: float = _radius * 0.95
var small: float = _radius * 0.40
```

The array has come back inside a body. So have the circle and the alternating value. Earlier, a field varied a shaft while its mesh connections remained. Here, selecting a construction changes how many parts the body begins with. These are different kinds of change, and our toolbox contains both.

The stand's plaque records a chosen variant and a score from a saved comparison. That score explains something about the selection procedure; it cannot decide what you should want from this body. Perhaps the small gathering holds your attention precisely because it is difficult to resolve at a glance. Perhaps you prefer the solitary orb.

A family offers possibilities, and choosing one still leaves other members unvisited. We can name the choice without closing the family. The same is true of our route through these halls: enough attention to make a discovery, with other directions still available.

Noise One takes the next step. Two surfaces will receive the same field and spend it differently, as relief and as colour. We leave with a question about the receiver as well as the source: what can this body do with the value it has been given?
