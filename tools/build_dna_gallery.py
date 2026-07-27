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
"""
from __future__ import annotations
import json
import shutil
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_dna_declarations import check_token  # noqa: E402

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"
SWEEP_OUT = REPO / "ada_run" / "sweep"


def registry() -> dict:
    out: dict = {}
    for rp in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else data
        if isinstance(arts, dict):
            for tok, e in arts.items():
                if isinstance(e, dict):
                    out[tok] = e
    return out


def sweep(token: str, axes: dict, cap: int) -> list[dict]:
    """One Godot boot; returns [{file, params}] for the frames it produced.

    Serialised by construction — the caller loops. Two Godot instances cannot run at once
    (the second dies on the user:// lock), so this must never be parallelised.
    """
    # Stale frames from a previous artifact would be harvested as this one's variants.
    for old in SWEEP_OUT.glob(f"{token}__*.png"):
        old.unlink()

    args = [sys.executable, str(REPO / "tools" / "cabinet_sweep.py"), token, f"--max={cap}"]
    picked: list[tuple[str, list]] = []
    total = 1
    for name, vals in axes.items():
        if len(picked) == 2:
            break
        v = list(vals)
        while len(v) > 1 and total * len(v) > cap:
            v = v[:-1]
        if len(v) < 2:
            continue
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
    cap = 9
    title = ""
    for a in sys.argv[1:]:
        if a.startswith("--slug="):
            slug = a.split("=", 1)[1]
        elif a.startswith("--tokens="):
            tokens = [t.strip() for t in a.split("=", 1)[1].split(",") if t.strip()]
        elif a.startswith("--only="):
            only = {t.strip() for t in a.split("=", 1)[1].split(",") if t.strip()}
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
    if only:
        mf_old = out / "manifest.json"
        if mf_old.exists():
            try:
                kept = json.loads(mf_old.read_text(encoding="utf-8")).get("entries", [])
                entries = [e for e in kept if str(e.get("prop")) not in only]
                print(f"  (keeping {len(entries)} variant(s) from artifacts not rebuilt)")
            except Exception:
                entries = []

    for token in tokens:
        if only and token not in only:
            continue
        e = reg.get(token)
        if not e:
            print(f"  {token}: not in registry")
            continue
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
        frames = sweep(token, axes, cap)
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
        "entries": entries,
    }, indent=1), encoding="utf-8")
    print(f"\n{len(entries)} variants -> {out}/manifest.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
