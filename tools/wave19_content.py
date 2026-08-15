# wave19_content.py — the prose of the wave-19 gallery, imported by build_wave_gallery.py.
# H1 and masthead written after the sweep was scored.

TITLE = "Wave 19 &mdash; three classifiers, none of which draws a boundary"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 19 &middot; 15 August 2026 &middot; six agents, one orchestrator</p>
  <h1>The clean families were the ones<br>hiding the most.</h1>
  <p>Three of these six axes are the corpus's tidiest &mdash; one vocabulary shared exactly
  across three members, nothing to untangle. Built, they turned out to be hiding more than the
  messy ones. Three classifier visualisations between them draw <em>no decision boundary at
  all</em>. A tile editor and its mirror are one scene whose distinguishing config is the
  script's own defaults. Four marker names are two scenes, and neither has a marked thing in
  it. Sixteen designed nulls were registered and sixteen held, which is sixty-one of sixty-one
  since wave 14.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 96 frames &middot; 12 axes, 11 bite + 1 local &middot; 6 predictions, 5 hit &middot; 16 designed nulls, 16 held &middot; 0 clipped, 0 blank</span></div>
"""

SECTIONS = [
 ("cohort_bench", "cohort &middot; 3 members &middot; 1 vocabulary &middot; and none of them draws its boundary",
  "Five toy datasets are not five pictures. They are five adversaries, each built to defeat one inductive bias.",
  """<p class="body">enhanced_kmeans, random_forest_visualization and svm_visualization all declare
  <em>blobs / block / rings / braid / skew</em>. The five shapes are chosen to break things:
  k-means partitions by distance to a centroid, so a <b>ring</b> around a centre is cut into
  wedges; a forest cuts axis-aligned boxes and takes <b>block</b> natively; a margin is one
  plane and <b>braid</b> is not linearly separable. <b>centroid</b>, <b>axis</b> and
  <b>margin</b> are those three biases, built as real geometry &mdash; Voronoi planes, box
  slabs, a margin slab.</p>
  <p class="body"><b>And none of the three members photographs its own boundary.</b> k-means'
  Voronoi is <em>k</em> flat squares parked at the centroids behind a flag that ships
  <code>false</code>. The forest draws no boundary at all and its
  <code>show_ensemble_prediction</code> is read by nothing. The SVM's boundary is a
  PRIMITIVE_POINTS cloud built inside a Timer-driven <code>finalize_training</code>, and
  <code>margin_meshes</code> is <b>never appended to</b> &mdash; the max-margin artifact draws
  no margin. Three visualisations of classifiers, none of which shows the thing that makes a
  classifier visible.</p>
  <p class="body">Two more corrections from the source: the SVM ships an <b>rbf</b> kernel, not
  a linear one, so the brief's "cannot separate rings" was wrong about that member; and no
  cohort defeats all three cuts &mdash; it is the other way round, <b>centroid is defeated by
  all five</b>. Also checked and rejected: the staircase a forest is supposed to make of
  <em>rings</em> does not exist, because a single box separates a disc from an annulus whenever
  the inner radius exceeds r&radic;2.</p>""",
  [({"cohort": "rings", "cut": "centroid"}, "rings &middot; centroid &mdash; cut into wedges"),
   ({"cohort": "block", "cut": "axis"}, "block &middot; axis &mdash; taken natively"),
   ({"cohort": "braid", "cut": "margin"}, "braid &middot; margin &mdash; one plane, no chance"),
   ({"cohort": "skew", "cut": "axis"}, "skew &middot; axis &mdash; a corner box")],
  "The null is a counting result: <b>block and skew are one lattice under two labellings</b>, "
  "agreeing on 66 of 120 points and disagreeing on 54 &mdash; and <em>centroid</em> never reads "
  "the label, so it draws the same unlabelled cloud for both. Held at 0.00%. The prediction, "
  "axis against margin on blobs, is #1 of 3: blobs is built as an exact mirror pair, so the "
  "tree's only wall lands at x = 0.000000 and the margin's plane at x = 0.000000 &mdash; the "
  "same object, and the whole difference is two margin faces."),

 ("assembly_stair", "assembly &middot; 3 members &middot; and the mesh counts say it is three things",
  "One vocabulary is a decomposition, one is a derivation, and one is a degree — and you can tell by counting.",
  """<p class="body">The brief said two things: a decomposition (which parts are shown) and a
  degree (how organised the whole set is). <b>The counts say three.</b> cube_staircase runs
  6&nbsp;&rarr;&nbsp;11&nbsp;&rarr;&nbsp;13&nbsp;&rarr;&nbsp;26 meshes &mdash; additive and
  nested, a genuine decomposition. bricoleur_golem runs 6,&nbsp;6,&nbsp;6,&nbsp;6 &mdash; the
  same parts rearranged, a degree. But recursive_table runs
  13&nbsp;&rarr;&nbsp;<b>5</b>&nbsp;&rarr;&nbsp;5&nbsp;&rarr;&nbsp;9: non-monotone and not
  nested. Its second step <em>destroys nine cells to make one slab</em>, and its third adds no
  mesh at all &mdash; it rewrites <code>box.size</code> and <code>position.y</code> in place.
  That is a <b>derivation</b>, a third kind, and nothing in the corpus had named it.</p>
  <p class="body">Twelve parts in every one of the 21 cells &mdash; four decks, four posts, four
  ties, same sizes, same colours. Drawn: <em>cells</em> 8, <em>treads</em> 4, <em>slab</em> four
  parts as one mesh, <em>legs</em> 4, <em>full</em> 12, <em>lashed</em> 12, <em>heap</em> 12.
  treads&nbsp;+&nbsp;legs&nbsp;=&nbsp;cells; cells&nbsp;+&nbsp;ties&nbsp;=&nbsp;full. No degree
  value ever draws fewer than twelve, which is the difference made arithmetic.</p>
  <p class="body">Two more from the code. cube_staircase <b>omits</b> rather than highlights
  &mdash; the gate is on the call and <code>_create_part</code> is never reached, no dimming, no
  alpha. And bricoleur_golem has no <em>full</em> because <b>figure IS its full</b>: the complete
  set in its intended arrangement, named with a degree word.</p>""",
  [({"assembly": "full", "object": "stair"}, "full &middot; twelve parts"),
   ({"assembly": "treads", "object": "stair"}, "treads &middot; four"),
   ({"assembly": "slab", "object": "table"}, "slab &middot; four parts as one mesh"),
   ({"assembly": "heap", "object": "figure"}, "heap &middot; twelve, disordered")],
  "Three nulls, three held at <b>0.00%</b>, and they are the axis confessing: <em>heap</em> "
  "reads a literal table that never consults which object it is, so <span class=\"tok\">object"
  "</span> is worth 42&ndash;43% at every other assembly value and <b>exactly nothing</b> here. "
  "The prediction, treads against slab on the table, is #1 of 21 at 0.17% &mdash; a 10&nbsp;mm "
  "seam cross, 305 of 25,600 samples, the one pair in the sheet where the critic's hottest-5% "
  "window does not saturate."),

 ("boundary_tile", "boundary &middot; 3 members &middot; 1 vocabulary &middot; 2 names, 1 scene, 0 differences",
  "Where a pattern admits it is made of parts.",
  """<p class="body"><b>none</b> lets the field run and the repeat is unlocatable. <b>edge</b>
  marks the rim of the whole field. <b>cell</b> frames one unit, once. <b>lattice</b> rules the
  entire grid. So the axis is a ladder of how loudly a pattern declares its own modularity
  &mdash; the classic distinction between ornament that reads as a continuous field and ornament
  that reads as a tiling. Two of the brief's glosses were wrong and are corrected from the code:
  <em>edge</em> is the field's rim and says nothing about repeating, and <em>lattice</em> does
  <b>not</b> include <em>edge</em> &mdash; both files exclude the rim deliberately, so the subset
  null the brief expected does not exist.</p>
  <p class="body"><b>vr_tile_editor and vr_tile_editor_mirror are one scene</b>, and worse than
  the usual case: the mirror token's entire config is <code>{tile_size: 4, repeat_mode: 3}</code>
  &mdash; exactly the shared script's own export defaults. Not two objects, not even two
  configurations. A name that promises a difference attached to a config that changes nothing.
  (It also explains a standing result: the interaction harness measured both as INERT with all
  sixteen controls dangling. Same scene, same dangling controls, counted twice.)</p>""",
  [({"boundary": "none", "symmetry": "plain"}, "none &middot; the repeat is unlocatable"),
   ({"boundary": "edge", "symmetry": "plain"}, "edge &middot; the field's rim"),
   ({"boundary": "cell", "symmetry": "plain"}, "cell &middot; one unit, once"),
   ({"boundary": "lattice", "symmetry": "mirror"}, "lattice &middot; the whole grid")],
  "<b>Four nulls, four held at 0.0000%, and they are a group-theory result rather than a "
  "construction accident.</b> The motif is invariant under both a half-turn and its main "
  "diagonal, so MIRROR_XY and ROTATE_90 produce the same floor <em>tessera for tessera</em> "
  "&mdash; at every one of the four boundary values. Two wallpaper rules, one photograph. The "
  "prediction, none against cell under mirror, is #1 of 6."),

 ("accord_swarm", "accord &middot; 3 members &middot; 1 vocabulary &middot; and nothing in it is an attractor",
  "Four settings of a three-number weight vector, of which two are not produced by the rules at all.",
  """<p class="body">Reynolds' boids are three local weights &mdash; separation, alignment,
  cohesion &mdash; and <span class="tok">accord</span> names the global form they produce:
  <b>school</b> 1.5/1.0/1.0, <b>orb</b> 0/0/4.5, <b>lane</b> 0/4.5/0.5, <b>lattice</b> 4.5/0/0.
  The brief asked which forms are stable attractors the flock returns to. <b>None of them
  is.</b> Separation and cohesion are conservative; alignment is the family's only dissipative
  term &mdash; "alignment acts as pure drag", the aquarium's own words &mdash; and orb's setting
  switches it off. Kicked, orb's rms radius runs 1.22&nbsp;&rarr;&nbsp;2.886&nbsp;&rarr;&nbsp;1.007
  across the window and never settles. It is a centre, not an attractor.</p>
  <p class="body"><b>lattice is imposed, not emergent</b>, proved three ways: all three members
  <em>deposit</em> a grid arithmetically; separation is purely repulsive so it has no finite
  equilibrium spacing, making every arrangement past the cutoff a fixed point &mdash; a continuum,
  not a lattice; and both commenting members say so outright. <b>And lane is in exactly the same
  condition, which nobody had written down.</b> Neighbour counts at the settled state: orb 30 of
  30, school 0, lane 0, lattice 0. Only one of the four is actually a flock.</p>""",
  [({"accord": "school", "reading": "flock"}, "school &middot; 1.5/1.0/1.0"),
   ({"accord": "orb", "reading": "flock"}, "orb &middot; the only cohesive one"),
   ({"accord": "lane", "reading": "weights"}, "lane &middot; weights &mdash; deposited, not flown"),
   ({"accord": "orb", "reading": "recover"}, "orb &middot; recover &mdash; never settles")],
  "Three nulls held. Two are exact by construction &mdash; at <em>lane</em> and <em>lattice</em> "
  "the flock and its weights are the same frame, because the arrangement was deposited rather "
  "than flown, with 12.4% and 14% spacing margins that are arithmetic and RNG-independent. The "
  "third was registered honestly as <b>a bound that can break</b> rather than an identity, and "
  "came in at 0.07% against a 4% ceiling. The prediction ranked #2 of 6 on a sheet the builder "
  "had already declared saturated, all six pairs inside 4.2 points."),

 ("measure_bench", "measure &middot; 4 members &middot; a derivative, a state, and a canon",
  "Three kinds of quantity under one word, and only one of them needs a time window.",
  """<p class="body">A velocity is a DERIVATIVE &mdash; it does not exist at an instant without a
  limit. A strain is a STATE &mdash; it is a property of the body right now. And
  modulor_man_demo's <em>module</em> and <em>canon</em> are a CANON: not measurements at all but
  Le Corbusier's proportional system, ratios decided in advance and imposed on a body to make it
  commensurable with architecture. The constants check out &mdash; 2.26 / 1.83 / 1.40 / 1.13, and
  the canon circle's top lands on 2.26 exactly &mdash; but <code>RED_SERIES</code> is the Red and
  Blue series <em>interleaved</em>, <code>BLUE_SERIES</code> contains 0.46 and 0.18 which are in
  neither (they are the figure's own shoulder and hip), and &phi; is never computed anywhere.</p>
  <p class="body"><b>The brief's kind-assignment was wrong.</b> ForceMagnitudeDemo takes no limit
  at all: velocity is read off <code>linear_velocity</code> and acceleration is F/m. The only
  genuine difference quotient in the whole family is <em>collision</em>. So the <b>window</b>
  reading &mdash; the sampled positions a derivative needs &mdash; is empty for six of eight
  values, not five.</p>
  <p class="body">And the decisive find, which is about units: <code>SCENE_SCALE = 0.33</code>
  scales newtons, metres per second and metres per second squared <b>alike</b>. Three dimensions,
  one undeclared ruler.</p>""",
  [({"measure": "velocity", "reading": "on"}, "velocity &middot; a rod that is the speed"),
   ({"measure": "strain", "reading": "on"}, "strain &middot; a state, read now"),
   ({"measure": "canon", "reading": "on"}, "canon &middot; decided in advance"),
   ({"measure": "collision", "reading": "window"}, "collision &middot; the only real limit")],
  "<b>The window reading empties six of eight values into one class</b> &mdash; fifteen "
  "mutually identical pairs &mdash; which is precisely the distinction the axis had collapsed. "
  "Five were registered and five held, four at 0.00% and one deliberately registered as "
  "<em>under 1.0% and explicitly not zero</em>. The prediction, velocity against none in "
  "<em>on</em>, is #1 of 28 at 0.09%."),

 ("mode_marker", "mode &middot; 6 names &middot; 2 scenes &middot; and no marked thing in either",
  "How much a label commits to the thing it labels — except there is nothing being labelled.",
  """<p class="body">The ladder should run: <b>float</b> hovers and touches nothing;
  <b>plate</b> sits on a surface; <b>stake</b> is driven into the ground beside the work;
  <b>decal</b> is printed on the work itself and cannot be removed without damaging it. <b>Both
  ends are wrong in the members.</b> <em>plate</em> sits on nothing in either &mdash;
  request_note's plate still bobs &mdash; and <em>decal</em> in both is on the FLOOR, not the
  work. There is no marked thing in either scene. A vocabulary about attachment, in two
  artifacts with nothing to attach to.</p>
  <p class="body">The four marker names are <b>two scenes</b>: all three gallery_marker_* load
  gallery_marker.tscn, and request_note is the second. That halved the default vote &mdash;
  3-to-1 for <em>stake</em> by name, 1-to-1 by scene &mdash; so the tie was broken by counting
  placements in the maps, request_note 724 against 56, and the default is <em>float</em>.
  synthesis_stand's <em>auto</em> is confirmed a dispatch value, and SphericalHarmonics'
  <em>mode</em> is a homonym (spherical harmonic indices) and excluded.</p>""",
  [({"mode": "float", "subject": "facade"}, "float &middot; touching nothing"),
   ({"mode": "plate", "subject": "facade"}, "plate &middot; on the surface"),
   ({"mode": "stake", "subject": "facade"}, "stake &middot; driven beside it"),
   ({"mode": "decal", "subject": "soft_body"}, "decal &middot; on the work, and it deforms")],
  "One null, held at 0.00%, and it is a fallback rather than an identity: on <em>pattern</em> the "
  "field covers the deck edge to edge &mdash; a plane group has no outside &mdash; so a post that "
  "must meet the floor has no floor, and what remains is the plate. The builder registered that "
  "one and stated plainly that no other cell falls back, so there is no second. The prediction, "
  "plate against stake on the facade, is #1 of 6 at 0.44% &mdash; and was pre-declared as sitting "
  "just over the critic's twin bar, so a TWIN verdict there would be correct rather than a fault."),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the scoreboard</h2><span class="fam">6 predictions &middot; 5 hit &middot; 16 designed nulls &middot; 16 held</span><span class="chip">61 of 61 since wave 14</span></div>
    <p class="thesis">The tidiest families in the corpus were hiding the most, and the nulls are what made it visible.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank among non-null pairs, within the context each prediction names.</p></div>
    <p class="body"><b>Three of these six axes are the corpus's cleanest</b> &mdash; cohort, accord
    and boundary each share one vocabulary exactly across three members, with no drift to catch.
    That was supposed to make them the dull ones. Instead: three classifier visualisations that
    draw no decision boundary between them, a flock vocabulary in which two of four values are
    deposited rather than flown, and a tile editor whose "mirror" variant is the same scene with
    the default config. A vocabulary agreeing with itself is not evidence that it describes
    anything.</p>
    <p class="body"><b>What a null is for, stated once more.</b> Sixteen were registered and
    sixteen held. boundary_tile's four are group theory &mdash; a motif invariant under both a
    half-turn and its diagonal makes two wallpaper rules one photograph. assembly_stair's three
    are the axis confessing that <em>heap</em> never asks which object it is. measure_bench's five
    empty six of eight values into a single class. cohort_bench's one is a counting result about
    two labellings of one lattice. None of these is a curiosity found afterwards; each was written
    down before the capture, and each names the place its axis stops being able to tell its own
    values apart.</p>
    <p class="tail"><b>What this wave does not settle.</b> mode_marker's <span class="tok">mode</span>
    axis is LOCAL (27.30% focus, 1.47% of frame) &mdash; a marker is small against the thing it
    marks, which is honest and was predicted, but it is a thin axis and has not been tried from a
    second standpoint. The finding that three classifier artifacts draw no boundary is a defect
    report about the corpus, recorded here and not repaired here. And the survey is running out:
    twelve unused axes with three or more members remained when this wave was chosen, and six of
    them are now spent.</p>
  </section>

<footer><span>wave 19</span><span>6 syntheses &middot; 12 axes &middot; 5 of 6 hit &middot; 16 of 16 nulls held &middot; six agents, one orchestrator</span>
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
