#!/usr/bin/env python3
"""build_catalogue.py — the placement catalogue for the endless museum.

Every synthesis this programme has built, labelled, with what a curator needs to hang it:
a stable accession label, the token a map actually uses, the axes and values that can be
varied, a copy-ready placement string, whether the thing CAN be hung at all, how big a room
it can survive, and where it already stands.

WHY IT IS NOT JUST A LIST OF NAMES. Three things measured this session make the difference
between a catalogue and a wish:

  · 46 axes across 44 artifacts CANNOT be hung with `#axis:value` at all. When a config key
    is outside GridInteractablesComponent's CONFIG_PARAM_NAMES and its value parses as a
    float, the fragment is read as positional shorthand: the axis is set to `true` and the
    number becomes a rotation. Silently. Those axes are marked here, because a curator who
    types one gets a rotated default and no warning.
  · An artifact has a BODY, and a room has an extent. Wave 23 hung six rooms that passed
    every rule and rendered their works as specks — 1.5% to 5.3% of the hall. The catalogue
    states the largest room each work survives at a 3% floor, so the room is chosen from the
    work rather than the other way round.
  · A designed null is the strongest thing a room can show: two works identical by
    construction, which a visitor discovers by walking. They are listed as pairs to hang.

Usage:  python tools/build_catalogue.py
Writes ada_encyclopedia/public/galleries/catalogue.html and ada_run/catalogue.json
"""
from __future__ import annotations
import json, pathlib, re, collections, html

REPO = pathlib.Path(__file__).resolve().parents[1]
REG = REPO / "commons" / "artifacts" / "registry"
ENC = REPO.parent / "ada_encyclopedia"
GAL = ENC / "public" / "galleries"
MAPS = REPO / "commons" / "maps"


def config_param_names() -> set:
    src = (REPO / "commons" / "grid" / "GridInteractablesComponent.gd").read_text(encoding="utf-8")
    m = re.search(r"const CONFIG_PARAM_NAMES\s*=\s*\[(.*?)\]", src, re.S)
    return {x.strip().strip("\"'").lower() for x in m.group(1).split(",") if x.strip()} if m else set()


def load_entries() -> dict:
    out = {}
    for f in REG.glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for t, e in (d.get("artifacts") or {}).items():
            out[t] = e
    return out


def gallery_homes(synth: list[str]) -> dict:
    """Which gallery OWNS each synthesis.

    A gallery owns a synthesis if it gives it a section heading. Frames are the next best
    evidence, and a bare prose mention is not evidence at all — evidence_ladder is discussed
    inside wave 21's basin_field section and belongs to six-syntheses, where it has an h2.
    """
    txt = {f.stem: f.read_text(encoding="utf-8", errors="ignore") for f in sorted(GAL.glob("*.html"))}

    def wk(s):
        m = re.match(r"wave-(\d+)$", s)
        return (0, int(m.group(1))) if m else (1, s)

    order = sorted(txt, key=wk)
    home = {}
    for t in synth:
        for g in order:                                    # 1. section heading
            if re.search(rf'<h2[^>]*>\s*{re.escape(t)}\s*<', txt[g]):
                home[t] = g; break
        else:
            for g in order:                                # 2. owns its frames
                if re.search(rf'src="/[a-z0-9\-]+/{re.escape(t)}__', txt[g]):
                    home[t] = g; break
            else:
                for g in order:                            # 3. mentioned at all
                    if re.search(rf"\b{re.escape(t)}\b", txt[g]):
                        home[t] = g; break
    return home


def hung_in() -> dict:
    """token -> {map name: count of configured placements}"""
    out = collections.defaultdict(collections.Counter)
    for md in MAPS.glob("*/map_data.json"):
        try:
            d = json.loads(md.read_text(encoding="utf-8"))
        except Exception:
            continue
        for r in ((d.get("layers") or {}).get("interactables") or []):
            for c in (r if isinstance(r, list) else []):
                s = str(c).strip()
                if not s or "#" not in s:
                    continue
                out[s.split("#")[0].split(":")[0]][md.parent.name] += 1
    return out


def main() -> int:
    cpn = config_param_names()
    ent = load_entries()
    synth = sorted(t for t, e in ent.items() if ((e.get("dna") or {}).get("sources")))
    home = gallery_homes(synth)
    hung = hung_in()

    by_gal = collections.defaultdict(list)
    for t in synth:
        by_gal[home.get(t, "unfiled")].append(t)

    def wk(s):
        m = re.match(r"wave-(\d+)$", s)
        return (0, int(m.group(1))) if m else (1, s)

    titles = {}
    for f in GAL.glob("*.html"):
        m = re.search(r"<title>(.*?)</title>", f.read_text(encoding="utf-8", errors="ignore"), re.S)
        titles[f.stem] = re.sub(r"\s*&mdash;\s*Ada Research\s*$", "", m.group(1).strip()) if m else f.stem

    rows, cat = [], {}
    for gal in sorted(by_gal, key=wk):
        m = re.match(r"wave-(\d+)$", gal)
        code = f"W{m.group(1)}" if m else "".join(w[0] for w in gal.split("-")).upper()
        for i, tok in enumerate(sorted(by_gal[gal]), 1):
            e = ent[tok]
            dna = e.get("dna") or {}
            axes = {}
            for a, spec in (dna.get("axes") or {}).items():
                vals = spec.get("values") if isinstance(spec, dict) else spec
                axes[a] = [str(v) for v in (vals or [])]
            # can each axis be hung?
            blocked = {a: vs for a, vs in axes.items()
                       if a.lower() not in cpn
                       and any(re.fullmatch(r"-?\d+(\.\d+)?", v) for v in vs)}
            aabb = (e.get("measurements") or {}).get("aabb_size")
            longest = max(float(aabb[0]), float(aabb[2])) if aabb else None
            max_span = int(longest / 0.03) if longest else None
            names = list(axes)
            tmpl = tok + ":0:0" + "".join(
                f"#{a}:{axes[a][0]}" for a in names[:2] if a not in blocked)
            nulls = []
            for nd in (dna.get("designed_nulls") or []):
                a, b = nd.get("a") or {}, nd.get("b") or {}
                if a and b:
                    nulls.append((a, b))
            cat[tok] = dict(label=f"{code}·{i}", gallery=gal, axes=axes,
                            blocked=sorted(blocked), aabb=aabb, max_span=max_span,
                            placement=tmpl, nulls=nulls, hung=dict(hung.get(tok, {})))
            rows.append((code, f"{code}·{i}", gal, tok, axes, blocked, longest,
                         max_span, tmpl, nulls, dict(hung.get(tok, {}))))

    (REPO / "ada_run" / "catalogue.json").write_text(json.dumps(cat, indent=1), encoding="utf-8")

    # ---- page -------------------------------------------------------------
    esc = html.escape
    out = ["""<title>Placement Catalogue</title>
<style>
:root{--bg:#0d0f13;--ink:#e8e6e1;--dim:#8a8f98;--rule:#242830;--brass:#c9a227;--ok:#5fa869;--bad:#c0553f;--mono:ui-monospace,SFMono-Regular,Menlo,monospace}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.55 ui-sans-serif,system-ui,sans-serif}
.wrap{max-width:1180px;margin:0 auto;padding:38px 22px 90px}
h1{font-size:31px;line-height:1.15;margin:0 0 12px;font-weight:640;letter-spacing:-.02em}
.eyebrow{font:12px/1 var(--mono);letter-spacing:.14em;text-transform:uppercase;color:var(--dim);margin:0 0 16px}
.lede{color:#c3c7cd;max-width:74ch;margin:0 0 8px}
.bar{border-top:1px solid var(--rule);border-bottom:1px solid var(--rule);padding:9px 0;margin:22px 0 30px;font:12.5px/1.5 var(--mono);color:var(--dim)}
h2{font-size:15px;margin:34px 0 4px;font-weight:600}
h2 .code{font:12px/1 var(--mono);color:var(--brass);border:1px solid var(--rule);padding:3px 6px;border-radius:3px;margin-right:9px}
.gsub{color:var(--dim);font-size:13px;margin:0 0 12px}
table{width:100%;border-collapse:collapse;font-size:13px}
th{text-align:left;font-weight:400;color:var(--dim);font-size:11.5px;text-transform:uppercase;letter-spacing:.07em;padding:6px 9px;border-bottom:1px solid var(--rule)}
td{padding:8px 9px;border-bottom:1px solid var(--rule);vertical-align:top}
.lab{font:12px/1.4 var(--mono);color:var(--brass);white-space:nowrap}
.tok{font:12.5px/1.4 var(--mono)}
.ax{font:11.5px/1.5 var(--mono);color:var(--dim)}
.ax b{color:#b9bec6;font-weight:500}
code{font:11.5px/1.5 var(--mono);background:#151922;border:1px solid var(--rule);padding:2px 5px;border-radius:3px;display:inline-block;color:#cfd4db;cursor:pointer}
code:hover{border-color:var(--brass)}
.warn{color:var(--bad);font-size:11.5px}
.hung{color:var(--ok);font-size:11.5px}
.null{color:var(--dim);font-size:11.5px}
a{color:inherit}
footer{margin-top:56px;border-top:1px solid var(--rule);padding-top:16px;color:var(--dim);font:12px/1.6 var(--mono);display:flex;justify-content:space-between;flex-wrap:wrap;gap:10px}
.mwrap{overflow-x:auto}
</style>
<div class="wrap">
<p class="eyebrow">Ada Research &middot; placement catalogue</p>
<h1>Every synthesis, labelled &mdash;<br>and what it takes to hang one.</h1>
<p class="lede">One row per work. The <b>label</b> is for referring to it; the <b>token</b> is what a
map actually writes. <b>Room max</b> is the largest hall the work survives at the 3% floor wave 23
measured &mdash; below that it photographs as a speck. A <b>cannot hang</b> flag means the axis has
numeric values and a key outside <code>CONFIG_PARAM_NAMES</code>, so <code>#axis:value</code> is read
as positional shorthand and silently sets the axis to <code>true</code> with the number as a rotation.
Click any placement string to copy it.</p>
"""]
    n_block = sum(1 for r in rows if r[5])
    n_hung = sum(1 for r in rows if r[10])
    out.append(f'<div class="bar">{len(rows)} works &middot; {len(by_gal)} collections '
               f'&middot; {n_hung} already hung &middot; {n_block} carry an axis that cannot be hung</div>')

    for gal in sorted(by_gal, key=wk):
        grp = [r for r in rows if r[2] == gal]
        code = grp[0][0]
        t = titles.get(gal, gal)
        href = f"/galleries/{gal}.html"
        out.append(f'<h2><span class="code">{esc(code)}</span>'
                   f'<a href="{href}">{t}</a></h2>')
        out.append(f'<p class="gsub">{len(grp)} work{"s" if len(grp)!=1 else ""}</p>')
        out.append('<div class="mwrap"><table><tr><th>label</th><th>token</th><th>axes &amp; values</th>'
                   '<th>placement</th><th>room max</th><th>notes</th></tr>')
        for _, lab, _, tok, axes, blocked, longest, max_span, tmpl, nulls, hg in grp:
            ax_html = "<br>".join(
                f'<b>{esc(a)}</b> {esc(" &middot; ".join(v)) if False else " &middot; ".join(esc(x) for x in v)}'
                + (' <span class="warn">&#9888; cannot hang</span>' if a in blocked else '')
                for a, v in axes.items()) or '<span class="null">none declared</span>'
            span_html = (f'{max_span}&nbsp;m' if max_span else '<span class="null">unmeasured</span>')
            notes = []
            if hg:
                notes.append('<span class="hung">hung: ' + ", ".join(
                    f'{k.replace("Museum_AAA_","")}&times;{v}' for k, v in sorted(hg.items())) + '</span>')
            if nulls:
                a, b = nulls[0]
                pa = " ".join(f"{k}:{v}" for k, v in a.items())
                pb = " ".join(f"{k}:{v}" for k, v in b.items())
                notes.append(f'<span class="null">walkable null &mdash; {esc(pa)} &equiv; {esc(pb)}'
                             + (f' (+{len(nulls)-1} more)' if len(nulls) > 1 else '') + '</span>')
            out.append(f'<tr><td class="lab">{esc(lab)}</td><td class="tok">{esc(tok)}</td>'
                       f'<td class="ax">{ax_html}</td>'
                       f'<td><code onclick="navigator.clipboard&amp;&amp;navigator.clipboard.writeText(this.textContent)">{esc(tmpl)}</code></td>'
                       f'<td class="ax">{span_html}</td><td>{"<br>".join(notes)}</td></tr>')
        out.append("</table></div>")

    out.append('<footer><span>placement catalogue</span>'
               f'<span>{len(rows)} works &middot; generated by tools/build_catalogue.py</span>'
               '<span><a href="/synthesis-gallery">&larr; all galleries</a></span></footer></div>')
    dest = GAL / "catalogue.html"
    dest.write_text("\n".join(out), encoding="utf-8")
    print(f"wrote {dest}  ({len(rows)} works, {len(by_gal)} collections, "
          f"{n_hung} hung, {n_block} with an unhangable axis)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
