#!/usr/bin/env python3
"""The visual memory atlas (handover 2026-10-24, § 6 and slice D).

One image, 8–20 symbols: each a thumbnail (the game's own capture of the mod_ token), its
name, its definition in the grammar's notation, and arrows to the symbols it is built from.
Mode B — a self-contained capsule: everything a reader needs is drawn into the pixels (names,
definitions, the legend of operators); no sidecar is assumed. The canonical AST is written
beside it as JSON so a BLIND decode (a model given the image only) can be scored against it.

    python tools/visual_memory_atlas.py                       # ada_run/visual_memory/atlas.png + canonical.json
    python tools/visual_memory_atlas.py --symbols a,b,c       # choose the symbols
    python tools/visual_memory_atlas.py --score decoded.json  # compare a blind decode with the canonical

Score: per symbol, the name recovered; the set of parents (what it is built from); the
operator at the root of its definition; the counts in it (n of times / array). Reported as
hits over expected, never as a single number without its parts.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ENC = ROOT.parent / "ada_encyclopedia"
TERMS = ROOT / "commons/modular/terms.json"
CAPTURES = ENC / "public/artifact-gallery/captures"
SYMBOL_ICONS = ENC / "public/book-images/live-update"
OUT_DIR = ROOT / "ada_run/visual_memory"

DEFAULT = ["point", "sphere_collider", "grab_sphere", "line", "tape", "plank", "triangle", "quad", "cube",
           "wooden_box", "skateboard", "eu_pallet", "tied_pallet", "tilt_gate", "pallet_sorted", "grid"]

BY_KINDS = {"sine", "sine_field", "noise", "random"}


def to_text(e: dict) -> str:
    """the notation of MODULAR_SPINE_TEXT.md, from a build expression"""
    if not e:
        return "·"
    if "t" in e:
        return str(e["t"])
    if e.get("p") == "prefab":
        return f"[{e.get('token', '?')}]"
    if "p" in e:
        return str(e["p"]) + (f"({e['shape']})" if e.get("shape") else "")
    op = e.get("op", "")
    of = lambda: to_text(e.get("of", {}))  # noqa: E731
    if op == "compose":
        parts = [to_text(p) for p in e.get("parts", [])]
        folded, i = [], 0
        while i < len(parts):   # a run of identical parts reads as (part) * n
            j = i
            while j < len(parts) and parts[j] == parts[i]:
                j += 1
            folded.append(f"({parts[i]}) * {j - i}" if j - i > 1 else parts[i])
            i = j
        return " + ".join(f"({p})" if " + " in p and not p.startswith("(") else p for p in folded) or "·"
    if op == "assemblage":
        return "assemblage(" + ", ".join(to_text(p.get("of", p)) for p in e.get("parts", [])) + ")"
    dress = (f", palette {'/'.join(str(c)[:6] for c in e['palette'])}{' by ' + e['palette_by'] if e.get('palette_by') else ''}" if e.get("palette") else "") \
        + (f", profile {e['profile']}" if e.get("profile") else "") + (f" rise {e['rise']}" if e.get("rise") is not None else "")
    if op == "times":
        lay = f" {e['layout']}" if e.get("layout") in ("circle", "phyllotaxis") else ""
        if e.get("layout") == "circle" and e.get("arc") not in (None, 360):
            lay += f" {e['arc']}°"
        return f"({of()}) * {e.get('n', 1)}{lay}{dress}"
    if op == "recurse":
        return (f"recurse({of()}, {len(e.get('rules', []))} copies, depth {e.get('depth', 3)}"
                f"{', keep seed' if e.get('keep') == 'seed' else ''}{', every generation' if e.get('stack') else ''})")
    if op == "rewrite":
        rules = "; ".join(f"{k} → {v}" for k, v in (e.get("rules") or {}).items())
        return f"rewrite({e.get('axiom', 'F')}: {rules}, {e.get('depth', 3)}, {e.get('angle', 25)}°)"
    if op == "array":
        inside = ", inside a field" if e.get("inside") else ""   # centre-based voxel sampling
        return f"array({of()}, {e.get('n', 3)}{', ' + str(e['dims']) + 'd' if e.get('dims', 2) != 2 else ''}{dress}{inside})"
    if op == "exhibit":
        return f"exhibit({of()})"
    if op == "field":   # a surface where a function of space crosses zero
        def fn(f):
            for k in ("union", "intersect", "smooth_union"):
                if k in f:
                    return f"{k.replace('smooth_union', 'smooth union')}({', '.join(fn(g) for g in f[k])})"
            if "subtract" in f:
                body, cutter = f["subtract"]
                return f"{fn(body)} − {fn(cutter)}{' smooth' if f.get('k') else ''}"
            return next((k for k in ("sphere", "box", "torus", "cylinder", "gyroid", "metaballs", "terrain", "blobs", "plane") if k in f), "?")
        return f"field({fn(e.get('fn', {}))}){' + ground' if e.get('collide') else ''}"
    if op == "associate":
        return f"association({of()}{', ' + e['surface'] if e.get('surface') else ''})"
    if op == "transform":
        bits = []
        if any(e.get("at", [])):
            bits.append("at " + ",".join(str(v) for v in e["at"]))
        if any(e.get("rot", [])):
            bits.append("rot " + ",".join(str(v) for v in e["rot"]))
        if e.get("scale") not in (None, 1):
            bits.append(f"scale {e['scale']}")
        return f"transform({of()}{', ' + ' '.join(bits) if bits else ''})"
    if op == "engine" and e.get("kind") == "tween":   # the transform's time domain
        bits = [f"{k} {','.join(str(v) for v in e[k]) if isinstance(e[k], list) else e[k]}" for k in ("at", "rot", "scale") if e.get(k) not in (None, 1)]
        return f"tween({of()}, {' '.join(bits)}, every {e.get('period', 4)} s)"
    if op == "engine" and e.get("kind") == "random" and e.get("keep") is not None:   # a draw that removes
        return f"by({of()}, random keep {e['keep']})"
    if op == "engine" and e.get("kind") == "random" and e.get("angles"):   # a choice among a few turns
        return f"by({of()}, random among {'/'.join(str(a) for a in e['angles'])}°)"
    if op == "engine" and e.get("kind") == "trail":   # stigmergy: agents that write the field they read
        bits = [f"agents {e.get('agents', 80)}", f"evaporate {e.get('evaporate', 0.05)}"] + (["two channels"] if e.get("channels") == 2 else [])
        bits += ([f"{len(e['anchors'])} anchors"] if e.get("anchors") else []) + (["follow 0"] if e.get("follow") == 0 else [])
        return f"trail({of()}, {', '.join(bits)})"
    if op == "engine":
        return f"{'by' if e.get('kind') in BY_KINDS else 'step'}({of()}, {e.get('kind')})"
    if op == "sort":
        return f"sort({of()}, by {e.get('by', 'size')})"
    if op == "connect":
        ties = e.get("ties") or [[e.get("a", 0), e.get("b", 1), e.get("kind", "rope")]]
        return f"connect({of()}, " + ", ".join(f"{t[0]}–{t[1]} {t[2] if len(t) > 2 else 'rope'}" for t in ties) + ")"
    return "?"


def canonical(symbols: list[str]) -> dict:
    doc = json.loads(TERMS.read_text(encoding="utf-8"))["terms"]
    out = {}
    for s in symbols:
        t = doc.get(s)
        if not t:
            continue
        b = t["build"]
        parents = sorted(set(x for x in t.get("from", []) if x in doc))
        root_op = b.get("op") or ("term" if "t" in b else b.get("p", "?"))
        counts = sorted(set(re.findall(r"\* (\d+)|array\([^,]+, (\d+)", to_text(b))))
        counts = sorted({int(v) for pair in counts for v in pair if v})
        out[s] = {"text": to_text(b), "parents": parents, "root_op": root_op, "counts": counts, "chapter": t.get("chapter", "")}
    return out


def render(symbols: list[str], out_dir: Path, pictures_only: bool = False) -> Path:
    from PIL import Image, ImageDraw, ImageFont
    canon = canonical(symbols)
    names = [s for s in symbols if s in canon]
    cols, cell_w, cell_h = 4, 420, 360
    rows = (len(names) + cols - 1) // cols
    W, H = cols * cell_w + 40, rows * cell_h + 220
    paper, ink, violet = (243, 236, 221), (43, 29, 20), (122, 75, 138)
    img = Image.new("RGB", (W, H), paper)
    d = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 18)
        bold = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 22)
        small = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 15)
        title = ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", 30)
    except OSError:
        font = bold = small = title = ImageFont.load_default()
    d.text((20, 16), "Ada Research · the grammar · a visual memory capsule", fill=ink, font=title)
    d.text((20, 58), "Each tile: a symbol's picture, its NAME, and its DEFINITION in the grammar. A name in a definition is another tile. "
           "Arrows run from a symbol to what it is built from.", fill=ink, font=small)
    d.text((20, 80), "Notation: a + b compose · (a) * n times · array(a, n) addresses · association(a, surface) a surface laid on · "
           "transform(a, …) moved/turned/scaled · step(a, rule) a rule from the neighbours · sort(a, by …) parts in a row by a reading · "
           "connect(a, i–j kind) a tie", fill=ink, font=small)
    pos = {}
    for i, s in enumerate(names):
        r, c = divmod(i, cols)
        x, y = 20 + c * cell_w, 130 + r * cell_h
        pos[s] = (x, y)
    # arrows first, from each tile's "= name" corner to its parents' bottom edge, so the
    # tiles' words are drawn over them and stay legible
    for s in (names if not pictures_only else []):
        x, y = pos[s]
        for pnt in canon[s]["parents"]:
            if pnt in pos:
                px, py = pos[pnt]
                d.line([(x + 60, y + 240), (px + 60, py + cell_h - 24)], fill=(205, 190, 215), width=3)
                d.ellipse([px + 54, py + cell_h - 30, px + 66, py + cell_h - 18], fill=violet)
    for s in names:
        x, y = pos[s]
        d.rectangle([x, y, x + cell_w - 16, y + cell_h - 16], outline=(185, 176, 160), width=2, fill=(247, 242, 230))
        icon = None
        for cand in (CAPTURES / f"mod_{s}" / "front.png", SYMBOL_ICONS / f"symbol-{s}.png"):
            if cand.exists():
                icon = Image.open(cand).convert("RGB")
                break
        if icon is not None:
            side = min(icon.size)
            icon = icon.crop(((icon.width - side) // 2, (icon.height - side) // 2, (icon.width + side) // 2, (icon.height + side) // 2)).resize((150, 150))
            img.paste(icon, (x + 12, y + 12))
        else:
            d.rectangle([x + 12, y + 12, x + 162, y + 162], outline=(185, 176, 160), width=1)
            d.text((x + 40, y + 78), "no picture", fill=(140, 130, 115), font=small)
        if pictures_only:
            d.text((x + 176, y + 14), f"tile {names.index(s) + 1}", fill=ink, font=bold)
            continue
        d.text((x + 176, y + 14), s, fill=ink, font=bold)
        d.text((x + 176, y + 44), canon[s]["chapter"], fill=(140, 130, 115), font=small)
        # the definition, wrapped
        text = canon[s]["text"]
        words, lines, cur = text.split(" "), [], ""
        for w in words:
            if len(cur) + len(w) + 1 > 28:
                lines.append(cur); cur = w
            else:
                cur = (cur + " " + w).strip()
        if cur:
            lines.append(cur)
        for k, ln in enumerate(lines[:11]):
            d.text((x + 176, y + 72 + k * 19), ln, fill=ink, font=small)
        if len(lines) > 11:
            d.text((x + 176, y + 72 + 11 * 19), "…", fill=ink, font=small)
        d.text((x + 12, y + 172), "= " + s if not pictures_only else "= ?", fill=violet, font=bold)
        if not pictures_only:
            d.text((x + 12, y + 202), "from: " + (", ".join(canon[s]["parents"]) or "—"), fill=(90, 61, 44), font=small)
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / ("atlas_pictures.png" if pictures_only else "atlas.png")
    img.save(out)
    if not pictures_only:
        (out_dir / "canonical.json").write_text(json.dumps({"symbols": names, "canonical": canon}, indent=1), encoding="utf-8")
    return out


def score(decoded: dict, canon: dict) -> dict:
    """decoded: {symbol: {text?, parents?, root_op?, counts?}} — as a blind reader wrote it"""
    rows, hits = [], {"name": 0, "parents": 0, "root_op": 0, "counts": 0}
    for s, c in canon.items():
        dcd = decoded.get(s)
        row = {"symbol": s, "name": bool(dcd)}
        if dcd:
            hits["name"] += 1
            dp = set(dcd.get("parents", [])); cp = set(c["parents"])
            row["parents"] = f"{len(dp & cp)}/{len(cp)}" + (f" +{len(dp - cp)} extra" if dp - cp else "")
            hits["parents"] += 1 if dp == cp else 0
            ro = str(dcd.get("root_op", "")).lower()
            row["root_op"] = ro == c["root_op"] or (ro in ("by", "step") and c["root_op"] == "engine")
            hits["root_op"] += 1 if row["root_op"] else 0
            dc = sorted({int(v) for v in dcd.get("counts", []) if str(v).isdigit()})
            row["counts"] = dc == c["counts"]
            hits["counts"] += 1 if row["counts"] else 0
        rows.append(row)
    n = len(canon)
    return {"expected": n, "hits": hits, "rows": rows, "extra_symbols": sorted(set(decoded) - set(canon))}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--symbols", default=",".join(DEFAULT))
    ap.add_argument("--out", default=str(OUT_DIR))
    ap.add_argument("--score", help="a blind decode (JSON) to compare with the canonical")
    ap.add_argument("--pictures", action="store_true", help="names and definitions hidden: what do the thumbnails alone carry?")
    a = ap.parse_args()
    symbols = [s.strip() for s in a.symbols.split(",") if s.strip()]
    out_dir = Path(a.out)
    if a.score:
        canon = json.loads((out_dir / "canonical.json").read_text(encoding="utf-8"))["canonical"]
        decoded = json.loads(Path(a.score).read_text(encoding="utf-8"))
        res = score(decoded, canon)
        (out_dir / "score.json").write_text(json.dumps(res, indent=1), encoding="utf-8")
        h = res["hits"]
        print(f"blind decode vs canonical — {res['expected']} symbols: names {h['name']}, parents exact {h['parents']}, "
              f"root operator {h['root_op']}, counts {h['counts']}; extra symbols {len(res['extra_symbols'])}")
        for r in res["rows"]:
            print("  ", r)
        return 0
    out = render(symbols, out_dir, pictures_only=a.pictures)
    print(f"wrote {out} + canonical.json — {len(symbols)} symbols")
    return 0


if __name__ == "__main__":
    sys.exit(main())
