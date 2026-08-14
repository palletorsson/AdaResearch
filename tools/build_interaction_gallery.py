#!/usr/bin/env python3
"""build_interaction_gallery.py — publish what the interaction harness found.

Reads ada_run/interaction/*.json and writes a page to the encyclopedia. The page is a
TABLE rather than a contact sheet, because the finding here is not a picture: it is which
artifacts move when driven, measured against what they do on their own.

COVERAGE IS STATED ON THE PAGE. The corpus is 2676 artifacts with a scene and this run
covers a fraction of them; a page that quietly reported percentages of a partial sample as
if they were the corpus would be the same fault this whole harness exists to catch.
"""
from __future__ import annotations
import collections
import glob
import html
import json
import pathlib

REPO = pathlib.Path(__file__).resolve().parents[1]
ENC = pathlib.Path(r"C:\Users\palle\Documents\GitHub\ada_encyclopedia")
SRC = REPO / "ada_run" / "interaction"
TOTAL_WITH_SCENE = 2676


def rows() -> list:
    out = []
    for f in sorted(glob.glob(str(SRC / "*.json"))):
        if pathlib.Path(f).name.startswith("_"):
            continue
        try:
            out.append(json.loads(pathlib.Path(f).read_text(encoding="utf-8")))
        except Exception:
            continue
    return out


def bucket(r: dict) -> str:
    return str(r.get("verdict", "?")).split(" -")[0]


def main() -> int:
    rs = rows()
    tally = collections.Counter(bucket(r) for r in rs)
    responds = [r for r in rs if bucket(r) == "RESPONDS"]
    inert = [r for r in rs if bucket(r) == "INERT"]
    incon = [r for r in rs if bucket(r) == "inconclusive"]
    void = [r for r in rs if bucket(r) == "unmeasurable"]

    # Reuse the style block from the newest wave gallery so the set stays one thing.
    base = (ENC / "public/galleries/wave-12.html").read_text(encoding="utf-8")
    cut = base.index("</style>") + len("</style>")
    head = base[:cut].replace(
        "<title>Wave 12 &mdash; the tip that never moves</title>",
        "<title>Does it actually respond?</title>")
    tail = base[cut:]
    script = tail[tail.rindex("<script"):] if "<script" in tail else ""

    def table(items, cols, cap):
        h = f'<div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">'
        h += ('<tr style="border-bottom:1px solid var(--rule)">'
              + "".join(f'<th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">{c}</th>' for c in cols)
              + "</tr>")
        for r in items:
            h += '<tr style="border-bottom:1px solid var(--rule)">'
            h += f'<td style="padding:5px 10px;color:var(--brass)">{html.escape(str(r.get("label","")))}</td>'
            h += f'<td style="padding:5px 10px;text-align:right">{r.get("controls_found",0)}</td>'
            h += f'<td style="padding:5px 10px;text-align:right">{r.get("grabbables_found",0)}</td>'
            dv = r.get("drift") or 0.0
            rv = r.get("response") or 0.0
            h += f'<td style="padding:5px 10px;text-align:right;font-variant-numeric:tabular-nums">{dv:.3f}</td>'
            h += f'<td style="padding:5px 10px;text-align:right;font-variant-numeric:tabular-nums">{rv:.3f}</td>'
            h += "</tr>"
        return h + f'</table><p class="hint" style="margin-top:8px">{cap}</p></div>'

    top = sorted(responds, key=lambda r: -(r.get("response") or 0.0))[:14]
    worst = sorted(incon, key=lambda r: -(r.get("drift") or 0.0))[:10]
    dead = sorted(inert, key=lambda r: -(r.get("controls_found") or 0))[:10]
    cols = ["artifact", "controls", "grabs", "drift", "response"]
    ## Two different denominators, and conflating them is exactly the fault this page exists
    ## to report. `pct` is a share OF WHAT WAS MEASURED — the right denominator for "how many
    ## of the artifacts we drove responded". `cov` is the share of the CORPUS, and is the only
    ## honest way to say how far the run got. The first build of this page used pct() for both
    ## and printed "550 of 2676 measured - 100% coverage".
    pct = lambda n: 100.0 * n / max(1, len(rs))
    cov = 100.0 * len(rs) / TOTAL_WITH_SCENE

    body = f"""
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; interaction harness &middot; 14 August 2026</p>
  <h1>Does it actually <em>respond</em>?</h1>
  <p>Until now &ldquo;interactive&rdquo; in this corpus meant <em>the file contains the word grab</em>.
  This instantiates each artifact, emits its controls' own signals, nudges its grabbables, and
  measures the subtree &mdash; against a negative control, because a vortex that spins and a
  ball that falls would both &ldquo;change after a button press&rdquo; with nothing listening.</p>
</header>
<div class="bar">
  <span class="hint">{len(rs)} of {TOTAL_WITH_SCENE} artifacts measured &middot; {cov:.0f}% coverage &middot; run in progress</span>
</div>

  <section>
    <div class="hd"><h2 class="tok">the count</h2><span class="fam">first runtime interaction test this corpus has had</span><span class="chip"><b>{len(responds)}</b> respond &middot; <span class="bad">{len(inert)}</span> inert</span></div>
    <p class="thesis">Firing a control and seeing movement proves nothing on its own.</p>
    <p class="body">Every verdict is measured against what the artifact does when left alone. The probe snapshots the subtree, waits, snapshots again to learn its <b>drift</b>, and only then fires; the <b>response</b> must clear that drift by 2&times; and clear an absolute floor. An artifact that moves as much on its own as it did when driven is reported <em>inconclusive</em> &mdash; not a pass.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:13px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:7px 10px;color:var(--dim);font-weight:400">verdict</th><th style="text-align:right;padding:7px 10px;color:var(--dim);font-weight:400">n</th><th style="text-align:right;padding:7px 10px;color:var(--dim);font-weight:400">share</th><th style="text-align:left;padding:7px 10px;color:var(--dim);font-weight:400">meaning</th></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:6px 10px" class="ok"><b>RESPONDS</b></td><td style="padding:6px 10px;text-align:right">{tally.get('RESPONDS',0)}</td><td style="padding:6px 10px;text-align:right">{pct(tally.get('RESPONDS',0)):.1f}%</td><td style="padding:6px 10px;color:var(--dim)">driven, and the subtree moved well past its own drift</td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:6px 10px">no affordance</td><td style="padding:6px 10px;text-align:right">{tally.get('no affordance',0)}</td><td style="padding:6px 10px;text-align:right">{pct(tally.get('no affordance',0)):.1f}%</td><td style="padding:6px 10px;color:var(--dim)">nothing to fire &mdash; a display, not a control</td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:6px 10px" class="bad"><b>INERT</b></td><td style="padding:6px 10px;text-align:right">{tally.get('INERT',0)}</td><td style="padding:6px 10px;text-align:right">{pct(tally.get('INERT',0)):.1f}%</td><td style="padding:6px 10px;color:var(--dim)">has controls, they were fired, and <b>nothing moved</b></td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:6px 10px" class="hold">inconclusive</td><td style="padding:6px 10px;text-align:right">{tally.get('inconclusive',0)}</td><td style="padding:6px 10px;text-align:right">{pct(tally.get('inconclusive',0)):.1f}%</td><td style="padding:6px 10px;color:var(--dim)">drifts as much as it responded &mdash; unanswerable this way</td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:6px 10px" class="hold">unmeasurable</td><td style="padding:6px 10px;text-align:right">{tally.get('unmeasurable',0)}</td><td style="padding:6px 10px;text-align:right">{pct(tally.get('unmeasurable',0)):.1f}%</td><td style="padding:6px 10px;color:var(--dim)">fired, but built <b>no geometry</b> &mdash; the harness has no standing</td></tr>
      <tr><td style="padding:6px 10px" class="hold">CRASHED</td><td style="padding:6px 10px;text-align:right">{tally.get('CRASHED',0)}</td><td style="padding:6px 10px;text-align:right">{pct(tally.get('CRASHED',0)):.1f}%</td><td style="padding:6px 10px;color:var(--dim)">killed the runner on load &mdash; a tombstone, not a verdict</td></tr>
    </table></div>
    <p class="tail"><b>The INERT column is the one that did not exist before.</b> These artifacts declare controls, the harness found them, fired them with arguments built from their own declared signal types &mdash; and the subtree did not move. A static audit calls every one of them interactive.</p>
  </section>

  <section>
    <div class="hd"><h2 class="tok">the harness first</h2><span class="fam">what the first run got wrong about itself</span><span class="chip"><b>3 of 22</b> INERT verdicts voided</span></div>
    <p class="thesis">A dead reading is a claim about the instrument until you prove otherwise.</p>
    <p class="body">The first pass returned 22 INERT, and every one of them read <b>drift 0.0000, response 0.0000</b> &mdash; a suspiciously perfect pair. Both numbers are built from mesh counts, positions and bounding boxes, so a subtree that never built any geometry scores zero on both <em>whatever the controls did</em>. Among the accused was <span class="tok">boid_flocking</span>, a live flocking simulation that cannot sit still. It was not sitting still; it had built <b>nothing at all</b> &mdash; 0 meshes, 0 spatial nodes.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">artifact</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">meshes</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">spatials</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">first verdict &rarr; after the gate</th></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">boid_flocking</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px"><span class="bad">INERT</span> &rarr; <span class="hold">voided</span></td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">ca_chair_test</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px;text-align:right">5</td><td style="padding:5px 10px"><span class="bad">INERT</span> &rarr; <span class="hold">voided</span></td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">advancedglitch</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px;text-align:right">32</td><td style="padding:5px 10px"><span class="bad">INERT</span> &rarr; <span class="hold">voided</span></td></tr>
      <tr><td style="padding:5px 10px;color:var(--brass)">caverandomwalk</td><td style="padding:5px 10px;text-align:right">3206</td><td style="padding:5px 10px;text-align:right">9622</td><td style="padding:5px 10px"><span class="bad">INERT</span> &rarr; <span class="bad">INERT, and it stands</span></td></tr>
    </table><p class="hint" style="margin-top:8px">The gate is one line: an INERT verdict on a subtree with no geometry is reported <em>unmeasurable</em> instead. It cost three convictions and made the other nineteen worth reading.</p></div>
    <p class="tail">Nineteen survived with real bodies present. <span class="tok">caverandomwalk</span> stands up 3,206 meshes, has nine controls fired at it, and does not move a millimetre &mdash; that is a finding about the artifact. The three that fell were findings about the probe.</p>
  </section>

  <section>
    <div class="hd"><h2 class="tok">inert</h2><span class="fam">controls found, fired, nothing moved</span><span class="chip"><b>{len(inert)}</b> so far</span></div>
    <p class="thesis">A declared control that changes nothing is decoration with a collision shape.</p>
    {table(dead, cols, "Ranked by how many controls were found and fired. Response is what moved after firing; these are at or near zero.")}
  </section>

  <section>
    <div class="hd"><h2 class="tok">inconclusive</h2><span class="fam">the negative control earning its place</span><span class="chip"><b>{len(incon)}</b> so far</span></div>
    <p class="thesis">Every one of these would have passed a naive before-and-after test.</p>
    <p class="body">These artifacts move on their own &mdash; a colony forages, a rocket flies, a puzzle settles under gravity. Fire a control and the subtree changes, and it would have changed anyway. The harness refuses to call that a response.</p>
    {table(worst, cols, "Ranked by drift. Read the two right-hand columns against each other: where they are comparable, the firing proved nothing.")}
  </section>

  <section>
    <div class="hd"><h2 class="tok">responds</h2><span class="fam">driven, and moved past its own drift</span><span class="chip"><b>{len(responds)}</b> so far</span></div>
    {table(top, cols, "The strongest responders. catapult drifts 0.000 and responds 116.56 — it fires.")}
    <p class="tail"><b>What this does not prove.</b> Firing signals and shoving grabbables into a live physics scene causes motion whatever is listening. A large response against near-zero drift is good evidence; it is not proof that the artifact <em>handled</em> the event rather than the physics reacting to being pushed. Separating those needs a probe that watches the handler rather than the subtree, and this is not that.</p>
    <p class="tail"><b>And coverage is partial.</b> {len(rs)} of {TOTAL_WITH_SCENE} artifacts, {cov:.0f}%. The batch runner dies on certain scenes and resumes past them, so the run is still going; every share on this page is a share of what has been measured, not of the corpus.</p>
  </section>

<footer><span>interaction harness</span><span>{len(rs)} measured &middot; negative control on every verdict</span>
<span><a href="/synthesis-gallery">&larr; all galleries</a></span></footer>
</div>
"""
    out = ENC / "public/galleries/interaction.html"
    out.write_text(head + body + script, encoding="utf-8")
    print(f"wrote {out}  ({len(rs)} measured: "
          + ", ".join(f"{v} {n}" for v, n in tally.most_common()) + ")")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
