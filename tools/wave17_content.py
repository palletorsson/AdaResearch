# wave17_content.py — the prose of the wave-17 gallery, imported by build_wave_gallery.py.
# Klee's wave: point, line, plane. H1 and masthead written after the sweep was scored.

TITLE = "Wave 17 &mdash; the catenary that is a parabola"

MAST = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 17 &middot; 15 August 2026 &middot; six agents, one orchestrator</p>
  <h1>Point, line, plane &mdash;<br>and the line was lying about its law.</h1>
  <p>Klee's Pedagogical Sketchbook opens by saying a point in motion makes a line and a line in
  motion makes a plane: one operation, applied again. The corpus has families for all three, so
  this wave built them &mdash; and the families turned out to be keeping secrets. The artifact
  that offers you a <em>catenary</em> draws a parabola. The axis that offers four right triangles
  changes their size as well as their shape. The cube that shows you its <em>silhouette</em> has
  one frozen at a single camera. Twelve designed nulls were registered and twelve held, including
  one that my own scorer called broken because it asked the question in the wrong colour.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 91 frames &middot; 12 axes, 10 bite + 1 local + 1 conditional &middot; 6 predictions, 5 hit &middot; 12 designed nulls, 12 held</span></div>
"""

SECTIONS = [
 ("motion_primitive", "the spine &middot; rank is synthesis-introduced, and says so",
  "The primitives are not three kinds of thing. They are one sweep applied nought, once, twice, three times.",
  """<p class="body">No member of this corpus declares a dimension axis, so <span class="tok">rank</span>
  is invented here rather than derived &mdash; the builder states that plainly in the registry and in
  the script, because a synthesis-introduced axis and a derived one are not the same kind of claim.
  <b>point</b> is the generator at rest. <b>line</b> is one application of the sweep. <b>plane</b> is
  two. <b>body</b> is three. Every rung keeps its ancestors visible &mdash; cool for the mark, warm for
  the generator, so the same tube is cyan at <em>line</em> and amber at <em>plane</em> &mdash; which is
  what makes it one operation rather than four objects.</p>
  <p class="body"><b>translate</b>, <b>rotate</b> and <b>scale</b> are invariants_demo's own words.
  Its <em>project</em> was declined on its own comment ("a READ, not a transform"), <em>none</em>
  because it already <em>is</em> rank=point, and <em>shear</em> because it photographs as translate
  skewed. Rotate's third application travels 0.475&nbsp;m rather than a full 0.560, because a full
  step pushes the fan through the stage wall &mdash; declared, not hidden.</p>""",
  [({"rank": "point", "sweep": "translate"}, "point &middot; the generator at rest"),
   ({"rank": "line", "sweep": "translate"}, "line &middot; one sweep"),
   ({"rank": "plane", "sweep": "translate"}, "plane &middot; two"),
   ({"rank": "body", "sweep": "rotate"}, "body &middot; three, rotated")],
  "All three nulls held at <b>0.00%</b>: at <span class=\"tok\">rank=point</span> the sweep has been "
  "applied nought times, so it is never consulted and all three sweeps are one shared constant. And "
  "the prediction &mdash; point against line, the smallest step on the ladder &mdash; is #1 of 6 and "
  "also the closest non-null pair in the whole sheet, so it survives a change of pool and of "
  "denominator, which is the standard this programme now holds a closest-pair claim to."),

 ("line_slack", "slack &middot; line_builder_3d's five &middot; and one of them is misnamed",
  "Between two points there is not one line but as many as there are laws — and the corpus has no cosh in it.",
  """<p class="body"><b>chord</b> is the straight segment: no physics at all, a claim about space rather
  than matter. <b>catenary</b> should be what a chain does under gravity. <b>truss</b> is compression.
  <b>spline</b> is the draughtsman's tool. <b>festoon</b> is decoration.</p>
  <p class="body"><b>Except the catenary is a parabola.</b> All three family scripts compute
  <code>p.y -= factor*span*4.0*t*(1.0-t)</code> and there is no <code>cosh</code> anywhere in the
  family. A parabola is a cable under load uniform per <em>horizontal</em> metre &mdash; a suspension
  bridge deck &mdash; not a chain hanging under its own weight. The two differ by <b>1.7&nbsp;mm on a
  40&nbsp;mm run</b>, which is why nobody caught it and why the <b>load</b> reading exists: draw the
  force each curve is obeying and the misnaming becomes a picture instead of a word.</p>
  <p class="body">Two more corrections from the source. <em>chord</em> is not the only law-free value
  &mdash; the code calls spline "the draughtsman's answer, granted", curvature "DRAWN, not derived",
  so there are two blanks in the <b>load</b> reading, not one. And <em>festoon</em> is not a separate
  law at all: it is the same call at a different factor, 0.45 against 1.15, a sag dial wearing a
  law's name.</p>""",
  [({"slack": "chord", "reading": "line"}, "chord &middot; no law"),
   ({"slack": "catenary", "reading": "line"}, "catenary &middot; actually a parabola"),
   ({"slack": "truss", "reading": "load"}, "truss &middot; load &mdash; compression drawn"),
   ({"slack": "chord", "reading": "load"}, "chord &middot; load &mdash; nothing to draw")],
  "Four nulls, four held at <b>0.00%</b>. Two of them are the thesis: chord and truss are identical "
  "in <em>line</em> and <em>span</em> because the source builds truss as the chord plus a web, so the "
  "first line it emits IS the chord; and chord and spline are identical between <em>line</em> and "
  "<em>load</em> because a drawing has no load to show. The prediction &mdash; chord against spline, "
  "which never leaves the chord by more than 21&nbsp;mm, half the run's own thickness &mdash; is #1 of 9."),

 ("point_mark", "point &middot; 4 members &middot; a point has no extent, so every mark is a lie",
  "Everything you can see of a point is notation, and each notation imports a property the point does not have.",
  """<p class="body">A <b>bead</b> is a lie about size. A <b>crosshair</b> is a lie about direction. A
  <b>cage</b> is a lie about volume. A <b>halo</b> is a lie about influence. Klee's point is
  non-dimensional; a renderer cannot show nothing, so it must choose which false property to add, and
  <span class="tok">mark</span> is that choice rather than a style option.</p>
  <p class="body"><span class="tok">frame</span> is the other thing a point needs: alone it cannot be
  located, so <b>world</b>, <b>local</b>, <b>grid</b> and <b>mute</b> are what make it a position
  rather than a thing. In `point.gd` these are four captions; this bench draws the arithmetic they
  report rather than the text, which is what makes two of them collapse.</p>
  <p class="body">The corpus already contains the limit case and it is named as kin here:
  <span class="tok">grey_point</span>, built deliberately with no DNA axes and invisible to the sweep
  &mdash; Klee's non-dimensional origin "between becoming and passing", the one point in the corpus
  that refuses to be marked.</p>""",
  [({"mark": "bead", "frame": "world"}, "bead &middot; a lie about size"),
   ({"mark": "crosshair", "frame": "world"}, "crosshair &middot; about direction"),
   ({"mark": "cage", "frame": "grid"}, "cage &middot; about volume"),
   ({"mark": "halo", "frame": "world"}, "halo &middot; about influence")],
  "The brief's null was <b>refused</b>: <code>_build_mark</code> dispatches on <span class=\"tok\">mark"
  "</span> alone and never consults a frame, so forcing the collapse would have invented a dependency "
  "and published two subjectless tiles. The real nulls are elsewhere and both held at 0.00% &mdash; at "
  "<em>local</em> the origin IS the point, so the three legs are zero long and nothing is drawn, making "
  "local and mute identical for bead and for cage. The prediction ranked #2 of 6; the closest pair is "
  "bead against halo."),

 ("face_convention", "sidedness + convention &middot; parasol_triangle's complete truth table",
  "A triangle is three points; which side is its front is not in the three points.",
  """<p class="body">Front-ness comes from a convention &mdash; the winding order of the vertices, or a
  stored normal &mdash; and the renderer culls the other side. So a plane in a polygon renderer has a
  side only because somebody chose an order. The bench stands <b>four poles carrying the complete truth
  table</b>: pole 0 has order and normal agreeing outward, pole 3 has them agreeing inward, poles 1 and
  2 <em>disagree</em>. Then <b>none</b> keeps all four, <b>winding</b> keeps 0 and 1, <b>normal</b> keeps
  0 and 2, <b>both</b> keeps only 0. Same tally, different set &mdash; which is the finding, and it
  corrects parasol_triangle's own claim (gd:149) that normal and winding "encode the same fact": one is
  enforceable, the other is only believed.</p>
  <p class="body">This is not abstract. Earlier in this programme <span class="tok">frequency_shell</span>
  derived twenty icosahedron faces from mutual edge distance, which fixes the vertices and says nothing
  about order. Roughly half came out wound inward and were culled: v1 photographed as a handful of loose
  triangles, v4 as a ball with a bite taken out of it. The repair was one line comparing the cross
  product against the centroid, and it changed the measured convergence tenfold. <b>The convention is
  invisible until it is wrong.</b></p>""",
  [({"sidedness": "two_tone", "convention": "none"}, "two_tone &middot; none &mdash; all four stand"),
   ({"sidedness": "two_tone", "convention": "winding"}, "winding &middot; keeps 0 and 1"),
   ({"sidedness": "two_tone", "convention": "normal"}, "normal &middot; keeps 0 and 2"),
   ({"sidedness": "two_tone", "convention": "both"}, "both &middot; keeps only 0")],
  "<b>This null is the wave's instrument result.</b> The builder solved the front and back colours to "
  "equal luma under Rec.601 <em>and</em> Rec.709 (0.54430 / 0.54639), so reversing an unenforced "
  "convention should be grey-invisible. The scorer reported it <span class=\"bad\">BROKEN at 6.45%</span> "
  "&mdash; and was wrong: measured directly, luma changed <b>0.00%</b>, maximum difference 2 levels of "
  "255. What moved was hue, red and blue swapping at constant brightness: R 6.45%, G 0.00%, B 6.45%. A "
  "null registered against luma had been scored per-channel. score_wave now reads the metric out of the "
  "registration and prints both numbers."),

 ("edge_ground", "disclosure + separation &middot; two different things share the word line",
  "One line is a mark you could rub out. The other is where a solid ends relative to where you stand.",
  """<p class="body">cube_lines' vocabulary contains both and has never separated them. <b>frame</b> and
  <b>visible</b> are marks &mdash; drawn edges with a thickness. <b>silhouette</b> is a boundary: it is
  not on the object at all, it is where the object stops for a viewer. <b>plan</b> and <b>corner</b> are
  projections. <span class="tok">separation</span> then asks how far the drawn line sits from the surface
  it describes: <b>coincident</b> is coplanar and really z-fights, <b>hairline</b> is 6&nbsp;mm,
  <b>clear</b> 55&nbsp;mm, <b>inverted</b> &minus;6&nbsp;mm, inside the solid.</p>
  <p class="body"><b>The silhouette in the source is frozen.</b> cube_lines ships a hard-coded edge list
  that is correct only because the sweep camera stands in the +++ octant. The builder checked it against
  this programme's five standpoints: right at canonical and from-above, <em>wrong</em> at opposite,
  from-below and square-on. That makes <span class="tok">silhouette</span> the one axis value in the
  corpus where anamorphism is <em>correct behaviour</em> rather than a fault &mdash; a boundary is
  supposed to move when you do &mdash; and simultaneously a defect, because this one does not.</p>""",
  [({"disclosure": "frame", "separation": "clear"}, "frame &middot; a drawn mark"),
   ({"disclosure": "visible", "separation": "clear"}, "visible &middot; silhouette + near triad"),
   ({"disclosure": "silhouette", "separation": "clear"}, "silhouette &middot; a boundary"),
   ({"disclosure": "corner", "separation": "coincident"}, "corner &middot; coincident, z-fighting")],
  "Both nulls I suggested were <b>falsified before capture</b> and written up: visible is silhouette "
  "&cup; the near-vertex triad, 30.18% apart, and <em>coincident</em> is a 50/50 z-fight award rather "
  "than an erasure, so its column spreads 5.7&ndash;50.3%. The real nulls are at <em>corner</em>, where "
  "every mark lies on a hidden edge so separation has no surface to be a relation to &mdash; both held "
  "at 0.12%. The prediction, frame against visible, is #1 of 10."),

 ("proportion_bench", "proportion &middot; righttriangle's four &middot; all the same theorem",
  "Which right triangle counts as the right triangle is a choice about what you can build and what you find beautiful.",
  """<p class="body">At a hypotenuse fixed to 0.450&nbsp;m: <b>isoceles</b> is 1:1:&radic;2, legs
  0.3182/0.3182, 45&deg;/45&deg;. <b>3-4-5</b> is the Egyptian rope-stretcher's triangle you can build
  with knots and no measurement, legs 0.270/0.360, 36.87&deg;/53.13&deg;. <b>1-2</b> is the half-domino
  &mdash; not the half-square, which is isoceles &mdash; legs 0.2012/0.4025. <b>kepler</b> is
  1:&radic;&phi;:&phi;, the only right triangle whose sides are a geometric progression, legs
  0.2781/0.3538. Every column squares to 1.000000000000. All four satisfy a&sup2;+b&sup2;=c&sup2;; they
  are one theorem and four cultures.</p>
  <p class="body">Two corrections from the source. righttriangle normalises the <b>longer leg</b> to 1.0
  rather than the hypotenuse, so its four hypotenuses span 1.118&ndash;1.414 and <b>its axis confounds
  shape with size</b>; this bench inverts that and says what it costs (3-4-5's legs become 0.270 and
  0.360 &mdash; "3 and 4 of nothing"). And the golden ratio doubled as a transcription check: the
  source's literal 0.7861513777574233 is 1/&radic;&phi;, which survives renormalisation unchanged,
  which is the definition of a geometric progression.</p>""",
  [({"proportion": "3-4-5", "reading": "figure"}, "3-4-5 &middot; the rope-stretcher's"),
   ({"proportion": "kepler", "reading": "figure"}, "kepler &middot; 1:&radic;&phi;:&phi;"),
   ({"proportion": "isoceles", "reading": "figure"}, "isoceles &middot; the half-square"),
   ({"proportion": "3-4-5", "reading": "squares"}, "3-4-5 &middot; the theorem as slabs")],
  "<b>A null registered in reverse.</b> Four distinct ratios are four distinct pictures, so no "
  "construction-identical pair exists &mdash; and rather than register nothing, the builder registered "
  "the <em>absence</em>: all 66 pairs must be non-zero, and any 0.00% would mean the sweep failed to set "
  "what it claims. It also verified that <code>\"3-4-5\"</code> and <code>\"1-2\"</code> both fail "
  "int() and float(), so the silent typed-set() trap that cost this programme a whole wave cannot fire "
  "on this axis. Prediction: 3-4-5 against kepler, 1.303&deg; apart where the next gap is 6.827&deg;. "
  "#1 of 6, at 0.06%."),
]

CLOSING_TEMPLATE = """
  <section>
    <div class="hd"><h2 class="tok">the scoreboard</h2><span class="fam">6 predictions &middot; 5 hit &middot; 12 designed nulls &middot; 12 held</span><span class="chip">one held null was scored as broken</span></div>
    <p class="thesis">Twelve nulls, twelve held — and the one that looked broken was a question asked in the wrong colour.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">synthesis</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">predicted</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">rank</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th></tr>
      __ROWS__
    </table><p class="hint" style="margin-top:8px">Rank among non-null pairs, within the context each prediction names.</p></div>
    <p class="body"><b>What the families were hiding.</b> The artifact that offers a <em>catenary</em>
    draws a parabola, and the difference is 1.7&nbsp;mm on a 40&nbsp;mm run &mdash; a suspension deck
    wearing a chain's name. <span class="tok">righttriangle</span> normalises the longer leg, so its
    proportion axis changes size along with shape. <span class="tok">cube_lines</span> ships a frozen
    silhouette that is right in one octant and wrong in three of the five standpoints this programme
    checks. None of these are bugs that break anything; they are words that have drifted from what the
    code does, which is the only kind of defect a corpus this size accumulates silently.</p>
    <p class="body"><b>And one more fault in the scorer, which is now four.</b> A designed null inherits
    its METRIC the way a rank inherits its denominator and its pool. face_convention solved two colours
    to equal luma and registered a greyscale identity; score_wave measured per-channel and called a
    perfectly held null broken at 6.45%. Measured in the colour it was registered in, luma moved 0.00%
    with a maximum difference of 2 levels out of 255. The scorer now reads the metric out of the
    registration and prints both numbers, so nobody has to take the verdict on trust.</p>
    <p class="tail"><b>What this wave does not settle.</b> <span class="tok">proportion_bench</span>'s
    proportion axis is <em>local</em> &mdash; 12.57% in focus, 0.91% of frame &mdash; because four
    triangles at a constant hypotenuse differ in a small wedge and nothing else; that is honest and it
    was predicted, but it is a thin axis and a second standpoint has not been tried. Neither has one on
    <span class="tok">edge_ground</span>'s silhouette, where the builder has already shown the source
    list is wrong at three of five standpoints &mdash; the obvious next move is to run
    probe_anamorphic there and let the corpus's own frozen edge list be measured from where it fails.</p>
  </section>

<footer><span>wave 17</span><span>6 syntheses &middot; 12 axes &middot; 5 of 6 hit &middot; 12 of 12 nulls held &middot; six agents, one orchestrator</span>
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
