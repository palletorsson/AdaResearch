# wave21_content.py — the prose of the wave-21 gallery, imported by build_wave_gallery.py.
# The first wave at the two-member bar. H1 and masthead written after the sweep was scored.

TITLE = "Wave 21 &mdash; the fault is on the default"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 21 &middot; 17 August 2026 &middot; six agents, one orchestrator</p>
  <h1>Six families of two.<br>Four of them break on the default.</h1>
  <p>Every axis word with three or more never-worked members is now spent. What remains is
  twenty-eight words declared by exactly two artifacts, and with two members you cannot
  triangulate &mdash; so the question changes. <b>A two-member family is a hypothesis that these
  two artifacts are about the same thing</b>, and each synthesis here tests it. Two came back yes,
  three partly, one flatly no. And in four of the six, the thing that was wrong was the value every
  shipped placement uses.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 88 frames &middot; 12 axes, 12 bite &mdash; 0 local, 0 weak, 0 inert &middot; 6 predictions, 5 hit &middot; 6 designed nulls tested, 6 held &middot; 3 correctly untested &middot; 0 clipped, 0 blank</span></div>
"""

SECTIONS = [
 ("basin_field", "basin &middot; gradient descent and simulated annealing &middot; and one value is inverted",
  "Three of the five values are the same expression twice. The fourth is the same result from different code. The fifth is upside down.",
  """<p class="body">A shared vocabulary is honest when the members mean the same thing by it, and
  for most of <span class="tok">basin</span> they do &mdash; literally. <b>bowl</b> is the same
  expression in both files; <b>valley</b> is the same Rosenbrock term for term; <b>scarp</b> is
  <em>different code with an identical result</em>, because annealing's
  <code>SCARP_RATIO = 3.0/32.0</code> evaluates to descent's literal <code>3.0</code> exactly at
  domain 4. Two authors, one number, arrived at twice.</p>
  <p class="body">Then <b>plateau</b>. Gradient descent's is a flat disc inside a high rim &mdash;
  flat in the middle, <b>one</b> minimum. Annealing's is Ackley: a corrugated plain with a needle
  at the centre and <b>49</b> minima. Under one word, one file draws the easiest landscape it has
  and the other draws the hardest. Ackley is more <em>plural</em> than <b>plural</b> is: annealing's
  Himmelblau has four.</p>
  <p class="body">And the axis never reaches the thing it appears to be about.
  <code>_step_optimizers()</code> and <code>_perform_annealing_step()</code> contain no reference to
  it; both redraw terrain under an unchanged solver. What does differ is the standpoint: descent
  hand-picks a start and a y-scale per value, annealing picks a random start and normalises. One
  member <em>composes</em> each basin, the other <em>measures</em> it.</p>""",
  [({"basin": "bowl", "reading": "relief"}, "bowl &middot; relief"),
   ({"basin": "plateau", "reading": "relief"}, "plateau &middot; descent's flat disc &mdash; one minimum"),
   ({"basin": "plural", "reading": "census"}, "plural &middot; census &mdash; the minima counted"),
   ({"basin": "bowl", "reading": "residue"}, "bowl &middot; residue &mdash; where three values agree")],
  "Two nulls, two held at <b>0.00%</b>, and they are the finding rather than a check on it: three "
  "of the five values render the <em>residue</em> reading identically, pre-registered as such. "
  "Prediction #1 of 10 at 4.21%. <b>The pair's OTHER shared axis is worse.</b> On "
  "<span class=\"tok\">evidence</span>, annealing keeps its offer lists only at <em>axiom</em> "
  "&mdash; the top of an accumulation ladder &mdash; while descent returns early for <em>axiom</em> "
  "alongside the null rung, drawing nothing. Same word, same values, the ordering reversed between "
  "members. <code>evidence_ladder</code> synthesised that word from twelve artifacts and neither of "
  "this pair is among them, so nobody had ever put these two side by side.",),

 ("macrostate_shelf", "macrostate &middot; and the number is not a function of the picture",
  "Only one member counts anything. Its count is sixteen decades wrong one way and twelve the other.",
  """<p class="body">A macrostate is an equivalence class of microstates, and the entire content of
  the idea is the multiplicity <b>W</b> &mdash; how many arrangements produce the same description.
  So the hypothesis had a sharp test: does either member ever compute one? <b>random_cubes</b> does
  not; its four values are arrangements wearing a class name. <b>microstate_counter</b> does, and
  prints <code>W ~ 10^55</code> and <code>S = k log W</code>.</p>
  <p class="body">But that number is a lookup table, and the table is not a function of the geometry
  beside it. <code>CELLS_BASE</code> holds <code>{uniform 24.0, corner 3.35, layered 6.8}</code>
  over 40 particles. The chamber it draws has a 0.5208&nbsp;m interior, a 0.20&nbsp;m confined
  octant, and two slabs of 0.12 &times; 0.57 &times; 0.57. Taking cells proportional to volume:</p>
  <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
  <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:5px 10px;color:var(--dim);font-weight:400">value</th><th style="text-align:right;padding:5px 10px;color:var(--dim);font-weight:400">the plate prints</th><th style="text-align:right;padding:5px 10px;color:var(--dim);font-weight:400">the geometry gives</th><th style="text-align:left;padding:5px 10px;color:var(--dim);font-weight:400">error</th></tr>
  <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">corner</td><td style="padding:5px 10px;text-align:right">10<sup>21</sup></td><td style="padding:5px 10px;text-align:right">10<sup>5.3</sup></td><td style="padding:5px 10px" class="bad">15.7 decades too generous</td></tr>
  <tr><td style="padding:5px 10px;color:var(--brass)">layered</td><td style="padding:5px 10px;text-align:right">10<sup>33</sup></td><td style="padding:5px 10px;text-align:right">10<sup>44.9</sup></td><td style="padding:5px 10px" class="bad">11.6 decades too stingy</td></tr>
  </table></div>
  <p class="body">Wrong in <b>opposite directions</b>, in the artifact named for the count. The
  table gives itself away in its own comment, which states its entries by their output
  (<em>24.0 &rarr; 10^55</em>) rather than deriving them. A number and a picture, asserted
  separately, sharing a frame. Two smaller things fall out of the same read: the sorted slabs at
  0.57&nbsp;m are wider than the 0.5208&nbsp;m interior and pass through the chamber walls, and
  <b>spilled</b> is <em>uniform</em> plus an addendum in <b>both</b> members &mdash; two more
  all-rungs values, and the table hands <em>spilled</em> uniform's base exactly.</p>""",
  [({"macrostate": "uniform", "reading": "specimen"}, "uniform &middot; one arrangement"),
   ({"macrostate": "corner", "reading": "specimen"}, "corner &middot; confined"),
   ({"macrostate": "corner", "reading": "ledger"}, "corner &middot; ledger &mdash; the count, and it is wrong"),
   ({"macrostate": "uniform", "reading": "asserted"}, "uniform &middot; asserted &mdash; the null")],
  "One null, held at <b>0.00%</b>: <em>uniform</em> and <em>spilled</em> in the <em>asserted</em> "
  "reading, because the table gives them the same base and the assertion is all that reading draws. "
  "Prediction #1 of 5 at 2.00%. The bench prints both the drawn multiplicity and the asserted one "
  "on the same shelf, which is the only way to photograph a disagreement between a number and a "
  "picture &mdash; and the sweep needed <code>--max=16</code>, because at the default of 9 the "
  "second column vanishes and the null goes with it.",),

 ("becoming_jar", "becoming &middot; a transcription, not a convergence",
  "The two members agree because one copied the other, character for character. It says so at line 26.",
  """<p class="body">Perfect vocabulary agreement is supposed to be the strong case. Here it is
  documentary: <code>dna_specimen.gd:26-27</code> records that the word and its four values were
  taken <em>character for character</em> from queer_morphology_specimen, five days earlier. A family
  that cannot disagree is not evidence about a vocabulary. The one place the copy slipped is the one
  place they diverge &mdash; at <b>cracked</b>, one file shortens the glass and builds an open rim,
  the other never touches the jar and only moves the lid, drops the fluid and raises the helix.
  Breached in one, merely opened in the other.</p>
  <p class="body">The ordered-stages reading holds and its usual explanation does not.
  <em>jarred &rarr; cracked &rarr; escaped</em> is monotone, and the nesting is literal &mdash;
  <b>escaped</b> calls the same <code>_lay_lid_down()</code> that <b>cracked</b> calls. But
  <b>clouded</b> is not a change in the medium: both files leave the fluid at full height and
  untouched. It changes the <em>occupant</em> and returns the container to stage zero. So
  <span class="tok">becoming</span> is a <b>product</b> &mdash; container
  {sealed, breached, absent} &times; occupant {single, dispersed} &mdash; with four of six cells
  built. Dispersed-and-breached, and dispersed-and-free, are things the word cannot currently say.
  The bench separates the two factors into readings so the missing cells are visible as gaps.</p>
  <p class="body"><b>And three of one member's four values have never rendered as designed.</b>
  <code>queer_morphology_specimen.gd:176-189</code> carries a fluid shader with two compile errors
  &mdash; <code>vec3()</code> given four components, <code>fmod()</code> given one argument &mdash;
  and the file's own comment states the consequence: three of the four values are defined against
  the fluid volume that noise drives, so all three have only ever been seen through the error
  material.</p>""",
  [({"becoming": "jarred", "reading": "container"}, "jarred &middot; sealed"),
   ({"becoming": "cracked", "reading": "container"}, "cracked &middot; breached"),
   ({"becoming": "clouded", "reading": "occupant"}, "clouded &middot; dispersed &mdash; and the jar is whole"),
   ({"becoming": "escaped", "reading": "occupant"}, "escaped &middot; absent")],
  "One null, held at <b>0.00%</b> in both luma and per-channel: <em>jarred</em> and <em>clouded</em> "
  "in the <em>container</em> reading are the same function called with the same argument, because "
  "clouded's whole change is on the other factor. That is the product structure proved by "
  "photograph. The prediction missed at #2 of 6 &mdash; <em>jarred</em> against <em>cracked</em> is "
  "closer, at 3.35%, because a lid lifted 0.09&nbsp;m is nine tenths of the helix's own pitch and "
  "reads as almost no movement at all.",),

 ("temperament_table", "consonance_theory &middot; the suspicion was wrong &middot; the default is not",
  "There is no tuning system in this family. There is one array that four values share, and a fifth path that skips it.",
  """<p class="body">The brief proposed that these four values were two questions &mdash; tuning
  systems (<em>ratio</em>, <em>flat</em>) against repertoires (<em>western</em>, <em>blues</em>)
  &mdash; and that they were therefore orthogonal. <b>The code destroys it.</b> Both members compute
  pitch with one unconditional <code>440 &middot; 2^((midi&minus;69)/12)</code> and neither consults
  the axis. All four values are judgement tables at one frozen tuning. The word is one honest
  question, and the split does not exist.</p>
  <p class="body">This family is also more honestly shared than most: harmonic_distance_table
  <b>preloads</b> chord_tension_spring's four tables rather than copying them, and its own comment
  explains why (&ldquo;shared vocabulary drifts into nine vocabularies&rdquo;). Which is exactly
  what makes the exception invisible. <code>_shared_for()</code> short-circuits at <code>:326</code>:</p>
  <pre class="code"><code>func _shared_for(interval_class: int) -&gt; int:
    if consonance_theory == "western":
        return int(SHARED_OVERTONES.get(interval_class, 0))   # this file's own dict
    var table: Array = _consonance_table(consonance_theory)   # the shared tables</code></pre>
  <p class="body"><code>_consonance_table()</code> <em>has</em> a correct western path &mdash; its
  <code>_:</code> fallback returns the shared <code>CONSONANCE</code> &mdash; and that branch is
  unreachable for the one value the family ships as its default. The two arrays are not close:
  pushed through the file's own inversion rule, the perfect fourth scores <b>14</b> in one and
  <b>3</b> in the other, and the <code>shared &lt; 2</code> gate would draw all 66 pairs instead of
  36. Second finding: that member's two axes are not orthogonal &mdash; consonance_theory moves
  nodes under exactly one of six layout values, an undeclared conditional axis.</p>""",
  [({"consonance_theory": "western", "interval_space": "tempered"}, "western &middot; tempered &mdash; the shipped default"),
   ({"consonance_theory": "blues", "interval_space": "tempered"}, "blues &middot; the blue notes rewritten"),
   ({"consonance_theory": "ratio", "interval_space": "lattice"}, "ratio &middot; lattice &mdash; 3- and 5-exponents"),
   ({"consonance_theory": "ratio", "interval_space": "comma"}, "ratio &middot; comma &mdash; the gap that will not close")],
  "Prediction #1 of 6 at 3.03%, and counter-intuitively so: <em>western</em> and <em>blues</em> "
  "disagree most in magnitude yet are bit-identical at <b>five</b> of twelve stations &mdash; "
  "unison, major third, fourth, fifth, major seventh. Blues rewrites the blue notes and leaves the "
  "structural frame alone. <b>Its three nulls are the wave's other instrument finding</b> and are "
  "reported below rather than here: all three are conditioned on <code>comma_gain</code>, which "
  "<code>dna.fixture</code> pins, so the sweep never rendered the frames they are about. They are "
  "UNTESTED &mdash; not held, and emphatically not broken.",),

 ("packing_court", "packing &middot; a generative parameter and a rendering parameter, under one word",
  "One member reads the value inside the recursion. The other reads it once, after every leaf is already placed.",
  """<p class="body">Identical word, identical values, identical order &mdash; and consumed at
  different depths of the construction. In the circle packing the value is the <b>similitude
  ratio</b>, read <em>inside</em> <code>_recursive_build</code>, so each value is a different
  attractor with a different dimension (2.714 &middot; 2.000 &middot; 1.321 &middot; 1.000). In the
  pyramid it is read <b>once, after</b> every leaf is placed: lattice, census and dimension are
  identical across all four, and only the ink changes. They agree at exactly one rung, where
  <code>2R(1&minus;2r)</code> and <code>(1&minus;fill)&middot;L</code> both cross zero at
  <em>contact</em>.</p>
  <p class="body">Both of the brief's suspicions were wrong, and instructively. Neither member
  removes anything &mdash; six purely additive calls, no complement anywhere, and the source argues
  this itself, refusing cantor_set's word <em>removal</em>. And <b>dust</b> is fully reachable for
  the pyramid, stripping 97.8% of drawn volume, precisely <em>because</em> packing is not a
  dimension knob there.</p>
  <p class="body"><b>And the pyramid is not a Sierpi&nacute;ski pyramid.</b> Under a comment reading
  <code># 5 sub-pyramids</code>, <code>_recursive_build</code> makes <b>six</b> calls: an orphaned
  top at <code>:109</code>, left behind while the author reasoned about offsets in sixty lines of
  comments, plus the real top at <code>:174</code> and four bases. Six children, not five: 1296
  leaves at the shipped depth rather than 625, two tops at different heights, and a dimension of
  log6/log2 = <b>2.585</b> instead of 2.322. <b>The proof was already in the repository</b> &mdash;
  the registry's own <code>measurements.aabb_size</code> is <code>[8.5, 12.25, 8.5]</code> with
  <code>aabb_center.y = 1.88</code>, measured 2026-04-29. A correct pyramid on an 8.5 base is
  neither 12.25 tall nor offset upward. A recorded measurement had been contradicting the geometry
  for four months in a field nobody reads.</p>""",
  [({"packing": "fused", "reading": "kept"}, "fused &middot; kept"),
   ({"packing": "open", "reading": "kept"}, "open &middot; kept"),
   ({"packing": "open", "reading": "gap"}, "open &middot; gap &mdash; the holes drawn as solids"),
   ({"packing": "dust", "reading": "web"}, "dust &middot; web &mdash; the contact graph")],
  "One null, held at <b>0.00%</b>: <em>fused</em> against <em>contact</em> in the <em>gap</em> "
  "reading, where both benches draw nothing, because at contact the gap has just closed to zero and "
  "at fused there was never one. Prediction #1 of 6 at 0.90%. The six-child build and the "
  "off-by-two lattice were <b>declined</b> rather than reproduced &mdash; a court whose "
  "<em>contact</em> is a 4:1 overlap photographs a bug, not a word &mdash; and are filed as a repair "
  "task instead.",),

 ("ground_layer", "priming &middot; one script, two tokens &middot; and a prediction that did not under-shoot",
  "A family that cannot disagree is not evidence about a vocabulary. It is one reading counted twice.",
  """<p class="body">ball_painting_demo is a canvas with thirty grabbable pigment balls;
  drawing_paper is a sheet with a pen. <b>Both run <code>paper_draw_surface.gd</code></b> and
  nothing else supplies their visible body &mdash; one script under two registry names, this
  corpus's most common hidden family, found here for the <b>eighth</b> time. The registry already
  knew, and predicted the two &ldquo;should MEASURE ALIKE&rdquo;. What it does not say is that a
  family which <em>cannot</em> disagree is not evidence about a vocabulary at all. The same entry
  also contradicts itself: drawing_paper carries a <code>dna.axes.priming</code> block <b>and</b> a
  note saying the axis cannot be declared without breaking the gate, because its scene instantiates
  gitignored addon scripts.</p>
  <p class="body">A ground is not a background colour. Bole is the red clay laid under gold leaf, to
  be burnished through and warm it from beneath; verdaccio is the green earth under flesh, chosen
  because green neutralises the pink laid over it. So the axis only means anything if something is
  drawn on top &mdash; hence a second axis of <em>handling</em>: bare, glaze, body, sgraffito. What
  of the ground survives into the mark.</p>
  <p class="body">Two instrument decisions are worth stating because they change what the numbers
  are. The painted layers are <b>unshaded</b>, so a measured difference between two grounds is not
  partly a fact about the key light; and the glaze is <b>computed, not alpha-blended</b> &mdash;
  <code>_glazed()</code> converts to linear, multiplies, converts back, the same arithmetic the
  renderer uses. Together those make the prediction exact rather than approximate, which is the
  first time in this programme that has been true.</p>""",
  [({"priming": "bole", "handling": "bare"}, "bole &middot; bare &mdash; the ground alone"),
   ({"priming": "bole", "handling": "glaze"}, "bole &middot; glazed &mdash; warmed from beneath"),
   ({"priming": "verdaccio", "handling": "body"}, "verdaccio &middot; body &mdash; the ground hidden"),
   ({"priming": "verdaccio", "handling": "sgraffito"}, "verdaccio &middot; scraped back through")],
  "One null, held at <b>0.00%</b> to the byte: over <em>white</em>, glaze and body are the same "
  "image, because multiplying by linear white is the identity and <code>_glazed()</code> returns "
  "the mark tint unchanged. <b>Prediction #1 of 6 &mdash; predicted 1.797%, measured 1.919%, a "
  "factor of 1.07.</b> Every geometry prediction in this programme has under-shot by 1.5&times; to "
  "6.7&times;, because a paper rasteriser has no shadows or antialiasing; this one had nothing to "
  "miss. But reading it took a scorer fix, described below: on the count metric all six pairs "
  "measure 12.994% and the prediction ranked fifth of six.",),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the scoreboard</h2><span class="fam">6 predictions &middot; 5 hit &middot; 6 nulls tested &middot; 6 held &middot; 3 untested</span><span class="chip">81 of 81 since wave 14</span></div>
    <p class="thesis">Four of six faults sit on the value every shipped placement uses.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank among non-null pairs, within the context each prediction names, on the metric it declares.</p></div>
    <p class="body"><b>Every axis bites.</b> Twelve of twelve, no local, no weak, no inert &mdash;
    the first wave where that is true, and it is the two-member bar's one clear advantage: with a
    pair rather than a cohort, a builder reads both files completely and designs against what is
    actually there.</p>
    <p class="body"><b>The default is where the fault is.</b> temperament_table's
    <em>western</em> silently reads a different array, with the correct branch sitting beside it as
    dead code. macrostate_shelf's shipped table is sixteen decades out one way and twelve the other.
    becoming_jar's second source has rendered three of its four values through a shader that never
    compiled. packing_court's pyramid has recursed six times per level, under a comment saying five,
    since it was written. None of these is exotic; all four are the state an artifact is in when
    nobody has looked at it recently, and all four survived every gate this programme has, because
    a gate compares a declaration to its own deriver and both were right.</p>
    <p class="body"><b>Two instruments were repaired mid-wave, and both had been quietly lying.</b>
    First: <span class="tok">a null conditioned on a pinned parameter is UNTESTED, not broken.</span>
    The scorer drops fixture keys when matching a null, so a builder need not restate what the
    fixture pins &mdash; but temperament_table registered three nulls about <code>comma_gain</code>
    at 1.0, 0.0 and 40.0 while <code>dna.fixture</code> pins it at 5.0. Dropping the key rewrote
    each claim into one about gain 5.0 and then measured that. Two came back BROKEN at ~4.9%, which
    would have been the first null failures since wave 14. Both claims are true and neither frame
    was ever rendered.</p>
    <p class="body">Second: <span class="tok">a rank inherits its METRIC</span> &mdash; the third
    thing after its denominator and its pool. <code>changed_pct</code> COUNTS pixels differing past
    a threshold; it does not measure how much. On an axis that changes only colour inside fixed
    geometry the moving pixels are the same set for every pair, so the count is <b>constant</b>:
    ground_layer's six priming pairs all measured 12.994%, equal to three decimals, and the sort
    order put its prediction fifth. On the metric the prediction declared, the same six spread 1.9%
    to 8.7% and the predicted pair is first. The scorer now honours a declared magnitude metric and
    refuses to report a rank at all when the metric ties.</p>
    <p class="tail"><b>What is open.</b> Sierpi&nacute;ski's six-child recursion and its 4:1 leaf
    overlap are filed for repair, not fixed here &mdash; it is a shipped artifact with live
    placements. queer_morphology_specimen's broken shader is unrepaired. temperament_table's three
    nulls remain untested until something sweeps <code>comma_gain</code>. And none of wave 21's
    twelve axes has been looked at from a second standpoint, so every verdict on this page is a
    verdict from yaw 0.62.</p>
  </section>

<footer><span>wave 21</span><span>6 syntheses &middot; 12 axes &middot; 12 bite &middot; 5 of 6 hit &middot; 6 of 6 nulls held &middot; six agents, one orchestrator</span>
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
