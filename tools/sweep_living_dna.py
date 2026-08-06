#!/usr/bin/env python3
"""sweep_living_dna.py — the second half of the DNA loop, for living things.

promote_living_dna.py declared the axes. This SWEEPS them: one capture per
variant, exactly the artifact loop's contract (per-variant PNGs + a manifest
the gallery reads + a bite verdict), so a declared axis has to prove it
actually changes the picture instead of being a claim in a registry.

The artifact sweep drives a scene's @export vars. A living specimen has none —
it is a grammar token — so this sweep writes the TOKEN for each variant onto
the scratch stage and captures it. Same evidence, different knob.

  python tools/sweep_living_dna.py --list
  python tools/sweep_living_dna.py --token living_fungus_fruit     # one specimen
  python tools/sweep_living_dna.py --all                            # every specimen
  python tools/sweep_living_dna.py --critic                         # bite verdicts

Output: ada_encyclopedia/public/living-dna/<token>/<variant>.png + manifest.json
"""
import argparse
import itertools
import json
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY = os.path.join(ROOT, "commons", "artifacts", "registry", "living.json")
ENC = os.path.normpath(os.path.join(ROOT, "..", "ada_encyclopedia"))
OUT_ROOT = os.path.join(ENC, "public", "living-dna")
STAGE = "Biome_Ex_Stage"
STAGE_DIR = os.path.join(ROOT, "commons", "maps", STAGE)
SHOTS = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata",
                     "Ada Research Zero One", "multi_shots", STAGE)
GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
N = 5   # stage size


def _specimens():
    d = json.load(open(REGISTRY, encoding="utf-8"))
    return d["artifacts"]


def _variants(spec):
    """Every combination of the declared axes -> (label, {axis: value})."""
    axes = spec["dna"]["axes"]
    names = list(axes.keys())
    for combo in itertools.product(*[axes[n] for n in names]):
        vals = dict(zip(names, combo))
        label = "__".join("%s-%s" % (n, vals[n]) for n in names)
        yield label, vals


def _token_for(spec, vals):
    """Render the biome grammar token for one variant. The axis NAME decides
    where its value lands in the token — algo/role are positional, family and
    pose are mods (fd=/sf=), tier is t=."""
    base = spec["biome_token"]           # e.g. "fungus:dna:seed" or "fungus:<algo>:seed"
    kingdom, algo, role = (base.split(":") + ["", "", ""])[:3]
    mods = []
    for axis, val in vals.items():
        if axis == "algo":
            algo = val
        elif axis == "role":
            role = val
        elif axis == "tier":
            mods.append("t=" + val)
        elif axis == "family":
            mods.append("fd=" + val)
        elif axis == "pose":
            mods.append("sf=" + val)
    if kingdom.startswith("<"):
        kingdom = "flora"
    if algo.startswith("<") or not algo:
        algo = "scatter"
    if role.startswith("<") or not role:
        role = "seed"
    return ":".join([kingdom, algo, role] + mods)


def _write_stage(token):
    structure = [["1"] * N for _ in range(N)]
    utilities = [[""] * N for _ in range(N)]
    utilities[N - 1][N - 1] = "sp"
    biome = [[""] * N for _ in range(N)]
    # A halo/edge role must sit on the RIM to express itself: an interior halo
    # cell has no outward direction, so GridBiomeComponent falls back to the
    # pilot marker and the sweep photographs a green CUBE instead of the
    # wilderness spill. The role is the 3rd positional field and a token may end
    # there (flora:scatter:halo) or carry mods after it — so parse the field.
    # The old check was `":halo:" in token`, which never fired on a token that
    # ENDS in the role: a harness bug that made a real axis look like a marker.
    parts = token.split(":")
    role = parts[2] if len(parts) > 2 else "seed"
    if role in ("halo", "edge"):
        biome[0][N // 2] = token
    else:
        biome[N // 2][N // 2] = token
    m = {"map_info": {"name": STAGE, "title": STAGE,
                      "description": "living DNA sweep: %s" % token,
                      "dimensions": {"width": N, "depth": N}},
         "layers": {"structure": structure, "utilities": utilities,
                    "interactables": [[""] * N for _ in range(N)], "biome": biome},
         "settings": {"disable_biome": True,
                      "background": {"color": [0.05, 0.06, 0.1], "type": "sky"}}}
    os.makedirs(STAGE_DIR, exist_ok=True)
    json.dump(m, open(os.path.join(STAGE_DIR, "map_data.json"), "w", encoding="utf-8"), indent=1)


def _capture(dest_png):
    if os.path.isdir(SHOTS):
        shutil.rmtree(SHOTS, ignore_errors=True)
    cmd = [sys.executable, os.path.join(ROOT, "tools", "godot_watchdog.py"),
           "--grace=60", "--stall=25",
           "--expect=" + os.path.join(SHOTS, "capture_report.json"), "--",
           GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/capture_multi_angle.gd", "--",
           "--mode=map", "--target=" + STAGE]
    subprocess.run(cmd, cwd=ROOT, capture_output=True)
    src = os.path.join(SHOTS, "iso.png")
    if not os.path.isfile(src):
        return False
    # DEAD-FRAME GUARD. Two Godot instances cannot run at once (the second dies
    # on the user:// lock) and this sweep shares ONE scratch stage map, so any
    # concurrent capture — a manual shot, another sweep — silently produces
    # black frames. Seven were published that way before this check existed.
    # A frame with no bright pixel is not evidence; refuse it and say so.
    try:
        from PIL import Image
        if Image.open(src).convert("L").getextrema()[1] < 40:
            print("      DEAD FRAME (black) — is another Godot / sweep running?")
            return False
    except Exception:
        pass
    shutil.copyfile(src, dest_png)
    return True


def cmd_list():
    total = 0
    for tok, spec in _specimens().items():
        n = sum(1 for _ in _variants(spec))
        total += n
        print("%-22s %-26s %3d variants" % (tok, spec["biome_token"], n))
    print("TOTAL %d variants" % total)


def sweep_one(tok, spec):
    out_dir = os.path.join(OUT_ROOT, tok)
    os.makedirs(out_dir, exist_ok=True)
    entries = []
    variants = list(_variants(spec))
    print("%s — %d variants" % (tok, len(variants)))
    for i, (label, vals) in enumerate(variants, 1):
        token = _token_for(spec, vals)
        png = os.path.join(out_dir, label + ".png")
        _write_stage(token)
        ok = _capture(png)
        print("  [%d/%d] %-34s %s %s" % (i, len(variants), label, token, "" if ok else "MISS"))
        entries.append({"variant": label, "values": vals, "token": token,
                        "image": "/living-dna/%s/%s.png" % (tok, label) if ok else None})
    man = {"token": tok, "biome_token": spec["biome_token"],
           "description": spec.get("description", ""),
           "axes": spec["dna"]["axes"], "note": spec["dna"].get("note", ""),
           "derived_from": spec["dna"].get("derived_from", ""),
           "variants": entries}
    json.dump(man, open(os.path.join(out_dir, "manifest.json"), "w", encoding="utf-8"),
              indent=1, ensure_ascii=False)
    return sum(1 for e in entries if e["image"]), len(entries)


def _write_gallery_manifest():
    """ONE manifest in the shape GalleryView reads (/public/<slug>/manifest.json
    with entries[{id,image,notes,config}]) so the living specimens appear in the
    same component as every other DNA gallery — not a bespoke page."""
    entries = []
    for tok in sorted(os.listdir(OUT_ROOT)):
        p = os.path.join(OUT_ROOT, tok, "manifest.json")
        if not os.path.isfile(p):
            continue
        man = json.load(open(p, encoding="utf-8"))
        for e in man["variants"]:
            if not e["image"]:
                continue
            vals = ", ".join("%s=%s" % (k, v) for k, v in e["values"].items())
            entries.append({
                "id": "%s / %s" % (tok, vals),
                "image": e["image"],
                "config": e["token"],
                "notes": "%s — %s" % (man.get("description", tok), man.get("note", "")),
            })
    out = {"version": 1,
           "description": "Living DNA — the biome's organisms swept across their "
                          "declared axes. Each frame is one grammar token on the bare "
                          "stage; the axes are derived from the grammar parser, the "
                          "dispatcher's algo branches and the preset families on disk.",
           "entries": entries}
    json.dump(out, open(os.path.join(OUT_ROOT, "manifest.json"), "w", encoding="utf-8"),
              indent=1, ensure_ascii=False)
    print("gallery manifest: %d entries -> /living-dna/manifest.json" % len(entries))


def cmd_sweep(args):
    specs = _specimens()
    todo = {args.token: specs[args.token]} if args.token else specs
    if args.token and args.token not in specs:
        raise SystemExit("unknown specimen %s" % args.token)
    ok = n = 0
    for tok, spec in todo.items():
        a, b = sweep_one(tok, spec)
        ok += a
        n += b
    # index for the gallery page
    os.makedirs(OUT_ROOT, exist_ok=True)
    idx = sorted(d for d in os.listdir(OUT_ROOT)
                 if os.path.isdir(os.path.join(OUT_ROOT, d))
                 and os.path.isfile(os.path.join(OUT_ROOT, d, "manifest.json")))
    json.dump({"specimens": idx}, open(os.path.join(OUT_ROOT, "index.json"), "w",
                                       encoding="utf-8"), indent=1)
    _write_gallery_manifest()
    print("%d/%d variants captured -> %s" % (ok, n, OUT_ROOT))


def cmd_critic(_args):
    """Does each axis actually change the picture?

    Pixel-diff sibling variants differing in exactly ONE axis value. Measured
    TWO ways, because measuring only the first lies:

      frame%  — changed pixels over the whole 1800x1200 capture. On this stage
                that number is DILUTED: the 5x5 floor fills ~25% of frame and
                the organism is a sliver, so a total transformation of the body
                still reads as ~1% and every axis looks INERT. That is the
                harness, not the design (CLAUDE.md: check the harness before
                believing an INERT verdict).
      focus%  — changed pixels within the BOUNDING BOX of the change itself,
                i.e. how thoroughly the thing that moved was rewritten. This is
                the artifact critic's "hottest region" idea, and it is the
                number the verdict uses.
    """
    from PIL import Image, ImageChops
    import statistics
    print("LIVING DNA — BITE CRITIC")
    for tok in sorted(os.listdir(OUT_ROOT)):
        man_p = os.path.join(OUT_ROOT, tok, "manifest.json")
        if not os.path.isfile(man_p):
            continue
        man = json.load(open(man_p, encoding="utf-8"))
        shots = {e["variant"]: os.path.join(OUT_ROOT, tok, e["variant"] + ".png")
                 for e in man["variants"] if e["image"]}
        axes = man["axes"]
        print("\n%s  (%s)" % (tok, man["biome_token"]))
        for axis, values in axes.items():
            if len(values) < 2:
                continue
            diffs = []
            for e in man["variants"]:
                if not e["image"]:
                    continue
                base_vals = dict(e["values"])
                if base_vals.get(axis) != values[0]:
                    continue
                for other in values[1:]:
                    cmp_vals = dict(base_vals)
                    cmp_vals[axis] = other
                    label = "__".join("%s-%s" % (k, cmp_vals[k]) for k in axes)
                    if label not in shots or e["variant"] not in shots:
                        continue
                    a = Image.open(shots[e["variant"]]).convert("L")
                    b = Image.open(shots[label]).convert("L")
                    if a.size != b.size:
                        continue
                    d = ImageChops.difference(a, b)
                    mask = d.point(lambda v: 255 if v > 12 else 0)
                    px = list(d.getdata())
                    n_changed = sum(1 for v in px if v > 12)
                    frame_pct = n_changed / float(len(px)) * 100.0
                    # focus: the change, measured inside the box the change occupies
                    box = mask.getbbox()
                    focus_pct = 0.0
                    if box and n_changed:
                        bw, bh = box[2] - box[0], box[3] - box[1]
                        if bw > 0 and bh > 0:
                            focus_pct = n_changed / float(bw * bh) * 100.0
                    diffs.append((frame_pct, focus_pct))
            if not diffs:
                print("  %-8s no comparable pairs" % axis)
                continue
            frame_mean = statistics.mean(d0 for d0, _ in diffs)
            focus_mean = statistics.mean(d1 for _, d1 in diffs)
            verdict = "BITES" if focus_mean >= 12.0 else ("faint" if focus_mean >= 5.0 else "INERT")
            print("  %-8s focus %5.1f%%  (frame %4.2f%%)  %s" % (
                axis, focus_mean, frame_mean, verdict))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--token")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--critic", action="store_true")
    a = ap.parse_args()
    if a.critic:
        cmd_critic(a)
    elif a.list or (not a.token and not a.all):
        cmd_list()
    else:
        cmd_sweep(a)


if __name__ == "__main__":
    main()
