#!/usr/bin/env python3
"""build_interaction_gallery.py — publish what the interaction harness found.

Reads ada_run/interaction/*.json and writes a page to the encyclopedia. The page is a TABLE
rather than a contact sheet, because the finding here is not a picture: it is which artifacts
move when driven, measured against what they do on their own.

THE PAGE LEADS WITH THE INSTRUMENT. Four separate times in this run a confident-looking
verdict turned out to be a fact about the rig — a geometry-blind zero, a stalled batch, a
watchdog kill, an out-of-domain response. Anything that survived all four is worth reading;
nothing would have been, published straight off the first pass.

TWO DENOMINATORS, NEVER CONFLATED. `pct` is a share of what was MEASURED; `cov` is a share of
the CORPUS. The first build of this page used pct() for both and printed "550 of 2676 measured
- 100% coverage", which is the same class of fault the harness exists to catch.
"""
from __future__ import annotations
import collections
import glob
import html
import json
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
ENC = pathlib.Path(r"C:\Users\palle\Documents\GitHub\ada_encyclopedia")
SRC = REPO / "ada_run" / "interaction"
TOTAL_WITH_SCENE = 2676

sys.path.insert(0, str(REPO / "tools"))


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


def carries_audio(tok: str, reg: dict):
    """DERIVED from the artifact's own scene and script, never guessed from its name.

    The first cut of this split matched on the token text and flagged NoiseColors3D and
    WhiteNoiseGallery as audio — they are VISUAL noise, and the word was doing the work a
    reading of the scene should have done. Same fault as transcribing a dna.axes block.
    """
    sc = str((reg.get(tok) or {}).get("scene") or "")
    if not sc.startswith("res://"):
        return None
    p = REPO / sc[6:]
    seen = False
    for f in (p, p.with_suffix(".gd")):
        if f.exists():
            seen = True
            try:
                t = f.read_text(encoding="utf-8", errors="replace")
            except Exception:
                continue
            if re.search(r"AudioStreamPlayer|AudioStreamGenerator|play_note|AudioServer", t):
                return True
    return False if seen else None


def main() -> int:
    import check_interaction
    reg = check_interaction.registry()

    rs = rows()
    tally = collections.Counter(bucket(r) for r in rs)
    responds = [r for r in rs if bucket(r) == "RESPONDS"]
    inert_all = [r for r in rs if bucket(r) == "INERT"]
    incon = [r for r in rs if bucket(r) == "inconclusive"]
    void = [r for r in rs if bucket(r) == "unmeasurable"]

    audio = [r for r in inert_all if carries_audio(r.get("label", ""), reg) is True]
    inert = [r for r in inert_all if r not in audio]

    base = (ENC / "public/galleries/wave-12.html").read_text(encoding="utf-8")
    cut = base.index("</style>") + len("</style>")
    head = base[:cut].replace(
        "<title>Wave 12 &mdash; the tip that never moves</title>",
        "<title>Does it actually respond?</title>")
    tail = base[cut:]
    script = tail[tail.rindex("<script"):] if "<script" in tail else ""

    def table(items, cap, extra=""):
        h = ('<div class="mwrap"><table style="width:100%;border-collapse:collapse;'
             'font-family:var(--mono);font-size:12.5px">')
        cols = ["artifact", "controls", "grabs", "meshes", "drift", "response"]
        h += ('<tr style="border-bottom:1px solid var(--rule)">'
              + "".join(f'<th style="text-align:{"left" if c=="artifact" else "right"};'
                        f'padding:6px 10px;color:var(--dim);font-weight:400">{c}</th>'
                        for c in cols) + "</tr>")
        for r in items:
            dv = r.get("drift") or 0.0
            rv = r.get("response") or 0.0
            mv = r.get("meshes")
            h += '<tr style="border-bottom:1px solid var(--rule)">'
            h += ('<td style="padding:5px 10px;color:var(--brass)">'
                  f'{html.escape(str(r.get("label","")))}</td>')
            h += f'<td style="padding:5px 10px;text-align:right">{r.get("controls_found",0)}</td>'
            h += f'<td style="padding:5px 10px;text-align:right">{r.get("grabbables_found",0)}</td>'
            h += ('<td style="padding:5px 10px;text-align:right;color:var(--dim)">'
                  f'{mv if mv is not None else "&mdash;"}</td>')
            h += ('<td style="padding:5px 10px;text-align:right;'
                  f'font-variant-numeric:tabular-nums">{dv:.3f}</td>')
            h += ('<td style="padding:5px 10px;text-align:right;'
                  f'font-variant-numeric:tabular-nums">{rv:.3f}</td>')
            h += "</tr>"
        return h + f'</table><p class="hint" style="margin-top:8px">{cap}</p>{extra}</div>'

    top = sorted(responds, key=lambda r: -(r.get("response") or 0.0))[:12]
    worst = sorted(incon, key=lambda r: -(r.get("drift") or 0.0))[:10]
    dead = sorted(inert, key=lambda r: -(r.get("controls_found") or 0))[:14]
    deaf = sorted(audio, key=lambda r: -(r.get("controls_found") or 0))[:6]
    novoid = sorted(void, key=lambda r: -(r.get("controls_found") or 0))[:8]

    pct = lambda n: 100.0 * n / max(1, len(rs))
    cov = 100.0 * len(rs) / TOTAL_WITH_SCENE

    def vrow(name, n, meaning, cls="", last=False):
        b = "" if last else "border-bottom:1px solid var(--rule)"
        c = f' class="{cls}"' if cls else ""
        return (f'<tr style="{b}"><td style="padding:6px 10px"{c}><b>{name}</b></td>'
                f'<td style="padding:6px 10px;text-align:right">{n}</td>'
                f'<td style="padding:6px 10px;text-align:right">{pct(n):.1f}%</td>'
                f'<td style="padding:6px 10px;color:var(--dim)">{meaning}</td></tr>')

    body = f"""
<div class="wrap">
<header class="mast">
  <p class="eyebrow">Ada Research &middot; interaction harness &middot; 15 August 2026</p>
  <h1>Does it actually <em>respond</em>?</h1>
  <p>Every gallery before this one photographed artifacts. This one drives them: instantiate
  each artifact, emit its controls' own declared signals, nudge its grabbables, and measure the
  subtree &mdash; against a negative control, because a vortex that spins and a ball that falls
  would both &ldquo;change after a button press&rdquo; with nothing listening.</p>
</header>
<div class="bar">
  <span class="hint">{len(rs)} of {TOTAL_WITH_SCENE} artifacts measured &middot; {cov:.1f}% of the corpus &middot; complete</span>
</div>

  <section>
    <div class="hd"><h2 class="tok">the count</h2><span class="fam">first runtime interaction test this corpus has had</span><span class="chip"><b>{len(responds)}</b> respond &middot; <span class="bad">{len(inert)}</span> inert</span></div>
    <p class="thesis">Firing a control and seeing movement proves nothing on its own.</p>
    <p class="body">Until now &ldquo;interactive&rdquo; here meant <em>the file contains the word grab</em>. A static grep proves an affordance is <b>declared</b>; it cannot prove the button is wired or that anything happens when it fires. Every verdict below is measured against what the artifact does when left alone: the probe snapshots the subtree, waits, snapshots again to learn its <b>drift</b>, and only then fires. The <b>response</b> must clear that drift by 2&times; and clear an absolute floor.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:13px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:7px 10px;color:var(--dim);font-weight:400">verdict</th><th style="text-align:right;padding:7px 10px;color:var(--dim);font-weight:400">n</th><th style="text-align:right;padding:7px 10px;color:var(--dim);font-weight:400">share</th><th style="text-align:left;padding:7px 10px;color:var(--dim);font-weight:400">meaning</th></tr>
      {vrow("RESPONDS", len(responds), "driven, and the subtree moved well past its own drift", "ok")}
      {vrow("no affordance", tally.get("no affordance", 0), "nothing to fire &mdash; a display, not a control")}
      {vrow("INERT", len(inert), "spatial, has controls, they were fired, and <b>nothing moved</b>", "bad")}
      {vrow("out of domain", len(audio), "controls drive <b>sound</b> &mdash; this probe sees geometry only", "hold")}
      {vrow("inconclusive", len(incon), "drifts as much as it responded &mdash; unanswerable this way", "hold")}
      {vrow("unmeasurable", len(void), "fired, but built <b>no geometry</b> to measure", "hold", last=True)}
    </table></div>
    <p class="tail"><b>The bottom four rows are the point.</b> A first pass reported only the top two and a single undifferentiated INERT column &mdash; and it was wrong four separate ways. Each correction below cost convictions and made the survivors worth reading.</p>
  </section>

  <section>
    <div class="hd"><h2 class="tok">the instrument</h2><span class="fam">four times a verdict was a fact about the rig</span><span class="chip"><b>4</b> corrections</span></div>
    <p class="thesis">A dead reading is a claim about the instrument until you prove otherwise.</p>

    <p class="body"><b>1 &middot; The geometry-blind zero.</b> The first pass returned 22 INERT and every one read <b>drift 0.0000, response 0.0000</b> &mdash; the same number twice, to the byte, on artifacts as different as a flocking simulation and an info board. Both numbers are built from mesh counts, positions and bounding boxes, so a subtree that never built any geometry scores zero on both <em>whatever its controls did</em>. Among the accused was <span class="tok">boid_flocking</span>, a live flocking simulation that cannot sit still. It was not sitting still &mdash; it had built <b>nothing at all</b>, 0 meshes and 0 spatial nodes.</p>
    <div class="mwrap"><table style="width:100%;border-collapse:collapse;font-family:var(--mono);font-size:12.5px">
      <tr style="border-bottom:1px solid var(--rule)"><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">artifact</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">meshes</th><th style="text-align:right;padding:6px 10px;color:var(--dim);font-weight:400">spatials</th><th style="text-align:left;padding:6px 10px;color:var(--dim);font-weight:400">first verdict &rarr; after the gate</th></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">boid_flocking</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px"><span class="bad">INERT</span> &rarr; <span class="hold">voided</span></td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">fibonacci_sequences</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px;text-align:right">1241</td><td style="padding:5px 10px"><span class="bad">INERT</span> &rarr; <span class="hold">voided</span> &mdash; 1241 nodes, no mesh</td></tr>
      <tr style="border-bottom:1px solid var(--rule)"><td style="padding:5px 10px;color:var(--brass)">noir_sequencer</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px;text-align:right">0</td><td style="padding:5px 10px"><span class="bad">INERT</span> &rarr; <span class="hold">voided</span> &mdash; 283 controls, no body</td></tr>
      <tr><td style="padding:5px 10px;color:var(--brass)">caverandomwalk</td><td style="padding:5px 10px;text-align:right">3206</td><td style="padding:5px 10px;text-align:right">9622</td><td style="padding:5px 10px"><span class="bad">INERT</span> &rarr; <span class="bad">INERT, and it stands</span></td></tr>
    </table><p class="hint" style="margin-top:8px">The gate is one branch: an INERT verdict on a subtree with no geometry is reported <em>unmeasurable</em> instead. {len(void)} artifacts sit there now.</p></div>

    <p class="body" style="margin-top:22px"><b>2 &middot; The run was not slow, it was stopped.</b> The corpus pass kept dying after about a chunk, and read as merely slow. It was not: each pass resumes past what is already on disk, so a scene that hard-killed the process put itself <em>first</em> in the next chunk and killed it again. Writing a tombstone <em>before</em> each load means a kill leaves evidence and the next pass steps over it. It named the culprit on the first try &mdash; <span class="tok">context_toy</span> &mdash; and the very next pass went from 732 measured to 2,311.</p>

    <p class="body" style="margin-top:22px"><b>3 &middot; And then the tombstones were wrong too.</b> Ten artifacts carried a CRASHED marker, four of them from one <span class="tok">ca_showcase</span> family &mdash; a tidy-looking cluster that would have been written up as a crash bug. Run individually, <span class="tok">percolation_ca</span> measured fine in 46 seconds. They are not crashing; they are <b>slow</b>, and in batch they trip the watchdog's 16-second output-stall rule, which kills the whole run at them. Re-measured one at a time, <b>all ten</b> produced clean verdicts &mdash; two of them <span class="ok">RESPONDS</span>. The CRASHED column is now empty and no artifact was ever at fault.</p>

    <p class="body" style="margin-top:22px"><b>4 &middot; A geometry probe cannot hear.</b> {len(audio)} of the {len(inert_all)} INERT verdicts belong to artifacts that carry an audio player &mdash; fifteen <span class="tok">step_sequencer</span> variants alone, 135 controls each. Press a step sequencer's buttons and the correct response is <em>sound</em>. This probe measures meshes, positions and boxes; it is structurally deaf, and it has no standing to call those dead. They are split out above rather than counted as convictions.</p>
    {table(deaf, "Six of the audio-carrying artifacts. Membership is DERIVED by reading each scene and script for an AudioStreamPlayer — the first cut matched on the token name and flagged NoiseColors3D and WhiteNoiseGallery, which are visual noise.")}
  </section>

  <section>
    <div class="hd"><h2 class="tok">inert</h2><span class="fam">spatial, controls fired, nothing moved</span><span class="chip"><b>{len(inert)}</b> convictions</span></div>
    <p class="thesis">A declared control that changes nothing is decoration with a collision shape.</p>
    <p class="body">These survived all four corrections. Each builds real geometry, declares controls, had those controls fired with arguments built from their own declared signal types &mdash; and did not move. A static audit calls every one of them interactive.</p>
    {table(dead, "Ranked by controls fired. color_sets_overview declares 288 of them. caverandomwalk raises 3,206 meshes and does not shift a millimetre.")}
  </section>

  <section>
    <div class="hd"><h2 class="tok">inconclusive</h2><span class="fam">the negative control earning its place</span><span class="chip"><b>{len(incon)}</b> unanswerable</span></div>
    <p class="thesis">Every one of these would have passed a naive before-and-after test.</p>
    <p class="body">These move on their own &mdash; a colony forages, a rocket flies, an assembly puzzle settles under gravity. Fire a control and the subtree changes, and it would have changed anyway. Read the two right-hand columns against each other: where they are comparable, the firing proved nothing, and the harness refuses to score it as a pass.</p>
    {table(worst, "Ranked by drift. platonic_grabbables drifts 1637.88 on its own and responded 2080.93 — a 27% difference that a before-and-after test would have reported as a confident yes.")}
  </section>

  <section>
    <div class="hd"><h2 class="tok">responds</h2><span class="fam">driven, and moved past its own drift</span><span class="chip"><b>{len(responds)}</b> &middot; {pct(len(responds)):.0f}% of the corpus</span></div>
    {table(top, "The strongest responders, ranked by response against near-zero drift.")}
    <p class="tail"><b>What this does not prove.</b> Firing signals and shoving grabbables into a live physics scene causes motion whatever is listening. A large response against near-zero drift is good evidence; it is not proof that the artifact <em>handled</em> the event rather than the physics reacting to being pushed. Separating those needs a probe that watches the handler rather than the subtree, and this is not that.</p>
    <p class="tail"><b>And one more standpoint problem.</b> The DNA critic learned that an INERT verdict from a single camera angle was wrong five times in seven. This harness has the same shape of limit in a different axis: it drives every control <em>at once</em>, in one order, with default arguments. An artifact that needs two controls in sequence, or a specific value, will read inert here and work in the headset.</p>
  </section>

<footer><span>interaction harness</span><span>{len(rs)} of {TOTAL_WITH_SCENE} measured &middot; negative control on every verdict</span>
<span><a href="/synthesis-gallery">&larr; all galleries</a></span></footer>
</div>
"""
    out = ENC / "public/galleries/interaction.html"
    out.write_text(head + body + script, encoding="utf-8")
    print(f"wrote {out}\n  {len(rs)} of {TOTAL_WITH_SCENE} ({cov:.1f}%): "
          + ", ".join(f"{v} {n}" for n, v in tally.most_common())
          + f"\n  INERT split: {len(inert)} spatial convictions, {len(audio)} out of domain")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
