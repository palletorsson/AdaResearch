#!/usr/bin/env python3
"""biome_research.py — the auto-research loop for the biome's LOOK.

The project's method (every config becomes a capture, Claude judges the images,
the weakest gets improved) applied to the whole living layer, not one mushroom
family. The gallery already renders every substrate; this ties those captures
into a weakest-first agenda + a ledger of judgments, and points each weak
specimen at the tool that can improve it.

TWO dimensions, both persisting to doc/reports/biome_research.json:

  SPECIMEN — each token alone on a bare stage (does it read in isolation):
    python tools/biome_research.py sheet | agenda | summary
    python tools/biome_research.py score --slug fungus_ca --score 4 --note "reads"

  IN-SITU — the layer in a REAL map, at density, in context (does it make the
  scene better — the question the specimen pass structurally cannot answer):
    python tools/biome_research.py capture           # render the curated maps in context
    python tools/biome_research.py sheet --in-situ    # contact sheet of the maps
    python tools/biome_research.py agenda --in-situ
    python tools/biome_research.py score --map Chamber_CA --score 4 --note "..."
    python tools/biome_research.py summary --in-situ

Specimen inventory is ada_encyclopedia/public/biome_gallery.json; in-situ is the
curated IN_SITU_MAPS. Cost (probe_biome_cost.gd) is the third axis, folded into
the specimen agenda. Unreviewed / low-scored items sort to the agenda top.
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
COST = os.path.join(ROOT, "doc", "reports", "biome_cost.json")  # probe_biome_cost.gd output
COST_WARN_MS = 100.0   # a specimen slower than this is a latent map-load freeze

# ── IN-SITU: the biome in a REAL map, at density, in context. The specimen pass
# judges each token alone on a bare stage; this judges whether the living layer
# makes an actual scene better. Curated authored maps only — test/gallery
# scaffolding (Biome_*Test, Biome_Gallery_*, Trial_*) is excluded on purpose.
IN_SITU_MAPS = [
    "Chamber_CA", "Chamber_LSystems", "Chamber_SoftBodies",
    "Chamber_Random", "Chamber_Noise",
    "LSystems_Growth_BiomeCompiled", "Biome_VisualBench", "TemplateMap_BiomeAuth",
]
IN_SITU_DIR = os.path.join(ROOT, "doc", "reports", "biome_in_situ")
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
SHOTS_ROOT = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata",
                          "Ada Research Zero One", "multi_shots")


def _biome_tokens(map_name):
    """The distinct biome tokens a map declares (for context in the agenda)."""
    p = os.path.join(MAPS_DIR, map_name, "map_data.json")
    if not os.path.isfile(p):
        return [], 0
    b = json.load(open(p, encoding="utf-8")).get("layers", {}).get("biome")
    if not b:
        return [], 0
    rows = b.get("rows", b) if isinstance(b, dict) else b
    toks = set()
    n = 0
    for row in rows:
        for c in row:
            if isinstance(c, str) and c.strip():
                n += 1
                toks.add(c.split(":")[0] + ":" + (c.split(":") + ["", ""])[1])
    return sorted(toks), n


def _in_situ_inventory():
    """map_name -> {kingdoms/algos it uses, cell count, capture path}."""
    out = {}
    for m in IN_SITU_MAPS:
        toks, n = _biome_tokens(m)
        img = os.path.join(IN_SITU_DIR, m + ".png")
        out[m] = {"map": m, "tokens": toks, "cells": n,
                  "image": img if os.path.isfile(img) else None}
    return out


def _costs():
    """slug -> build_ms, from probe_biome_cost.gd. Empty if never run."""
    if not os.path.isfile(COST):
        return {}
    d = json.load(open(COST, encoding="utf-8"))
    return {s: v.get("build_ms") for s, v in d.get("specimens", {}).items()}

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
        d = json.load(open(LEDGER, encoding="utf-8"))
        d.setdefault("in_situ", {})   # the second dimension: the biome in real maps
        return d
    return {"_readme": "biome look-research judgments (tools/biome_research.py). "
            "score 1-5: 1=broken, 3=reads, 5=hero. Weakest sort to the agenda top. "
            "reviewed = specimens alone on a stage; in_situ = the layer in real maps.",
            "reviewed": {}, "in_situ": {}}


def _save_ledger(led):
    os.makedirs(os.path.dirname(LEDGER), exist_ok=True)
    json.dump(led, open(LEDGER, "w", encoding="utf-8"), indent=1, ensure_ascii=False)


def cmd_agenda(_args):
    inv = _inventory()
    led = _load_ledger()["reviewed"]
    costs = _costs()
    rows = []
    for slug, spec in inv.items():
        j = led.get(slug)
        score = j["score"] if j else None
        # priority: a costly specimen (latent freeze) OR a weak/unreviewed one
        ms = costs.get(slug)
        cost_bad = ms is not None and ms > COST_WARN_MS
        rows.append((score if score is not None else -1, slug, spec, j, ms, cost_bad))
    # unreviewed (-1) first, then lowest score; costly ones flagged inline
    rows.sort(key=lambda r: (r[0], r[1]))
    print("BIOME RESEARCH AGENDA — weakest first (%d specimens)" % len(rows))
    if costs:
        slow = sorted(((costs[s], s) for s in costs if costs[s] > COST_WARN_MS), reverse=True)
        if slow:
            print("COST WATCH (build > %dms — latent map-load freeze):" % COST_WARN_MS)
            for ms, s in slow:
                print("   %-20s %.0f ms  -> %s" % (s, ms, _improver(inv.get(s, {}).get("token", ""))))
    print()
    for score, slug, spec, j, ms, cost_bad in rows:
        tag = "  ? " if score < 0 else ("%d/5" % score)
        cflag = (" [%.0fms!]" % ms) if cost_bad else (" [%.0fms]" % ms if ms is not None else "")
        note = (" — " + j["note"]) if j and j.get("note") else ""
        print("[%s]%s %-24s %s" % (tag, cflag, slug, spec["token"]))
        if score < 0 or score <= 3 or cost_bad:
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
    costs = _costs()
    if costs:
        slow = [(costs[s], s) for s in costs if costs[s] and costs[s] > COST_WARN_MS]
        print("  COST: %d measured, %d over %dms%s" % (
            len(costs), len(slow), COST_WARN_MS,
            (" (%s)" % ", ".join("%s %.0fms" % (s, ms) for ms, s in sorted(slow, reverse=True))) if slow else ""))
    else:
        print("  COST: not measured — run probe_biome_cost.gd (look-health is only half the story)")


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


# ── IN-SITU command handlers (the biome in real maps) ──

def cmd_capture(args):
    """Render each curated biome map IN CONTEXT (no disable_biome — the living
    layer as authored) and copy its iso shot to the research dir. Serialized
    under the watchdog; a map that hangs (simulation artifacts) is skipped."""
    import shutil
    import subprocess
    import sys
    only = set(m.strip() for m in args.only.split(",")) if args.only else None
    todo = [m for m in IN_SITU_MAPS if not only or m in only]
    os.makedirs(IN_SITU_DIR, exist_ok=True)
    watchdog = os.path.join(ROOT, "tools", "godot_watchdog.py")
    ok = 0
    for i, m in enumerate(todo, 1):
        shots = os.path.join(SHOTS_ROOT, m)
        if os.path.isdir(shots):
            shutil.rmtree(shots, ignore_errors=True)
        print("[%d/%d] capturing %s ..." % (i, len(todo), m))
        cmd = [sys.executable, watchdog, "--grace=60", "--stall=25",
               "--expect=" + os.path.join(shots, "capture_report.json"), "--",
               GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
               "--script", "res://commons/testing/capture_multi_angle.gd", "--",
               "--mode=map", "--target=" + m]
        subprocess.run(cmd, cwd=ROOT)
        src = os.path.join(shots, "iso.png")
        if os.path.isfile(src):
            shutil.copyfile(src, os.path.join(IN_SITU_DIR, m + ".png"))
            ok += 1
            print("   ok -> %s.png" % m)
        else:
            print("   MISS (no iso — hang or load fail)")
    print("%d/%d in-situ maps captured -> %s" % (ok, len(todo), IN_SITU_DIR))


def cmd_insitu_agenda(_args):
    inv = _in_situ_inventory()
    led = _load_ledger()["in_situ"]
    rows = []
    for m, spec in inv.items():
        j = led.get(m)
        rows.append((j["score"] if j else -1, m, spec, j))
    rows.sort(key=lambda r: (r[0], r[1]))
    n_shot = sum(1 for _, sp in inv.items() if sp["image"])
    print("BIOME IN-SITU AGENDA — weakest first (%d maps, %d captured)\n" % (len(rows), n_shot))
    for score, m, spec, j in rows:
        tag = "  ? " if score < 0 else ("%d/5" % score)
        shot = "" if spec["image"] else " (not captured)"
        note = (" — " + j["note"]) if j and j.get("note") else ""
        print("[%s] %-30s %d cells  %s%s" % (tag, m, spec["cells"], ",".join(spec["tokens"]), shot))
        if note:
            print("       %s" % note.strip(" —"))


def cmd_insitu_score(args):
    inv = _in_situ_inventory()
    if args.map not in inv:
        raise SystemExit("unknown map %s (in-situ set: %s)" % (args.map, ", ".join(IN_SITU_MAPS)))
    led = _load_ledger()
    led["in_situ"][args.map] = {"score": args.score, "note": args.note,
                                "date": datetime.date.today().isoformat()}
    _save_ledger(led)
    print("recorded in-situ %s = %d/5 — %s" % (args.map, args.score, args.note))


def cmd_insitu_summary(_args):
    inv = _in_situ_inventory()
    led = _load_ledger()["in_situ"]
    scored = [led[m]["score"] for m in inv if m in led]
    print("BIOME IN-SITU HEALTH (the layer in real maps)")
    print("  maps:      %d" % len(inv))
    print("  captured:  %d" % sum(1 for _, sp in inv.items() if sp["image"]))
    print("  reviewed:  %d" % len(scored))
    if scored:
        print("  mean:      %.2f/5" % (sum(scored) / len(scored)))
        weak = sorted((led[m]["score"], m) for m in inv if m in led)[:3]
        print("  weakest:   %s" % ", ".join("%s(%d)" % (m, sc) for sc, m in weak))


def cmd_insitu_sheet(args):
    from PIL import Image, ImageDraw
    inv = _in_situ_inventory()
    items = [(m, sp) for m, sp in inv.items() if sp["image"]]
    if not items:
        raise SystemExit("no in-situ captures — run: biome_research.py capture")
    cell, cols = 420, 3
    rows = (len(items) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell, rows * cell), (10, 11, 16))
    dr = ImageDraw.Draw(sheet)
    for i, (m, sp) in enumerate(items):
        im = Image.open(sp["image"]).convert("RGB")
        w, h = im.size
        im = im.crop((int(w * 0.12), int(h * 0.28), int(w * 0.88), int(h * 0.92))).resize((cell, cell), Image.LANCZOS)
        x, y = (i % cols) * cell, (i // cols) * cell
        sheet.paste(im, (x, y))
        dr.rectangle([x, y, x + cell - 1, y + cell - 1], outline=(60, 60, 70))
        dr.text((x + 6, y + 6), m, fill=(230, 230, 120))
    out = args.out or os.path.join(ROOT, "doc", "reports", "biome_in_situ_sheet.png")
    sheet.save(out)
    print("in-situ sheet: %s (%d maps)" % (out, len(items)))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("agenda"); a.add_argument("--in-situ", action="store_true", dest="in_situ")
    s = sub.add_parser("summary"); s.add_argument("--in-situ", action="store_true", dest="in_situ")
    p = sub.add_parser("score")
    p.add_argument("--slug"); p.add_argument("--map")
    p.add_argument("--score", type=int, required=True, choices=range(1, 6))
    p.add_argument("--note", default="")
    q = sub.add_parser("sheet"); q.add_argument("--out", default="")
    q.add_argument("--in-situ", action="store_true", dest="in_situ")
    c = sub.add_parser("capture"); c.add_argument("--only", default="")  # in-situ only
    args = ap.parse_args()
    if args.cmd == "capture":
        cmd_capture(args)
    elif args.cmd == "score":
        (cmd_insitu_score if args.map else cmd_score)(args)
    elif getattr(args, "in_situ", False):
        {"agenda": cmd_insitu_agenda, "summary": cmd_insitu_summary, "sheet": cmd_insitu_sheet}[args.cmd](args)
    else:
        {"agenda": cmd_agenda, "summary": cmd_summary, "sheet": cmd_sheet}[args.cmd](args)


if __name__ == "__main__":
    main()
