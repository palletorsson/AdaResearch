#!/usr/bin/env python3
"""
build_dna_gallery.py — a gallery for ANY set of promoted artifacts.

build_readymades_gallery.py does this for one hardcoded list of nine. That list was the
whole population when it was written; it is not any more. Every promotion pass now ends
with the same three steps — sweep the declared axes, publish per-variant PNGs, run the
critic over them — and the critic can only read a gallery manifest. So the set has to be
an argument.

Same output contract as the readymades gallery, deliberately: one PNG per VARIANT (not a
tiled sheet) plus a manifest the GalleryView component reads. A tiled sheet is a picture
of an experiment; per-variant frames are the experiment.

WHY THE AXES ARE READ FROM THE REGISTRY AND NOT GUESSED: a promoted artifact declares its
own `dna.axes`. Sweeping anything else would measure knobs nobody claimed were meaningful,
and the critic's verdict is only interesting against a CLAIM. An artifact with no declared
axes is skipped and said so, never silently swept on its exports.

Usage:
  python tools/build_dna_gallery.py --slug=exhibits-dna --tokens=dark_sphere,science_screen
  python tools/build_dna_gallery.py --slug=exhibits-dna --tokens=... --max=16
  python tools/build_dna_gallery.py --slug=exhibits-dna --only=dark_sphere   # rebuild one row
  python tools/build_dna_gallery.py --slug=... --singletons=prop_spigot,...  # portraits, unswept

SINGLETONS (2026-08-27). A gallery is a family portrait as well as an experiment, and a
family can contain members whose argument is TIME - prop_spigot's rain, parlour_orbits'
orbits - for which any declared still-axis would manufacture the info_board failure
(N identical tiles dressed as an experiment). --singletons includes such members as ONE
frame each, labelled as unswept and unjudged, taken from the artifact's standing
capture_multi_angle portrait (front_mid) rather than the sweep camera. The critic
ignores them: no axis, no pairs, no verdict. An artifact WITH declared axes is refused
here - it belongs in --tokens.
"""
from __future__ import annotations
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_dna_declarations import check_token, registry  # noqa: E402

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"
SWEEP_OUT = REPO / "ada_run" / "sweep"


# registry() is IMPORTED, not redefined. A lookup name can appear in more than one file
# under commons/artifacts/registry, and not all of them are artifact registries —
# substrate_vectors.json is a feature-weight table keyed by the same names. This file used
# to carry its own last-write-wins copy, so a body-less entry displaced the real one and
# four already-promoted qfep artifacts were skipped here as "no declared dna.axes" while
# the gate reported them declared. That is a fact about file ordering presented as a fact
# about the artifact — the same disease the declaration checker exists to cure, so it gets
# the same cure: one implementation, in the module that already got it right.


def sweep(token: str, axes: dict, cap: int, coverage: dict = None) -> list[dict]:
    """One Godot boot; returns [{file, params}] for the frames it produced.

    Serialised by construction — the caller loops. Two Godot instances cannot run at once
    (the second dies on the user:// lock), so this must never be parallelised.

    WHAT `coverage` IS FOR, and why it is not optional in spirit. The variant budget below
    trims a declared axis until the cross product fits `cap`, and it trims from the END of
    the declared value list. It used to do that in silence. dot_aligner declares
    opening(4) x workings(4); at the default cap of 9 that renders 4 x 2, and the critic
    then read `workings` over `outcome` and `trace` alone and called the axis INERT — a
    verdict about two values, published as a verdict about four. Worse, the two it dropped
    included `operands`, which is the artifact's own default and therefore the baseline the
    other values are supposed to differ FROM.

    A dropped value is invisible downstream: the manifest lists what rendered, so a
    truncated axis looks exactly like a complete one. CLAUDE.md's rule is that a workflow
    which bounds coverage must say what it dropped. This records it, per axis, so the
    manifest carries the denominator with the measurement.
    """
    if coverage is None:
        coverage = {}
    # Stale frames from a previous artifact would be harvested as this one's variants.
    for old in SWEEP_OUT.glob(f"{token}__*.png"):
        old.unlink()

    args = [sys.executable, str(REPO / "tools" / "cabinet_sweep.py"), token, f"--max={cap}"]
    picked: list[tuple[str, list]] = []
    total = 1
    for name, vals in axes.items():
        declared = list(vals)
        if len(picked) == 2:
            # The sweep renders at most two axes. A third is not measured at all.
            coverage[name] = {"declared": declared, "swept": [], "dropped": declared,
                              "reason": "only the first two declared axes are swept"}
            continue
        v = list(declared)
        while len(v) > 1 and total * len(v) > cap:
            v = v[:-1]
        if len(v) < 2:
            coverage[name] = {"declared": declared, "swept": [], "dropped": declared,
                              "reason": f"cap={cap} left room for fewer than 2 values"}
            continue
        if len(v) < len(declared):
            coverage[name] = {"declared": declared, "swept": list(v),
                              "dropped": declared[len(v):],
                              "reason": f"cap={cap} on the axis cross product"}
        else:
            coverage[name] = {"declared": declared, "swept": list(v), "dropped": [],
                              "reason": ""}
        picked.append((name, v))
        total *= len(v)
    if not picked:
        return []
    for name, vals in picked:
        args += ["--set", f"{name}=" + ",".join(
            str(x).lower() if isinstance(x, bool) else str(x) for x in vals)]
    r = subprocess.run(args, cwd=REPO, capture_output=True, text=True, timeout=1800)
    if r.returncode != 0:
        print(f"    sweep exited {r.returncode}: {(r.stderr or r.stdout or '')[-300:]}")

    frames: list[dict] = []
    for png in sorted(SWEEP_OUT.glob(f"{token}__*.png")):
        parts = png.stem.split("__")[1:]
        params = {}
        for p in parts:
            if "-" in p:
                k, _, v = p.partition("-")
                params[k] = v
        frames.append({"file": png, "params": params})
    return frames


def main() -> int:
    slug = ""
    tokens: list[str] = []
    only: set[str] = set()
    singletons: list[str] = []
    # WHY 16 AND NOT 9. The cap bounds the AXIS CROSS PRODUCT, and the corpus's standard
    # shape is two axes of four values - exactly 16. At 9 that shape was silently swept
    # 4x2: the second axis lost half its values, the gallery published a full-looking row,
    # and the critic issued a whole-axis verdict over a subset. Audited across every
    # manifest, 94 axes in 29 galleries came out short this way, boolean_surfaces included
    # - where the dropped values were, in five of five cases, the ones the authors had
    # already flagged as the doubtful ones. `partial_axes` records the shortfall now, but
    # recording a fault is not the same as not having it, and a default that silently
    # halves the most common shape in the corpus is the wrong default.
    cap = 16
    title = ""
    for a in sys.argv[1:]:
        if a.startswith("--slug="):
            slug = a.split("=", 1)[1]
        elif a.startswith("--tokens="):
            tokens = [t.strip() for t in a.split("=", 1)[1].split(",") if t.strip()]
        elif a.startswith("--only="):
            only = {t.strip() for t in a.split("=", 1)[1].split(",") if t.strip()}
        elif a.startswith("--singletons="):
            singletons = [t.strip() for t in a.split("=", 1)[1].split(",") if t.strip()]
        elif a.startswith("--max="):
            cap = int(a.split("=", 1)[1])
        elif a.startswith("--title="):
            title = a.split("=", 1)[1]
    if not slug or not tokens:
        print(__doc__)
        return 2

    out = ENC / slug
    out.mkdir(parents=True, exist_ok=True)
    reg = registry()

    # --only REBUILDS A ROW, not the gallery. Writing a fresh manifest from just the swept
    # artifacts silently drops every other variant — a partial rebuild that looks complete
    # is the same failure class as a sweep of identical tiles.
    entries: list[dict] = []
    coverage: dict = {}
    if only:
        mf_old = out / "manifest.json"
        if mf_old.exists():
            try:
                old = json.loads(mf_old.read_text(encoding="utf-8"))
                kept = old.get("entries", [])
                entries = [e for e in kept
                           if str(e.get("prop")) not in only
                           and str(e.get("prop")) not in singletons]
                print(f"  (keeping {len(entries)} variant(s) from artifacts not rebuilt)")
                # Carry the denominator forward with the frames it belongs to, or an
                # --only rebuild would silently promote another artifact's partial axis
                # back to looking complete.
                for k, c in (old.get("partial_axes") or {}).items():
                    if str(k).split(".")[0] not in only:
                        coverage[k] = c
            except Exception:
                entries = []

    for token in tokens:
        if only and token not in only:
            continue
        found = reg.get(token)
        if not found:
            print(f"  {token}: not in registry")
            continue
        # The shared registry() returns (entry, source_filename); this file wants the entry.
        e = found[0] if isinstance(found, tuple) else found
        axes = ((e.get("dna") or {}).get("axes") or {})
        if not axes:
            print(f"  {token}: no declared dna.axes — skipped (never swept on raw exports)")
            continue

        # REFUSE TO SWEEP A LYING DECLARATION. An axis whose declared values are not the
        # code's values does not fail anywhere downstream: the artifact falls back to its
        # default, N identical frames get published, and the critic reports the ARTIFACT
        # as inert. Dropping the axis here is the only place the loop can still tell the
        # difference between "this design does nothing" and "this declaration is wrong".
        broken = {r["axis"] for r in check_token(token, e)
                  if r["status"] in ("MISMATCH", "NO_EXPORT")}
        if broken:
            for r in check_token(token, e):
                if r["axis"] in broken:
                    print(f"  {token}.{r['axis']}: REFUSED — {r['detail']}")
            axes = {k: v for k, v in axes.items() if k not in broken}
            if not axes:
                print(f"  {token}: every declared axis is broken — nothing swept")
                continue

        print(f"  {token}: sweeping {list(axes)} ...")
        cov: dict = {}
        frames = sweep(token, axes, cap, cov)
        for ax_name, c in cov.items():
            if c["dropped"]:
                coverage[f"{token}.{ax_name}"] = c
                print(f"  {token}.{ax_name}: PARTIAL — swept {len(c['swept'])}/"
                      f"{len(c['declared'])} values, dropped {c['dropped']} ({c['reason']}). "
                      f"Any verdict on this axis is about the swept values only.")
        if not frames:
            print(f"  {token}: sweep produced no frames")
            continue
        for f in frames:
            fid = f["file"].stem
            shutil.copy2(f["file"], out / f"{fid}.png")
            axis_txt = " · ".join(f"{k} = {v}" for k, v in f["params"].items())
            entries.append({
                "id": fid,
                "prop": token,
                "index": 0,
                "label": axis_txt or "default",
                "subtitle": str(e.get("name", token)),
                # The axis reading FIRST. GalleryView shows `notes` as the tile subtitle,
                # and the artifact's description is identical across every variant of that
                # artifact — so leading with it makes sixteen distinct renders caption
                # themselves identically, which is the sheet-of-identical-tiles failure
                # moved into the UI. What varies goes first; the description is context.
                "notes": (f"{token} — {axis_txt}" if axis_txt else f"{token} — default")
                         + f"  ·  {str(e.get('description', '') or '')[:150]}",
                "image": f"/{slug}/{fid}.png",
                "dna": f["params"],
            })
        print(f"  {token}: {len(frames)} variant(s)")

    for token in singletons:
        found = reg.get(token)
        if not found:
            print(f"  {token}: not in registry - singleton refused")
            continue
        e = found[0] if isinstance(found, tuple) else found
        if ((e.get("dna") or {}).get("axes") or {}):
            print(f"  {token}: declares dna.axes - belongs in --tokens, singleton refused")
            continue
        src_png = (Path(os.path.expandvars("%APPDATA%")) / "Godot" / "app_userdata"
                   / "Ada Research Zero One" / "multi_shots" / token / "front_mid.png")
        if not src_png.exists():
            print(f"  {token}: no standing portrait - run: godot --path . --xr-mode off "
                  f"--no-window --script res://commons/testing/capture_multi_angle.gd -- "
                  f"--mode=artifact --target={token}")
            continue
        fid = f"{token}__shipped"
        shutil.copyfile(src_png, out / f"{fid}.png")
        entries.append({
            "id": fid,
            "prop": token,
            "index": 0,
            "label": "shipped - no axis declared",
            "subtitle": str(e.get("name", token)),
            "notes": (f"{token} - SINGLETON, unswept and unjudged: no dna.axes, because its "
                      f"argument is TIME and a still-axis would manufacture identical tiles. "
                      f"Portrait from capture_multi_angle (front_mid), not the sweep camera."
                      f"  \u00b7  {str(e.get('description', '') or '')[:150]}"),
            "image": f"/{slug}/{fid}.png",
            "dna": {},
        })
        print(f"  {token}: singleton portrait")

    order = {t: i for i, t in enumerate(tokens)}
    entries.sort(key=lambda x: (order.get(str(x.get("prop")), 99), str(x.get("id"))))
    for i, x in enumerate(entries):
        x["index"] = i

    (out / "manifest.json").write_text(json.dumps({
        "version": 1,
        "description": title or (
            f"{len(set(e['prop'] for e in entries))} promoted artifacts, each swept across "
            "the DNA axes it declares in the registry."),
        "capture_size": [900, 900],
        # The denominator, travelling with the measurement. Absent or empty means every
        # declared value of every swept axis rendered; a key here means the axis was
        # measured over a SUBSET and no verdict on it covers the whole declaration.
        "partial_axes": coverage,
        "entries": entries,
    }, indent=1), encoding="utf-8")
    if coverage:
        print(f"\n{len(coverage)} axis/axes swept PARTIALLY — recorded in manifest "
              f"under `partial_axes`:")
        for k, c in sorted(coverage.items()):
            print(f"  {k}: {len(c['swept'])}/{len(c['declared'])} values "
                  f"— dropped {c['dropped']}")
        print("  Re-run with a larger --max to close these.")
    print(f"\n{len(entries)} variants -> {out}/manifest.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
