# wavefunctions: the chapters

## WaveFunctions Intro

*WaveFunctions_Intro*

### Returning differently

The ring marks a place the bob keeps leaving.


A thin line hangs from the pivot towards it. Take the bob to one side and release it. Watch the first crossing of the ring, then the next. Something has returned. Before looking at the numbers, try to say what has not.

The counter may already be above zero. Taking hold of the bob gives us a beginning inside a swing that began earlier. Those crossings remain in the count.

At the ring the angle is close to zero on both passes. The velocity reading carries a different sign. One zero is on the way out; the other is on the way back. A position that looked sufficient a moment ago needs another number before we can say what happens next.

Follow the bob towards an end of its swing. It slows, seems to wait, and turns. The speed has reached zero there too, but the angle has not. The body can be still for an instant without having finished moving.

We have met position, velocity and force in earlier rooms. Here they take turns making the return. These are the state updates in the pendulum's physics step, with the optional driving force omitted:

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
```

The angle supplies a restoring acceleration. Acceleration changes velocity; damping reduces it; velocity changes the angle. At the next step, the new angle enters the first line. Read down, then return to the top. The repetition in the code makes a return in the room without listing the positions the bob must visit.

Now release it from the other side. Try giving it a small movement as you let go, then releasing it as nearly still as you can. The hand can supply speed as well as a starting position. But how much of the hand gets through?

The release code takes a velocity averaged from recent positions and projects it onto the direction of the swing:

```gdscript
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

The dot product keeps the part along that tangent. A sideways flourish can occupy your hand and contribute little to this number. The constraint makes the pendulum manageable: one angle, one angular velocity. It also gives you something to play against. Try two different gestures that leave a similar swing. Their resemblance belongs to what this body accepts from them.

Behind the bob, a curve predicts six seconds from a standard starting angle. Make a larger release and compare it with that curve. The prediction did not watch your hand. It began with another condition. A wide swing also presses against the small-angle approximation in which length, with gravity fixed, sets the period. The actual restoring rule still contains `sin(_angle)`. Give several complete swings time to pass before deciding how their rhythm differs.

There are several beginnings here: the engine's, the counter's, the prediction's, the moment you let go. They do not have to coincide for the experiment to work.


The nearby cubes return by other means. A clock prescribes one cube's bobbing; a steady rotation brings another back to its orientation; a third listens to this pendulum's signal. Similar repetitions can be made by different arrangements of state and time.

Our counter can tell us that the bob crossed the middle. It cannot show the gesture that started this particular swing. We leave with a number that has kept something, and a reason to want more than a number. In the next room the past takes up space.

---

## WaveFunctions Pendulum

*WaveFunctions_Pendulum*

### Where a swing leaves its past

Behind the bob, something is leaving the room very slowly.


Stand beside the frame and follow the swing. Then choose one teal mark just behind it. The bob turns. Keep looking at your mark: does it turn too?

It continues away along the hall. Walk beside it. From here the whole record resembles a wave, although the bob has only swung in one plane. The long direction belongs to something the bob did not do.

Each mark keeps a position and a time. When the record is drawn, this line gives it depth:

```gdscript
var depth: float = (time - p.z) * time_speed
```

`p.z` holds the time of the sample. Subtract it from the present and an age appears; multiply by 0.6 metres per second and that age becomes a distance. An old moment is further away. We can walk beside a duration because a direction has been given another job.

Look at the two intervals on the plate. FINE requests 25 milliseconds. The actual gaps are about 16.7 to 33.3 milliseconds. Which rhythm is in the drawing?

The recorder works on a physics clock ticking sixty times per second. Its request falls between ticks, so the gaps alternate between one tick and two. The small mismatch has a place in every swing's record. The cyan joins can make it easy to overlook.

Press COARSE and let a few swings leave their marks. Now find two crossings of the record's centre line that go the same way, one full swing apart. There are far fewer marks to count between them. Divide the measured period on the plate by the requested interval: does it come close to your count?

Keep watching as the older marks move away. Compare how far the oldest gets before disappearing. The rougher line can reach further into the past.

Two endings are written into this list:

```gdscript
while trail_points.size() > max_trail_length:
	trail_points.pop_back()
while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
	trail_points.pop_back()
```

The newest samples enter at the front. These lines remove from the back: first anything beyond three hundred entries, then anything older than ten seconds. FINE fills the available entries in roughly 7.5 seconds. COARSE keeps around fifty under the age limit. We changed which detail was affordable, and gained duration. A person looking for a small tremor and a person looking for a long return would have different reasons to choose.

Walk to the far end and wait with one mark. It is there, then absent. No fading gives it a farewell. The pendulum carries on from its current angle and speed; this little piece of its accessible past has gone.

Now press STROBE. The sampler uses the period measured from the pendulum's own crossings. After a few swings, compare the moving bob with the sparse record behind it. The marks nearly line up. Tick-sized differences remain, but much of the movement has vanished from what was kept.

This can become an instrument for finding repetition. It can also make repetition look like stillness. Try reading the marks before glancing back at the bob. The same setting helps with one question and makes another difficult to answer.

RESET begins this experiment again: starting angle, local time, empty list. The museum continues. We have already seen how useful it is to make a beginning without beginning everything.


Across from the sampler panel, a drum turns beneath a pen. There, time takes an angle instead of a depth. In the point rooms, the drawing dot asked whether a hand had moved far enough to keep another position. These recorders ask different questions of what passes them.

We could stay and change what a record values. Ahead, rising and falling are being given yet another direction: two walls carry waves along a passage. A line that helped us read time will become something we read with a moving body.

---

## WaveFunctions Sine Space

*WaveFunctions_Sine_Space*

### What a wave can hold


The blue surface is tilted towards an open edge. Choose a hollow. Will a body that reaches it leave again?

Press RELEASE on the side desk. Thirty-two spheres arrive together. Follow one while the others keep moving. When it meets a fold, its next position depends on contact with that surface and sometimes with another sphere. The landscape has become part of the movement.

After twelve seconds the bodies stop. The small display separates those that crossed the outlet from those still inside and those that left elsewhere. The spheres in the neat rows below are a record: the program moves each departed body there and removes it from further collisions.

Leave RELIEF alone and press SIZE. The surface waits for a larger body. Release again. Which hollow from your first prediction still matters? Cycle SIZE once more to try the smallest spheres. A place in the landscape has dimensions; so does what arrives there. The name of the wave has not told us their relationship.

RESET returns the middle size and the original relief. Now change RELIEF and repeat. RELIEF cycles through three height ranges. From the middle setting, one press makes the folds steeper; the next makes them shallower than when you arrived. Their positions across the tray stay the same. You have changed the surface's height range, then watched what that means to a body with its own size, mass and contacts.

Open RULE. Before the heights are rescaled, the surface begins with this product:

```gdscript
samples.append(sin(TAU*0.9*x) * sin(TAU*0.9*z))
```

One sine repeats across the tray and another along it. Their product supplies a height at each sampled address. Triangles join those addresses. Then a further line gives the visible mesh a collision shape:

```gdscript
collision.shape = mesh.create_trimesh_shape()
```

The surface now participates in the physics simulation. It stays still throughout the trial. Time belongs to the moving bodies and to our observation window.

Look again at STILL IN. Twelve seconds gave us time to compare. It did not give us forever. A body present at this deadline has not been proven permanently trapped. And if the purpose were to hold something here, our judgement of the same count might change. What else would we need to learn before calling this hollow a shelter?


Beyond the tray, at the mouth of the passage, a fold comes towards you.


There is a corresponding fold on the other wall, a little out of step. Enter at the end beside the tray and stop. Choose a narrow place ahead. Watch what becomes of it while you stay where you are.

The walls keep changing the invitation. Walk back to the panel and press FREEZE. Now the folds wait for you. Pass one, turn, and approach it from the other direction. A shape can come to meet a body through its own motion or through the body's movement. For a moment these felt alike.

Run the walls again and follow a small ripple across a broader fold. The layers slip past each other. Walking the frozen surface carries one arrangement past the eye; advancing the phase changes how its layers agree. We have found a difference inside the resemblance.

Leave AMP where it is and slide PHASE through half a turn. Look at a place where the left wall approaches the middle. What is the right doing now?

Both sides bend the same way. The passage swerves while the readout settles at 2.00 to 2.00 metres. Slide back towards zero and openings and pinches return. One relative setting has changed the kind of passage the pair makes.

Here is how a displacement is placed on either side:

```gdscript
var x_pos: float = base_x - side * displacement
```

`side` is -1 on the left and 1 on the right. The same positive value moves both walls inward. Give one wall the negative of the other's value and their movement across the passage agrees instead. A half-turn phase offset does that to a sine. It does it to every sine in this sum:

```gdscript
offset += base_amplitude * amp_multiplier * amp_mul * sin((base_frequency * freq_multiplier * freq_mul) * z_norm * PI + phase_shift + phase_layer)
```

Read the terms through what you just changed. Amplitude multiplies the depth of a fold. Frequency sets how many returns fit along the passage. Phase changes where in the return a wall stands. The fundamental makes 4.5 cycles over seven metres; two higher spatial frequencies add the smaller ripples. All receive the running phase, but their different wavelengths make the layers drift at different speeds.

Return PHASE to half a turn and inspect a bend. The number still says two metres. Notice its name: `x-gap`. It compares the two walls at matching positions along the passage, across local X. The shortest way between curved surfaces need not follow that direction. We have made a constant width by deciding how to measure it. Which width would matter to a body trying to get through?

Bring PHASE back towards zero, then raise AMP. Approach a pinch slowly. Try crossing a visible crest instead of following the opening.

You can pass through. The walls have no collision shapes; a thin floor slab above the museum deck supplies support. Yet the surfaces have already offered a direction, a narrowing, a reason to hesitate. Their influence did not wait for collision to be enabled.

Try following the apparent passage for a few steps, then cutting across a fold. The same construction permits both. Giving these surfaces the power to stop you would change what can happen here, and it would require another part of the program.

RESET restores the declared settings. The walls begin to disagree by the familiar amount. You can recognise the passage and still choose a different route through it.


The small case beside the tray desk offers another view of the wall rule. Below the bridge, the older floor of spheres rises and falls through a product of two sines. A repeating value has acquired several bodies already.

Ahead, a point travels around a circle. A graph grows beside it, then stays while the point keeps turning. Follow the point and try to predict the graph. After walking among these folds, we can look at one way their returning values are made.

---

## WaveFunctions Unit Circle

*WaveFunctions_Unit_Circle*

### A circle becoming a graph

How can going round a circle make a line that rises and falls?


Follow the point on the circle and look at the projection rods beside it. When the point reaches the top, compare its height with the corresponding part of the wave. Repeat at a side and at the bottom. The graph builds for two turns, then keeps its steps. The point goes on turning beside what its movement has left.

![The turning point at the top of the complete circle, inside the museum.](/book-review/doc/book/figures/wavefunctions/unit-circle-return-museum.png)

The point's vertical position rises and falls while its journey continues around the circumference. Its horizontal position follows another cycle. The two projections do not reach their extremes together: when one is at an extreme, the other passes through its middle.

Pick four reference positions around the circle: right, top, left and bottom. At each, compare the point's horizontal and vertical offsets from the centre. At the top and bottom, the horizontal offset returns to its middle while the vertical offset reaches opposite extremes. At the sides, those roles exchange. Use that sequence to predict a quarter of the adjacent graph before following it. Then start your reading from a different reference position. You have changed where you begin describing the cycle without changing its order. A beginning is needed to label the progression, even though the circle itself has no privileged first point.

For a circle of unit radius, those coordinate values are sine and cosine. The adjacent graph gives angle progression a new axis and uses one changing coordinate as height. It unfolds a relationship already present in the circular motion. The graph is not the path the point takes across the floor; its horizontal direction has a different meaning from the circle's horizontal coordinate.

Find a height that appears twice in a cycle. One occurrence belongs to a rising part and the other to a falling part. Knowing the height therefore does not recover the whole angular position. The missing distinction matters whenever a cyclic process is described by one measured value.

The displayed construction is finite. It adds sampled steps until its allotted cycles are complete. The point returns to the top; no new step arrives. Those kept positions let you count and compare, but the spaces between them remain. Resembling a bridge does not, by itself, make this graph a route for your body.


Next, a lattice of oscillators asks what happens when neighbouring cycles influence one another. You have followed one point and its projections; now look for relationships between many moving points.

---

## WaveFunctions 3D Wave Propagation

*WaveFunctions_3D_Wave_Propagation*

### The motion that travels

How can a disturbance travel while its parts stay near their places?


Choose one sphere near the centre of the lattice. Follow that sphere alone for several movements. Then widen your attention to its neighbours. Their movement can be much smaller. Compare when they rise together and when their displacements differ, without abandoning your first sphere as a reference. The panel begins with COUPLED and SINE. RESET returns the same still lattice and starts its drive again.

The spheres remain at their horizontal grid positions. Their movement is vertical. The pattern spreading across them can therefore travel without any one sphere crossing the whole display. This is the distinction to establish before naming the result a wave.

Select two neighbouring spheres and look for a moment when their heights differ. Follow the pair through several movements, describing their separation rather than only the larger pattern. Now choose two spheres farther apart and make the same comparison. Similar heights at one instant do not establish that the two places are always moving together; watch which way each moves next. If you find a repeating relationship, check whether it persists through another cycle. This is a way to investigate coordination without assuming every visible crest is a travelling object. The pattern needs more than one instant to reveal what is changing and what remains related.

Press SINE; the button now reads PULSE. After a short wait, the centre receives one push. Follow what happens beyond it. Press COUPLED; it becomes INDEPENDENT, and the same push begins from the same still lattice. What has stopped travelling? Press INDEPENDENT to restore COUPLED before explaining the difference. Every button restarts the comparison; it does not cut a moving wave midway.

Each oscillator has its own restoring influence towards an equilibrium and a damping term that resists its velocity. Coupling adds another influence: a neighbour displaced differently contributes a force. The program gathers those forces and then updates the oscillators' velocities and displacements. SINE keeps driving the centre; PULSE adds a single initial velocity after half a second. The same source can now be tried with and without the links.

The readout reports the largest displacement reached by one immediate neighbour since the reset, in millimetres. Under SINE it may be easy to miss that small response among the larger centre movements. PULSE makes a different comparison visible without changing the spring, mass or damping settings. A measurement can help you notice a motion; it does not replace watching which sphere moves next.

Look at an edge and then at the interior. An edge cell has fewer neighbours. A boundary is therefore part of the mechanism, not merely where the picture happens to stop. The finite arrangement cannot behave exactly like an unlimited medium, and these simplified links do not claim to reproduce every material that carries waves.

Try describing the display twice: first as a collection of individual moving spheres, then as a pattern moving through their relationships. Each account makes something visible and leaves something out. Neither requires the spheres to agree consciously or to know the pattern they collectively form.


The switch disconnects all the links at once. Removing only selected neighbours remains a further experiment: a different boundary inside the same lattice. The next room turns to sound, where one oscillation can modify another and a relationship between simple sources can change what you hear.

---

## WaveFunctions Effect Sound

*WaveFunctions_Effect_Sound*

### One wave inside another

In Sine Space, a sampled wave carried spheres and two moving walls suggested a passage. Here the wave enters another rule. Past the racks, near the far end of the hall, two balls sit in separate cages above desks. Begin with one note.


The blue ball belongs to the carrier, the orange to the modulator. Their desks leave room to approach each separately. Press BASELINE, let the short note end, then press HOLD to keep it as the comparison's A.

Leave the blue ball where it is. Lift the orange one a little and listen again; PLAY sounds the current setting without another movement. While the ball is moving far enough to retrigger, the rig starts fresh notes at most once every 0.3 seconds. A drag can become a run of beginnings. Let the ball rest and give the note time to finish. Before giving the change a name, decide where you heard it: at the beginning, through the middle, or near the end.

COMPARE returns A, leaves a quarter-second gap, then plays the current note B. You do not have to keep the first sound intact in memory. Look at the `differs:` line. If the lift changed only I, the modulation index, we have one change to listen through. If other values moved too, return to BASELINE and try a more deliberate lift.

At index zero, the modulator contributes nothing to the carrier's phase. Raising it gives that contribution more depth. A sound may become brassy, brittle, bell-like, or acquire a quality for which you have no ready name. Keep listening before choosing a familiar object to stand in for it.

The two oscillations meet in this line:

```gdscript
var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
```

The modulator is inside the sine's argument. Adding it there advances or delays the carrier's phase; the envelope outside controls the note's rise and fading. The instrument names this phase modulation: an FM-style synthesis method that also changes instantaneous frequency. The orange contribution is not mixed in as a second audible output. It changes how the other oscillation proceeds.

Now keep the height of the orange ball as steady as you can and change its depth along the desk. That direction changes the modulator's decay. Listen through the tail before moving again. Can the altered character persist while the note grows quiet?

The modulator has a fading of its own:

```gdscript
var mod_env = exp(-t / mod_decay)
var modulator_freq = carrier_freq * mod_ratio
var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
```

A longer `mod_decay` keeps the phase disturbance present for more of the note. The carrier's envelope can remain the same. Something we first heard as one fading has separated into two processes we can vary.

Try the orange ball's left-to-right direction last. It changes the ratio between the oscillators' frequencies. Keep a reference and compare. Listen for a relation you want to return to, even if it refuses the name of an instrument you know. A setting that would spoil one imitation may be the beginning of another sound.

BASELINE is a chosen reference too: a 440-hertz carrier, an attack and a decay, index zero. The generator still applies its `tanh` shaping and gain to the output. Calling this the beginning makes a comparison possible; it does not uncover a sound before all decisions.

HOLD can keep a note without knowing what you liked about it. COMPARE gives that decision back to your ear. The rig reports changed parameters, but there is no field in its list for the difference that made you want to listen again.


Look back at the scope. Once the orange contribution is above zero, raising its index need not make the orange trace taller: the display divides that lane by the index to fit it. The output changes while the apparent height of its cause can stay much the same. Even this small window has an arrangement to uncover. It shows two carrier periods near the attack, not the whole fading note. The coloured cube gives some of the settings another appearance. Neither can take over the listening.

Next, Bernini gives periodic change another direction: along the height of a column. Walk around it. What changes as you move, and what keeps moving when you stand still?

---

## Wavefunctions Bernini

*Wavefunctions_Bernini*

### A movement kept in a column

Can a shape keep the rhythm of a movement without travelling along it?


Choose one ridge on a twisting shaft and follow it upward. Notice how it moves around the vertical axis as height increases. Change your viewpoint and find the ridge again. Then compare it with a neighbouring column.

There are two different changes to disentangle. The shaft is already twisted as a shape: its profile varies from one height to another. It also rotates slowly as a whole. Watching that rotation does not explain how the twist was made, and following the twist does not require the column to rotate.

Look at the shaft at a low level, then at a higher level, keeping its central axis in mind. Where has the ridge moved around that axis? Continue upward until you recognise a comparable orientation again. You are reading a repeated turn through height. Next keep your attention at one level and let the column's slow rotation bring the surface past you. This second observation follows change through time. The two readings can resemble one another while using different coordinates. Say which reading you are making before comparing two columns; otherwise a turning shaft can disguise a difference already built into their profiles.

Circular coordinates provide sine and cosine values around an axis. Combining those changing coordinates with height produces a helix. Further variations in the radius and surface give the shaft its richer profile. A periodic function that previously described movement through time now helps specify where parts of a solid belong.

Look at the columns together. Their repetition creates intervals and sight lines that a single shaft cannot. The form and its arrangement contribute different things: one supplies the twist, the other decides whether you meet a field of objects, a threshold or an aisle. This version presents a repeated set rather than a control for rearranging the plan.

The scene is inspired by spiral architectural columns. Its mathematical construction does not account for the whole history of a building, the labour of making it, or what it means to those who use it. A low generated hum accompanies the columns; its level is tied to their rotation speed. Touching a shaft does not play it.

From the wall, a synthetic voice attempts “right here, right now”, pauses, then begins again. This is a separate instrument. The words return while the columns keep turning. Which “now” has the repeated phrase brought back?


Try reading the shaft once as a solid and once as a sequence of changing cross-sections. The next room leaves more of its temporal composition to chance. A rule can preserve a recognisable form while allowing individual events to arrive differently.

---

## WaveFunctions John Cage

*WaveFunctions_John_Cage*

### The limits of the unexpected

What remains composed when the next event is left to chance?


Let the soundscape load, then listen long enough to separate a continuous layer from intermittent events. Count a few entrances without trying to force them into a regular beat. On a second listening, attend to the intervals rather than to the events themselves.

The background can remain recognisable while particular sounds arrive differently. There is a difference between not knowing which event comes next and hearing something the system has no means to produce. Listen for the vocabulary that persists through the variation: the kinds of sound available, their textures and their recurring relationships to the drone.

For one listening interval, attend only to whether the background continues beneath an event. For the next, attend to how the event begins and fades. A sound can arrive unexpectedly while retaining a recognisable envelope or texture. If a related sound returns, compare what seems shared and what differs without assuming it is exactly the same prepared variation. Then leave an event uncounted and listen to what remains around it. This gives you several ways to hear organisation even when the entrances resist a regular pulse. Your attention supplies a repeatable listening task, although the generator does not promise to repeat the same sequence for you.

The composition prepares a collection of generated sounds, including variations of several effect types, then makes choices about their playback. Randomness operates within that prepared collection. The program has already decided what can be selected and has supplied the rules that govern selection. Chance changes the sequence without escaping its frame.

The luminous forms respond to sound activity, but looking at them does not reveal every scheduling choice. The listening experiment also does not depend on treating them as physically located sources whose volume you can mix by walking around. Give the sound itself time to disclose its layers.

Try deciding that an interval is the part you are waiting for. This changes your listening without changing the generator. A version that admitted sounds recorded from visitors or the surrounding room would change the available vocabulary; that remains a proposed extension.


The room's title offers a reference, not a claim to perform a particular John Cage score. Its concrete question is about authorship inside a chance procedure. In Air Music, a strike will supply a more direct beginning: you will choose when an oscillation starts and hear what continues after your contact ends.

---

## WaveFunctions AirMusic

*WaveFunctions_AirMusic*

### After the strike

In Effect Sound we kept a note and changed the rule that made it. Here the hand can leave while its consequence continues.

A stick lies in a cradle at the left end of a table, front to back. Eight metal bars lie along the table beside it, the longest nearest the stick, and a pale rail runs along the table's front edge.


Take the stick and bring it down on the left-hand bar. Lift it away at once and keep listening. The contact is over; the bar glows and rings, and the plate above the row names one voice, its hertz and its age. The glow fades as the seconds count up. Decide, before the note is gone, whether what you hear is the strike or what the strike began.

Strike the same bar again while it still rings. There is another attack, but no additional voice: this bar starts its existing player again, and its age on the plate returns towards zero. Now strike a shorter bar instead, while the first is still fading. The plate says two voices, each with its own age. The first was not stopped by the second. Try to hear where one ends and the other goes on.

The bar keeps its note as a number and its ring as a curve. Each bar plays a sound it made once at startup:

```gdscript
		var envelope = exp(-t / decay_time)
		var wave = sin(2.0 * PI * frequency * t)
```

a sine at the bar's frequency under an exponential decay. After three seconds its envelope is about 37 percent of its initial value. The glow uses that decay too:

```gdscript
			current_amplitude = (hit_velocity * max_amplitude) * exp(-resonance_time / decay_factor)
```

So this is a synthesised resonance, not the vibration of a metal bar solved from its material. The length is chosen from the note, not the note from the length:

```gdscript
	return BAR_LENGTH * sqrt(root / maxf(1.0, freq))
```

The chosen relation makes length fall with the square root of frequency. This gives the row a visible order before you have struck anything. The program does not compute this note from the metal, the stick's material or the table underneath. Those bodies could change without changing the stored frequency. The resemblance is an arrangement we can inspect.

The stick's speed does reach the bar. A slow touch lands at a fraction of the level a fast one does:

```gdscript
		hit_velocity = clamp(velocity_magnitude * 2.0, 0.1, 1.0)
```

Try the same bar slowly and then quickly, and listen for what the level changes and what it leaves alone. The glow uses the strike value directly; the player maps it into decibels. A much dimmer glow need not mean a proportionally quieter note. The hand has reached two different mappings.

Now the pair. Choose two bars and strike them with a clear gap, letting the first almost finish. Reverse the order. Then shorten the gap until the second enters while the first is still loud. The plate lists both voices with their own playback ages. The ribbon adds a short piece of the two generated notes, and the sum is not a third bar. When one masks the other, let them separate again and try the gap once more.

The eight notes take C, D, E, G and A and continue into the next octave, ending at E5. That is a decision about which pairs are available to you, not a law about which pairs are good. Another cut would offer other pairs; this room offers this one.

Set the stick down more than half a metre from its cradle and leave it alone. After three seconds the return begins. Leave it at rest and listen to the last voice go.

An exponential never quite arrives at zero, but this note does end. The stored sound lasts seven and a half seconds, with a fade over its last tenth of a second. The model lets go before the mathematical tail does.

Look at the plate's other number: 12 ms. The ribbon has only that much time across its width. It reads samples near each bar's playback position, after that player's gain, before distance and the rest of the audio system. A smooth curve here still joins chosen data points. Moving your head changes what reaches you without rewriting these stored notes.


Every note here is one sinusoid under one decay. Sky Stairs next asks what a sampled curve needs before it can become a place for a body. The beat display then separates two ongoing motions from their sum. In the Synthesis Lab, we will add such sinusoids together on purpose; what the ribbon drew for you as a sum is where that begins.

---

## Wavefunctions Sky Stairs

*Wavefunctions_Sky_Stairs*

### What a curve needs from a stair

When does a sampled curve become a route a body can use?


Begin by following the treads with your eyes from the lower end. Compare one step with the next: the change of height, the turn, and the distance from the centre. Notice the surfaces joining neighbouring edges as well as the steps themselves.

The route combines an angular progression with a steady rise. Its radius also varies with a sine function. A regular rule therefore produces a stair that does more than circle a fixed cylinder. The outline breathes inward and outward as it climbs.

Choose three consecutive treads that you can see clearly from the surrounding floor. Compare their centres first, then compare the edges a foot would meet. A regular change between centres can still leave different apparent gaps at the inner and outer edges of a turn. Move your viewpoint to check whether a gap is real or hidden by an overlapping surface. You do not need to step onto it to make that distinction. Repeat the comparison where the staircase's radius appears wider. Describe which relation changed: height, turn, width or edge connection. These observations turn a general impression of smoothness into several concrete questions about support.

Those sampled positions are only the beginning of a staircase. Each needs a tread with width and depth, an orientation, and a relationship to the next tread. The default construction adds connecting membranes between facing edges. They make the gaps part of the visible argument: a formula gives positions, while a route needs provision for the body moving between them.

Do not judge the whole climb from the smoothness of its outline. An entrance, a comfortable rise, headroom and continuous support have to work at the scale of the visitor. From the surrounding floor you can follow the spiral with your eyes. That journey does not tell you whether your body could complete it.

Identify one turn or gap that would matter to a different stride. A route that feels continuous to one walker can remain discontinuous to another. The question is not answered by adding more samples alone: their arrangement and support also matter.


A handrail, supporting posts or a different connection between treads could each change this encounter; they are choices to test, not qualities the equation supplies automatically. The following room returns to interacting cycles. Keep the distinction between a mathematical relation and the particular object that makes it available to perception.

---

## WaveFunctions TrigWalkingPath

*WaveFunctions_TrigWalkingPath*

### A slow pulse from fast motions

How can two quick repetitions produce one slow pulse?


Look at the rows labelled A, B and A+B. Use the two frequency controls to bring A and B close together. Follow one part of the lower row long enough to see its movement grow and shrink, then compare that slower change with the quicker movement above.

Make the frequency difference smaller while keeping both sources moving. The envelope changes more slowly. At equal frequencies, this version's initially aligned waves reinforce one another without the same slow pattern of beating.

Keep A fixed and move B towards it from one side. Watch a single location on the lower row through a broadening and a narrowing of its motion. Now move B away again and compare how quickly that alternation returns. Avoid counting every small rise as a separate beat; you are following the larger change in how much motion is available. At a moment when the lower row is quiet, inspect A and B above it. Their contributions can remain substantial while opposing one another. A small sum therefore does not establish that both inputs have become small or that either source has stopped oscillating.

The lower row combines the two values at each sampled position and moment. When the sources are near alignment, their contributions reinforce. As their phases drift apart, they increasingly cancel; later they approach alignment again. The slow pulse belongs to this changing relationship. It is not a third independent source secretly supplying a new rhythm.

The beat readout gives the absolute difference between the two frequencies. This makes a small difference conspicuous in another form: two individually quick oscillations reveal their separation through a slow envelope. The lower row is drawn at half the raw sum's height so it fits the display, so compare the pattern rather than measuring the amplitudes with a ruler.

Try predicting how the envelope will change before moving one control. Then reverse which source has the higher frequency. The absolute difference can remain the same even though you have exchanged the roles of A and B.


This display does not generate an audible beat. Elsewhere in the hall, the paired red and blue steps give sine and cosine another body. Their quarter-turn difference sets two rows at different heights; here the question of where a curve lies can become a question of where support will be.

At the synthesis lab, you will change the contributions of several harmonics and ask how their sum can acquire a shape that no single component has.

---

## WaveFunctions Synthesis Lab

*WaveFunctions_Synthesis_Lab*

### The sum on the bench

In AirMusic one note could begin while another was already fading. Here a wave is waiting to be taken apart.

Find the bench with the dark board above it. The board carries a pale wave with five coloured rows beneath it, and the wave already has a shape when you arrive: a long slope down and a steep rise, four times across the board, drifting to the left. On the bench, at its right end, five sliders stand in a column, one for each row.

#### Five amounts


Read the rows before you touch anything. The top row is one smooth rise and fall per cycle; each row below has more, two, three, four, five, and each is drawn smaller than the one above. None of them looks like the pale wave. Press HOLD on the panel at the left of the bench and the drift stops, so a place on the board stays where it is.

Now take the four lower sliders down, one at a time, and keep your eye on the pale wave while each row leaves the ladder. What remains is the top row, drawn larger: a sine. Press BASELINE and the four return together; press H1 ALONE and they leave together. The shape you arrived at is not one thing with a slope in it. It is five smooth returns added, and the slope belongs to none of them.

Bring the second row back on its own slider and choose a place on the board. The amber line marked *mark* is one such place. Before you raise the third slider, decide what the sum will do there: the third row is at a crest, or crossing its middle, or in a trough, and its slider decides how much of that is admitted. Raise it and read the plate on the bench. Its third line lists each row's value at the mark; the fourth adds them and prints the total drawn beside them. With these five visible rows, their sum agrees with the total. The pale wave is built by this loop:

```gdscript
	var value = 0.0
	for h in range(harmonic_amplitudes.size()):
		value += harmonic_amplitudes[h] * sin(phase * (h + 1))
	return value
```

Row h is a sine at h + 1 times the phase, scaled by its coefficient, and the sum is the running total. There is no separate drawing of "the wave". The pale line is this loop evaluated 256 times across two metres,

```gdscript
const WAVE_POINTS: int = 256
const WAVE_LENGTH: float = 2.0  # Visual length in meters
const NUM_HARMONICS: int = 5
```

with the phase running four cycles across the board and the clock adding the drift you stopped with HOLD:

```gdscript
		var phase = t * TAU * 4.0 + _time * TAU
```

A slider changes exactly one number. When a handle moves, the instrument reads the handle's position back as that row's coefficient:

```gdscript
		harmonic_amplitudes[harmonic_index] = harmonic_sliders[harmonic_index].get_normalized_value()
```

Even the first slider only changes how much of the first return is present. This is a visual instrument; it does not play the curve as sound. No slider changes the fundamental's frequency. The rows use integer multiples of one phase, so the vocabulary here is five amounts. Unlike the separately struck bars, these rows cannot choose separate beginnings. A shifted row or a negative amount would need a control this bench does not offer. BASELINE returns them to the table the room was placed with:

```gdscript
		"sawtooth":
			# Sawtooth: all harmonics, amplitude 1/n
			_set_amplitudes([1.0, 0.5, 0.333, 0.25, 0.2])
```

one over n, all five present, the recipe the label calls a sawtooth. The plate's last line names every coefficient that differs from this table, so you can wander and still know how far you have gone.

With the baseline held, look at the rise. An ideal sawtooth jumps; this one climbs from trough to crest over about nine centimetres of a fifty-centimetre cycle. Its descent ripples where the ideal would be straight. Raise the fifth slider and those ripples change. The baseline peaks near 1.58; other amounts can rise further. Five smooth returns can suggest a corner and cannot make an exact one. From across the room the pale line suggests a sawtooth. At the bench its rounded rise remains available to inspect.

Take the second and fourth rows out and leave the odd three; the label offers a name. Move the fifth a little. At first the name stays. Move further and it gives way to Custom Waveform. The curve has changed continuously; the naming rule crossed a threshold. It checks all five amounts relative to the first, allowing a small difference from a recipe. Custom is a place to continue from.

Then remove the row you think matters least and find where its absence shows. It is not in one place, because each row runs the whole cycle. Near zero, a row disappears before its coefficient reaches zero: the display hides values below 0.01 while the sum still includes them. At some marks the plate can report a difference between the visible rows and the total. Something has left the picture without leaving the calculation.


#### What the room keeps

At the bench, one slider changed how much of a wave was present. Another instrument in the laboratory, Slow Circuits, offers ENTER ROOM. It takes you out of this hall and into a listening room. BACK TO HALL will bring you to the museum again. Take a phrase with you.


A loudspeaker stands inside. At the Voice station, press RECORD / END, say a short phrase, and press again to finish. Eight seconds is the limit. DEMO VOICE offers a synthetic phrase if you prefer. Listen once. Then press HEAR ORIGINAL, let it finish, and hear it again. The instrument plays the same stored recording. Repetition has not yet altered its data.

Press NEXT PASS. Something has acted on the phrase. Listen for a vowel, a consonant, a pause. Press again. Which is easiest to follow now? AUTO continues the returns; HEAR ORIGINAL interrupts them with the recording you began from. The comparison remains available even when the words become difficult to recognize.

The room keeps the result of each pass and makes that result the next input. Leaving out the worker and playback machinery, the operation is:

```gdscript
current = DSP.room_pass(current, absorption).samples
```

The next pass begins with a sound that has already been changed. Compare that with the line used when you press RESET:

```gdscript
current = original.duplicate()
```

A copy can keep the values. A filter acts on them. Here, delayed sound returns into the calculation, reinforcing some frequencies more than others. Repeating the operation makes that unevenness increasingly audible. The voice and the rule participate in what remains.

Alvin Lucier's *I Am Sitting in a Room* begins with a voice recorded and played back into a physical room, then recorded again. The room's resonances become prominent through successive returns. A digital recorder could take part in that physical process too; tape damage is not required for its central effect.[^WaveFunctions_Synthesis_Lab--synthesis-lucier]

Calling everything we hear here *analogue distortion* would hide a distinction we can investigate. In Lucier's physical setup, sound passes through air between a loudspeaker and a microphone. In this virtual room, the first recording enters a numerical model. Three delayed paths use the room's dimensions; damping changes what returns. The visible walls do not, by themselves, act on the sound.[^WaveFunctions_Synthesis_Lab--synthesis-room-model]

Go to SURFACE and move ABSORB. The panels change colour and the experiment returns to the stored voice. Begin the passes again. Keep the same phrase and compare what happens under the changed conditions. Colour and acoustic response have been connected by code. One has not caused the other.

A wall can look like concrete before we have given it any of concrete's acoustic behaviour. What would it mean to give that wall the response of cloth? Or to let a curtain ring? Those rooms are possibilities for another iteration. The current control changes absorption; it does not yet let us exchange a whole material's behaviour. Even this smaller choice makes appearance and action available to question separately.

There are other choices inside the return. Each pass is adjusted to the same peak amplitude. The recording has a fixed length, with a short allowance for its tail. Sound that continues beyond that window is cut away. HEAR ORIGINAL means the first recording this instrument stored; it cannot give us the voice before recording, sampling and preparation. Walking changes where we hear the virtual loudspeaker, while the simplified resonance model stays fixed.

Listen once more to the original. What became difficult to hear has not been deleted from every place. It remains in a buffer we chose to keep. The room's rules shaped one version of the voice; comparison lets us notice their work. Which properties would we carry into another room, and which might we let it change?


#### Back at the bench

![The five rows and their restored sum on the synthesis bench inside the museum.](/book-review/doc/book/figures/wavefunctions/synthesis-return-museum.png)

Choose BACK TO HALL and find the five rows again. Press HOLD, then BASELINE. Pick a place on the pale curve and move the fifth slider. Watch that place change. Press BASELINE once more: with the phase held, restoring the five amounts brings the curve back to where you just saw it.

In the listening room, each pass began with the altered result of the last. Here the slider changes an amount used to calculate the sum afresh. The previous curve does not become an ingredient in the next one. Both instruments let us return, but they keep different things available.

Release HOLD. The five amounts stay while the shape moves across the board. BASELINE can restore this recipe without recovering the moment before we left the hall. Repeating a recipe and repeating an exact instant ask for different things to be kept. In Random Definition, that question will meet an unfamiliar result: what would we need to retain to bring it back?


[^WaveFunctions_Synthesis_Lab--synthesis-lucier]: Alvin Lucier, *I Am Sitting in a Room* (1969). Nicolas Collins's [album notes](https://www.dramonline.org/albums/alvin-lucier-i-am-sitting-in-a-room/notes) (1990) describe the result as an encounter between a particular voice and a particular space, and discuss its realization with digital delays or samplers. Collins also attends to Lucier's stutter as a rhythmic contribution. Lucier’s stutter is part of the voice the room receives, not a fault the passes correct. “Less intelligible” describes what happens to the recording, not a judgement of its speaker.

[^WaveFunctions_Synthesis_Lab--synthesis-room-model]: Julius O. Smith III, [“Artificial Reverberation,” *Physical Audio Signal Processing*](https://www.dsprelated.com/freebooks/pasp/Artificial_Reverberation.html), explains how delays and filters model propagation, reflections and absorption, and why a response between a source and receiver depends on their positions. Ada's current three-path model is much simpler: it does not calculate reflections from the visible mesh, an open doorway or a moving microphone. The equation above abbreviates `room_memory_audio.gd` and `room_memory_dsp.gd`; the actual processing runs on a background worker.

---
