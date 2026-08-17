# wave22_content.py — the prose of the wave-22 gallery, imported by build_wave_gallery.py.
# The wave where three axes turned out to be understated by the rig, in three different ways.

TITLE = "Wave 22 &mdash; the camera has an opinion"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 22 &middot; 17 August 2026 &middot; six agents, one orchestrator</p>
  <h1>The rig sees depth at a quarter strength.<br>One of these axes is named after depth.</h1>
  <p>Six more two-member families, and the through-line is not in the artifacts. <b>Three of the
  twelve axes here are understated by the instrument, in three different ways</b> &mdash; one by
  foreshortening, one by hue-blindness, one by how the subject is fitted to the frame. The first
  of those is a constant: the canonical camera pitches 15&deg; down, so a depth axis projects at
  sin(0.26) = <b>0.257081</b>, and <em>every sweep this programme has ever run</em> has measured
  depth 3.89&times; weaker than sideways. Meanwhile four of the six families repeat wave 21's
  result &mdash; the fault is on the shipped default &mdash; and one of them ships a default that
  hides its own subject inside an opaque box.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 95 frames &middot; 12 axes, 7 bite + 2 local + 1 weak &middot; 6 predictions, 5 hit &middot; 13 designed nulls, 13 held &middot; 94 of 94 since wave 14 &middot; 0 clipped, 0 blank</span></div>
"""

SECTIONS = [
 ("recession_hall", "recession &middot; an axis that is the name of its default",
  "One of eight cells recedes. It is the value the family ships.",
  """<p class="body">Four values, and the suspicion going in was that <b>abreast</b> is not a
  recession &mdash; it puts levels side by side at one depth, which is the axis's negation rather
  than a point on it. That was right and <b>three rungs too small</b>. Counted in the source:
  <code>animated_folding_past.gd:185</code> spreads ten frames over 4.05&nbsp;m of z at
  <b>nested</b>, and <code>:194</code>, <code>:197</code>, <code>:204</code> pin <b>collapsed</b>,
  <b>abreast</b> and <b>strata</b> each to a <em>single</em> z. In the other member
  <code>_seat()</code> returns z = 0.0 in <b>every</b> branch; the entire z ladder is a
  0.003-per-level offset sitting outside the recession switch, whose own comment says what it is
  &mdash; anti-z-fighting. Fifteen millimetres across a 1.06&nbsp;m frame, under an
  <code>@identity</code> reading &ldquo;receding in Z&rdquo;.</p>
  <p class="body">So one of eight cells recedes, and it is the shipped default. That is a
  <b>new species</b> beside the nine all-rungs values waves 20 and 21 turned up: not a value that
  is the union of its axis, but <span class="tok">an axis that is the name of its default</span>,
  where every other value is the word's negation. Both are ways a vocabulary hides a hole.</p>
  <p class="body">And the instrument agrees with the artifact for the wrong reason. For a subject
  squared up to the canonical camera, a sideways axis projects at 1.000000, a vertical one at
  cos(pitch) = 0.966390, and a <b>depth axis at sin(pitch) = 0.257081</b>. The axis is named after
  the one direction the rig is 3.89&times; worst at seeing &mdash; which is why its verdict here is
  CONDITIONAL at 1.29% of frame and why that number should not be read as a fact about the design.
  Neither source, incidentally, is recursive: one makes a single recursive call, branching factor
  1, a tail call; the other is a plain <code>for</code> loop.</p>""",
  [({"recession": "nested", "inheritance": "halved"}, "nested &middot; the only value that recedes"),
   ({"recession": "abreast", "inheritance": "halved"}, "abreast &middot; one depth, side by side"),
   ({"recession": "strata", "inheritance": "halved"}, "strata &middot; also one depth"),
   ({"recession": "collapsed", "inheritance": "equal"}, "collapsed &middot; equal &mdash; self-similarity discarded")],
  "The second axis came out of a contradiction inside one file: <code>:196</code> and "
  "<code>:203</code> set <code>scale = 1.0</code>, discarding the very <code>scale_ratio</code> "
  "its own <code>@identity</code> names one clause after <em>recession</em>, while "
  "<code>_drawn_size</code> keeps the halving. Same word, opposite answers about whether "
  "self-similarity survives rearrangement &mdash; so <span class=\"tok\">inheritance</span> "
  "(halved &middot; eased &middot; equal) is the question the family cannot agree on, and it has "
  "no shared default. Prediction #1 of 3 at 0.17%, registered as two-sided rather than a floor.",),

 ("remainder_box", "remainder &middot; the default hides the subject",
  "An opaque box, and the superposition it exists to show sealed inside it.",
  """<p class="body">These two are closer than any pair the programme has found without being one
  script: they name different scripts, but <code>superposition_display.gd:224</code>
  <b>preloads</b> <code>schrodinger_box.gd</code> and parses its own axis words through the box's
  static <code>remainder_name()</code>. The vocabulary has one implementation, and it lives in the
  other file.</p>
  <p class="body">Both gloss <b>core</b> as <em>sealed</em>, and both ship it as the default. On the
  display that builds an emissive sphere standing in the open &mdash; the brightest thing in frame.
  On the box it is literally true, and nobody costed it: <code>_create_box()</code> builds an
  <b>opaque</b> 0.4 &times; 0.3 &times; 0.3 BoxMesh at the origin, and
  <code>_create_superposition_effect()</code> builds a 0.12&nbsp;m glow sphere <em>at the same
  origin</em>. Half-extents 0.20 / 0.15 / 0.15 against 0.12: the sphere is entirely enclosed.
  <b>The artifact's whole subject is invisible in the value it ships</b>, and <code>_process()</code>
  animates alpha and emission on a mesh no camera can reach.</p>
  <p class="body">One value below that, the physics: <code>schrodinger_box.gd:314</code> is
  <code>var is_alive = randf() &gt; 0.5</code>, under an <code>@identity</code> at line 10 declaring
  <code>|&psi;&rang; = &alpha;|alive&rang; + &beta;|dead&rang; &rarr; observation collapses &hellip;
  with P = |&alpha;|&sup2;</code>. &alpha; is never read. The artifact states the rule it exists to
  teach and implements the one thing that rule rules out. And the brief's own physics suspicion was
  <em>wrong</em> in an interesting way: the pair draws twin-against-haze correctly as topology, but
  renders a mixture as <b>faintness</b> when what a mixture lacks is <b>coherence</b> &mdash;
  neither file contains a phase anywhere.</p>""",
  [({"remainder": "core", "keeping": "vault"}, "core &middot; the default &mdash; and the subject is inside"),
   ({"remainder": "twin", "keeping": "vault"}, "twin &middot; walled and definite"),
   ({"remainder": "haze", "keeping": "vault"}, "haze &middot; outside and spread"),
   ({"remainder": "twin", "keeping": "dial"}, "twin &middot; dial &mdash; the amplitudes read off")],
  "<b>witness</b> was declined and the reason is structural: it answers the question of the "
  "pair's OTHER shared axis, <span class=\"tok\">vantage</span>, not this one. Four values name "
  "something LEFT after resolution; a witness is what causes the resolution. That is the mirror of "
  "wave 20's all-rungs fault &mdash; not a value that is the whole axis, but a value that is not on "
  "the axis at all. Prediction #1 of 6 at 0.22%, declared in luma and two-sided; one null held at "
  "0.00%.",),

 ("constant_dispute", "calibration &middot; a plate that argues equality and draws dominance",
  "Three territories at equal strength, says the comment. The code builds 35 / 10 / 55.",
  """<p class="body">The premise I handed this builder was wrong: <code>phi_slider</code>'s
  &phi; is not the golden ratio but QFEP's entropy-sensitivity parameter, so both constants are free
  parameters of one invented formula and neither carries an error bar. But the <em>shape</em> of the
  suspicion survived. &lambda;'s recommendation is a bounded interval with both ends interior;
  &phi;'s is a half-line whose far end is the rail's end. That breaks three of five words: <b>band</b>
  draws a bracket at <code>hi</code> unconditionally, so &phi;'s second bracket marks the instrument
  rather than a threshold; <b>gap</b> is built under <code>if hi &lt; 0.998</code>, false for &phi;,
  so one plate has a hole and the other is merely truncated; and &lambda;'s <b>dispute</b> marks are
  <em>band</em>'s own two brackets plus the shipped default, all inside &lambda;'s own band &mdash;
  so it cannot disagree with itself.</p>
  <p class="body">And then the plate itself. Its comment states the design in as many words:</p>
  <pre class="code"><code>&#35; three territories at equal strength, so the plate shows the
&#35; disagreement rather than resolving it</code></pre>
  <p class="body">The code beneath builds a <b>one-dimensional nearest-neighbour partition</b>, with
  the outer territories running to 0.0 and 1.0. That is equal only if the marks are evenly spaced
  <em>and</em> the outer two sit at the rail ends. Neither slider's are. &lambda;'s marks
  0.30/0.40/0.50 give <b>35% / 10% / 55%</b> &mdash; the shipped default takes the <em>smallest</em>
  territory. &phi;'s 0.50/0.65/0.875 give <b>57.5% / 18.75% / 23.75%</b>, handing the majority to the
  position that file's own truth line exists to refute. A plate built to show that no school
  dominates gives the board to whichever school sits nearest an end.</p>
  <p class="body"><span class="hint">The bench renames the vocabulary it inherits &mdash;
  <em>point &middot; interval &middot; rival &middot; threshold &middot; absent</em> for the sources'
  <em>optimum &middot; band &middot; dispute &middot; gap &middot; none</em> &mdash; because four of
  the five source words name the instrument's rail rather than the claim being made on it. Frame
  captions below use the bench's words; the prose above uses the sources'.</span></p>""",
  [({"claim": "point", "record": "bare"}, "point &middot; a single value"),
   ({"claim": "interval", "record": "bare"}, "interval &middot; the sources' <em>band</em>"),
   ({"claim": "rival", "record": "bare"}, "rival &middot; three territories, unequal"),
   ({"claim": "absent", "record": "count"}, "absent &middot; count &mdash; no claim, and the tally")],
  "Three nulls, three held at <b>0.00%</b> against a tight 0.10% cap: at <em>point</em> the three "
  "record readings build 52 identical meshes, verified in Python and again in Godot. Prediction "
  "#1 of 10 at 0.65%, with the next-closest a clean 3.00&times; away. <b>gap</b> was declined "
  "&mdash; it is a claim about the instrument's rail rather than about the set's topology, and "
  "carrying it would have made the axis two questions.",),

 ("statute_fitting", "statute &middot; two decisions and a clock, and a dead export",
  "The only certificate anywhere in either file is an expired one.",
  """<p class="body">These are, as far as the corpus goes, the only two artifacts whose form is
  dictated by an external legal code rather than by an algorithm. And they are one hand: the
  <code>SUPPORTS</code> and <code>DEGRADE</code> tables, the livery table and all four livery
  function bodies are identical to the last digit across 904 and 981 lines, and both hang the same
  tag via <code>make_panel_mesh("2019")</code>.</p>
  <p class="body">The seam is one value left of where the brief put it. <b>joinery</b> is not a
  construction detail &mdash; it is the <em>building's</em> cabinetwork absorbing the object. So the
  real split is that <b>issue</b>, <b>notice</b> and <b>joinery</b> are all decisions taken at
  install, while <b>lapse</b> is not a decision at all but <em>time</em>. A single <code>match</code>
  makes them mutually exclusive, so the family cannot photograph a serviced extinguisher on a rotted
  wall &mdash; which is why <span class="tok">currency</span> (certified &middot; discharged &middot;
  overdue) had to become the second axis: the clock, separated from the decisions.</p>
  <p class="body">The dead export is the find. Under <b>joinery</b> the livery table sets
  <code>ink_amt = 1.0</code>, which makes <code>_ink()</code> &mdash; <code>c.lerp(ink, 1.0)</code>
  &mdash; a <b>constant function</b>. So at that one value the <code>label_color</code> and
  <code>accent_color</code> exports silently discard whatever a map passes and always return
  <code>Color(0.44, 0.46, 0.42)</code>. Beside it, a smaller asymmetry with the same shape:
  <code>support</code> is normalised and allow-listed on every config read, with a comment about the
  space a human types after a colon, while <code>statute</code> is matched <b>raw</b> in two places.
  Same file, same author, one axis defended and the other not.</p>""",
  [({"statute": "issue", "currency": "certified"}, "issue &middot; certified"),
   ({"statute": "notice", "currency": "certified"}, "notice &middot; the sign"),
   ({"statute": "joinery", "currency": "certified"}, "joinery &middot; the building absorbs it"),
   ({"statute": "lapse", "currency": "overdue"}, "lapse &middot; overdue &mdash; time, not a decision")],
  "Two nulls, two held, and the first is the argument: <em>certified</em> against <em>overdue</em> "
  "under <b>joinery</b> measures <b>0.0000%</b>, because once the building has absorbed the fitting "
  "there is no certificate left to be current or lapsed. Prediction #1 of 6 at 0.08%, declared in "
  "luma and two-sided &mdash; and it had to be, because <code>changed_pct</code> cannot rank that "
  "column at all: the moving pixel set is identical in three of its rows.",),

 ("stick_office", "office &middot; the fulcrum is welded to the lever",
  "A use is not a property of the object. The corpus keeps trying to store one there anyway.",
  """<p class="body">Both scenes attach <code>commons/primitives/cubes/grab_rod.gd</code> to their
  root. One script, two registry tokens &mdash; the <b>ninth</b> instance of the corpus's most common
  hidden family, and the first where the duplication is visible as a <em>measurement</em>: both
  tokens had already been swept separately, and the two published bite files agree on all ten office
  pairs to within <b>0.02 percentage points</b>, four of them identical to two decimals. Two sheets,
  one experiment, counted twice.</p>
  <p class="body">Half the brief's suspicion was destroyed &mdash; the rod does build real geometry
  for four of five values, so this is not a label axis. The other half was confirmed by the file's
  own docstring, which concedes that office &ldquo;shows entirely in what is fitted at its ends.&rdquo;
  And that is where the fault is. Everything the axis fits is added as a child of the rod
  (<code>grab_rod.gd:142</code>), and the rod is an <code>XRToolsPickable</code> RigidBody3D. So at
  <b>lever</b>, <b>the fulcrum is parented to the body you pick up</b> &mdash; hanging 0.112&nbsp;m
  under a shaft you can hold anywhere, touching nothing, travelling with the thing it is supposed to
  pivot. A fulcrum is by definition the part that does not move with the lever.</p>
  <p class="body">The bench therefore builds the world instead of the rod: a fulcrum that sits on the
  ground, graduations that belong to a stock, a target that makes a pointer a pointer. Which makes
  the whole rod column a designed null &mdash; the rod is byte-identical across all five offices,
  and that is the argument rather than a check on it.</p>""",
  [({"office": "reach", "reading": "fitted"}, "reach &middot; the bare rod"),
   ({"office": "lever", "reading": "fitted"}, "lever &middot; a fulcrum that stays put"),
   ({"office": "rule", "reading": "fitted"}, "rule &middot; graduations belong to the stock"),
   ({"office": "baton", "reading": "trace"}, "baton &middot; trace")],
  "<b>The wave's one missed prediction</b>, at #6 of 29 &mdash; <em>rule</em> against "
  "<em>pointer</em> was predicted closest in the trace reading at 0.843%, and <em>lever</em> "
  "against <em>pointer</em> came in at 0.41%. Three nulls held at 0.00%. Also carried out of this "
  "one and filed for repair rather than fixed: both source scenes fit the camera by <b>diagonal</b>, "
  "putting the subject at 2.26% of frame while <em>lever</em> and <em>baton</em> move 29.4% inside "
  "it &mdash; so both published faint verdicts are facts about the camera, and neither entry carries "
  "<code>dna.framing</code>.",),

 ("mixing_jar", "found_state &middot; one member measures, the other declares",
  "The same word is an output in one file and an input in the other.",
  """<p class="body"><b>entropy_jar</b> measures: eighty bodies lie where they lie, and
  <code>_measure_entropy()</code> bins them into six vertical slices and computes S.
  <b>entropy_morphogenesis</b> declares: there is no measurement anywhere in the file &mdash;
  <code>_apply_found_state()</code> writes 0.0 or 1.0 into an export, which fans out into a gyroid.
  One <span class="tok">found_state</span> is a result, the other is a setting.</p>
  <p class="body">The all-rungs suspicion is <b>destroyed</b>. <b>mixed</b> is not a union of
  <em>sorted</em> and <em>stirred</em> in either member; both implement the axis as three samples of
  one scalar (the jar's overlap reach 0 / 0.35 / 1.0, the gyroid's S 0.0 / 0.3 / 1.0), so mixed is
  the top rung of a monotone ladder. And <b>shelled</b>, which only one member declares, is not a
  container detail that wandered in &mdash; it is the family's only demonstration that entropy is
  relative to the coarse-graining, and the sibling that dismissed it as &ldquo;a joke&rdquo; was
  wrong.</p>
  <p class="body">The source finding: <code>entropy_morphogenesis_vr.gd:61-64</code> names its top
  level &ldquo;past the percolation point &hellip; isolated pockets &hellip; the whole argument&rdquo;
  at threshold +0.95. <b>It does not break.</b> Flood-filled over one gyroid period, G &gt; 0.95 is a
  single connected percolating component; so is its complement. The likely cause is one comment:
  <code>GyroidFieldGenerator.gd:72</code> states the field range as &ldquo;roughly [&minus;3, 3]&rdquo;
  when the gyroid's true extremum is <b>1.5</b> &mdash; on the diagonal it reduces to
  3&thinsp;sin&thinsp;t&thinsp;cos&thinsp;t = 1.5&thinsp;sin&thinsp;2t. Out by 2&times;, so a
  threshold meant to sit past percolation sits at 63% of maximum.</p>""",
  [({"found_state": "sorted", "reduction": "form"}, "sorted &middot; form"),
   ({"found_state": "stirred", "reduction": "form"}, "stirred &middot; form"),
   ({"found_state": "mixed", "reduction": "cells"}, "mixed &middot; cells &mdash; the coarse-graining"),
   ({"found_state": "shelled", "reduction": "figure"}, "shelled &middot; figure &mdash; the measure itself")],
  "Three nulls, three held at 0.00%: <em>mixed</em> and <em>shelled</em> coincide in all three "
  "readings, because a shell is a coarse-graining of a mixture and the reductions cannot tell them "
  "apart. Prediction #1 of 5. <b>But read the verdict carefully</b> &mdash; the critic returns WEAK "
  "at 4.37% focus, and its own colour check reports the same pairs at <b>20.58%</b> and "
  "<b>25.82%</b> in hue. This axis moves colour at near-constant brightness, which luminance cannot "
  "see. The second of this wave's three instrument understatements, and the reason the WEAK label "
  "on this row is not a fact about the design.",),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the scoreboard</h2><span class="fam">6 predictions &middot; 5 hit &middot; 13 designed nulls &middot; 13 held</span><span class="chip">94 of 94 since wave 14</span></div>
    <p class="thesis">Three axes understated by the instrument, in three different ways, in one wave.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank among non-null pairs, within the row each prediction names, on the metric it declares. Four of the six declared a magnitude metric &mdash; new this wave, and three of those four could not have been ranked without it.</p></div>
    <p class="body"><b>The three understatements.</b> They are independent, and each would have been
    read as a weak artifact by anyone trusting the headline number.</p>
    <ol class="body">
      <li><b>Depth.</b> For a subject squared to the canonical camera, a sideways axis projects at
      1.000000, a vertical at cos(pitch) = 0.966390, a depth axis at sin(pitch) = <b>0.257081</b>.
      The rig pitches 15&deg; down, so anything whose argument is depth is measured 3.89&times;
      weak &mdash; across every sweep in the programme's history, not just this one.</li>
      <li><b>Hue.</b> mixing_jar's axis returned WEAK at 4.37% focus and 20.58% / 25.82% in colour.
      Luminance cannot see a change at constant brightness.</li>
      <li><b>Fit.</b> stick_office's two sources fit by diagonal, putting the subject at 2.26% of
      frame while the axis moves 29.4% inside it. Two published faint verdicts, both about the
      camera.</li>
    </ol>
    <p class="body"><b>And the defaults, again.</b> Wave 21 found the fault on the shipped default in
    four of six families; wave 22 does it again in four of six. remainder_box's <em>core</em> seals
    the superposition inside an opaque box &mdash; the subject invisible in the value that ships.
    recession_hall's <em>nested</em> is the only one of four values that recedes, which makes the
    axis <span class="tok">the name of its default</span>: a new species beside the nine all-rungs
    values of waves 20&ndash;21. constant_dispute's plate gives its own default the smallest
    territory on a board arguing that none dominates. statute_fitting's <em>joinery</em> silently
    kills two colour exports.</p>
    <p class="body"><b>A seventh parser fault, same family as the other six.</b> recession_hall
    registered its pair as <code>collapsed/halved against collapsed/eased</code> &mdash; compound
    notation naming the row and the value together, which is how a person writes a pair on a second
    axis. Read literally that is two equal <em>recession</em> values, so the scorer picked the wrong
    axis and reported &ldquo;pair not measured&rdquo; on a correctly registered prediction. Fixed;
    it now splits the compound and hands the matching half to the row resolver. Every one of the
    seven has been the same mistake &mdash; the instrument being more literal than the person
    feeding it.</p>
    <p class="tail"><b>Source defects found and not repaired here</b>, because these are shipped
    artifacts with live placements: schrodinger_box's opaque default and its
    <code>randf() &gt; 0.5</code> collapse under a Born-rule identity; grab_rod's fulcrum parented to
    the lever; entropy_jar shipping <code>particle_seed = 0</code> with no <code>dna.fixture</code>,
    whose one recorded sweep measured two size exports rather than its declared axis and contains no
    same-parameter control, so nothing in it separates signal from re-draw; GyroidFieldGenerator's
    2&times; range comment; and fire_extinguisher's dead <code>label_color</code>. Two are filed as
    repair tasks. Also standing: <b>seven sceneless registry tokens declare <code>dna.axes</code></b>,
    all in living.json &mdash; axes nothing can ever photograph.</p>
  </section>

<footer><span>wave 22</span><span>6 syntheses &middot; 12 axes &middot; 5 of 6 hit &middot; 13 of 13 nulls held &middot; six agents, one orchestrator</span>
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
