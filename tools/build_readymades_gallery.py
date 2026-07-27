#!/usr/bin/env python3
"""
build_readymades_gallery.py — the readymades DNA gallery, in the props-dna form.

Same convention as /props-dna-gallery: one PNG per VARIANT (not a tiled sheet) plus a
manifest the GalleryView component reads, so each variant is an evaluable row rather
than a picture of several. The sweep already renders per-variant PNGs into
ada_run/sweep before it tiles them; this harvests those.

For each artifact it reads the DECLARED dna.axes from the registry — these are all
stage-2 promoted, so the axes are authored rather than guessed — sweeps them in one
Godot boot each, and copies the frames out with their parameters recorded.

Usage:
  python tools/build_readymades_gallery.py [--only=token,token] [--max=6]
"""
from __future__ import annotations
import json
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"
SLUG = "readymades-dna"
OUT = ENC / SLUG
SWEEP_OUT = REPO / "ada_run" / "sweep"

# The set, in the order the gallery should read — the same argument as the map aisle.
SET = [
    ("stock_stratum", "Si-Qin", "the census as bedrock"),
    ("multiple_ring", "Fritsch", "the member cannot resign"),
    ("adjacency_shelf", "Steinbach", "arrangement is an argument"),
    ("lineage_vitrine", "—", "the siblings you did not become"),
    ("sturtevant_bench", "Sturtevant", "the claim beside the code"),
    ("default_body_bay", "Perry", "neutrality, used up"),
    ("poor_image_gate", "Steyerl", "resolution decides who travels"),
    ("unfinishable_terrarium", "Cheng", "a world with no reset"),
    ("operational_eye", "Farocki", "images that were never for you"),
]


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
    """Run one sweep and return [{file, params}] for the frames it produced."""
    args = [sys.executable, str(REPO / "tools" / "cabinet_sweep.py"), token, f"--max={cap}"]
    # one axis if a single axis already fills the budget, else the first two
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
    subprocess.run(args, cwd=REPO, capture_output=True, text=True, timeout=900)

    frames: list[dict] = []
    for png in sorted(SWEEP_OUT.glob(f"{token}__*.png")):
        # label format: token__axis-value__axis-value
        parts = png.stem.split("__")[1:]
        params = {}
        for p in parts:
            if "-" in p:
                k, _, v = p.partition("-")
                params[k] = v
        frames.append({"file": png, "params": params})
    return frames


def main() -> int:
    only: set[str] = set()
    cap = 6
    for a in sys.argv[1:]:
        if a.startswith("--only="):
            only = {t.strip() for t in a.split("=", 1)[1].split(",") if t.strip()}
        if a.startswith("--max="):
            cap = int(a.split("=", 1)[1])

    reg = registry()
    OUT.mkdir(parents=True, exist_ok=True)

    # --only REBUILDS A ROW, it does not rebuild the gallery. Writing a fresh manifest
    # from just the swept artifacts silently dropped the other 38 variants the first
    # time this ran — a partial rebuild that looks like a complete one is the same
    # failure mode as a sweep of identical tiles.
    entries: list[dict] = []
    if only:
        mf_old = OUT / "manifest.json"
        if mf_old.exists():
            try:
                kept = json.loads(mf_old.read_text(encoding="utf-8")).get("entries", [])
                entries = [e for e in kept if str(e.get("prop")) not in only]
                print(f"  (keeping {len(entries)} variant(s) from artifacts not rebuilt)")
            except Exception:
                entries = []
    idx = len(entries)
    for token, artist, line in SET:
        if only and token not in only:
            continue
        e = reg.get(token)
        if not e:
            print(f"  {token}: not in registry"); continue
        axes = ((e.get("dna") or {}).get("axes") or {})
        if not axes:
            print(f"  {token}: no declared dna.axes"); continue
        frames = sweep(token, axes, cap)
        if not frames:
            print(f"  {token}: sweep produced no frames"); continue
        for f in frames:
            fid = f["file"].stem
            shutil.copy2(f["file"], OUT / f"{fid}.png")
            axis_txt = " · ".join(f"{k} = {v}" for k, v in f["params"].items())
            entries.append({
                "id": fid,
                "prop": token,
                "index": idx,
                "label": axis_txt or "default",
                "subtitle": line,
                "notes": f"{e.get('name', token)} — {line}" + (f"  (after {artist})" if artist != "—" else ""),
                "image": f"/{SLUG}/{fid}.png",
                "dna": f["params"],
                "artist": artist,
            })
            idx += 1
        print(f"  {token}: {len(frames)} variant(s)")

    order = {tok: i for i, (tok, _a, _l) in enumerate(SET)}
    entries.sort(key=lambda e: (order.get(str(e.get("prop")), 99), str(e.get("id"))))
    for i, e in enumerate(entries):
        e["index"] = i

    manifest = {
        "version": 1,
        "description": (
            "Nine artifacts whose subject is this project's own condition, each swept "
            "across the DNA axes it declares. Built as surreal readymades from existing "
            "props: nothing in them is modelled for the piece except the relation."
        ),
        "capture_size": [900, 900],
        "entries": entries,
    }
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=1), encoding="utf-8")
    print(f"\n{len(entries)} variants -> {OUT}/manifest.json")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
