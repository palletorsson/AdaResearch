#!/usr/bin/env python3
"""build_wave13_gallery.py — wave 13, six syntheses, built to the study's own recipe.

doc/reports/GALLERY_STUDY.md measured all eighteen prior galleries and found the quality drop
was countable: waves 2-6 shipped five or six syntheses, waves 8-12 shipped one, and one object
cannot make a comparison so the late galleries argued about method instead. Every section here
carries the four things the strong ones all had — a family census, a thesis someone could
disagree with, a body that names each value, and a tail with the measurement AND the miss.
"""
from __future__ import annotations
import json
import pathlib

REPO = pathlib.Path(__file__).resolve().parents[1]
ENC = pathlib.Path(r"C:\Users\palle\Documents\GitHub\ada_encyclopedia")
SLUG = "wave13"

S = json.loads((REPO / "ada_run" / "wave13_scores.json").read_text(encoding="utf-8"))
MAN = json.loads((ENC / "public" / SLUG / "manifest.json").read_text(encoding="utf-8"))
BY = {}
for e in MAN["entries"]:
    BY.setdefault(e["prop"], []).append(e)


def frames(tok: str, pick: list) -> str:
    """A strip of named frames. pick is a list of (dna-dict, caption)."""
    out = '<div class="strip">'
    for want, cap in pick:
        hit = next((e for e in BY.get(tok, [])
                    if all(str(e["dna"].get(k)) == str(v) for k, v in want.items())), None)
        if hit is None:
            continue
        out += (f'<figure><img loading="lazy" src="{hit["image"]}" alt="{hit["label"]}">'
                f'<figcaption>{cap}</figcaption></figure>')
    return out + "</div>"


def tail(tok: str, extra: str = "") -> str:
    s = S[tok]
    hit = s["rank"] == 1
    verdict = ("named the closest pair" if hit
               else f'named #{s["rank"]} of {s["n"]}, not the closest')
    cls = "ok" if hit else "bad"
    return (f'<p class="tail"><b>Pre-registered, then measured.</b> The prediction named a '
            f'PAIR, and that is what is scored — a rank is unit-free, where comparing the '
            f'predicted percentage to the measurement is not, because the predictions were '
            f'written subject-relative and the sweep reports frame-relative. It '
            f'<span class="{cls}">{verdict}</span> (#{s["rank"]} of {s["n"]}, at '
            f'{s["meas"]}% of frame). The closest pair on the axis was '
            f'<span class="tok">{s["closest"]}</span> at {s["closest_pct"]}%. {extra}</p>')


SECTIONS = [
 ("frequency_shell", "subdivision &middot; 5 members &middot; 1 vocabulary &middot; one of them is a parts list",
  "A dome gets rounder and less buildable at the same time.",
  """<p class="body">Five artifacts share <span class="tok">subdivision</span> with the values
  v1 v2 v3 v4 — dome_builder, geodesic_dome, icosahedron_base, subdivision_demo, and
  <b>strut_inventory</b>. The corpus already contains an artifact whose entire subject is the
  parts list, standing next to four artifacts that offer the frequency dial, and nobody had
  put the two in the same room.</p>
  <p class="body">A geodesic sphere at frequency v is an icosahedron whose twenty faces are
  each cut into v&sup2; triangles and pushed out onto the sphere. Subdividing <em>then</em>
  normalising is what makes the edges unequal: a flat triangle projected onto a ball stretches
  by different amounts depending where it sits. So two things happen at once and they pull
  opposite ways. <b>shell</b> shows the surface, where the gain per step visibly collapses.
  <b>struts</b> shows the edges as rods, coloured by which distinct length they are.
  <b>inventory</b> lays each dome's distinct strut lengths out beneath it as real struts of
  those real lengths, sorted — the bar chart is banned, the parts list is made of parts.</p>""",
  [({"frequency": "v1", "reading": "shell"}, "v1 &middot; shell"),
   ({"frequency": "v4", "reading": "shell"}, "v4 &middot; shell &mdash; the eye is done"),
   ({"frequency": "v1", "reading": "inventory"}, "v1 &middot; two strut lengths"),
   ({"frequency": "v4", "reading": "inventory"}, "v4 &middot; the parts list has not converged")],
  "The shape converges and the parts diverge, which is the cost none of the five members shows."),

 ("octave_stack", "octaves &middot; 8 members &middot; the corpus's most-shared quantity axis",
  "The fourth octave cannot matter, and that is arithmetic, not taste.",
  """<p class="body">Eight artifacts declare <span class="tok">octaves</span>: noise_quarry and
  noise_space (1 2 3 4), simplex_noise (1 2 4 6), the four marching-cubes caves (1 2 3 6),
  generator_bench (1 2 3). Every one presents it as detail you can dial up.</p>
  <p class="body">Fractal noise sums octaves at halving amplitude and doubling frequency. The
  first contributes 1, the second &frac12;, the third &frac14;. So whatever any octave past
  the first can still add is bounded by what remains of the series — <b>the ladder converges
  before anything is drawn</b>. An artifact offering 1 2 3 6 is offering three useful rungs and
  a decoration, and half the family goes to 6. <b>sum</b> is the field, the only reading the
  family ships. <b>layers</b> draws every octave alone at its true amplitude, stacked, so the
  halving is thickness rather than a claim. <b>residue</b> is what this rung added over the
  one below, by itself.</p>""",
  [({"octaves": "1", "reading": "sum"}, "1 octave"),
   ({"octaves": "4", "reading": "sum"}, "4 octaves"),
   ({"octaves": "6", "reading": "sum"}, "6 &mdash; the two extra rungs"),
   ({"octaves": "4", "reading": "layers"}, "4 &middot; layers &mdash; each at true amplitude")],
  "The tightest pair in the whole wave, and it is the top of the ladder, exactly as the "
  "arithmetic said before anything was rendered."),

 ("depth_well", "depth &middot; 6 members &middot; one of them admits the number is a budget",
  "The same small integer, and the opposite curve.",
  """<p class="body">Six artifacts declare <span class="tok">depth</span>:
  example_8_3_recursion_circles_vr and room_grammar (1-5), lsystem_dungeon (1-4), lsystem_editor
  (0 2 3 4 6), fractal_recursion_2 (1 2 4 6 7), and space_filling_curve_gallery — which names
  its rungs <em>sketch, sparse, standard, fine</em> and is the only member in either family to
  admit out loud that the number is a budget.</p>
  <p class="body">This artifact exists because <span class="tok">octave_stack</span> is in the
  same wave. Both hand the user one integer and invite them to turn it up. In octaves the
  contributions <b>halve</b>. Here each level acts on everything the last level made, so the
  parts <b>multiply</b> — at a branching factor of three, depth 5 is 243 tips where depth 1 was
  3. Same control, same word, opposite curve, and no way to tell which from the interface.
  <b>whole</b> is every branch. <b>tips</b> marks only the ends, so the multiplication is read
  as density. <b>cost</b> lays each level's members out as its own horizontal course.</p>
  <p class="body">What the shared grammar forecloses: that some ladders have a limit object and
  some do not. Sum enough octaves and you approach a particular field. Recurse forever and
  there is no tree.</p>""",
  [({"depth": "1", "reading": "whole"}, "1"),
   ({"depth": "2", "reading": "whole"}, "2 &mdash; the actual closest pair"),
   ({"depth": "5", "reading": "whole"}, "5"),
   ({"depth": "5", "reading": "tips"}, "5 &middot; tips &mdash; 243 ends")],
  "<b>This is the wave's finding and it arrived as my own error.</b> See below."),

 ("sampling_bench", "resolution &middot; 5 members &middot; four of five default to coarse or mid",
  "The only ladder here with something real at the top of it.",
  """<p class="body">Five artifacts declare <span class="tok">resolution</span>:
  animated_noise_explorer and queer_marching_cave (mid coarse fine), sphere_mid and
  facture_bench (coarse mid fine ultra), riemann_pump (pump coarse mid fine). Four of the five
  make <em>mid</em> or <em>coarse</em> the default, which is a quiet admission that the top
  rung is not where the artifact wants to live.</p>
  <p class="body">Put four ladders on one bench and they are not the same shape. Octaves
  converge because the series is built to. Depth diverges. Subdivision converges in shape while
  its parts list diverges. Resolution is the only one of the four with a <b>limit object</b>:
  there is a true surface, it exists independently of the sampling, and every rung is a wrong
  answer about a right thing. That makes its error subtractable in a way the other three
  are not — you cannot subtract a recursion from its limit, because there is not one.
  <b>sample</b> is the sampled surface. <b>truth</b> stands the reference behind it as a wire
  ghost. <b>error</b> draws the gap as struts standing where it occurs.</p>""",
  [({"resolution": "coarse", "reading": "sample"}, "coarse"),
   ({"resolution": "ultra", "reading": "sample"}, "ultra"),
   ({"resolution": "coarse", "reading": "error"}, "coarse &middot; error, a forest"),
   ({"resolution": "ultra", "reading": "error"}, "ultra &middot; error, nearly bare")],
  "The critic independently flagged <span class=\"tok\">fine == ultra</span> as a TWIN pair — "
  "the same conclusion from the other direction, and the reason the family's own members "
  "default to the middle of their ladder."),

 ("stencil_quarter", "stencil &middot; 4 members &middot; and it is not one family",
  "A symmetry is a claim about how much you never had to keep.",
  """<p class="body">Three artifacts share this vocabulary exactly —
  mirror_cellular_texture_for_3d, mirrored_cellular_automata and persian_rug all say
  <em>motif / quadrant / octant / none</em>. The fourth, <b>gradient_hunter</b>, declares the
  same axis name with the values <em>ring / pair / axial / shell / swarm</em>, which is not a
  symmetry vocabulary at all. <b>An axis name can be shared by artifacts that do not share an
  axis.</b> The declaration gate passes both because both are internally honest; nothing in the
  pipeline compares two artifacts' vocabularies to each other, so <span class="tok">stencil</span>
  reads as a five-member family in every census and is really a three-member family and a
  homonym.</p>
  <p class="body">Each value names a fraction of the plane you actually store, the rest
  generated by reflection. <b>none</b> keeps everything. <b>halfturn</b> keeps a half, by
  rotation rather than mirror — persian_rug's one non-reflection. <b>quadrant</b> keeps a
  quarter. <b>octant</b> folds that quarter across its diagonal again. <b>motif</b> keeps a
  sixteenth and repeats it. A symmetry is compression and the ratio is the group's order; the
  three members that share the vocabulary all treat it as a look. <b>kept</b> stands only the
  stored tile up and leaves the generated remainder flat.</p>""",
  [({"stencil": "none", "reading": "pattern"}, "none &middot; nothing is generated"),
   ({"stencil": "quadrant", "reading": "pattern"}, "quadrant &middot; a quarter stored"),
   ({"stencil": "motif", "reading": "pattern"}, "motif &middot; a sixteenth"),
   ({"stencil": "octant", "reading": "kept"}, "octant &middot; kept &mdash; stored stands up")],
  "The critic called the <span class=\"tok\">reading</span> axis CONDITIONAL and it is right in "
  "a way worth keeping: at <b>none</b>, <em>kept</em> and <em>pattern</em> measure 0.00% — "
  "identical to the byte. With no symmetry there is no generated remainder, so everything IS "
  "stored. A structural zero, not a dead axis; the same pairs reach 71-72% at motif and octant."),

 ("mounting_yard", "support &middot; 10 members &middot; 6 vocabularies &middot; 13 words &middot; 1 ladder",
  "What a thing is mounted on says what it is for.",
  """<p class="body">The largest unbuilt family in the corpus, and no two members quite agree
  on the words. catalyst_target says none/cradle/frame/gantry. code_display, tt and info_board
  say none/stand/frame/pylon or cabinet. fire_extinguisher and fire_hose_box say
  bracket/stand/cabinet. science_screen says stand/frame/cabinet/pylon. double_helix_scene says
  monument/bench/vitrine/terrace. pollock_painting_in_3d says floor/table/easel/wall. Six
  vocabularies, thirteen distinct words, one axis — and underneath them the same ladder, which
  is why nobody noticed.</p>
  <p class="body">A mount reads as a practical detail: how do we keep it off the floor. It is
  not. <b>none</b> — the thing floats; it is an idea and gravity is not part of its argument.
  <b>bracket</b> — it is equipment, bolted to a wall, owned by the building. <b>stand</b> — it
  is an instrument; it has a working height, so it has a user. <b>frame</b> — it is a picture;
  the frame says where the object stops and the world starts. <b>cabinet</b> — it is a
  specimen, enclosed, protected from the person looking at it. <b>pylon</b> — it is signage,
  not for holding but for being seen from far off. The same object under six mounts is six
  different institutions, which is why the members disagree about words: each picked the
  vocabulary of the institution it already belonged to.</p>""",
  [({"support": "none", "occupant": "plate"}, "none &middot; an idea"),
   ({"support": "bracket", "occupant": "plate"}, "bracket &middot; equipment"),
   ({"support": "cabinet", "occupant": "plate"}, "cabinet &middot; a specimen"),
   ({"support": "pylon", "occupant": "plate"}, "pylon &middot; signage")],
  "And it found a fault in its own capture. At the solved framing the pylon variants CLIPPED — "
  "subject bbox (317, 0, 443, 760), occupant off the top — and the critic duly reported vessel "
  "and specimen as 0.00% at pylon, byte-identical, max pixel difference zero. That reads "
  "exactly like a rung that swallows its object. It was a camera too close to see the top of "
  "the post; at framing 0.46 the same pair differs by 13,088 pixels."),
]


def main() -> int:
    base = (ENC / "public/galleries/wave-12.html").read_text(encoding="utf-8")
    cut = base.index("</style>") + len("</style>")
    head = base[:cut].replace("<title>Wave 12 &mdash; the tip that never moves</title>",
                              "<title>Wave 13 &mdash; the ladder that does not converge</title>")
    head += """<style>
    .strip{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;margin:16px 0}
    .strip figure{margin:0}
    .strip img{width:100%;border:1px solid var(--rule);border-radius:3px;display:block;background:#0d0d10}
    .strip figcaption{font-family:var(--mono);font-size:11px;color:var(--dim);padding-top:5px;text-align:center}
    </style>"""
    t = base[cut:]
    script = t[t.rindex("<script"):] if "<script" in t else ""

    body = """
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; wave 13 &middot; 15 August 2026</p>
  <h1>I predicted the divergent ladder<br>as if it converged.</h1>
  <p>Six syntheses. Four of them are families where the corpus hands you one small integer and
  invites you to turn it up &mdash; subdivision, octaves, depth, resolution. They look like the
  same control. They are four different curves, and the one that behaves differently caught me
  making the exact mistake the wave says the shared grammar produces.</p>
</header>
<div class="bar"><span class="hint">6 syntheses &middot; 87 frames &middot; 12 axes, all biting &middot; 6 predictions pre-registered, 3 hit</span></div>
"""
    for tok, fam, thesis, prose, pick, extra in SECTIONS:
        body += f"""
  <section>
    <div class="hd"><h2 class="tok">{tok}</h2><span class="fam">{fam}</span>
      <span class="chip">{"prediction hit" if S[tok]["hit"] else "prediction missed"}</span></div>
    <p class="thesis">{thesis}</p>
    {prose}
    {frames(tok, pick)}
    {tail(tok, extra)}
  </section>
"""
    d = S["depth_well"]
    body += f"""
  <section>
    <div class="hd"><h2 class="tok">the miss, scored</h2><span class="fam">depth_well &middot; predicted #{d['rank']} of {d['n']}</span><span class="chip bad">wrong end of the ladder</span></div>
    <p class="thesis">I predicted the top of the ladder, and the answer was the bottom.</p>
    <p class="body">Every prediction in this wave named which pair of rungs would look most
    alike. For the three <b>convergent</b> ladders I said the top pair, and all three were
    right &mdash; <span class="tok">v3 vs v4</span>, <span class="tok">4 vs 6</span>,
    <span class="tok">fine vs ultra</span>, each ranked #1 of its axis. For depth I said
    <b>5 vs 4</b> for the same reason: the last level is thin and short, 0.62&#8308; of the trunk.</p>
    <p class="body">It ranked <b>#{d['rank']} of {d['n']}</b>. The closest pair is
    <span class="tok">1 vs 2</span> at <b>{d['closest_pct']}%</b> &mdash; the <em>bottom</em>.
    And that is obvious in hindsight and is the whole point: in a divergent ladder the early
    rungs are the similar ones, because a trunk plus three stubs still looks like a trunk. In a
    convergent ladder the late rungs are the similar ones. <b>The closest pair sits at the top
    of a convergent ladder and at the bottom of a divergent one</b>, and I reached for the
    convergent reasoning because both families present the identical control: a spin box with a
    small integer in it.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">ladder</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">kind</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">closest pair</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">%</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">where</th></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">frequency_shell</td><td style="padding:5px 10px">converges</td><td style="padding:5px 10px">v3 vs v4</td><td style="padding:5px 10px;text-align:right">{S['frequency_shell']['closest_pct']}</td><td style="padding:5px 10px" class="ok">top</td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">octave_stack</td><td style="padding:5px 10px">converges</td><td style="padding:5px 10px">4 vs 6</td><td style="padding:5px 10px;text-align:right">{S['octave_stack']['closest_pct']}</td><td style="padding:5px 10px" class="ok">top</td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">sampling_bench</td><td style="padding:5px 10px">converges</td><td style="padding:5px 10px">fine vs ultra</td><td style="padding:5px 10px;text-align:right">{S['sampling_bench']['closest_pct']}</td><td style="padding:5px 10px" class="ok">top</td></tr>
      <tr><td style="padding:5px 10px;color:var(--brass)">depth_well</td><td style="padding:5px 10px"><b>diverges</b></td><td style="padding:5px 10px">1 vs 2</td><td style="padding:5px 10px;text-align:right">{d['closest_pct']}</td><td style="padding:5px 10px" class="bad"><b>bottom</b></td></tr>
    </table><p class="hint" style="margin-top:8px">Four ladders, one grammar, and the shape of the diminishing return is not in the interface anywhere.</p></div>
    <p class="tail"><b>What this wave does not settle.</b> Four ladders is four, not a law &mdash;
    the corpus has other quantity axes (<span class="tok">resolution</span> alone appears under
    three more names) and none of them has been asked which curve it is. And the prediction
    that came in UNDER its floor, octave_stack at 0.5&times;, is the known rasteriser limit on
    edge-only subjects at sub-pixel displacement, not a fault found; it is on record as a limit
    and it stays there.</p>
  </section>

<footer><span>wave 13</span><span>6 syntheses &middot; 12 axes &middot; 3 of 6 predictions hit</span>
<span><a href="/synthesis-gallery">&larr; all galleries</a></span></footer>
</div>
"""
    out = ENC / "public/galleries/wave-13.html"
    out.write_text(head + body + script, encoding="utf-8")
    n = sum(len(p) for _, _, _, _, p, _ in SECTIONS)
    print(f"wrote {out}  ({len(SECTIONS)} syntheses, {n} frames shown, {len(MAN['entries'])} swept)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
