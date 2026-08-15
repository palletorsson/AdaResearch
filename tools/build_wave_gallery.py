#!/usr/bin/env python3
"""build_wave_gallery.py — any wave: --slug=waveN, prose from tools/waveN_content.py.

doc/reports/GALLERY_STUDY.md measured all eighteen prior galleries and found the quality drop
was countable: waves 2-6 shipped five or six syntheses, waves 8-12 shipped one, and one object
cannot make a comparison so the late galleries argued about method instead. Every section here
carries the four things the strong ones all had — a family census, a thesis someone could
disagree with, a body that names each value, and a tail with the measurement AND the miss.
"""
from __future__ import annotations
import json
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parents[1]
ENC = pathlib.Path(r"C:\Users\palle\Documents\GitHub\ada_encyclopedia")
import sys as _sys
SLUG = next((a.split("=",1)[1] for a in _sys.argv[1:] if a.startswith("--slug=")), "wave14")
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

S = json.loads((REPO / "ada_run" / f"{SLUG}_scores.json").read_text(encoding="utf-8"))
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



import importlib as _il  # noqa: E402
_content = _il.import_module(f"{SLUG}_content")
TITLE, MAST, SECTIONS, closing = _content.TITLE, _content.MAST, _content.SECTIONS, _content.closing
CLOSING = closing(S)


def main() -> int:
    base = (ENC / "public/galleries/wave-12.html").read_text(encoding="utf-8")
    cut = base.index("</style>") + len("</style>")
    head = base[:cut].replace("<title>Wave 12 &mdash; the tip that never moves</title>",
                              "<title>" + TITLE + "</title>")
    head += """<style>
    .strip{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:10px;margin:16px 0}
    .strip figure{margin:0}
    .strip img{width:100%;border:1px solid var(--rule);border-radius:3px;display:block;background:#0d0d10}
    .strip figcaption{font-family:var(--mono);font-size:11px;color:var(--dim);padding-top:5px;text-align:center}
    </style>"""
    t = base[cut:]
    script = t[t.rindex("<script"):] if "<script" in t else ""

    body = MAST
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
    body += CLOSING
    out = ENC / "public/galleries" / (SLUG[:4] + "-" + SLUG[4:] + ".html")
    out.write_text(head + body + script, encoding="utf-8")
    n = sum(len(p) for _, _, _, _, p, _ in SECTIONS)
    print(f"wrote {out}  ({len(SECTIONS)} syntheses, {n} frames shown, {len(MAN['entries'])} swept)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
