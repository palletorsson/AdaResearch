#!/usr/bin/env python3
"""biome_research.py — the auto-research loop for the biome's LOOK.

The project's method (every config becomes a capture, Claude judges the images,
the weakest gets improved) applied to the whole living layer, not one mushroom
family. The gallery already renders every substrate; this ties those captures
into a weakest-first agenda + a ledger of judgments, and points each weak
specimen at the tool that can improve it.

  python tools/biome_research.py sheet          # contact sheet of every specimen
  python tools/biome_research.py agenda          # weakest-first, with the improver
  python tools/biome_research.py score --slug fungus_ca --score 4 --note "reads"
  python tools/biome_research.py summary          # biome look-health at a glance

The inventory comes from ada_encyclopedia/public/biome_gallery.json (examples +
details); judgments persist to doc/reports/biome_research.json. Unreviewed and
low-scored specimens sort to the top of the agenda — the next thing to fix.
"""
import argparse
import datetime
import glob
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia"))
MANIFEST = os.path.join(ENC, "public", "biome_gallery.json")
IMG_DIR = os.path.join(ENC, "public", "biome-gallery", "ex")
LEDGER = os.path.join(ROOT, "doc", "reports", "biome_research.json")

# which tool can improve a specimen, by token shape
def _improver(token):
    kingdom = token.split(":")[0]
    algo = (token.split(":") + ["", ""])[1]
    if kingdom == "fungus" and algo == "dna":
        return "improve_fungus.py (fd family DNA mutation)"
    if algo in ("dna", "sdf") or kingdom == "fauna":
        return "DNA/SDF morphology — mutate genes or tune the builder"
    if algo in ("ca", "mycelium"):
        return "substrate params (rule=/gen=/d=) or the CA/colony builder"
    if kingdom in ("mineral", "water", "meta"):
        return "specimen builder in GridBiomeComponent (_build_crystal/pool/glyph)"
    if algo == "scatter":
        return "halo recipe / flower preset"
    return "morphology builder"


def _inventory():
    """Every reviewable specimen: {slug, token, caption, kingdom, image, group}."""
    d = json.load(open(MANIFEST, encoding="utf-8"))
    out = {}
    for grp in ("examples", "details"):
        for e in d.get(grp, []):
            slug = e["slug"]
            out[slug] = {
                "slug": slug, "token": e.get("token", ""),
                "caption": e.get("caption", ""),
                "kingdom": e.get("kingdom") or e.get("token", "").split(":")[0],
                "group": e.get("group", grp),
                "image": e.get("image"),
            }
    return out


def _load_ledger():
    if os.path.isfile(LEDGER):
        return json.load(open(LEDGER, encoding="utf-8"))
    return {"_readme": "biome look-research judgments (tools/biome_research.py). "
            "score 1-5: 1=broken, 3=reads, 5=hero. Weakest sort to the agenda top.",
            "reviewed": {}}


def _save_ledger(led):
    os.makedirs(os.path.dirname(LEDGER), exist_ok=True)
    json.dump(led, open(LEDGER, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def cmd_agenda(_args):
    inv = _inventory()
    led = _load_ledger()["reviewed"]
    rows = []
    for slug, spec in inv.items():
        j = led.get(slug)
        score = j["score"] if j else None
        rows.append((score if score is not None else -1, slug, spec, j))
    # unreviewed (-1) first, then lowest score
    rows.sort(key=lambda r: (r[0], r[1]))
    print("BIOME RESEARCH AGENDA — weakest first (%d specimens)\n" % len(rows))
    for score, slug, spec, j in rows:
        tag = "  ? " if score < 0 else ("%d/5" % score)
        note = (" — " + j["note"]) if j and j.get("note") else ""
        print("[%s] %-24s %s" % (tag, slug, spec["token"]))
        if score < 0 or score <= 3:
            print("       improve: %s%s" % (_improver(spec["token"]), note))


def cmd_score(args):
    inv = _inventory()
    if args.slug not in inv:
        raise SystemExit("unknown slug %s (see: biome_research.py agenda)" % args.slug)
    led = _load_ledger()
    led["reviewed"][args.slug] = {
        "score": args.score, "note": args.note,
        "date": datetime.date.today().isoformat(),
    }
    _save_ledger(led)
    print("recorded %s = %d/5 — %s" % (args.slug, args.score, args.note))


def cmd_summary(_args):
    inv = _inventory()
    led = _load_ledger()["reviewed"]
    scored = [led[s]["score"] for s in inv if s in led]
    n = len(inv)
    rev = len(scored)
    print("BIOME LOOK-HEALTH")
    print("  specimens:  %d" % n)
    print("  reviewed:   %d (%d unreviewed)" % (rev, n - rev))
    if scored:
        print("  mean score: %.2f/5" % (sum(scored) / len(scored)))
        for band, lo, hi in [("hero 5", 5, 5), ("good 4", 4, 4), ("reads 3", 3, 3), ("weak 1-2", 1, 2)]:
            c = sum(1 for s in scored if lo <= s <= hi)
            print("   %-9s %d" % (band, c))
    weakest = sorted((led[s]["score"], s) for s in inv if s in led)[:3]
    if weakest:
        print("  weakest reviewed: %s" % ", ".join("%s(%d)" % (s, sc) for sc, s in weakest))


def cmd_sheet(args):
    from PIL import Image, ImageDraw
    inv = _inventory()
    items = [(s, sp) for s, sp in inv.items()
             if sp["image"] and os.path.isfile(os.path.join(IMG_DIR, sp["slug"] + ".png"))]
    items.sort(key=lambda x: (x[1]["kingdom"], x[0]))
    if not items:
        raise SystemExit("no specimen images found — capture the gallery first")
    cell, cols = 300, 5
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell, rows * cell), (10, 11, 16))
    dr = ImageDraw.Draw(sheet)
    for i, (slug, sp) in enumerate(items):
        im = Image.open(os.path.join(IMG_DIR, slug + ".png")).convert("RGB")
        w, h = im.size
        im = im.crop((int(w * 0.28), int(h * 0.5), int(w * 0.72), int(h * 0.92))).resize((cell, cell), Image.LANCZOS)
        x, y = (i % cols) * cell, (i // cols) * cell
        sheet.paste(im, (x, y))
        dr.rectangle([x, y, x + cell - 1, y + cell - 1], outline=(60, 60, 70))
        dr.text((x + 5, y + 5), slug, fill=(230, 230, 120))
    out = args.out or os.path.join(ROOT, "doc", "reports", "biome_research_sheet.png")
    sheet.save(out)
    print("contact sheet: %s (%d specimens)" % (out, len(items)))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("agenda")
    sub.add_parser("summary")
    p = sub.add_parser("score"); p.add_argument("--slug", required=True)
    p.add_argument("--score", type=int, required=True, choices=range(1, 6))
    p.add_argument("--note", default="")
    q = sub.add_parser("sheet"); q.add_argument("--out", default="")
    args = ap.parse_args()
    {"agenda": cmd_agenda, "score": cmd_score, "summary": cmd_summary, "sheet": cmd_sheet}[args.cmd](args)


if __name__ == "__main__":
    main()
