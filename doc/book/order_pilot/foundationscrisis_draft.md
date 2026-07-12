# The Foundations Crisis — the order the writing found

## 1. The plaque with five statements
*register: walk*
The first room holds a bronze-framed plaque on a dark stand, five statements printed on its face, tagged I to V along the bottom edge. Click, and a small amber highlight slides from numeral to numeral. The first four are one line each: a straight line joins any two points; a line extends as far as you like; a circle can be drawn around any center; all right angles agree. You nod before you finish reading. Then the fifth. The highlight turns orange, the whole plaque warms, and the text runs four lines about crossing lines and interior angles. Euclid's postulates carried geometry for two thousand years, and geometers spent most of those years trying to derive the long one from the four short ones. The plaque keeps it glowing: the odd axiom out.

## 2. The sign that speaks about the sign
*register: walk*
The next stand is a slim mast holding a chalk slate framed in purple wire. Written across it: THIS STATEMENT IS FALSE. Above the slate a glass bulb hangs in a thin steel hoop, TRUE on its left, FALSE on its right. Watch the truth-lamp work. It eases green and TRUE swells — but grant the sentence truth and it tells you it is false. The bulb slides red, FALSE swells — but grant it falsehood and it has just told the truth. The lamp never settles. Around the slate an almost-closed circle of glowing tubes chases its own tail, arrowhead forever a hand's width behind its end. The plaque made claims about points and lines. This chalk sign is the liar: a sentence whose only subject is the sentence.

## 3. The box that contains the question
*register: walk*
On a low table sits a wooden box the color of old rust, lid closed. Its label reads S = { x | x ∉ x } — the set of all sets that do not contain themselves — and beneath, smaller: Does S contain itself? Say yes, and by its own label it must not. Say no, and then it qualifies, so it must. The liar again, dressed as furniture. Click the lid: it hinges back from the rear edge, and inside waits another box, smaller, cooler in color. Open that one — another. Five deep the nesting stops pretending, and a pale glyph glows in the last hollow: ∞. Bertrand Russell mailed this paradox to Frege in 1901, and the ground arithmetic was being rebuilt on cracked before the letter was opened.

## 4. The box, opened in source
*register: code*
```gdscript
# commons/interfaces/foundations/russell_set_box.gd — _update_paradox_text()
	match _current_depth:
		0:
			text = "Does S contain itself?"
		1:
			text = "If S ∈ S, then S ∉ S (by definition)"
		2:
			text = "If S ∉ S, then S ∈ S (by definition)"
		3:
			text = "Therefore S ∈ S ↔ S ∉ S"
		4:
			text = "CONTRADICTION"
		_:
			text = "The paradox has no resolution. Every formal system has an outside."
```

## 5. Five lines that recite a collapse
*register: turn*
Read the source before admiring the wound. The box does not derive its crisis; a five-branch lookup recites it, one printed line per opening, and the branch for depth four is simply CONTRADICTION. Depth is a counter. The infinite regress is five props and a glyph — max_visible_depth is 5 — a paradox with a display budget. What the exhibit flattens is the damage: Russell's letter did not open a toy, it broke the ground the postulates had promised, and the rebuilding of arithmetic on collections stalled in one page. Yet the code is honest where the wood cannot be: no finite prop nests forever, so the last branch stops arguing and posts a sign. The liar could oscillate all day. The set had to ship.

## 6. The machine that prints its own limit
*register: walk*
A chalk circle on the floor, and inside it a standing slab on two steel legs. Printed across the panel: G: "G IS NOT PROVABLE" — and beneath, smaller and purple: = this very sentence. Out of the G a glowing loop spins and bites back into it, arrowhead first — the liar's own tail welded in wire, captioned G names itself. From the right edge a steel prover arm swings in, a two-jawed clamp stamped PROVE reaching for the sentence. It seizes. A red JAM flare, the whole panel flushes hot, the arm shudders and retracts. Then, overhead, a gold plate breathes into view — TRUE, BUT UNPROVABLE — holds, fades, and the arm swings in again. This is Godel's 1931 sentence staged as a machine: the true claim no derivation reaches, watched failing to be reached.

## 7. The jam, scheduled
*register: code*
```gdscript
# commons/artifacts/godel_sentence_machine/godel_sentence_machine.gd — _process()
	# phase 0.00..0.40  attempt: arm swings in toward G
	# phase 0.40..0.55  jam: arm shudders, red spark flares
	# phase 0.55..1.00  conclude: arm retracts, gold verdict glows then fades
	if phase < 0.40:
		reach = _smooth(phase / 0.40)
	elif phase < 0.55:
		reach = 1.0
		jam = (phase - 0.40) / 0.15
	else:
		conclude = (phase - 0.55) / 0.45
		reach = 1.0 - _smooth(conclude)
```

## 8. The jam is on the clock
*register: turn*
Now the schedule. The seizure is not discovered, it is booked: jam = (phase - 0.40) / 0.15. At forty percent of a six-second cycle the arm must shudder, at fifty-five it must give up, and the gold plate is contractually due at the end. Nothing searches. No derivation is attempted and found wanting; the failure is choreography with a fixed curtain time. Before calling that a cheat, ask what an honest version would do: actually hunt for a proof of G, live, in front of visitors. That hunt would never come back, and the exhibit would stand still forever, indistinguishable from a broken one. The staged jam is the only way to show this limit and still open the doors. The loop, at least, spins for real.

## 9. The judge that cannot exist
*register: walk*
Stand at the same machine and time it against your breath. Six seconds: reach, seize, retract, gold. You can promise a stranger the arm comes back, because its return is written into the cycle. Alan Turing, 1936, asked whether that promise can be manufactured in general: one judge that reads any machine with any input and always answers — this one finishes, this one never will. Build such a decider and you can build its saboteur: a machine that asks the judge about itself, then does the opposite — running on when told it stops, stopping when told it runs. The liar's move, aimed at prediction instead of truth. So no such judge exists. The halting problem is this wing's second great limit, and notice: it has no bench of its own. The museum lends it Godel's machine.

## 10. Forever, implemented
*register: code*
```gdscript
# commons/artifacts/godel_sentence_machine/godel_sentence_machine.gd
@export var cycle_period: float = 6.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var phase: float = fmod(_t, cycle_period) / cycle_period  # 0..1
	# The cycle: attempt (reach in) -> jam (seize, red) -> conclude (gold verdict).
```

## 11. Forever, six seconds wide
*register: turn*
The word forever, in source, is fmod(_t, cycle_period): a six-second wheel that wraps. It has to be. _process must hand control back every frame; an artifact that genuinely ran without returning would freeze the room, the headset, the visitor's hands. The engine's one absolute rule is that everything halts, sixty times a second. So the halting problem is the single exhibit this museum can never perform, only mime — every indoor forever you will ever be shown is a modulo. That is worth keeping. Turing's limit is not scenery here; it is the reason the scenery works at all. The scheduled jam and this wheel are the same confession at two depths: what cannot be computed can, at best, be scheduled.

## 12. The tower of patches
*register: walk*
Past the machine stands a tower of five translucent floors, each narrower than the one below, tagged S1 to S5 up the side. In every floor an opening glows the familiar gold — the same gold as the unprovable plate — and above each opening hovers a small cyan block labeled + AXIOM. A pulse climbs. When it reaches a floor, the block descends and seats itself; the gold cools to cyan and nearly closes; that level is patched. The instant it seats, the floor above flares a fresh gold hole. Patch, climb, flare, all the way up — then the whole thing wraps and begins again at the bottom. Adopt the unreachable truth as a new axiom and you own a larger system, which manufactures its own unreachable truth. Five levels are enough to teach the rhythm.

## 13. Renovation as a way of life
*register: turn*
The tower sells repair as rhythm. Each patch is real — S2 truly seals the hole S1 could not — and each patch grows the building, so the leak moves one level up and one size larger. What the loop flatters is the calm. In working mathematics, adding an axiom is not an elevator ride; it is a fight about what the subject is. Choice was contested for decades; large-cardinal axioms still are. The exhibit's pulse climbs at a fixed pace, as if patching were maintenance rather than allegiance. And the wrap at the top quietly teaches despair on a timer: five floors, then reset. Godel's second act is stranger than that — the ladder has no top, and every rung is a decision about whom you trust.

## 14. Two rings and a gold remainder
*register: walk*
A low plinth carries two rings of light: an outer blue hoop labeled TRUE, an inner cyan one labeled PROVABLE, and between them a flat gold band. From above, small white beads rain down in a staggered drizzle — statement-tokens, the placard says. Most settle inside the cyan circle: true, and reachable by derivation. Some land in the gold between and stay there, pulsing — TRUE BUT UNPROVABLE, the sign reads. One bead never fell with the others: fixed in the band, brighter, tagged G, breathing where Godel's sentence lives. The sorter's whole claim is drawn on the floor in circles: the provable is a proper subset of the true, an inner region with a remainder that never empties. Watch long enough and the rhythm is plain — most truths land inside, and the band always catches its share.

## 15. The sorter's dice
*register: code*
```gdscript
# commons/artifacts/provability_sorter/provability_sorter.gd — _build_tokens()
	var i: int = 0
	while i < token_count:
		_drop_t[i] = _rng.randf()                        # stagger the fall
		# roughly 1 in 4 lands in the gold gap (true-but-unprovable); rest are provable
		var gap: bool = (_rng.randf() < 0.28)
		_is_gap[i] = 1 if gap else 0
		_ang[i] = _rng.randf() * TAU
		if gap:
			_rest_r[i] = gap_r + _rng.randf_range(-0.02, 0.02)
		else:
			_rest_r[i] = _rng.randf() * (inner_radius - 0.04)
```

## 16. The lottery inside the sorter
*register: turn*
Find the sorting rule in the source: var gap: bool = (_rng.randf() < 0.28). Which statements land forever beyond derivation is decided by a random draw against a hand-set dial, and the comment above it shrugs — roughly 1 in 4. This is not laziness; it is the theorem wearing overalls. A procedure that could examine a statement and announce true-but-unreachable would be exactly the decider Turing forbade — a working sorter would refute its own placard. So the artifact rolls dice and hides the confession in a comment, honester than the plinth it stands on. What the staging still flattens: the band's population is no fixed rate of nature. Candidates drift in and out of reach as axioms are adopted — the tower runs next door — and 0.28 freezes a border that is actually a negotiation.

## 17. The table where the fifth is denied
*register: walk*
A round table of dark glass, edged with an amber rim that glows: the Poincaré disk. Across its face run eight blue arcs, and every one meets the rim at a right angle. These arcs are this floor's straight lines — geodesics — and through a point beside any one of them pass many others that never cross it. A red triangle sits near the center, its three sides bowed inward, its posted angle sum about 150 degrees, thirty short of the flat page's 180. The rim is infinity: an endless plane compressed to a tabletop you could lean over. This is the fifth postulate denied outright — and nothing collapses. The other four hold. Triangles thin, parallels multiply, and the geometry runs on, consistent, hyperbolic, at home on a coffee table.

## 18. Infinity as a coaster
*register: turn*
The disk domesticates its own bad news. Infinity as a coaster, the great denial as table decor — walk past too fast and it reads as a curio, not a crisis. Its comfort is borrowed, too: the disk is a model built inside the old flat geometry, so what it earns is relative safety — if the plaque's world is consistent, so is this one. Certainty is not restored; the mortgage is transferred. After this table, the fifth postulate stops being a truth you failed to derive and becomes a preference you declare, and the plaque in the first room retroactively turns into a menu. What the model forecloses is quieter: rendered flat and finite, the endless floor can be admired without ever being walked.

## 19. The sphere that keeps both faces
*register: walk*
The last alcove holds a sphere you can see into: a violet, translucent skin — and, look again, both sides of that skin lit at once, the far face glowing through the near one. Inside, a white core pulses. The tag reads A ∧ ¬A. Pavel Florensky, mathematician and priest, shot in 1937, argued that some truths only arrive as held contradictions: A and not-A together, and the world does not end. Click the sphere and it collapses — pure blue A or pure red not-A, chosen by chance — holds that single answer for two seconds, then returns to violet both. The resting state is the contradiction; the settled answer is only the visitor's brief interruption. Where Russell's box burst on contact with its own question, this surface carries the same charge and does not burst.

## 20. The disabled cull
*register: code*
```gdscript
# commons/interfaces/foundations/florensky_sphere.gd — _create_sphere()
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color_both
	# Paraconsistency made visible: the skin is double-faced.
	# Disable culling so the sphere's INNER surface and OUTER surface both
	# render at once — the boundary reads from both sides simultaneously
	# (A ∧ ¬A on one skin, not two objects). Back-lighting lets the far
	# face glow through the near one, so inside-and-outside coexist.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.backlight_enabled = true
	mat.backlight = Color(0.5, 0.5, 0.5)
```

## 21. Peace by not computing
*register: turn*
One line carries the whole theology: mat.cull_mode = BaseMaterial3D.CULL_DISABLED. Holding A and not-A is implemented as switching a default off. Renderers routinely discard the face you are not supposed to see; paraconsistency, in this sphere, is just ceasing to throw the far side away. Read generously, that is the deepest claim in the room — the contradiction was never exotic, the exclusion was manufactured, and removing it costs one line. Read coldly, the sphere buys its peace by not computing: classical logic detonates because from A and not-A anything follows, and this skin simply never runs that inference. Russell's box was an alarm — contradiction as the sign the ground had failed. Make the alarm an ornament and you may stop hearing alarms. Florensky held both readings; so should the exhibit.

## 22. One line, still breathing
*register: walk*
The exit room contains a single line of floating text, each character its own slab of glowing mesh: QFE = F − λE(S) + φΔE(S,t). The colors do the reading. F burns blue — the order every room here wanted, the plaque's old dream of ground. The middle term sits green and red — what holding an order costs, paid out in excluded possibility. And the tail, φΔE(S,t), pulses magenta and never fully dims: the equation grants its own last term an idle glow the others are denied. This is the whole wing printed once: build form, price its exclusions, and keep one term open on purpose. The liar's lamp that would not settle, the gold band that never empties, the sphere at rest inside its contradiction — each was this phi term already, met earlier and wearing work clothes.

## 23. The order the crisis makes
*register: turn*
Walk it backwards. An equation that keeps one term deliberately open. A sphere holding not-A against A. A hyperbolic disk where the fifth postulate died and nothing else did. A sorter whose gold band is stocked by dice, because no honest procedure could stock it. A tower where every patch buys a taller leak, one level up. A machine whose prover arm jams on schedule, since a true hunt would never return — and, read again, the halting judge that cannot exist. A liar's lamp. A set that bursts as furniture. A plaque of five axioms, one glowing wrong. The order was itself an argument: ground, speech aimed at itself, collapse, the two great limits, rooms for living with them. Every proof here was staged, and said so. The staging, read closely, was the most honest thing on display.

<!-- order-declaration
axioms
selfreference
russellset
godel
halting
tower
truthgap
hyperbolic
paraconsistency
formula
why: The baseline puts Russell's set before self-reference, and the draft could not hold that order: every attempt to describe the box's question ("does it contain itself?") kept borrowing the liar's whole pattern — a sentence about the sentence — in clumsier words, so the liar moved ahead and the box became "the liar dressed as furniture," which is what the walk actually says. Second real reorder: the baseline holds provability_sorter for last ("prove it — or fail to"), but the sorter's turn only bites if Turing's decider is already on the table (the 0.28 dice ARE the impossibility of the sorting), so truthgap slid forward to sit with the limits, and the Poincare disk and Florensky sphere closed the chapter as the two habitable rooms — limit first, then living with it. One concept resisted becoming concrete: halting has no bench of its own (its cast is the borrowed godel_sentence_machine, marked weak in the baseline), and the engine itself cannot host a non-returning run — so its walk had to teach through the visitor timing the borrowed machine's cycle, and its code section quotes fmod(_t, cycle_period): forever, implemented as a wheel. The danger words (set, paradox, proof, halt) resolved by debut order — set and paradox went to the box which debuts third, proof-words to Godel, halt-words to Turing — and section 1 and 2 were rewritten to say "derive" instead of "prove," which cost nothing.
-->
