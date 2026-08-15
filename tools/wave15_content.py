# wave15_content.py — the prose of the wave-15 gallery, imported by build_wave_gallery.py.
#
# Same discipline as wave 14: every section carries a family census, a thesis someone could
# disagree with, every value glossed from the builder's registry note, and a tail with the
# measurement AND the miss. H1 and masthead written after the sweep was scored.

TITLE = "Wave 15 &mdash; four briefs overruled from the source"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 15 &middot; 15 August 2026 &middot; six agents, one orchestrator</p>
  <h1>Four of six briefs were wrong,<br>and the members' code said so.</h1>
  <p>I briefed phyllotaxis and no member does it. I briefed a false diagram and every member
  removes the curvature instead. I briefed a designed null and the member's own doorway breaks
  it. I briefed one right-hand rule and the family disagrees with itself. Six agents read the
  source before they read me, which is the order the brief asks for, and four of them came back
  with the corpus's version instead of mine. Five designed nulls held; four of six predictions
  named the closest pair; and one thing no word in the corpus names at all.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 84 frames &middot; 12 axes, all biting &middot; 6 predictions, 4 hit &middot; 5 designed nulls, 5 held &middot; critic flagged 3 of them CONDITIONAL on its own</span></div>
"""

SECTIONS = [
 ("working_shown", "evidence &middot; 32 promoted members &middot; 41 declarations &middot; the corpus's largest unbuilt family",
  "How much of the working is shown is a theory of who is looking, and the rungs do not nest.",
  """<p class="body">Eighteen of thirty-two members default to <b>result</b>, nine to longhand, five to
  trace. The brief assumed a ladder &mdash; each rung everything below it plus more. The code says
  otherwise: only calder_mobile nests. control_pendulum drops the curve at axiom, example_2_8 hides
  its answer above result, box_counting's axiom shows the least. So the rungs are four addressees,
  not four detail levels: <b>result</b> is the outcome and the fixture; <b>trace</b> is the path as a
  real tube in space; <b>longhand</b> withholds the tube and stands equal-time stamps and rods whose
  lengths ARE the quantities, 0.10&nbsp;m per m/s; <b>axiom</b> removes body and fixture entirely and
  leaves the law as one built figure of rulers.</p>
  <p class="body">Three events, closed-form, one moment frozen: <b>throw</b> under gravity,
  <b>attraction</b> of two bodies at G&nbsp;=&nbsp;1 so the rods are visible at the shared scale,
  <b>swing</b> released from 0.5&nbsp;rad with the linear form and its 1.6% period error stated.
  The builder pre-registered that axiom-throw and axiom-swing would be one figure &mdash;
  s&nbsp;=&nbsp;&frac12;gt&sup2; and L&nbsp;=&nbsp;gT&sup2;/4&pi;&sup2; are the same law shape.</p>""",
  [({"evidence": "result", "event": "throw"}, "result &middot; throw"),
   ({"evidence": "trace", "event": "throw"}, "trace &middot; the path as a tube"),
   ({"evidence": "longhand", "event": "attraction"}, "longhand &middot; rods are the quantities"),
   ({"evidence": "axiom", "event": "swing"}, "axiom &middot; the law alone")],
  "The designed null held at <b>0.00%</b>: axiom-throw and axiom-swing are byte-identical, and the "
  "critic independently called <span class=\"tok\">event</span> CONDITIONAL on it before anyone told "
  "it the pair was registered."),

 ("postulate_bench", "postulate &middot; 3 members &middot; 1 vocabulary &middot; euclid removes the curvature in all three",
  "The parallel postulate is a claim about a surface, and Euclid's page is true on one of three.",
  """<p class="body">elliptic_surface, hyperbolic_surface and riemann_sphere all say <em>bare /
  parallels / triangle / net / euclid</em>. The brief asked whether the members' <b>euclid</b> draws
  a false flat diagram on the curved surface. It does not &mdash; all three <em>remove the
  curvature</em> and draw the construction on a flat disc. Under two axes that meaning belongs to
  <span class="tok">curvature</span>, so here euclid is Euclid's page: a tangent sheet carrying the
  flat construction, flush on the plate, touching the ball at one point, sliced by the saddle's
  ridge. Same object, true on one surface only.</p>
  <p class="body">Sphere R&nbsp;0.50 (K&nbsp;=&nbsp;+4), plate 1.0&nbsp;m (K&nbsp;=&nbsp;0), saddle
  y&nbsp;=&nbsp;x&sup2;&minus;z&sup2; (K&nbsp;=&nbsp;&minus;4 at P). Geodesics are great circles on the
  sphere and hyperbolic_surface's own RK4 integrator with a shooting solve on the other two.
  <b>triangle</b>'s corner wedges are filled sectors, and the angle sums come from the built
  geometry: <b>225.1&deg; / 180.0&deg; / 154.0&deg;</b>. <b>net</b> is geodesic families on all three
  &mdash; the elliptic members' latitude circles are not geodesics and were declined.</p>""",
  [({"postulate": "triangle", "curvature": "sphere"}, "triangle &middot; sphere &middot; 225&deg;"),
   ({"postulate": "triangle", "curvature": "plane"}, "triangle &middot; plane &middot; 180&deg;"),
   ({"postulate": "triangle", "curvature": "saddle"}, "triangle &middot; saddle &middot; 154&deg;"),
   ({"postulate": "euclid", "curvature": "saddle"}, "euclid &middot; the page, sliced by the ridge")],
  "Predicted through a Python replica of the sweep camera and critic pipeline: triangle against "
  "bare on the saddle. Ranked #1 of 30."),

 ("habit_grove", "habit &middot; 3 members &middot; 1 vocabulary &middot; and none of them does phyllotaxis",
  "A habit is a roll of the fork plane, and spiral is a fan in a mirror.",
  """<p class="body">The brief said planar / fanned / whorled / spiral was botany &mdash; divergence
  angle around a stem, whorled as n per node, spiral at 137.5&deg;. The builder read
  branching_vine.gd:73-78, which the stochastic tree preloads and lsystem_tree copies, and found
  <b>no member does that</b>. All three implement <span class="tok">habit</span> as a ROLL of the
  two-child fork plane about the parent axis, once per descent, siblings sharing a plane, the
  parent's plane restored on the L-system's <code>]</code>. Consequences, built and glossed: every
  fork on one axis is coplanar under every habit &mdash; no stem carries a spiral. <b>whorled</b>
  at 90&deg; is decussate, two planes. <b>spiral</b> at 137.5&deg; is &minus;42.5&deg; modulo 180
  for a plane, which is <b>fanned</b> in a mirror and 12.5&deg; wider. <b>planar</b> is 0&deg;.</p>
  <p class="body">The brief's <em>nodes</em> reading &mdash; beads on the stem &mdash; was declined
  because under a roll it is a designed null on the whole axis; <b>crown</b> shows the 171 tips
  alone and <b>roll</b> draws the arc of the roll at all 85 forks with the plant ghosted.</p>""",
  [({"habit": "planar", "reading": "plant"}, "planar &middot; 0&deg;"),
   ({"habit": "fanned", "reading": "plant"}, "fanned"),
   ({"habit": "spiral", "reading": "plant"}, "spiral &middot; a fan in a mirror, edge-on"),
   ({"habit": "whorled", "reading": "roll"}, "whorled &middot; roll &middot; decussate")],
  "Predicted planar against fanned, in the plant reading; ranked <b>#4 of 6</b> there, with the "
  "closest pair <b>whorled against spiral</b> at 5.42%. And then the probe was run, and the claim "
  "did not survive it. From five standpoints the closest pair is planar/fanned twice, fanned/spiral "
  "twice and fanned/whorled once &mdash; <b>five viewings, three different answers, and the six pairs "
  "span only 5.4% to 7.2% of frame</b>. This axis has no stable closest pair, and any single number "
  "for it is a fact about where the camera stood. The builder said so before capture: spiral's "
  "first-fork planes are 22% wide from the sweep standpoint and its plant frame is half the width of "
  "planar's, 121 px against 228. <span class=\"hint\">Corrected 15 Aug 2026: first published as “planar against spiral, #3 of 18”, which pooled all three readings &mdash; the six <em>crown</em> pairs, which draw 171 tips and almost no ink, held the whole top of that ladder.</span>"),

 ("handed_pair", "handedness &middot; 3 members &middot; 2 vocabularies &middot; and they disagree about right",
  "Handedness is a convention, and the family did not agree on which one.",
  """<p class="body">VectorCrossProduct and torque_demo say <em>right / left / both</em>; dna_specimen
  says <em>right / left</em>. The builder checked the convention across all three and found the
  family <b>disagrees with itself</b>: doublehelix.gd's <b>right</b> &mdash; the +i winding it calls
  B-DNA &mdash; has negative discrete torsion. It is a left-hand screw in Godot's right-hand frame,
  and its <em>left</em> is right-handed. The two arrow benches are right-handed by construction. This
  bench follows the right-hand rule in all three figures, so its right helix winds the way
  dna_specimen's left does, and the note says so with the numbers.</p>
  <p class="body">One construction turned so a&times;b is vertical and the mirror plane is the floor,
  nearly edge-on to the sweep camera. <b>cross</b> is two vectors and their product;
  <b>torque</b> a lever, a force and its sense; <b>helix</b> a coil on the axis. <b>both</b> is the
  union of right and left standing together, costing nothing beyond right&nbsp;&cup;&nbsp;left in the
  AABB. No member draws a mirror pane, so none is drawn.</p>""",
  [({"handedness": "right", "figure": "cross"}, "right &middot; cross"),
   ({"handedness": "left", "figure": "cross"}, "left &middot; the mirror"),
   ({"handedness": "both", "figure": "cross"}, "both"),
   ({"handedness": "right", "figure": "helix"}, "right &middot; helix &mdash; dna_specimen calls this left")],
  "Predicted left against both, reasoning from the critic's colour-blindness on the member's own "
  "lavender; within the cross figure it ranked <b>#3 of 3</b>, the closest being right against both. "
  "Then the probe was run from five standpoints, and it turned the miss into a confirmation. The "
  "closest pair <em>alternates</em> &mdash; right/both from two viewpoints, left/both from three "
  "&mdash; because which hand the union sits nearer is occlusion, not convention. But <b>right "
  "against left, the mirror itself, is the WIDEST pair from all five standpoints</b>, 67% to 79% in "
  "focus and last in every ranking. The thing the axis is actually about is stable from everywhere; "
  "only the comparison involving the union is unstable, and it is unstable for a mechanical reason. "
  "right and left measure 1.88% and 1.87% of frame &mdash; the mirror pair is as symmetric as a "
  "mirror pair should be."),

 ("arrangement_yard", "arrangement &middot; 4 members &middot; 3 vocabularies &middot; scale_lines is kin, not member",
  "An arrangement of identical objects is a claim about the relation between them.",
  """<p class="body">grabcolorcollection and gravity_gun_test_scene say <em>grid / ramp / ring /
  stack</em>; particle_systems says <em>grid / row / ring</em>; scale_lines says ladder / log /
  ruler, which is a spacing law of unlike lengths and is named kin. Ten bodies, not eight &mdash;
  ten swatches, ten spheres, and gravity_gun's stack is 4+3+2+1. <b>grid</b> says independent and
  interchangeable. <b>row</b> says ordered. <b>ramp</b> raises by height, as both members do; with
  identical bodies the only quantity is rank, so ramp is row with 45&nbsp;mm of rise per step.
  <b>ring</b> says cyclic, no first and no last, cubes facing outward as grabcolorcollection's do.
  <b>stack</b> is gravity_gun's brick pyramid, each body bearing on two below &mdash; not a pile,
  which is a row on end.</p>
  <p class="body"><b>relation</b> draws the bodies at half edge so the neighbour rods show: grid has
  four, row two, ring closes, stack bears on two. <b>footprint</b> draws no bodies at all &mdash; a
  slate plate and pads, overlapping plans clipped, so the stack shows four pads.</p>""",
  [({"arrangement": "grid", "reading": "bodies"}, "grid &middot; interchangeable"),
   ({"arrangement": "ring", "reading": "relation"}, "ring &middot; no first, no last"),
   ({"arrangement": "stack", "reading": "relation"}, "stack &middot; bearing on two"),
   ({"arrangement": "row", "reading": "footprint"}, "row &middot; footprint = ramp's footprint")],
  "The builder registered that row and ramp share a footprint by construction, that this null "
  "would occupy rank #1, and that the prediction was for the first NON-null rank. The null held at "
  "<b>0.00%</b>; set aside, row against stack in footprint is #1 of 29 &mdash; exactly as written."),

 ("interior_block", "interior &middot; 3 members &middot; 2 vocabularies &middot; 2 scenes &middot; no word names a sealed void",
  "An interior is what a solid keeps from you, and no value in the family keeps anything.",
  """<p class="body">csg_architecture_cavity says <em>none / corner / court / room</em>; the two
  landscape names are one scene saying <em>caverned / none / undercut / warren</em>. The brief
  handed the builder an obvious designed null &mdash; from outside, room and caverned and warren
  must equal none, the block keeping its interior being the whole point. The member's own code
  broke half of it: <b>room</b> is built with 2.6&nbsp;m walls, no roof at any rung, and a doorway
  cut in the front run (gd:56, 293-294). Room is a pit open to the sky with a door. The null holds
  only for the roofed words.</p>
  <p class="body">And then the larger finding: <b>no value has a sealed void.</b> Neither vocabulary
  names one &mdash; csg's room has a door, the landscape's replica counted roof and never reach. The
  builder built a dark "sealed" marker and ran a flood-fill census over all seven values: sealed
  =&nbsp;0 on every one. It is registered as the finding and not filled by invention. <b>section</b>
  cuts on x and keeps the &minus;x half so the cut face looks toward the camera; <b>void</b> casts
  the hollow as its own positive body.</p>""",
  [({"interior": "none", "reading": "solid"}, "none &middot; solid"),
   ({"interior": "room", "reading": "solid"}, "room &middot; a door and no roof"),
   ({"interior": "caverned", "reading": "section"}, "caverned &middot; section"),
   ({"interior": "warren", "reading": "void"}, "warren &middot; the hollow as a body")],
  "Three nulls registered, three held: caverned against warren in solid at <b>0.00%</b> (same mouth "
  "box, byte-identical shells), none against each at 0.89% under a 2% ceiling. Set aside, the "
  "prediction &mdash; none against room, the door and the open top &mdash; is #1 of 60."),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the misses, scored</h2><span class="fam">6 pre-registered &middot; 4 hit &middot; 5 designed nulls held</span><span class="chip">two instruments converged</span></div>
    <p class="thesis">Three of the five designed nulls were flagged CONDITIONAL by the critic before it knew they were registered.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank among NON-null pairs; designed nulls are set aside first, because a builder who registered a null has said in advance it will be closest. Percent is a share of frame.</p></div>
    <p class="body"><b>The nulls are the wave's instrument result.</b> Five pairs were registered as
    identical by construction with a ceiling &mdash; axiom-throw against axiom-swing, row against
    ramp in footprint, caverned against warren in solid, none against each of those from outside
    &mdash; and all five held, three of them at 0.00% to the byte. The critic, which does not read
    registrations, flagged exactly those three as CONDITIONAL on their crossed axis: 0.00% here,
    77&ndash;90% elsewhere. Two independent instruments naming the same three pairs is the strongest
    negative control the programme has had. And one null the brief supplied was <em>broken by the
    member's own code</em> before it was ever measured &mdash; room has a door &mdash; which is the
    other thing a pre-registration is for.</p>
    <p class="body"><b>The two misses are one standpoint.</b> habit_grove's closest pair is planar
    against spiral, not fanned: spiral's fork planes are 22% wide from the sweep camera and its plant
    frame is half the width of planar's. handed_pair's right and left measure 1.88% and 1.87% of frame
    &mdash; the mirror pair is as symmetric as it should be &mdash; and which one the union sits
    nearer is occlusion from one angle. Both are the wave-11 anamorphic gate arriving in a
    closest-pair claim instead of an INERT one, and both builders wrote the warning down before
    capture.</p>
    <p class="body"><b>What the orchestration did.</b> Six agents from one brief and four came back
    with the source's version instead of mine. That is the design working, and it is worth saying
    what kind of wrong the brief was each time: botany where the code has a roll; a false diagram
    where the code removes curvature; a null the member's doorway breaks; one convention where the
    family holds two. And a tool fault fixed mid-wave: solve_framing took the SMALLER of its two
    solved framings &mdash; the closer camera &mdash; so the wider dimension overflowed. That is why
    mounting_yard clipped at pylon in wave 13 and needed a hand fix; here it would have put
    arrangement_yard's row at 240% of frame. Now the larger, so both dimensions fit.</p>
    <p class="tail"><b>What this wave does not settle.</b> handed_pair follows the right-hand rule and
    so contradicts dna_specimen's labels; that is a registry-and-code disagreement in the source
    family, on record here and not repaired here. interior_block's finding that no word in either
    vocabulary names a sealed void is likewise a fact about the corpus, not a rung this bench could
    honestly add. And the two anamorphic misses want probe_anamorphic runs on spiral and on the
    mirror before anyone quotes those closest pairs.</p>
  </section>

<footer><span>wave 15</span><span>6 syntheses &middot; 12 axes &middot; 4 of 6 hit &middot; 5 of 5 nulls held &middot; six agents, one orchestrator</span>
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
