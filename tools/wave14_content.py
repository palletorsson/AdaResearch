# wave14_content.py — the prose of the wave-14 gallery, imported by build_wave14_gallery.py.
#
# Kept apart from the builder so the machinery (frames, tail, scoring table) can be reused by
# wave 15 while the words stay with the wave they describe. Every section carries the study's
# four things: a family census line, a thesis someone could disagree with, a body that glosses
# each value by name from the builder's registry note, and a tail with the measurement AND
# the miss. The H1 and masthead were written AFTER the sweep was scored, never before.

TITLE = "Wave 14 &mdash; the point nobody can see"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 14 &middot; 15 August 2026 &middot; six agents, one orchestrator</p>
  <h1>It argued the critical point is invisible,<br>then predicted a different pair.</h1>
  <p>Six syntheses built in parallel by six agents from one brief. Three of them overruled the
  brief from the members' own code &mdash; <em>steep</em> is not a tilt, <em>necked</em> is already
  connected, the snap puzzles have no cube scene &mdash; which is what a brief is for. Four
  predictions named the closest pair. The two that missed are the two whose artifacts were
  right: the pair the camera could not separate was the pair the thesis said nobody can.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 81 frames &middot; 12 axes, 11 bite + 1 local &middot; 6 predictions pre-registered, 4 hit &middot; 2 designed nulls held</span></div>
"""

SECTIONS = [
 ("regime_threshold", "regime &middot; 5 members &middot; 1 vocabulary shared, 3 cousins &middot; one dial",
  "A regime is a name laid over one continuous dial, and the boundary is a point promoted to a peer of the two half-lines beside it.",
  """<p class="body">control_pendulum and mass_spring_damper share the damping vocabulary; rotation_gimbal,
  the bouncing ball and the bifurcation diagram use <span class="tok">regime</span> for other
  threshold crossings and are named as kin. The bench is mass_spring_damper's byte for byte
  &mdash; k&nbsp;=&nbsp;40, m&nbsp;=&nbsp;1, &omega;&#8320;&nbsp;=&nbsp;6.32 &mdash; released
  from the same 0.20&nbsp;m in every variant, the trajectory laid down as a real tube against a
  rest rail. <b>free</b> is &zeta;&nbsp;=&nbsp;0, a cosine forever. <b>underdamped</b> is
  &zeta;&nbsp;=&nbsp;0.25, crosses the rest line and decays. <b>critical</b> is
  &zeta;&nbsp;=&nbsp;1.00 exactly, the fastest return that never crosses &mdash; the point.
  <b>overdamped</b> is &zeta;&nbsp;=&nbsp;2.5, two exponentials. <b>resonance</b> is
  &zeta;&nbsp;=&nbsp;0.08 with a crank driving the anchor at &omega;&#8320;.</p>
  <p class="body">The builder found the family's own proof in the source: mass_spring_damper's
  <em>Critically Damped</em> preset is d&nbsp;=&nbsp;12 at k&nbsp;=&nbsp;40, which is
  <b>&zeta;&nbsp;=&nbsp;0.949</b> &mdash; five percent underdamped and labelled critical since it
  was written. Nobody could see the point, including the person who built the artifact about it.</p>""",
  [({"regime": "underdamped", "reading": "trace"}, "underdamped &middot; &zeta; 0.25"),
   ({"regime": "critical", "reading": "trace"}, "critical &middot; &zeta; 1.00 &mdash; the closest pair"),
   ({"regime": "overdamped", "reading": "trace"}, "overdamped &middot; &zeta; 2.5"),
   ({"regime": "resonance", "reading": "envelope"}, "resonance &middot; envelope")],
  "The measurement is the thesis. The closest pair on the axis is <b>underdamped against critical</b> "
  "&mdash; the threshold and its neighbour &mdash; and the builder, who had just written that nobody "
  "can see that point, predicted free against resonance and ranked #5. It went and looked at the two "
  "big envelope sheets, which is exactly where the eye goes."),

 ("fusion_ladder", "fusion &middot; 4 members &middot; 1 vocabulary, character for character",
  "Four names on one dial, and only two of the three gaps between them hide an event.",
  """<p class="body">metaballs, raymarched_metaballs, implicit_surface_modeling and csg_union_demo all say
  <em>distinct / necked / lobed / single</em>. The field is the family's own: two sphere SDFs of
  radius 0.18 folded by metaball.gdshader's polynomial smin at k&nbsp;=&nbsp;0.24, and the dial is
  what csg_union_demo turns &mdash; the separation of the centres. <b>distinct</b> is
  d&nbsp;=&nbsp;0.62, a gap of 0.26. <b>necked</b> is 0.42 &mdash; and here the builder overruled the
  brief: both members' code has necked <em>already connected</em>, so the topological event
  (one component from two) sits between distinct and necked at 2R&nbsp;+&nbsp;k/3&nbsp;=&nbsp;0.44,
  not where I had put it. <b>lobed</b> is 0.34, wider but nothing else. <b>single</b> is 0.16, past
  the second event at d&nbsp;&asymp;&nbsp;0.204 where the waist vanishes.</p>
  <p class="body">The skin is root-found on the field &mdash; bisection per radial ray, one lathed body
  per connected run of the axis &mdash; so the component count falls out rather than being asserted.
  <b>section</b> cuts it and lays the level sets in the cut, each connected iff F(mid)&nbsp;&le;&nbsp;c,
  so the isovalue dial and the separation dial read as one.</p>""",
  [({"fusion": "distinct", "reading": "skin"}, "distinct &middot; two bodies"),
   ({"fusion": "necked", "reading": "skin"}, "necked &middot; already one"),
   ({"fusion": "lobed", "reading": "skin"}, "lobed"),
   ({"fusion": "single", "reading": "section"}, "single &middot; section")],
  "The predicted twin was the one gap that hides no event &mdash; necked against lobed, nothing but "
  "widening between them &mdash; and it is the closest pair at 6.16%, ranked #1."),

 ("assembly_yard", "solid + stock &middot; 7 members &middot; 2 axis words &middot; 2 scenes under 4 names",
  "An assembly's state is a distance from being itself, and one of the four words is a different kind of distance.",
  """<p class="body">The four snap tokens are <b>two scenes under four names</b>: snap_tetra_puzzle
  points at snap_tetrahedron_puzzle.tscn and snap_cube_puzzle at snap_octahedron_puzzle.tscn.
  There has never been a cube scene; the cube exists only as the octahedron's <em>dual</em>.
  pick_up_cube also declares <span class="tok">stock</span> and is excluded &mdash; its own
  @identity says stock is what the cube is <em>made of</em>, a material axis wearing the family's
  word. <b>closed</b> is vertices exact and every strut built. <b>loose</b> pulls the vertices to
  0.70 of their radius, where both .tscn files ship. <b>scattered</b> throws them within a ball.
  <b>short</b> is one vertex absent, its three struts left as ghost stubs.</p>
  <p class="body">closed, loose and scattered are one distance &mdash; how far the parts are from
  the solid. short is near and incomplete: a different dial with the same word list. The line
  puzzles' words are mapped in the note from their coordinates, not their names &mdash;
  <em>ringed</em> is loose, <em>strewn</em> is scattered, and <em>stacked</em> has no snap
  equivalent because a rack of points is a cluster.</p>""",
  [({"state": "closed", "solid": "tetra"}, "closed &middot; tetra"),
   ({"state": "short", "solid": "tetra"}, "short &middot; one vertex gone"),
   ({"state": "loose", "solid": "tetra"}, "loose &middot; 0.70 radius"),
   ({"state": "scattered", "solid": "octa"}, "scattered &middot; octa")],
  "It also caught a capture fault by arithmetic. The first sweep measured closed/short at 0.25% "
  "against a 0.6% floor &mdash; UNDER the floor, which the corpus rule says is a fault, not a tight "
  "pair. Subject share was 0.3%: <em>scattered</em> inflates the union AABB and closed photographs as "
  "a speck. Reframed, the same pair is 1.48% and still #1."),

 ("plumb_room", "plumb &middot; 4 members &middot; 2 scenes on 1 script &middot; one of them dead to the axis",
  "A cave is defined by which way is down.",
  """<p class="body">One ridged scalar field, one seed, one threshold; the four values of
  <span class="tok">plumb</span> are four choices of plumb line through it, and what changes is not
  the rock but where a walker could stand. <b>The values are the family's numbers, not its words.</b>
  Everything the source shader knows about gravity is one term &mdash;
  MarchingCubes.glsl:218 &mdash; and TerrainGenerator.gd gives the four multipliers: <b>bedded</b>
  is +1, <b>overturned</b> is &minus;1, <b>weightless</b> is 0, <b>steep</b> is <b>+3</b>. The
  brief guessed steep meant a tilted down-axis. The code says same down, gradient tripled, and the
  builder followed the code and said so.</p>
  <p class="body">Two of the four sources declare the axis on marchingcubes.tscn, which ships
  <code>use_fallback = true</code> &mdash; the axis is inert there by construction, the script's own
  header says those tokens must not be declared, and the registry declares them anyway. That is a
  corpus fact the census cannot see. <b>standing</b> raises the walkable patches as geometry, not a
  percentage; <b>line</b> hangs the plumb line beside the chunk, a sphere alone at weightless.</p>""",
  [({"plumb": "bedded", "reading": "rock"}, "bedded &middot; +1"),
   ({"plumb": "steep", "reading": "rock"}, "steep &middot; +3 &mdash; the closest pair"),
   ({"plumb": "overturned", "reading": "standing"}, "overturned &middot; standing"),
   ({"plumb": "weightless", "reading": "line"}, "weightless &middot; line is a sphere")],
  "And it pre-registered two NULLS: overturned.rock against overturned.standing under 0.3% (every "
  "standing pocket sealed inside the mass) and weightless.rock against weightless.line under 0.3%. "
  "Measured <b>0.13%</b> and <b>0.01%</b>. Both held. The critic's one non-bite of the wave &mdash; "
  "<span class=\"tok\">reading</span> is <em>local</em>, 15.7% in focus and 0.9% of frame &mdash; is "
  "that same plumb line: a rod beside a chunk is decisive where it is and small everywhere else."),

 ("intrusion_bench", "intrusion &middot; 4 names &middot; 2 scenes &middot; 2 vocabularies sharing 2 words",
  "Six words for damaging a formula are one null, one union and four frequency bands.",
  """<p class="body">GyroidDemo and gyroid_demo are one scene; marchingcubes_torus_sculpture and
  mc_torus_sculpture are another. Both vocabularies were written by the same wave-1 pass, which took
  <em>melted</em> and <em>formula</em> from the gyroid on purpose so the shipped rung and the null
  rung would share names. Reading the shaders, the builder sharpened the brief: <b>melted</b> is not
  a smoothing &mdash; it is every band at once plus a coordinate warp; <b>eroded</b> is not a
  subtraction &mdash; it is signed single-octave noise, pits and warts, the <em>high</em> band.
  <b>drifting</b> is that grain plus a zero-frequency term. <b>rippled</b> is low and deterministic.
  <b>roughened</b>'s base octave is 0.32 cycles across the whole torus &mdash; the word says grain,
  the code says lump. <b>formula</b> is the level set alone.</p>
  <p class="body">The gyroid vocabulary is nested (eroded &sub; drifting &sub; melted); the torus
  vocabulary is a partition. Marching-cubes tables are reused from sdf_marching_cubes.gd, 26&sup3;
  cells, winding forced outward against the gradient. <b>sphere</b> is the null surface, so an
  intrusion can be read with no formula under it.</p>""",
  [({"intrusion": "formula", "surface": "gyroid"}, "formula &middot; gyroid"),
   ({"intrusion": "eroded", "surface": "gyroid"}, "eroded &middot; the high band"),
   ({"intrusion": "drifting", "surface": "sphere"}, "drifting &middot; DC on the null"),
   ({"intrusion": "roughened", "surface": "torus"}, "roughened &middot; the word says grain")],
  "The prediction reasoned that a zero-frequency band changes a picture least per metre &mdash; "
  "eroded against drifting. Measured, the closest pair is <b>formula against eroded</b> at 1.39%: the "
  "HIGH band is what this camera cannot resolve. Sub-pixel grain reads as no grain, which is the "
  "wave-13 rasteriser limit arriving from the other side &mdash; and it means the family's "
  "<em>eroded</em>, from a museum distance, is <em>formula</em>."),

 ("readout_bench", "readout &middot; 8 members &middot; 7 share the vocabulary character for character",
  "How a value is shown is a claim about how well it is known.",
  """<p class="body">health_display, hits_reset_display, line, line_interface, qfep_calibrator,
  xyz_coordinates and xyz_slider_plate all say <em>none / numeral / gradation / lattice</em>, and
  every one builds the ladder <em>additively</em> &mdash; gameplay_readout.gd:24 says each rung is
  everything below it plus one thing more. This bench reads the same four words as four claims and
  mounts each <b>alone</b>, because a lattice that still carries the numeral still carries the
  numeral's promise. One number, 0.62, held by three real bodies: fluid in a glass tank, a knob on
  a rail, five pucks of eight on a spindle.</p>
  <p class="body"><b>none</b> is the body and its plinth &mdash; the only readout that cannot be
  wrong. <b>numeral</b> is a bone nameplate with the digits: a decimal place is a promise, and this
  rung can be wrong to the hundredth. <b>gradation</b> is a ruled blade beside the span with no
  index; the body is the pointer. <b>lattice</b> is a wire grid over the face, showing the most and
  asserting the least. On <em>count</em> the numeral says 5 and cannot over-claim; on <em>level</em>
  it says 0.62 and does.</p>""",
  [({"readout": "none", "quantity": "level"}, "none &middot; level"),
   ({"readout": "numeral", "quantity": "level"}, "numeral &middot; 0.62"),
   ({"readout": "gradation", "quantity": "position"}, "gradation &middot; position"),
   ({"readout": "lattice", "quantity": "count"}, "lattice &middot; count")],
  "Predicted none against numeral &mdash; a nameplate is 0.0044&nbsp;m&sup2; on a body of "
  "0.28&nbsp;&times;&nbsp;0.31 &mdash; and it is the closest pair at 0.52%, #1 of 18."),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the misses, scored</h2><span class="fam">6 pre-registered &middot; 4 hit &middot; 2 designed nulls held</span><span class="chip">both misses confirm the thesis</span></div>
    <p class="thesis">The two predictions that failed named a pair the eye goes to. The measurement named the pair the eye cannot separate.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank is unit-free and is what was predicted. The percent is a share of frame; the pre-registered numbers were a share of subject, so they are floors, not forecasts.</p></div>
    <p class="body"><b>regime_threshold</b> ranked its pair #5. Its closest pair is underdamped against
    critical: the threshold and its neighbour. The artifact's whole claim is that this point is
    invisible &mdash; that mass_spring_damper shipped &zeta;&nbsp;=&nbsp;0.949 labelled critical and
    nobody noticed for the life of the artifact &mdash; and the camera agreed with the claim while the
    prediction, written by the same agent an hour after that sentence, went and looked at the two
    big envelope sheets instead. <b>intrusion_bench</b> ranked #4, reasoning that the DC band
    changes a picture least per metre. True per metre; but the closest pair is formula against
    eroded, the <em>high</em> band, because from this standpoint sub-pixel grain is no grain. That
    is the wave-13 rasteriser limit from the other side, and it says something about the family: at
    museum distance, <em>eroded</em> is <em>formula</em>.</p>
    <p class="body"><b>What the orchestration did.</b> Six agents from one brief, and three of them
    overruled it from the source &mdash; steep is a gradient not a tilt, necked is already connected,
    there is no cube scene. Every axis was derived from the code by the same tool, and that tool was
    found, mid-wave, to have been <em>destroying</em> pre-registered predictions: its axes
    replacement used a lazy regex that on an empty <code>"axes": {}</code> ran forward past every
    sibling key. Wave 13's six predictions were lost that way and its gallery was scored from a
    scratch file without anyone noticing. Fixed, brace-matched, negative-tested on the exact shape,
    and wave 13's predictions restored to the registry before any wave-14 agent ran it.</p>
    <p class="tail"><b>What this wave does not settle.</b> plumb_room's <span class="tok">reading</span>
    axis is <em>local</em>, not inert &mdash; a plumb line beside a chunk is 15.7% in focus and 0.9%
    of frame &mdash; and it stays as built rather than being thickened to please the camera; the two
    designed nulls on the same axis held at 0.01% and 0.13%. And two of the six sources plumb_room
    names declare an axis on a scene where it is inert by construction; that is a registry defect
    outside this wave, on record here and not repaired here.</p>
  </section>

<footer><span>wave 14</span><span>6 syntheses &middot; 12 axes &middot; 4 of 6 predictions hit &middot; six agents, one orchestrator</span>
<span><a href="/synthesis-gallery">&larr; all galleries</a></span></footer>
</div>
"""


def closing(scores: dict) -> str:
    rows = ""
    for tok, s in scores.items():
        cls = "ok" if s["hit"] else "bad"
        rows += (f'<tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">{tok}</td>'
                 f'<td style="padding:5px 10px">{s["pair"]}</td>'
                 f'<td style="padding:5px 10px;text-align:right" class="{cls}">#{s["rank"]}/{s["n"]}</td>'
                 f'<td style="padding:5px 10px">{s["closest"]}</td>'
                 f'<td style="padding:5px 10px;text-align:right">{s["closest_pct"]}</td></tr>')
    return CLOSING_TEMPLATE.replace("__ROWS__", rows)
