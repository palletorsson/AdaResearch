# wave18_content.py — the prose of the wave-18 gallery, imported by build_wave_gallery.py.
# H1 and masthead written after the sweep was scored.

TITLE = "Wave 18 &mdash; a word borrowed from a question nobody asks"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 18 &middot; 15 August 2026 &middot; six agents, one orchestrator</p>
  <h1>Six axes, and four of them<br>are two axes wearing one word.</h1>
  <p>This wave went looking at the corpus's remaining shared vocabularies and found the same
  shape under most of them: one word covering two questions that come apart the moment you
  build them. <em>substance</em> promises light and shape and delivers only light.
  <em>hand</em> covers gestures and graph algorithms. <em>law</em> covers three things that
  differ in what would refute them. <em>crossing</em> names an operation in one member and a
  result in another, and two of its values are not crossings at all. Sixteen designed nulls
  were registered and sixteen held.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 123 frames &middot; 12 axes, 9 bite + 2 local + 1 weak &middot; 6 predictions, 3 hit &middot; 16 designed nulls, 16 held &middot; 0 clipped, 0 blank</span></div>
"""

SECTIONS = [
 ("substance_room", "substance &middot; 3 members &middot; and it never touches geometry",
  "The vocabulary answers one question in words borrowed from another it never asks.",
  """<p class="body">breathing_room says <em>solid / flesh / glass / fabric</em>, rainbow says
  <em>light / glass / solid</em>, sculpt_one says <em>mixed / glossy / fabric / granular</em>.
  The brief said this was two questions fused: does light get through, and does the body hold
  its shape. <b>The code says worse.</b> In all three members <span class="tok">substance</span>
  never touches geometry at all &mdash; it sets a material and nothing else. So the shape
  question is not fused with the light question; <b>it is never asked</b>, and words like
  <em>flesh</em>, <em>fabric</em> and <em>granular</em>, which promise slump and drape and
  grain, are answering about surface in a vocabulary borrowed from a question the code does
  not put.</p>
  <p class="body">The three overlapping words were checked one by one. <b>solid</b> agrees:
  breathing_room asserts nothing, rainbow asserts opaque and diffuse, same surface. <b>glass</b>
  agrees about kind and not about amount &mdash; it is transparency <em>and</em> specular in
  both members, about 2&times; apart in each number. <b>fabric</b> does not agree at all: only
  sculpt_one gives it a weave, and neither member gives it a drape.</p>
  <p class="body"><b>body</b> is the thing itself; <b>through</b> puts a marked object directly
  behind it so transmission is a fact rather than an impression; <b>bear</b> rests it on a
  support so holding-its-shape would be visible &mdash; if any value did it.</p>""",
  [({"substance": "solid", "reading": "through"}, "solid &middot; through"),
   ({"substance": "glass", "reading": "through"}, "glass &middot; the bar behind shows"),
   ({"substance": "fabric", "reading": "bear"}, "fabric &middot; bear &mdash; and it does not slump"),
   ({"substance": "light", "reading": "body"}, "light &middot; body")],
  "Four nulls, four held. Three are the finding: in the <em>through</em> reading solid, fabric "
  "and granular are mutually identical at <b>0.00%</b>, because they are equally opaque and "
  "nothing else about them is drawn. The prediction &mdash; light against solid in <em>bear</em>, "
  "registered in advance as a cluster of two because solid and glass are themselves identical "
  "there &mdash; is #1 of 14."),

 ("crossing_bench", "crossing &middot; 3 members &middot; 2 vocabularies &middot; NOT one scene",
  "One vocabulary names what you did; the other names what happened; and two of the values are not crossings.",
  """<p class="body">sine_space's words name an OPERATION &mdash; <b>product</b>, <b>sum</b>,
  <b>radial</b>, <b>single</b>. fluency_seam's name a RESULT &mdash; <b>smooth</b>,
  <b>lattice</b>, <b>singular</b>. They are not in correspondence: a product and a sum can both
  look like a lattice.</p>
  <p class="body"><b>Two of sine_space's four values are not crossings at all.</b>
  <em>radial</em> does not combine the waves &mdash; it deletes the second and replaces the
  first's argument with a Euclidean distance. One sine, one scalar, a nodal set of concentric
  circles that never meet. <em>single</em> is the acknowledged null. So the operation vocabulary
  has two operations in it.</p>
  <p class="body">And the brief's mathematics was wrong: a sum's zero set is not curves, it is
  <b>straight diagonals</b> &mdash; sin&nbsp;u = &minus;cos&nbsp;v solves linearly. Product and
  sum both rule the plane with lines; they differ in orientation and spacing (0&deg;/90&deg; at
  1/6&nbsp;m against &plusmn;45&deg; at 0.236&nbsp;m), not in kind. That is what the <b>zero</b>
  reading is for. Checked too: sine_space and its explanation twin are <b>not</b> one scene
  &mdash; two scripts, two renderers &mdash; and they disagree, one computing sin&middot;sin and
  the other sin&middot;cos, a quarter period apart.</p>""",
  [({"crossing": "product", "reading": "field"}, "product &middot; beats"),
   ({"crossing": "sum", "reading": "field"}, "sum &middot; superposition"),
   ({"crossing": "product", "reading": "zero"}, "product &middot; zero &mdash; two families of lines"),
   ({"crossing": "radial", "reading": "zero"}, "radial &middot; circles that never meet")],
  "Five nulls, five held at <b>0.00%</b>. Three are the thesis: in the <em>parts</em> reading the "
  "two operands are unchanged whatever you do to them, so product, sum and lattice are one frame "
  "&mdash; a compression is not an ingredient. The prediction, product against singular in "
  "<em>zero</em>, is #1 of 20 at 0.14%, thirty-seven times closer than the next pair, and it was "
  "registered with its own gate: if the companion at <em>parts</em> had also come back near zero, "
  "the bump was not building."),

 ("law_bench", "law &middot; 3 members &middot; three things that differ in what would refute them",
  "A physical law, a probability model and a bounded approximation are not the same kind of claim.",
  """<p class="body">Newton's laws fall to a single counter-example, and did. A distribution
  cannot be refuted by one sample at all &mdash; you need a statistic and a threshold before any
  observation counts. And riemann_pi's <b>x_over_log</b> and <b>logint</b> are neither: they are
  estimates with known error bounds, and the Riemann hypothesis is a conjecture about how big
  that error is. <span class="tok">law</span> spans refutable-by-instance,
  refutable-only-statistically, and not-refutable-but-bounded.</p>
  <p class="body">Every value is built as a claim <em>and its residual</em> &mdash; the gap
  between prediction and truth, as a body with thickness. That is where the three kinds come
  apart, and the builder was strict about it: <b>Newton's residual here is the integrator's, not
  the law's</b>, and is labelled so. The relativistic residual, the one that actually refuted
  Newton, is about 1e&minus;16&nbsp;m and cannot be drawn honestly at this scale, so it is not
  drawn.</p>
  <p class="body">Only riemann_pi has a real null value. newtons_laws' <em>all</em> is the
  opposite &mdash; the most crowded arrangement, three bodies and three force histories, which
  its own comment calls "F=ma demonstrated three times over" &mdash; and random_space has no null
  at all; its <em>uniform</em> is just the shipped default.</p>""",
  [({"law": "inertia", "reading": "world"}, "inertia &middot; world"),
   ({"law": "gaussian", "reading": "residual"}, "gaussian &middot; residual is statistical"),
   ({"law": "logint", "reading": "claim"}, "logint &middot; li(x)"),
   ({"law": "x_over_log", "reading": "residual"}, "x/log x &middot; residual is bounded")],
  "<b>The brief's null was refuted with arithmetic.</b> li(x) and x/ln&nbsp;x converge in RATIO "
  "but their DIFFERENCE grows as x/(ln&nbsp;x)&sup2; &mdash; from &minus;2.9 counts at x=2 to "
  "+51.5 at 1998 &mdash; so they are the closest pair, not a null, and the prediction ranked #3 "
  "of 36. The three nulls that were registered all held at 0.00%, and the middle one is the "
  "sharpest thing in the section: <b>you cannot tell \&ldquo;no theory\&rdquo; from \&ldquo;a theory "
  "whose residual is exactly zero\&rdquo;</b>."),

 ("configuration_yard", "configuration &middot; 3 members &middot; a sketch, an arrangement, a theorem",
  "The exact solutions are not the robust ones. What survives perturbation is whatever stays far apart.",
  """<p class="body">nbody's words name a statistical shape you could sketch. three_body's name
  specific published solutions you must solve for. example_3_2's name an arrangement a stage
  manager would place. The builder verified the two exact ones against the literature rather than
  trusting the labels: <b>figure_eight really is Chenciner&ndash;Montgomery</b> &mdash; the
  source's (5.820, 0, &minus;1.459) is exactly 6&times;(0.97000436, &minus;0.24308753) with
  velocity scaled by &radic;(100/6), the correct Kepler scaling for its constants &mdash; and
  <b>lagrange really is equilateral L4/L5</b>, circumradius 5 and side 8.660 = 5&radic;3 verified
  on all three pairs.</p>
  <p class="body"><b>And then the brief's argument failed.</b> I claimed the split was
  exact-solution against sketched-shape, and that only the exact ones survive being nudged.
  <em>ring</em> turns out to be a homographic solution itself &mdash; an equilateral triangle is
  a central configuration &mdash; yet it fails the perturbation at 0.3731 while the merely
  hierarchical arrangement holds at 0.0305. <b>The split is closest approach, not theorem versus
  sketch.</b> What survives a nudge is whatever never comes close enough for the 1/r&sup2; to
  bite.</p>""",
  [({"configuration": "ring", "reading": "start"}, "ring &middot; start"),
   ({"configuration": "lagrange", "reading": "start"}, "lagrange &middot; the same placement"),
   ({"configuration": "figure_eight", "reading": "path"}, "figure_eight &middot; Chenciner&ndash;Montgomery"),
   ({"configuration": "hierarchical", "reading": "drift"}, "hierarchical &middot; drift &mdash; and it holds")],
  "<b>The prediction was its own null, which is the strongest form of one.</b> The builder said "
  "the closest pair would be ring against lagrange in <em>start</em> and that it would be exactly "
  "zero: both enter the same branch at the same radius and the same three angles, differing only "
  "in a scalar speed that <em>start</em> does not draw. Measured: <b>0.000%</b>. The exact "
  "solution and the stage arrangement are one picture until you integrate. "
  "(This also exposed a fault in the scorer, which sets nulls aside before ranking and so "
  "reported the prediction unmeasured; a null-prediction is now scored as what it is.)"),

 ("hand_bench", "hand &middot; 4 members &middot; gestures and graph algorithms, under one word",
  "A gesture has a rate and a spread. An algorithm has neither.",
  """<p class="body">The sculpt words &mdash; <b>stack</b>, <b>sweep</b>, <b>stipple</b>,
  <b>spatter</b> &mdash; are gestures of a hand. maze_generation's <b>prim</b> and
  <b>labyrinth</b> are graph algorithms, named after an inventor and a data structure. They are
  not gestures, and the axis has been holding both.</p>
  <p class="body"><b>The brief's premise was overruled.</b> I said the gestures differ in how much
  material lands per unit time. Both live members hold the amount <em>fixed</em> and say so, so
  this bench conserves <b>9.634 litres</b> across all six hands and the difference is entirely
  where it goes. And <em>labyrinth</em> complicates the clean split: it rolls no dice at all and
  its decision order is a walkable route &mdash; 4.349&nbsp;m of pass against 10.1&ndash;11.6 for
  the scattering hands. An algorithm that is also a path.</p>
  <p class="body">One thing found in the source: <span class="tok">sculpt_one</span> ships
  <em>composition</em> &mdash; a union of all its other rungs &mdash; as its DEFAULT. That is the
  all-rungs-inside-an-axis fault this programme has a rule against, sitting in a member's
  shipped default, and it was declined here for that reason.</p>""",
  [({"hand": "stack", "reading": "deposit"}, "stack &middot; deposit"),
   ({"hand": "spatter", "reading": "deposit"}, "spatter &middot; same volume, scattered"),
   ({"hand": "labyrinth", "reading": "pass"}, "labyrinth &middot; pass &mdash; a walkable route"),
   ({"hand": "stipple", "reading": "grain"}, "stipple &middot; grain at true scale")],
  "Both nulls held at 0.00%, and both were quoted out of the members' own headers &mdash; "
  "\&ldquo;THE SAME SEVEN DEPOSITS\&rdquo; and \&ldquo;exactly the same number of standing wall "
  "blocks\&rdquo;. The family had stated its own identities and nobody had registered them. The "
  "prediction ranked #4 of 13; the closest pair is stipple against prim at 0.28%, which is a "
  "gesture and an algorithm measuring the same &mdash; the axis's problem, photographed."),

 ("phase_field", "phase &middot; 4 members &middot; and traverse is the word all three share",
  "A taxonomy of critical points, in which the default value is the ordinary place.",
  """<p class="body">partial_derivative_terrain, slope_tangent_demo and velocity_arrow all use
  <span class="tok">phase</span> for where on a surface you are standing when you take a
  derivative, and all three default to <b>traverse</b> &mdash; the generic point, where nothing
  special happens, which is almost everywhere. The other values name the exceptions:
  <b>crest</b> and <b>trough</b> where the gradient vanishes, <b>steepest</b> where it is
  largest, <b>oppose</b> where the two partials have opposite sign, <b>mirror</b> for the
  reflected station. catalyst_foe declares the same word for a creature's disposition and is
  named kin and excluded.</p>
  <p class="body">One surface in every cell &mdash; f = 0.115&middot;sin(Wx)&middot;sin(Wz) +
  0.215&middot;x over 0.84&nbsp;m&sup2; &mdash; with only the standing point and its furniture
  moving. The gradient is a rod of true length, not a number: at <em>steepest</em> it is 1.0752
  long and at <em>crest</em> and <em>trough</em> it does not exist. And the builder checked the
  source it was quoting: <b>partial_derivative_terrain's own crest and trough do not exist</b>
  &mdash; the minimum |&nabla;f| on its field is 0.0588 and occurs only on the boundary, so this
  field was built to have interior criticals for the words to point at.</p>""",
  [({"phase": "traverse", "reading": "tangent"}, "traverse &middot; the ordinary place"),
   ({"phase": "steepest", "reading": "tangent"}, "steepest &middot; |&nabla;f| = 1.0752"),
   ({"phase": "crest", "reading": "tangent"}, "crest &middot; the gradient vanishes"),
   ({"phase": "trough", "reading": "partials"}, "trough &middot; no rod is built")],
  "<b>The brief's null was refused, correctly.</b> crest and trough carry identical apparatus "
  "&mdash; both have no gradient rod and a horizontal tangent plate &mdash; but their stations "
  "are 0.5875&nbsp;m apart, the furthest pair in the whole set, so they measure 15.02% and rank "
  "9th of 15. The real nulls are between READINGS at a critical point: with both partials zero, "
  "<em>partials</em> and <em>point</em> are the same frame. Both held at 0.00%. The builder also "
  "caught its own capture before it shipped &mdash; drawn flush, <em>trough</em> measured 0.00% "
  "in all three readings, buried by its own convex surface, so the furniture now rides 0.105&nbsp;m "
  "above the bead."),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the scoreboard</h2><span class="fam">6 predictions &middot; 3 hit &middot; 16 designed nulls &middot; 16 held</span><span class="chip">45 of 45 nulls held across waves 14&ndash;18</span></div>
    <p class="thesis">Four of the six axes turned out to be two axes sharing a word, and the nulls are how that became visible.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank among non-null pairs, within the context each prediction names. configuration_yard predicted its own null, which is rank #1 by construction — what is scored there is whether the null held.</p></div>
    <p class="body"><b>A designed null is how a shared word comes apart.</b> substance_room's three
    opaque substances are one frame in <em>through</em>; crossing_bench's three operations are one
    frame in <em>parts</em>; phase_field's two critical points are one frame across two readings;
    law_bench cannot distinguish no-theory from a theory with zero residual. In every case the null
    is not a curiosity &mdash; it is the place where the axis stops being able to tell its own
    values apart, and it was predicted before the capture rather than discovered after it.</p>
    <p class="body"><b>Three of my six briefs were wrong and the code said so.</b> substance never
    touches geometry, so the shape question is not fused into the light question &mdash; it is
    never asked. The sculpt hands hold volume fixed, not rate. And configuration's split is
    closest approach rather than theorem-versus-sketch: <em>ring</em> is itself an exact solution
    and still fails the nudge at 0.3731, while merely hierarchical holds at 0.0305. Two more
    briefs had their nulls refuted with arithmetic before any capture &mdash; li against x/ln x
    diverges in difference even as it converges in ratio, and crest against trough carries
    identical apparatus 0.5875&nbsp;m apart.</p>
    <p class="tail"><b>What this wave does not settle.</b> phase_field's <span class="tok">reading</span>
    axis came back WEAK (10.25% focus, 0.51% of frame) and configuration_yard's and phase_field's
    other axes are LOCAL &mdash; the apparatus in those benches is small furniture on a large
    surface, which is honest and was predicted, but a thin axis is still a thin axis and none of
    the three has been tried from a second standpoint. And the scorer gained its fifth fix this
    session: a prediction that IS its own registered null was being reported unmeasured. Every
    earlier wave was re-scored after the change and none moved.</p>
  </section>

<footer><span>wave 18</span><span>6 syntheses &middot; 12 axes &middot; 3 of 6 hit &middot; 16 of 16 nulls held &middot; six agents, one orchestrator</span>
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
