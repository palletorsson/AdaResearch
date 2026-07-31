# Catalyst Mode Triples — the 14 Unbound Sequences (PROPOSAL)

> 2026-07-31. Multi-agent design pass: two lenses (mechanics-first, QFEP-theory-first) per
> sequence cluster, 28 proposals merged by a global coherence judge. STATUS: PROPOSAL —
> Palle's call before any binding-table entry or mode script is written.
> Companion to `doc/plans/catalyst_ability_hazard_map.md` § 3 (the existing 10 triples).
> Animated gallery: see the catalyst-mode-triples artifact / session captures.

## The set at a glance

| # | Sequence | Mode | Foe kind | Friend power |
|---|----------|------|----------|--------------|
| 3 | symmetry | `symmetry` — Symmetry | transport | `twin` |
| 4 | array_tutorial | `array` — Array | goo | `repeater` |
| 6 | change | `change` — Change | goo | `integrator` |
| 8 | formfinding | `settle` — Settle | wave | `catcher` |
| 11 | noise | `noise` — Coherent Noise | swarm | `glider` |
| 15 | proceduralgeneration | `seed` — Seed | drainfriend | `reseeder` |
| 16 | softbodies | `drape` — Drape | transport | `cushion` |
| 17 | isosurfaces | `isosurface` — Threshold Extract | goo | `capper` |
| 18 | boolean_surfaces | `csg` — Boolean Carve | compound **(new)** | `carver` |
| 20 | machinelearning | `gradient` — Gradient Descent | drainfriend | `predictor` |
| 21 | graphtheory | `graph` — Edge Weaver | branch | `cutter` |
| 22 | foundationscrisis | `godel` — Incompleteness Frame | drainfriend | `oracle` |
| 23 | qfeplaboratory | `lambda` — Lambda | wave | `attuner` |
| 24 | postfoundationscrisis | `rhizome` — Rhizome | goo | `weaver` |

## Judge notes (the set as a whole)

The 24-mode timeline now reads as a single sentence: build (voxel/wedge/primitives), transform (symmetry, array, change), find form (settle), embrace structured randomness (noise through seed), soften (drape), extract and compose surfaces (isosurface, csg), then learn, connect, and finally lose and refound the ground itself (gradient, graph, godel, lambda, rhizome) — with the three crisis modes escalating from a shot that works through its own gap, to a shot whose only viable charge is the edge, to a shot that abolishes the origin entirely. Only one new foe kind was admitted (compound, for boolean_surfaces), well under the two-kind budget; it needs a multi-primitive union body with runtime mesh subtraction, which is the set's largest engine ask alongside the csg plug-drop. Everything else reuses existing FoeMode enums, and capper deliberately rides the existing porter park machinery. Three soft_stages enemies.kind entries should be updated to match the final bindings: graphtheory transport→branch, qfeplaboratory goo→wave (boolean_surfaces goo→compound once the kind exists); all four reserved mode names (array, change, isosurface, csg) are honored. Power slugs and mode ids were verified globally unique against catalyst_sequence_binding.gd's existing ten triples.

## The triples in full

### 3. symmetry — `symmetry` (Symmetry)

**Projectile.** One trigger pull fires a mirror PAIR: two bolts flying as exact reflections of each other across the aim axis, and each impact stamps a motif glyph that tiles outward across the surface under the wallpaper operations (translate, mirror, rotate, glide) — any foe standing on a symmetry-equivalent cell takes the identical hit. Firing is literally performing a symmetry group on the world.

*Animation:* The orb splits at the muzzle into two bolts that mirror-flip across the aim plane in perfect lockstep; on impact the splash glyph tiles-out into kaleidoscope wedges, each copy appearing via a visible mirror-flip or quarter-turn rotate.

**Foe (transport).** The foe walks in strict lattice steps — hop, mirror-flip its body, hop — leaving glide-reflected footprint stamps, and it evades by stepping exactly one lattice cell off its symmetry-equivalent position.

**Friend power `twin`.** Every block or wedge the player places with the catalyst bracelet is instantly duplicated at the mirrored cell across the room's symmetry axis — build half a staircase, own the whole staircase; the friend holds the axis and enforces closure on your labor.

*Animation:* On each placement the friend flash-flips like a page turning and an identical block materializes at the mirrored cell, a light seam glinting along the shared axis between the pair.

**Why.** The mechanics-lens paired-bolt-plus-stamp makes group closure the thing you literally shoot, while the theory-lens twin power extends the same closure to the bracelet build system — one operation, the group completes the rest. TRANSPORT's lattice hop is already a translation, so the foe reuses the enum with zero engine change.

### 4. array_tutorial — `array` (Array)

**Projectile.** The bolt snaps to the nearest grid cell on impact, then replicates cell-by-cell down the row at even spacing — one shot becomes N indexed strikes that fire in sequence, a visible for-loop over cells. Aim direction picks the axis; the sweep stops at walls or row's end.

*Animation:* The bolt lands on a cell, then copies stamp out one cell at a time down the row — a tile-out index sweep where each cell flashes its integer index and lights in order a beat before its strike detonates.

**Foe (goo).** Goo foes advance in straight ranks, pausing on each grid cell like a cursor stepping an index; when one converts, the conversion chain-touches down the rank one cell at a time — iteration made visible.

**Friend power `repeater`.** While an array friend follows, it locks into a fixed offset slot behind the player and re-fires a copy of every catalyst shot one beat later, the copies marching out at even grid spacing — the player's fire becomes an array.

*Animation:* The friend snaps into a grid-aligned slot with a click, and after each player shot it echoes a duplicate bolt that departs exactly one cell-width offset, one beat delayed.

**Why.** Mode id honors the soft_stages reservation and foe kind honors the declared goo, whose chain conversion down a rank IS array iteration. Repeater keeps the lesson in the player's own hands — every shot they fire gets indexed, offset, and repeated.

### 6. change — `change` (Change)

**Projectile.** A held stream instead of an impulse: the effect on the target is the integral of contact time, filling a visible accumulation bar; release early and the partial total decays back down — only sustained contact converts, making the sequence's designed sustain affordance the firing verb itself.

*Animation:* A continuous beam pours from the bracelet while a shaded area-bar swells beneath it in discrete Riemann rectangles that converge smooth the longer contact holds.

**Foe (goo).** The grey blob's color rises like a filling gauge only while the beam holds contact and drains back down the instant contact breaks — its state a running total under a rate, not a switch flipped by impact.

**Friend power `integrator`.** The friend soaks damage-over-time ticks aimed at the player (fire, toxic) into a visible reservoir; when the reservoir fills it discharges the accumulated total as one radial knockback pulse that clears nearby foes — rate turned into stored quantity and handed back whole.

*Animation:* A glass column on the friend's back fills in discrete steps with each absorbed tick, then dumps in one flash-flood pulse as the column snaps to zero.

**Why.** The reserved mode name and declared goo kind are honored, and the sustain-beam makes holding the trigger literally integration, with early release showing decay of the partial sum. Integrator closes the fundamental theorem in play: the same accumulation that converts a foe stores the world's damage-rate and returns it as one total.

### 8. formfinding — `settle` (Settle)

**Projectile.** The bolt does not fly straight: it lands and gradient-descends the actual terrain, rolling downhill with damped annealing overshoot until it rests at the local minimum, where it rings a flat detonation; a second tap anneals a stuck bolt, jolting it over the lip toward a deeper basin. Aiming becomes reading the energy landscape — and the shot can get trapped the way any optimizer can.

*Animation:* The bolt drops, then rolls downhill along the surface like a marble in a bowl — overshooting and damping in visibly shrinking swings — hesitating in every dip until a second-tap jolt shakes it over the rim, then settling motionless and ringing a flat ripple outward.

**Foe (wave).** The foe advances with an oscillation whose amplitude visibly anneals — wild jitter when hot and far, damping swing by swing to near stillness as it closes — always drifting toward the room's low points.

**Friend power `catcher`.** When the player falls past ledge height, the formfinding friend snaps beneath them into a catenary net that catches the fall, sags to its minimal curve, and springs them back up to the rim — fall rescue over voids and pits.

*Animation:* The friend leaps under the falling player and stretches into a sagging chain-curve net; the sag visibly relaxes to the minimal catenary shape, then rebounds, tossing the player back to the edge.

**Why.** WAVE reused as damped oscillation IS annealing made visible, so the new 'mesh' kind is unnecessary and the new-kind budget is saved for boolean_surfaces. The rolling-downhill shot with a tap-to-anneal escape teaches gradient descent including its local-minimum trap, and catcher answers the one movement gap existing powers leave open — falling — with the sequence's own solved form.

### 11. noise — `noise` (Coherent Noise)

**Projectile.** The bolt never flies straight: its velocity is steered each frame by a seeded curl-noise field, so the path is a coherent streamline — wandering but smooth, every deviation correlated with the last, unlike chaos-mode's jagged jitter. Re-firing from the same cell reuses the seed, so the player watches structured randomness repeat: similar paths, never identical — entropy-with-memory as flight.

*Animation:* A grainy orb swims along a visible curl-noise streamline — smooth serpentine drift, never a jagged jump — trailing a ribbon that hangs in the air as a smoke-line record of its path, its shell flickering through stacked octaves.

**Foe (swarm).** The brood moves as correlated static: each body jitters, but neighbours jitter together, so the pack drifts in slow smoothed billows — white noise resolving into smoke.

**Friend power `glider`.** While a noise friend follows, it emits a coherent flow field around the player: stepping off an edge caps fall speed and carries the player horizontally along the field's streamlines, turning drops into ridable drifts across gaps — a movement answer distinct from launcher's jump and porter's platform.

*Animation:* The friend spins a slow halo of drifting arrow-particles; the player steps off an edge and glides down along the arrows in one smooth streamline instead of plunging.

**Why.** Mode id stays 'noise' (freeing 'gradient' for machinelearning), the foe honors soft_stages' declared swarm, and the curl-streamline flight from the theory lens is the sharper demonstration: randomness that remembers its neighbors, contrasted live against chaos mode. Glider makes coherence a way of moving — the player literally rides structure through disorder.

### 15. proceduralgeneration — `seed` (Seed)

**Projectile.** The projectile is a seed pellet: on impact it runs a miniature space-colonization growth — attractor points scatter, branches colonize toward them, and a small rule-grown lattice stands where the shot landed, briefly rooting a foe it wraps. The rules are fixed and the seed varies per shot, so every firing is a live proof that rules plus randomness build a world without an author; it also matches the sequence's existing 'seed' catalyst affordance and seed_orb chamber artifact.

*Animation:* A seed pellet arcs and sticks, then tile-out growth erupts: attractor sparks scatter, twigs colonize toward them branch by branch, and a small lattice-form stands in about two seconds — same motion grammar, different form every shot.

**Foe (drainfriend).** The grey body ratchets forward in stutter-steps and, on catching the player, reels a converted friend backward on a grey thread — colour peeling off the friend as the generator re-generates it into the brood.

**Friend power `reseeder`.** While a seed friend follows, it can walk to the nearest active vent and re-seed it: the vent's next brood spawns already advanced one personality step (foe becomes wary), answering foe pressure at its source rather than body by body — the player curates the generator instead of fighting its output.

*Animation:* The friend kneels at the vent mouth, a spiral of seed-glyphs gradient-descends into the shaft, and the vent's glow morphs grey to green as the next brood emerges already half-tame.

**Why.** The theory-lens triple wins whole: drainfriend is soft_stages' bound kind and plays the generator's dark side (regeneration overwriting conversion), while seed/reseeder put the player at the sequence's Lambda_Edge — not authoring the world, but choosing where and when the rules run. 'Seed' also lands on an existing catalyst affordance, costing near-zero new vocabulary.

### 16. softbodies — `drape` (Drape)

**Projectile.** The projectile is a spring-mass jelly blob that visibly oscillates in flight, and on impact it does not bounce or explode — it drapes, conforming to the surface of whatever it hits, then reaction-diffusion spots bloom across the stretched skin before it fades. One shot performs the whole sequence: spring-mass deformation, cloth draping, and Turing morphogenesis, with the target's own shape doing the forming.

*Animation:* A wobbling jelly blob flies with visible spring-mass oscillation, then on contact peels open and drapes over the target's surface like a tablecloth, Turing spots blooming across the stretched skin as it settles.

**Foe (transport).** The foe charges stiff and rectilinear, shoulder-shoving anything in its lane aside in one rigid displacement — the exact refusal of yielding that the drape mode answers.

**Friend power `cushion`.** While a drape friend follows, it dives beneath a falling or shoved player and flattens into a soft pad: hard landings and TRANSPORT shoves are absorbed as slow deformation instead of damage or knockback — capacity-to-be-affected as the surviving power.

*Animation:* The friend slides under the falling player and flattens into a sagging cloth pad; the landing is one deep slow deformation and a gentle rebound rather than an impact flash.

**Why.** The theory lens wins intact: transport honors soft_stages' declared kind and embodies the rigidity that drape answers, so foe and mode argue with each other on screen. Cushion is the sequence's affect thesis as gameplay — being soft, being affected, is what lets the player survive the rigid world — and it stays distinct from catcher (rescue net) by absorbing rather than rebounding.

### 17. isosurfaces — `isosurface` (Threshold Extract)

**Projectile.** The projectile is a raw scalar field: a translucent density blob with no hard edge. Wherever its density overlaps a body above the isovalue, the mode contour-slices the overlap and crystallizes a triangulated marching-cubes shell there — the hit IS field-to-mesh extraction, and everything below threshold passes through harmlessly, so aiming is about pushing enough density across the line, not about contact.

*Animation:* A fuzzy translucent blob drifts from the hand, then horizontal contour-slices sweep up through it plane by plane, leaving a hard faceted mesh shell snapping cell by cell into existence wherever the fuzz crossed the threshold.

**Foe (goo).** The goo foe wobbles as a live metaball — its blobby skin re-polygonizes every frame, bulging and merging with nearby peers when their density fields overlap, then pinching apart into separate skins as they drift.

**Friend power `capper`.** The friend walks to the nearest active foe vent and parks on it (reusing the porter park state), hardening an isosurface plug over the mouth; the vent stops spawning foes while the friend stays parked.

*Animation:* The friend squats onto the vent, inflates a translucent metaball dome that shrink-wraps over the vent mouth, then the dome contour-slices into a hard faceted plug with a satisfying snap.

**Why.** Reserved mode name and declared goo kind both honored; the theory-lens projectile is stronger because below-threshold pass-through makes the isovalue's foreclosure the aiming mechanic itself. Capper takes the mechanics-lens power for its concrete engine reuse — the existing porter park machinery — over sealer's equivalent but new-surface crust timer.

### 18. boolean_surfaces — `csg` (Boolean Carve)

**Projectile.** The projectile is a wireframe operand solid (sphere by default). Where it overlaps a target the mode performs A−B: the intersection volume pops free as a solid lens-shaped plug that clatters to the floor, and the target is left with a crisp concave bite with flat cut faces — the player literally evaluates a CSG expression per shot, and successive hits show (A−B)−C ordering because bites compound. Against terrain blocks it carves the same lawful bite, never crumbling.

*Animation:* A glowing wireframe sphere spinning a minus-sign glyph flies out and sinks into the target; the overlap volume subtract-bites free and slides out as a hard lens-shaped plug, leaving flat, cleanly cut faces that flash once.

**Foe (compound — NEW KIND).** The compound foe lumbers as three interpenetrating primitives — cube, sphere, cylinder — sharing one union skin; each catalyst hit carves a lens out of it along the overlap, cut faces staying flat and machined as its silhouette is rewritten.

**Friend power `carver`.** While a compound friend follows, it can subtract a player-sized passage through a blocking wall segment (layers.walls) or solid block: a temporary doorway that stays open about ten seconds, with the carved plug left lying on the floor as evidence rather than deleted.

*Animation:* The friend presses a glowing negative solid into the wall, the overlap volume slides out as one solid plug and drops to the floor, and an arched doorway remains with flat cut faces morphing softly closed as the lease ends.

**Why.** This is the set's one genuinely new foe kind, and it earns it: no existing FoeMode is a composed-of-parts body, and CSG's union/difference only becomes legible on a silhouette built from named primitives. The plug that drops instead of vanishing keeps the subtracted remainder visible, and carver is the first power to answer the walls layer — every doorway shown to be a subtraction.

### 20. machinelearning — `gradient` (Gradient Descent)

**Projectile.** The orb launches deliberately off-aim, then homes by iterative correction: every 0.15s it samples its aim error and takes one discrete step down the error slope, step size shrinking as it converges on the target. A shot into open space settles into the nearest floor basin (local minimum) and detonates there, so terrain hollows become natural trap points the player learns to aim with — descent in a landscape you can't fully see.

*Animation:* The orb hops in a shrinking zigzag — big wrong-direction lunges tightening into tiny corrections — leaving a breadcrumb dot at each step so the whole descent path hangs in the air for a second after impact.

**Foe (drainfriend).** The grey foe extends a dashed suction tether to the nearest friend and reels it back one tug at a time, the friend's color desaturating a visible step per tug — a model catastrophically forgetting what it learned.

**Friend power `predictor`.** While a gradient friend follows, every foe in a radius grows a translucent ghost twin walking its predicted next seconds of movement, re-forecast twice per second — the player dodges the future, not the present, and the ghosts are visibly wrong whenever a foe changes behavior, making the model-reality gap playable rather than told.

*Animation:* Faint ghost copies stride ahead of each foe, snapping back and re-walking on each re-forecast, and flickering red at the moment a real foe diverges from its ghost.

**Why.** The mechanics-lens aim-error homing is chosen over terrain-rolling descent because formfinding's settle mode already owns rolling downhill — here descent happens in aim-space, keeping the two lessons distinct on screen. Drainfriend honors soft_stages and rereads the enum as catastrophic forgetting, while predictor's red-flicker divergence moment carries the theory lens's irreducibility point.

### 21. graphtheory — `graph` (Edge Weaver)

**Projectile.** Each shot plants a glowing node pylon where it lands; every new pylon immediately snaps a straight light-edge to its nearest existing pylon, so successive shots grow a visible spanning tree across the room. A direct hit welds the foe into the graph as a node and yanks it one cell along its new edge toward the tree — edge contraction as crowd control (pylons expire after ~20s, capped at 8).

*Animation:* The bolt lands, pings, and a line of light tiles-out segment-by-segment to the nearest earlier pylon; a struck foe is visibly tethered and dragged one sharp step along the fresh edge.

**Foe (branch).** Grey foes extend thin luminous struts to nearby peers and snap into a lattice, after which the linked cluster drifts and turns as one connected component — a hostile graph walking.

**Friend power `cutter`.** While a graph friend follows, it flies to the minimum-cut edge of any foe lattice the player faces and severs it, splitting the component in two and leaving the smaller half dazed and slow; on rare rhizomatic links — loops with no single weakest edge — the cut visibly fails and the shears glance off, because some relations refuse to reduce.

*Animation:* The friend darts to the thinnest strut in the lattice, shears it with a scissor-flash, and the two halves drift apart while their edges re-count and re-light; on an uncuttable loop the shears spark and rebound.

**Why.** Mechanics-lens projectile plus theory-lens power: building a spanning tree by firing teaches nodes, edges, and contraction, while min-cut severing teaches connectivity as the thing that can be attacked — and its rare failure on loops foreshadows the rhizome three sequences later. BRANCH is preferred over soft_stages' declared transport because a tethered connected component IS the sequence's subject; the soft_stages entry should follow the binding.

### 22. foundationscrisis — `godel` (Incompleteness Frame)

**Projectile.** Fires a slow cube-frame of axiom tiles that tiles-out around the target foe but always refuses to close one face; the conversion energy passes only through that open gap, so a frame that ever fully closed would prove nothing and fizzle inert. The player steers the shot so the gap faces the foe's grey seam — the mode works BECAUSE it is incomplete, and every converted creature keeps one permanently uncolored patch as its irreducible remainder.

*Animation:* Glowing axiom tiles tile-out into a cube around the creature, then one face conspicuously peels away and hangs open as a light-ringed hole through which the color pours in.

**Foe (drainfriend).** The drainfriend circles a converted friend and peel-strips its color off in ribbons, the friend's hue gradient-descending back to grey — a proof visibly being un-proven.

**Friend power `oracle`.** The oracle friend periodically points a thin beam at the one thing the player's current mode cannot affect — hidden voids, unreachable islands, sealed passages — outlining the true-but-unprovable geometry of the map for a few seconds so the player can route around or toward it.

*Animation:* The friend stops, tilts, and casts a single contour-slice beam that traces the silhouette of an otherwise invisible or unreachable structure in flickering outline before it fades.

**Why.** The theory lens wins because the constitutive gap is a real aiming skill (face the gap at the seam), keeping Gödel playable rather than decorative, and drainfriend honors soft_stages while enacting theorems coming un-proven. Oracle escalates the crisis arc's self-reference correctly: the power grants sight of the system's outside, not force over it.

### 23. qfeplaboratory — `lambda` (Lambda)

**Projectile.** Trigger hold time maps to lambda 0..1: below 0.3 it fires a rigid straight bolt with no tracking, above 0.6 it bursts into an inaccurate random scatter, and only in the 0.3-0.5 band does it fire an adaptive mote that homes on the nearest foe — the edge of chaos is the only charge that adapts. Firing the mode is operating the lab's own slider.

*Animation:* At short charge a bar of rigidly stacked cubes flies dead straight; at full charge it disintegrates into scattering sparks; at mid charge a single mote with a turbulent tail visibly bends and self-corrects toward its target.

**Foe (wave).** The foe breathes between a locked crystalline lattice and a boiling droplet cloud, morphing through the same lambda spectrum as the projectile and only surging forward during the loose phase — so the player can read its phase and match timing.

**Friend power `attuner`.** The attuner friend emits a regulating aura that clamps everything inside toward lambda 0.4: hyper-fast foes and swarms slow to a steady glide, vents throttle their spawn rate, ramping hazards hold at base intensity, and frozen mechanisms gently wake — extremes on both ends pulled to the adaptive middle.

*Animation:* A translucent dial-ring orbits the friend with a needle gradient-descending to the 0.4 mark, and creatures crossing the ring visibly relax from jitter or rigidity into a smooth mid-tempo drift.

**Why.** Charge-to-lambda gives the player direct control of the parameter (a lab, not a timing minigame), and both lenses' wave foe makes the order/chaos oscillation readable on the enemy's own body — soft_stages' goo entry should be updated to wave to match. Attuner over damper because regulating both extremes IS the QFEP thesis, not merely hazard mitigation, and it leaves damper's niche unclaimed rather than colliding with change.

### 24. postfoundationscrisis — `rhizome` (Rhizome)

**Projectile.** Each impact leaves a glowing floor node; nodes in range auto-link into a flat mesh with no root and no trunk, and when any linked creature advances a personality step, one step propagates to its linked neighbors — conversion spreads horizontally through the network instead of shot by shot. Cut any link and the mesh reroutes, because there is no privileged origin.

*Animation:* The bolt lands as a pulsing node and thin tendrils tile-out sideways across the floor to the nearest other nodes, knitting a flat web that visibly has no center and no upward trunk, forking and looping as it spreads.

**Foe (goo).** The grey foe oozes low across the floor and swallows a neighboring creature on contact, the pair briefly merging into one blob before separating in matching grey — spread by touch, peer to peer.

**Friend power `weaver`.** Each weaver friend spins persistent light-threads linking the player and every other friend into one mesh that holds damage in common: any hazard or foe hit anywhere is split across all woven nodes, each dimming slightly, so no single body can be one-shot — and if a friend falls, its share redistributes instead of vanishing.

*Animation:* Thin threads visibly loom outward from the friend to every ally, and when a hit lands the impact flash travels the whole web as a ripple while every node dims one shade in unison.

**Why.** Mechanics-lens projectile plus theory-lens power ends the arc: horizontal step-propagation is the rhizome as a firing pattern, goo honors soft_stages' declared kind (peer-contact spread is already horizontal), and weaver is a power that questions powers — protection never owned by one node, only held in common. After godel's gap and lambda's edge, the final mode answers foundations lost with connection instead.
