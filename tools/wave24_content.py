# wave24_content.py — the prose of the wave-24 gallery, imported by build_wave_gallery.py.
# The first wave chosen by CURRICULUM POSITION rather than family size: the spine walked backwards.

TITLE = "Wave 24 &mdash; a gate on words is blind to a split in meaning"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 24 &middot; 18 August 2026 &middot; six agents, one orchestrator &middot; the spine, walked backwards</p>
  <h1>The corpus repaired an artifact,<br>and the gate did not notice its family split.</h1>
  <p>Earlier waves chose families by how many members shared an axis word. This one walks the
  <b>curriculum spine from the back</b> &mdash; sequence 24 first &mdash; so these six are not the
  most populous left but the ones the curriculum arrives at LAST, in the sequences that land the
  thesis. The axis words there turn out to be the thesis vocabulary itself: <em>outside</em>,
  <em>seam</em>, <em>presence</em>, <em>refusal</em>. And three of the six shared a word and
  <b>not one value</b> &mdash; a shape no previous wave had, where the builder had to decide
  whether the family was a family at all. <b>All three were.</b></p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 92 frames &middot; 12 axes, 10 bite + 1 local + 1 weak &middot; 6 predictions, 5 hit &middot; 10 designed nulls, 10 held &middot; 104 of 104 since wave 14 &middot; 0 clipped, 0 blank</span></div>
"""

SECTIONS = [
 ("outside_hall", "outside &middot; sequence 24 &middot; the last thing a student walks",
  "One file was repaired. Its sibling was not. Both still declare the same five words.",
  """<p class="body">Gödel's undecidable statement and Russell's paradox, and the vocabulary has
  <b>one implementation</b>: <code>russell_set_box.gd:17</code> preloads the plaque and routes every
  value through its <code>normalise_outside</code>, <code>outside_measure</code>,
  <code>outside_cage</code>, <code>outside_field</code>. Four of the five words do the same work in
  both files.</p>
  <p class="body">The fifth does not, and the reason is documented in the source.
  <code>godel_statement_plaque.gd:69-81</code> records a repair dated 2026-07-31 that replaced its
  cracked plate with <b>two intact plates certifying each other</b>, on the argument that damage is
  the popular misreading of 1931 &mdash; incompleteness is a theorem, not a wound. The same comment
  then states that nothing was renamed, &ldquo;so russell_set_box.gd's word list is untouched and
  the pair still speak one vocabulary.&rdquo; The word list is untouched. <b>The vocabulary is
  not.</b> <code>russell_set_box.gd:228-267</code> still builds the crack &mdash; halves at 5.0 and
  3.5 degrees, three shards.</p>
  <p class="body">And the repair was <em>right</em>. The box's own truth line says naive set theory
  is <b>inconsistent</b>; the plaque's says incompleteness is a <b>theorem</b>. Russell's outside is
  a hole that got fenced off &mdash; change the rules and the object is not formable. Gödel's cannot
  be fenced: patch the system and a new one appears. So the repair did not render one value better,
  it asked a <em>second question</em> &mdash; and a second question is a second axis. The bench
  declares it: <span class="tok">remedy</span> (none &middot; fence &middot; reissue), and it is the
  loudest axis in the wave at 18.69% of frame.</p>
  <p class="body"><b>The transferable finding: <code>check_dna_declarations.py</code> cannot see
  this.</b> It compares declared words against code words, and both files still declare the same
  five. A gate on WORDS is blind to a split in MEANING. That is the seventh instrument in this
  programme found to be confidently reporting a fact about itself &mdash; and unlike the others it
  is not a bug, it is the limit of what a word-gate can be.</p>""",
  [({"outside": "quotation", "remedy": "none"}, "quotation &middot; none"),
   ({"outside": "breach", "remedy": "none"}, "breach &middot; the crack the box still builds"),
   ({"outside": "breach", "remedy": "reissue"}, "breach &middot; reissue &mdash; two plates certifying each other"),
   ({"outside": "habitat", "remedy": "fence"}, "habitat &middot; fence &mdash; the outside made liveable")],
  "Prediction #1 of 9 at <b>0.03%</b> &mdash; <em>quotation</em> against <em>margin</em> under "
  "<em>fence</em>, the tightest hit in the wave. One null held at 0.00%: <em>margin</em> and "
  "<em>habitat</em> under <em>fence</em> are byte-identical, and the builder probed that it is the "
  "<em>only</em> identical pair of the fifteen. Two corrections it made by measuring rather than "
  "assuming: the sweep merges WORLD-space AABBs, so the artifact's internal 0.62 yaw inflates the "
  "radius by 1.3949 and the framing is 0.41 rather than the 0.58 first computed; and node "
  "<code>_ready()</code> is not flushed during <code>SceneTree._initialize()</code>, so its first "
  "probe reported 0 meshes in all 15 cells and 105 identical pairs &mdash; a perfect false-dead "
  "verdict about the harness, caught before it was believed.",),

 ("bottleneck_cut", "bottleneck &middot; sequence 21 &middot; the artifact cannot know whether it succeeded",
  "It counts its successes against the best answer it has found so far.",
  """<p class="body">Karger's randomised min-cut and max-flow/min-cut &mdash; the same theorem from
  opposite ends, or so the brief supposed. The code says otherwise. In one file
  <span class="tok">bottleneck</span> is a <b>capacity</b> axis: <code>networkflow3d.gd:282-301</code>
  builds <em>braid</em> by overwriting capacities and keeping the same edge set, and says so in its
  own comment. In the other it is a <b>topology</b> axis: <code>karger_algorithm.gd:291-297</code>
  builds <em>braid</em> as a near-complete 24-edge graph, and that file contains no capacity
  anywhere &mdash; Karger's cut is a <em>count</em>. Only <em>severed</em> names one object in both.
  A shared word list, not a shared vocabulary.</p>
  <p class="body"><b>And then the statistic.</b> <code>karger_algorithm.gd:118</code> declares
  <code>_success_count</code> as &ldquo;runs that found the actual min cut&rdquo;. Line 460-469
  increments it whenever a run matches <code>_best_global_cut</code> &mdash; which is the best found
  <em>so far</em>, initialised to 999 at <code>:229</code>. So the first round always scores a
  success against a bar it set itself. Then <code>:887-895</code> compares that rate against the
  theoretical <code>2/(n(n&minus;1))</code> as though the two were the same quantity.
  <b>The artifact cannot know whether it has found the minimum</b>, and its success rate is a
  measurement of its own history.</p>
  <p class="body">Sharper still, and the thing the bench photographs: Karger minimises
  <b>cardinality</b>, so on a weighted network it returns a correct answer to the wrong question. At
  <em>mixed</em> against <em>capacity</em> it returns <b>18</b> where the true minimum is <b>9</b>
  &mdash; exactly twice &mdash; and the two blades stand 0.315 m apart on a 0.560 m field. The good
  news, checked rather than assumed: it IS seeded (<code>GRAPH_SEED = 20260729</code>, the same
  constant as its sibling), so every sweep of it has photographed the same graph.</p>""",
  [({"bottleneck": "severed", "against": "capacity"}, "severed &middot; capacity"),
   ({"bottleneck": "throat", "against": "capacity"}, "throat &middot; a width"),
   ({"bottleneck": "throat", "against": "flow"}, "throat &middot; flow"),
   ({"bottleneck": "mixed", "against": "capacity"}, "mixed &middot; 18 against a true minimum of 9")],
  "Two nulls, two held at 0.00%, and both are <b>identities by theorem</b> rather than by "
  "construction &mdash; a stronger kind: at <em>braid</em> the capacities are equal, so counting and "
  "summing are one optimisation; at <em>severed</em> the max flow is 0, so there is nothing to draw. "
  "Prediction #1 of 6. <b>But its two-sided claim failed</b>: predicted 0.0247% ±20%, measured "
  "0.22% &mdash; 8.9&times; over. The builder named a DOWNWARD caveat (a 2.1 px band a "
  "centre-sampled rasteriser under-reads) and the error went the other way. First two-sided "
  "prediction in the programme not to hold, and the reason `against` reads WEAK at 1.02% of frame "
  "while its axis is real.",),

 ("refusal_booth", "refusal &middot; sequence 22 &middot; opposite ends of one ladder, both shipped",
  "Two artifacts, four rungs each, no word in common — and their defaults sit at opposite ends.",
  """<p class="body">One of the three families in this wave that share a word and not one value:
  <em>void &middot; rim &middot; echo &middot; ghost &middot; none</em> against
  <em>blank &middot; regress &middot; oracle &middot; spin &middot; honest</em>. The builder had to
  decide whether that is a family at all, and the answer is yes &mdash; both files say in their own
  headers that the axis is a <b>disclosure ladder sitting downstream of a test whose answer never
  moves</b>. The rungs then align four for four: void&harr;blank (both authors write the refusal
  cannot be told from a crash), rim&harr;regress (displaced one step, closes nothing),
  echo&harr;oracle (returned in the accepting ink, unsigned), ghost&harr;honest (both use
  &ldquo;only&rdquo; for the same claim). The two leftovers are symmetric: <em>none</em> is
  off-ladder because no refusal happened, <em>spin</em> because no answer is reached.</p>
  <p class="body"><b>And the two members ship opposite ends of that ladder as their defaults.</b>
  <code>GaussianPaintSplatter.gd:102</code> defaults to <em>void</em> &mdash; its header calls this
  &ldquo;what all eight rooms ship today&rdquo;. <code>rice_verifier_booth.gd:59</code> defaults to
  <em>honest</em>. Every live placement of one <em>conceals</em> a decision; every placement of the
  other <em>displays</em> one. Nothing noticed, because they share no value to disagree about
  &mdash; the same blindness as outside_hall's, arriving from the other direction.</p>
  <p class="body">Two more from the same read: the splatter records that its hue draw had to be
  hoisted above the refusal test or the axis measures a recolour rather than a refusal (inherited by
  this bench); and <code>:505-512</code> admits the axis is <b>unreachable from any map token</b>,
  because the script sits on a <code>PaintSplatter</code> child rather than the <code>.tscn</code>
  root.</p>""",
  [({"refusal": "erased", "venue": "counter"}, "erased &middot; counter"),
   ({"refusal": "displaced", "venue": "counter"}, "displaced &middot; closes nothing"),
   ({"refusal": "marked", "venue": "witness"}, "marked &middot; witness"),
   ({"refusal": "tallied", "venue": "plate"}, "tallied &middot; the refusal counted")],
  "<b>The wave's one miss</b>, at #3 of 10 &mdash; <em>erased</em> against <em>tallied</em> was "
  "predicted closest and <em>erased</em> against <em>marked</em> came in at 1.26%. Two nulls held at "
  "0.00%: <em>erased</em> renders identically across three venues, because a refusal that conceals "
  "itself conceals itself everywhere. <b>spin</b> was declined and the reason is exact &mdash; a "
  "still of a non-halting machine is a still of a halted one, and the source's own "
  "<code>rotor_frozen</code> fixture concedes it. So was a <code>warrant</code> axis: whether a "
  "refusal is <em>justified</em> is not visible in a photograph, which is the dark spot here and the "
  "reason the two refusals were confusable in the first place.",),

 ("presence_pipe", "presence &middot; sequence 23 &middot; a scalar with no zero, against a truth table",
  "Can a thing be partly here? One artifact can only say yes; the other can only say yes or no.",
  """<p class="body">The second zero-overlap family, and the evidence that it IS a family is the
  <b>type</b> of each axis rather than the meaning of its words.
  <code>dark_sphere.gd:173-179</code> is a multiplier table: five rows, ten float columns, one
  builder, and <b>no zero anywhere</b> &mdash; <em>hush</em> is radius 0.55 and <em>eclipse</em> is
  radius 1.50, the largest row in the file. It is a scalar that <em>cannot express absence</em>.
  <code>magritte_pipe.gd:63-64</code> is a complete <b>2-bit truth table</b>:
  <code>PRESENCE_HAS_PIPE</code> and <code>PRESENCE_HAS_WORDS</code> give (T,T), (T,F), (F,T) and,
  as <em>empty_frame</em>, (F,F). A bit vector with no degree. One question &mdash; can a thing be
  partly here? &mdash; answered from the two ends.</p>
  <p class="body">The brief's suspicion that one member measures presence as a relation to an
  observer is <b>wrong</b>, and the code is blunt about it: nothing in dark_sphere.gd reads a viewer.
  No camera, no proximity, no Area3D. The observer appears exactly once, in prose, in a note that
  itself says the value &ldquo;is not a quantity of presence.&rdquo;</p>
  <p class="body">Two things the builder settled by reading rather than by analogy.
  <em>eclipse</em> and <em>empty_frame</em> are NOT the same move: eclipse is the largest body plus
  a <b>negative OmniLight</b> &mdash; absence by subtraction; empty_frame builds frame and canvas
  unconditionally and simply never calls <code>_create_pipe</code> &mdash; absence by non-arrival.
  And <em>picture_of_picture</em> IS an all-rungs value, arithmetic in the registry: five values are
  four cells plus a regress standing on one of them. That is the tenth all-rungs value this
  programme has found in the corpus, and the bench adds none.</p>""",
  [({"standing": "amount", "warrant": "frame"}, "amount &middot; a degree"),
   ({"standing": "denial", "warrant": "frame"}, "denial &middot; the closest pair"),
   ({"standing": "absence", "warrant": "frame"}, "absence &middot; frame &mdash; the null"),
   ({"standing": "likeness", "warrant": "room"}, "likeness &middot; room")],
  "Prediction #1 of 10 at 0.23%, declared in luma. One null held at 0.00%: <em>absence</em> is "
  "identical under <em>frame</em> and <em>room</em> by construction, because a thing that is not "
  "there is not there in either warrant. <b>All text was declined</b> &mdash; magritte's whole "
  "subject is words under an image, and the caption is rebuilt here as its own bounding box in its "
  "own ink rather than as letters, because text at 760&times;760 is unreadable and nearly invisible "
  "to a pixel difference. Twelve declines in total, each with arithmetic.",),

 ("occupancy_cloud", "occupancy &middot; sequence 23 &middot; two coordinates of one question",
  "One member varies how much is covered. The other varies where it sits. Neither varies both.",
  """<p class="body">The third zero-overlap family, and it resolves cleanly: occupancy of a region by
  a set has two independent parts &mdash; <b>EXTENT</b> (how much is covered) and <b>SITE</b> (where
  in the region it sits). <code>possibility_space_cloud</code> varies extent only:
  <em>pinched</em> is a 0.05 m knot, <em>packed</em> is clamped to a 0.322 m shell.
  <code>bifurcation_walkway</code> varies site only &mdash; <code>_dot_position</code> keeps the same
  4800 dots, the same colours and the same r window, and moves them onto a different submanifold.
  Zero overlap, and that is exactly why.</p>
  <p class="body">The brief guessed the walkway's values were architectural mountings under another
  name, and the source refutes it before the builder did: its own <code>dna.kin</code> already
  rejects <em>support</em> and <em>admission</em> by name. But the extent question <b>is</b> on that
  artifact &mdash; under the name <span class="tok">regime</span>, and the two are independent in
  code. Same subject, different halves, and one member quietly carries both under two words.</p>
  <p class="body"><b>The finding: the walkway sorts its attractor by iteration parity.</b>
  <code>_dot_position</code> picks which mural wall a dot lands on from
  <code>side = -1.0; if (j % 2) == 0: side = 1.0</code> &mdash; and in every period-2 window the
  orbit alternates on exactly that parity. So at <em>mural</em> the upper branch lands entirely on
  one wall and the lower branch entirely on the other: the artifact splits a bifurcation diagram
  into two half-diagrams by an accident of loop index. It compiles, it declares correctly, it
  renders plausibly.</p>""",
  [({"occupancy": "forked", "site": "pressed"}, "forked &middot; pressed"),
   ({"occupancy": "flooded", "site": "pressed"}, "flooded &middot; extent, filled"),
   ({"occupancy": "hairline", "site": "bedded"}, "hairline &middot; bedded"),
   ({"occupancy": "hairline", "site": "lofted"}, "hairline &middot; lofted &mdash; the null")],
  "Two nulls, two held at 0.00%: under <em>lofted</em> the extent values collapse, because a set "
  "lifted clear of its region has no extent within it to show. Prediction #1 of 6 at 0.59%. The "
  "scatter was declined on both members &mdash; it <em>fakes</em> occupancy, drawing 40 identical "
  "values as a 1.2 m cloud &mdash; and so was the parity trick, which would have reproduced a bug "
  "as a value.",),

 ("seam_stair", "seam &middot; sequence 24 &middot; one seam is a standpoint, the other is a sum",
  "Escher's impossibility is arithmetic, and reads the same from every angle.",
  """<p class="body">Same story at code level as outside_hall: <code>escher_staircase.gd:165</code>
  preloads <code>florensky_sphere.gd</code> and parses its own axis through the sphere's static
  <code>normalise_seam</code>. Five words, one implementation, one file.</p>
  <p class="body">But the brief's reason was half wrong, and the correction is the section.
  Florensky's seam <em>does</em> live in the line of sight &mdash; <code>SEAM_OPEN_MID_DEG :=
  58.0</code> is justified in the source by arithmetic on the sweep camera's own bearing of
  54.5&deg;, which is a source artifact reasoning explicitly about the rig that will photograph it.
  Escher's does not. <code>:276</code> closes the loop with a smooth ramp, and all five values route
  through <code>_seam_step_y</code> to a monotone run or a level ring. <b>Every one is buildable in
  3-space.</b> The impossibility is <em>arithmetic</em> &mdash; a rule that says the ring closes
  against geometry that shows it does not &mdash; and it reads identically from every angle. One
  seam is a fact about where you stand; the other is a fact about a sum.</p>
  <p class="body">Which makes the shipped default absurd in a way worth stating plainly:
  <code>escher_staircase.gd:40</code> ships <code>rotate_view: bool = true</code> and spins the
  figure every frame. <b>The one artifact in the corpus whose genre requires a privileged viewpoint
  is the one that refuses to hold still</b> &mdash; and there is no forced-perspective trick under
  the rotation for the spinning to protect.</p>""",
  [({"seam": "none", "facing": "lens"}, "none &middot; lens &mdash; the null"),
   ({"seam": "hairline", "facing": "lens"}, "hairline &middot; toward the viewer"),
   ({"seam": "gap", "facing": "away"}, "gap &middot; away"),
   ({"seam": "scaffold", "facing": "away"}, "scaffold &middot; the closest pair")],
  "Two nulls, two held at 0.00%, and they are the argument: <code>_phase()</code> is the only reader "
  "of <em>facing</em> and ignores it entirely for <em>none</em> and <em>field</em> &mdash; a "
  "contradiction put nowhere, or everywhere, has no place to be turned toward anybody. Prediction "
  "#1 of 10 at 1.12%, declared in luma because <code>changed_pct</code> cannot rank this column: "
  "emissive cyan swapped for unlit brass moves nearly the same pixel SET while magnitude falls "
  "3.0&times; and count only 2.43&times;. A camera-moving standpoint axis was declined for the "
  "reason that matters here &mdash; the sweep shoots from one fixed camera, so an axis that only "
  "moves the camera renders identical frames.",),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the scoreboard</h2><span class="fam">6 predictions &middot; 5 hit &middot; 10 designed nulls &middot; 10 held</span><span class="chip">104 of 104 since wave 14</span></div>
    <p class="thesis">Three families shared a word and not one value. All three were families.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank among non-null pairs, within the row each prediction names, on the metric it declares. Five of six declared a magnitude metric — three could not have been ranked without it.</p></div>
    <p class="body"><b>Chosen by the curriculum, not by me.</b> This wave walked the spine backwards
    from sequence 24, and 812 artifacts are reachable from spine maps with only 15 never-worked
    families among them. The deepest six were these. That the axis words at the back of the spine
    are the thesis vocabulary — <em>outside</em>, <em>seam</em>, <em>presence</em>,
    <em>refusal</em> — is not something the selection arranged; it is what the curriculum arrives
    at.</p>
    <p class="body"><b>And a word-gate has a ceiling.</b> outside_hall's finding is the one to carry
    forward: a documented, correct repair to one member changed what a value MEANS while leaving
    every declared word intact, so <code>check_dna_declarations.py</code> reads green on a family
    that has quietly split in two. refusal_booth is the same blindness from the other side — two
    members shipping opposite ends of one ladder as their defaults, invisible precisely because
    they share no value to disagree about. The gate compares words to words. Nothing in this
    programme yet compares a meaning to a meaning, and after 24 waves that is the most useful thing
    it has found out about itself.</p>
    <p class="tail"><b>Open.</b> bottleneck_cut's two-sided prediction failed at 8.9&times; over —
    the first in the programme not to hold, and its `against` axis reads WEAK at 1.02% of frame
    while being real by construction. karger_algorithm's success statistic measures its own history
    and is filed for repair, not fixed here. GaussianPaintSplatter's axis is unreachable from any
    map token because its script sits on a child rather than the scene root. russell_set_box still
    builds a crack its sibling repaired away — deliberately unrepaired, because erasing it would
    delete the finding. And none of these twelve axes has been seen from a second standpoint.</p>
  </section>

<footer><span>wave 24</span><span>6 syntheses &middot; 12 axes &middot; 5 of 6 hit &middot; 10 of 10 nulls held &middot; the spine, walked backwards</span>
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
