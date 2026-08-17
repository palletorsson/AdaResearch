# wave20_content.py — the prose of the wave-20 gallery, imported by build_wave_gallery.py.
# The last wave at the three-member bar. H1 and masthead written after the sweep was scored.

TITLE = "Wave 20 &mdash; six values that were not values"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 20 &middot; 16 August 2026 &middot; six agents, one orchestrator</p>
  <h1>Six of the values turned out<br>to be the axis itself.</h1>
  <p>This is the last wave at this bar. Five axes with three or more unused members remained in
  the corpus; all five are here, with the strongest two-member pair. And between them the six
  builders found <b>six values that are not values</b> &mdash; <em>reciprocal</em>,
  <em>together</em>, <em>flip</em>, <em>commute</em>, and <em>cycle</em> twice &mdash; each one a
  union of the other rungs, sitting inside an axis as though it were a peer. One of them is a
  shipped default. Fourteen designed nulls were registered and fourteen held, which is
  seventy-five of seventy-five since wave 14.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 115 frames &middot; 12 axes, 8 bite + 2 local + 1 weak &middot; 6 predictions, 3 hit &middot; 14 designed nulls, 14 held &middot; 0 clipped, 0 blank</span></div>
"""

SECTIONS = [
 ("algorithm_menu", "algorithm &middot; 3 members &middot; 36 values &middot; and every intersection empty",
  "An axis with sixteen unrelated values is not a dimension of variation. It is a dispatch table.",
  """<p class="body">A DNA axis is supposed to hold one thing varied while everything else stays
  put. <span class="tok">algorithm</span> does not. grid2d declares twelve values, grid3d eight,
  profile sixteen &mdash; and the builder checked every pair: <b>36 declared, union 36, every
  pairwise intersection empty.</b> Three widgets, three menus of whatever each can run, filed
  under one word. A menu has no closest pair in any meaningful sense, because its values are not
  points in a space.</p>
  <p class="body">And the corpus declares one thing under two axis names. grid2d's
  <em>RULE30</em>, <em>RULE110</em> and <em>RULE90</em> are literally ca_bridge's
  <span class="tok">rule</span> values: the factory calls one file,
  <code>cartridge_rule_1d.gd</code>, as <code>.new(30) / .new(110) / .new(90)</code>, and its
  whole state is a single <code>rule_number: int</code>. Wave 16 built rule_bench on that family
  under its proper name.</p>
  <p class="body"><b>kind</b> is the axis the family should have had &mdash; <em>automaton</em>,
  <em>search</em>, <em>signal</em> &mdash; and every algorithm belongs to exactly one, so it
  PARTITIONS the other axis and most of the cross product is undefined. Eight native cells,
  sixteen foreign. Declined and recorded: the five 2-D automata (both grid directions are already
  spent on space), the MSTs (edges, not cells), <em>RANDOM</em> (<code>randi()%8</code>, unseeded,
  its own header calls it "the antithesis cartridge"), and <em>SLOW</em> &mdash; which is not a
  speed at all but a real rule identical to DISCO's, differing only by a map-supplied tempo.</p>""",
  [({"algorithm": "RULE30", "kind": "automaton"}, "RULE30 &middot; automaton"),
   ({"algorithm": "BFS_FLOOD", "kind": "search"}, "BFS_FLOOD &middot; search"),
   ({"algorithm": "SINE_WAVE", "kind": "signal"}, "SINE_WAVE &middot; signal"),
   ({"algorithm": "RULE30", "kind": "search"}, "RULE30 &middot; search &mdash; a foreign cell")],
  "Three nulls, three held at <b>0.00%</b>: the foreign columns collapse sixteen frames to three "
  "images, because an algorithm in the wrong kind's substrate draws the substrate and nothing "
  "else. That is the partition made visible. The prediction ranked #10 of 27 &mdash; on an axis "
  "whose values are not commensurable, a rank is close to meaningless, and saying so is the point "
  "of building it. <b>And this bench found the fault in the gate</b>: reading grid2d to choose "
  "which values it could honestly implement, it found a thirteenth enum member, DISCO, hidden "
  "behind a comment containing a comma &mdash; invisible to the deriver, therefore matching the "
  "registry, therefore GREEN. Fixed; DISCO is now declared.",),

 ("order_pair", "order &middot; 3 members &middot; 2 vocabularies &middot; and two of the values are unions",
  "One member's order changes the result. The other's changes only the path.",
  """<p class="body">Vector subtraction does not commute: <b>a_minus_b</b> and <b>b_minus_a</b> are
  exact negatives, so order changes the RESULT and the axis earns its name. Cube assembly does
  commute: <b>ascend</b> and <b>descend</b> build the same cube, so order changes only the PATH
  and the finished object is identical. One word, two consequences, and nothing in the vocabulary
  distinguishes them.</p>
  <p class="body"><b>reciprocal is not a reversal and not a reciprocal.</b> Both members guard the
  swap on the literal string <code>"b_minus_a"</code>, so reciprocal runs the a&minus;b arithmetic
  untouched and merely ADDS a second arrow at &minus;diff &mdash; it is the union of the other two
  values, an all-rungs value living inside the axis. The word is wrong as well: that is the
  additive inverse. <b>together</b> is the same fault on the other member &mdash;
  <code>_phase_order()</code> returns an empty list, so every piece appears at once.</p>
  <p class="body">Two scenes, not one: VectorSubtraction extends a shared base with grab-sphere
  arrows and a RigidBody3D beam, example_1_3 extends Node3D with cylinders and a Label3D. Same
  word, same value list &mdash; the younger file's own comment says it copied both "character for
  character".</p>""",
  [({"order": "a_minus_b", "reading": "result"}, "a_minus_b &middot; result"),
   ({"order": "b_minus_a", "reading": "result"}, "b_minus_a &middot; the exact negative"),
   ({"order": "ascend", "reading": "path"}, "ascend &middot; path"),
   ({"order": "descend", "reading": "path"}, "descend &middot; the other way round")],
  "<b>The prediction was its own null and it landed exactly.</b> ascend against descend in the "
  "<em>result</em> reading, registered at 0.0% with a 0.05% ceiling because they build the same "
  "cube &mdash; measured <b>0.000%</b>, and <em>together</em> joins them, so all three cube words "
  "are one frame. The vector side collapses nowhere, which is the contrast the bench exists to "
  "make: on one member the axis is about an outcome, on the other it is about a history, and only "
  "the second one can be photographed away."),

 ("alphabet_grammar", "alphabet &middot; 3 members &middot; and the size ranking is inverted",
  "Two symbols make an endless maze. Nine symbols make one triangle.",
  """<p class="body">An <span class="tok">alphabet</span> is the set of primitives a generative
  system may combine, and the obvious guess is that more symbols means more reachable forms. The
  builder measured it instead, on 400 replica streams, counting the distinct local configurations
  that actually occur: <b>16 / 16 / 16 / 16 / 97 / 1 / 121</b>. The nine-symbol
  <em>csg_tree</em> has reach <b>ONE</b> &mdash; it declares nine gene kinds and
  <code>add_primitive_to_surface</code> emits a single triangle for all nine. The two-symbol
  alphabets reach 16. The ranking is inverted, and alphabet size predicts nothing.</p>
  <p class="body">ten_print_textile is named for <code>10 PRINT CHR$(205.5+RND(1)); : GOTO 10</code>,
  whose alphabet is two characters. All three of its values turn out to be two-symbol alphabets:
  <em>diagonals</em> is the &plusmn;45&deg; bar, <em>orthogonals</em> is <b>the same bar</b> at
  0&deg; and 90&deg;, <em>blocks</em> is a filled cell against a speck. Its axis never varies size
  at all. And <em>voxel</em> is not one cube but two symbols &mdash; cube and <b>void</b>.</p>
  <p class="body">The two GeneticProgramming entries are one scene, and the difference between them
  is that one carries <code>dna.fixture {population_seed}</code> and the other carries none: the
  same scene registered once seeded and once not. Its <code>.tscn</code> root is also scriptless,
  with the script on a child &mdash; so that source axis has never been reachable from a map
  token.</p>""",
  [({"alphabet": "diagonals", "reading": "field"}, "diagonals &middot; two symbols"),
   ({"alphabet": "orthogonals", "reading": "glyphs"}, "orthogonals &middot; the same bar, turned"),
   ({"alphabet": "csg_tree", "reading": "reach"}, "csg_tree &middot; nine symbols, reach 1"),
   ({"alphabet": "parametric", "reading": "reach"}, "parametric &middot; reach 121")],
  "<b>No designed nulls, and it said so.</b> The expected subset identity &mdash; csg_tree's "
  "primitives being a subset of <em>primitives</em>' &mdash; is destroyed by the one-triangle "
  "stub, so nothing in the build is identical and none was registered rather than manufacturing "
  "one. The prediction, diagonals against orthogonals in <em>glyphs</em>, is #1 of 21 at 0.16%: "
  "the same bar at two angles."),

 ("posture_bench", "posture &middot; 4 members &middot; 4 vocabularies &middot; the least agreed axis left",
  "A defence state, a spring's load, an animal's stance and a text layout, under one word.",
  """<p class="body">armadillo_eggling's <b>ball</b> and <b>walker</b> are a defence STATE.
  spring_hopper's <b>laden</b> and <b>solid</b> are a mechanical LOAD. tentacle_placer's
  <b>sentry</b>, <b>coil</b> and <b>cast</b> are an animal STANCE. And qfep_formula_3d's
  <b>line</b>, <b>arc</b> and <b>ring</b> are a text LAYOUT, with no body in them at all. The
  bench poses one six-link chain into every one of them, so a posture is six angles and nothing
  else.</p>
  <p class="body">The layout words were posed rather than declined, which is the interesting move:
  the same six segments arranged as a formula's line, arc or ring, at a constant turn per hinge.
  But <em>stack</em> was declined on the code &mdash; <code>_arrange_stack</code> translates and
  sets <code>rotation = Vector3.ZERO</code>, and a translation breaks a chain. So qfep's own
  vocabulary is three curvatures and one translation.</p>
  <p class="body">And <b>cycle appears in two members meaning the same thing in both</b>: a
  sentinel, an un-pinned branch, shipped as the default. That is wave 20's fifth and sixth
  all-rungs value. The brief said four kinds of thing; the code says three &mdash;
  <code>_fold_amount</code> and <code>_rest</code> turn out to be one scalar mechanism, so the
  state and the load are the same dial under two vocabularies.</p>""",
  [({"posture": "ball", "reading": "body"}, "ball &middot; the defence state"),
   ({"posture": "cast", "reading": "body"}, "cast &middot; the stance"),
   ({"posture": "arc", "reading": "body"}, "arc &middot; a body posed as a layout"),
   ({"posture": "ball", "reading": "envelope"}, "ball &middot; envelope &mdash; minimised")],
  "Three nulls, three held at <b>0.00%</b> across all three readings: <em>line</em> and "
  "<em>sentry</em> both resolve to six zero angles &mdash; one from a sweep of 0&deg;, the other "
  "from the unreachable branch of the source's own solver &mdash; so a text layout and an animal "
  "at rest are the same six numbers. The prediction, solid against arc in <em>body</em>, is #1 of "
  "44: a spring's coil-height law gives 20.93&deg; per hinge and qfep's 110&deg; sweep gives "
  "18.33&deg;, two constants derived from unrelated sources landing 2.6&deg; apart."),

 ("waveform_basis", "waveform &middot; 2 members &middot; and the family contains its own refutation",
  "Sine is not one option of four. It is the basis the other three are built from.",
  """<p class="body">Fourier's theorem is that square, sawtooth and triangle are each an infinite
  sum of sines &mdash; square takes odd harmonics at 1/n, sawtooth all harmonics at 1/n, triangle
  odd harmonics at 1/n&sup2; with alternating sign. So the axis lists a basis vector alongside
  three things made out of it as though they were peers. And the second member of the family is
  <span class="tok">fourier_transform</span>, the artifact whose entire subject is that
  decomposition, declaring the same flat list.</p>
  <p class="body"><b>partials</b> is where the claim becomes geometry: each waveform's sine
  components stacked at their true amplitudes, so the 1/n and 1/n&sup2; falloff is a physical
  fact rather than an assertion. <b>sum</b> draws the partial sum at a stated number of terms
  against the ideal, which makes Gibbs ringing at a discontinuity a thing with a size.</p>
  <p class="body">This artifact was also the one that survived a process exit mid-build: its
  code, scene and registry were on disk but its axes had never been derived, so the declaration
  was an empty stub. Derived from its own enums afterwards and gated &mdash; which is the
  difference between a declaration that is written and one that is read off the code.</p>""",
  [({"waveform": "sine", "reading": "wave"}, "sine &middot; the basis"),
   ({"waveform": "sine", "reading": "partials"}, "sine &middot; partials &mdash; itself, alone"),
   ({"waveform": "square", "reading": "partials"}, "square &middot; odd harmonics at 1/n"),
   ({"waveform": "triangle", "reading": "sum"}, "triangle &middot; sum &mdash; and the ringing")],
  "The null is the thesis in one line: <b>sine has exactly one partial, itself</b>, so its "
  "<em>wave</em> frame and its <em>partials</em> frame are the same object. Held at 0.00%. The "
  "prediction ranked #2 of 6; the closest pair is square against triangle, which share a partial "
  "SET &mdash; both odd harmonics &mdash; and differ only in how fast the amplitudes fall away."),

 ("construction_pair", "construction &middot; 3 members &middot; and both vocabularies named a union",
  "Three drawings and one theorem, and the theorem is drawn as the other two at once.",
  """<p class="body"><b>chain</b> puts b's tail at a's tip: addition as a journey, which makes order
  look as though it matters. <b>parallelogram</b> puts both tails at the origin: addition as a
  symmetric fact, which makes order look as though it does not. <b>bare</b> is the null. And the
  two vocabularies' distinguishing values are both UNIONS: <em>commute</em> is chain &cup; mirror
  chain, <em>flip</em> is chain &cup; parallelogram. <b>The vocabularies differ only in which
  union they named.</b></p>
  <p class="body">Two rendering faults in the sources, found while reading them: both subtraction
  members' shipped default draws one side of its own figure twice &mdash; the dotted run on
  a&rarr;r is coincident with the solid chained copy &mdash; and VectorAddition colours its two
  dotted runs for the wrong operand.</p>
  <p class="body">Asked whether this duplicates wave 13's <span class="tok">component_court</span>,
  the builder answered by kind: the court is UNARY, decomposing one vector into basis components;
  this is BINARY, combining two given operands. <em>commute</em> and <em>flip</em> have no unary
  analogue, and only a binary bench can say that the sum and the difference are the two diagonals
  of one parallelogram &mdash; verified exactly here, |a+b|&sup2; + |a&minus;b|&sup2; = 0.388800 =
  2(|a|&sup2; + |b|&sup2;).</p>""",
  [({"construction": "chain", "operation": "add"}, "chain &middot; add"),
   ({"construction": "parallelogram", "operation": "add"}, "parallelogram &middot; both from the origin"),
   ({"construction": "commute", "operation": "add"}, "commute &middot; a theorem, drawn as a union"),
   ({"construction": "parallelogram", "operation": "subtract"}, "subtract &middot; the other diagonal")],
  "Two nulls, two held at 0.00%, and they are a vocabulary gap drawn as an absence: <em>flip</em> "
  "is not defined under addition and <em>commute</em> is not defined under subtraction, so each "
  "falls back to <em>bare</em>. The builder declined to invent honest extensions and recorded why. "
  "<b>The axis came back WEAK</b> &mdash; 5.86% focus, 0.29% of frame &mdash; and that is not "
  "hidden: its whole subject is dotted guide lines, thirteen visible dots across 0.0047&nbsp;m&sup2; "
  "of a 0.60&nbsp;m&sup2; crop. It was not re-framed, because the prediction was computed at the "
  "declared framing and moving the camera afterwards would invalidate the arithmetic."),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the scoreboard</h2><span class="fam">6 predictions &middot; 3 hit &middot; 14 designed nulls &middot; 14 held</span><span class="chip">75 of 75 since wave 14</span></div>
    <p class="thesis">Six of the values in this wave were not values. They were the axis, listed as one of its own members.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank among non-null pairs, within the context each prediction names. order_pair predicted its own null, which is rank #1 by construction — what is scored there is whether the null held.</p></div>
    <p class="body"><b>The six.</b> <em>reciprocal</em> and <em>together</em> in order's family,
    <em>flip</em> and <em>commute</em> in construction's, and <em>cycle</em> twice in posture's.
    Each is a union of the other rungs wearing a peer's name, and one of them is a shipped default.
    This programme has a rule against putting an all-rungs value inside an axis &mdash; it cost
    wave 13 a whole sweep, because the union's bounding box frames every single rung as a speck.
    The rule was written for syntheses. Nobody had checked the corpus for it, and it is there six
    times in six families.</p>
    <p class="body"><b>And the gate had the same fault as everything else.</b> Reading grid2d to
    decide which of its twelve values it could honestly implement, algorithm_menu found a
    thirteenth: DISCO, with a cartridge and a factory branch, hidden from the deriver by a comment
    containing a comma. The registry declared exactly the twelve the deriver found, so declaration
    matched derivation and the gate reported ok &mdash; <em>on a wrong declaration</em>. A gate can
    only catch a disagreement between a declaration and its deriver; when both are wrong the same
    way it certifies the error. That is now the seventh instrument in this programme found to be
    confidently reporting a fact about itself, after the sweep, the critic, the scorer, the framing
    solver, the interaction probe and the harmony meter.</p>
    <p class="tail"><b>This is the last wave at this bar.</b> Five axes with three or more unused
    members remained when it was chosen; all five are here, with the strongest two-member pair.
    What is left is fifty-three axes with exactly two members &mdash; still a family, still the
    minimum for a comparison, but a different and thinner kind of evidence, and worth saying before
    anyone reads a wave 21 as though it were the same standard. Also open and not repaired here:
    construction_pair's axis is WEAK by construction, posture_bench's and construction_pair's second
    axes are LOCAL, and none has been tried from a second standpoint.</p>
  </section>

<footer><span>wave 20</span><span>6 syntheses &middot; 12 axes &middot; 3 of 6 hit &middot; 14 of 14 nulls held &middot; six agents, one orchestrator</span>
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
