"""em_ruling_to_maps.py — make the ruled halls BE the maps.

2026-08-29, Palle, looking at the width-and-walls sheet: "can we make this the
maps?" Yes: this writer replays the normalization that em_map_halls.normalize_row
performed on each hall BACK onto the source map_data.json — same tile, same
ledger, one implementation of the rule (the long_museum drift scar). Heights are
PRESERVED by merging: where the hall kept a map cell, the map keeps its own
value ("3" stays "3", "p:2" stays "p:2"); only cells the ruling actually touched
change ("w" for new walls and piers, "1" for pads, doors and carved channels,
ring rows appear as "w" with their floor thresholds).

Layers move in lockstep: structure, utilities and interactables are rotated,
padded and ring-shifted together; a rotated interactable token gets its :rot:
segment bumped +90. dimensions become engine-true {width, depth, max_height}
(the Walker_Warren lesson: a missing depth builds a ZERO-ROW grid).

  python tools/em_ruling_to_maps.py           dry — per-map summary, writes nothing
  python tools/em_ruling_to_maps.py --apply   write the conforming maps

SKIPPED, always: maps dirty in git (another session's uncommitted work — the
concurrent-writer rule; Point_One is being rewritten right now, forum
260831-qyx4v) and maps whose derived layers come out byte-identical.

After --apply, run `python tools/em_map_halls.py` again: every written map must
derive the SAME tile it had before the write (the idempotence gate) — the
museum must not change because its inputs caught up with it.
"""
from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import em_map_halls  # noqa: E402  (the one implementation of the rule)


def eff(v: str, ) -> int:
    s = str(v).strip()
    if s == "w":
        return 3
    if s == "p" or s.startswith("p:"):
        try:
            return max(1, int(s.split(":")[1])) if ":" in s else 1
        except ValueError:
            return 1
    return int(s) if s.isdigit() else 0


def grid_get(g: list, r: int, c: int, default: str = "") -> str:
    if 0 <= r < len(g) and 0 <= c < len(g[r]):
        return str(g[r][c])
    return default


def bump_rot(token: str) -> str:
    """name[:rot[:y]][#cfg...] -> rot + 90 (a rotated room turns its bodies)."""
    if not token.strip():
        return token
    head, *cfg = token.split("#")
    parts = head.split(":")
    rot = 0
    if len(parts) > 1 and parts[1].strip():
        try:
            rot = int(float(parts[1]))
        except ValueError:
            rot = 0
    parts = [parts[0], str((rot + 90) % 360)] + parts[2:]
    return "#".join([":".join(parts)] + cfg)


def rewrite_map(map_name: str, row: dict) -> dict | None:
    """Build the ruled layers for one map from its plan row. Returns the new
    map_data dict, or None when nothing changes."""
    path = ROOT / "commons" / "maps" / map_name / "map_data.json"
    raw_text = path.read_text(encoding="utf-8")
    md = json.loads(raw_text)
    S = md["layers"]["structure"]
    U = md["layers"].get("utilities") or []
    I = md["layers"].get("interactables") or []
    mus = (md.get("map_info", {}) or {}).get("museum", {}) or {}
    wall_h = int(mus.get("wall_height", 2)) if isinstance(mus, dict) else 2

    led = row.get("_ruling") or {}
    tile = row["tile"]
    H, W = len(tile), len(tile[0])
    rotated = bool(led.get("rotated"))
    off = 1 if led.get("ring") == "expand" else 0
    src_w, src_h = int(led.get("src_w", W)), int(led.get("src_h", H))
    h_rot, w_rot = (src_w, src_h) if rotated else (src_h, src_w)

    def src_cell(tr: int, tc: int):
        gr, gc = tr - off, tc - off
        if 0 <= gr < h_rot and 0 <= gc < w_rot:
            if rotated:
                return (src_h - 1 - gc, gr)
            return (gr, gc)
        return None

    ns = [["0"] * W for _ in range(H)]
    nu = [[""] * W for _ in range(H)]
    ni = [[""] * W for _ in range(H)]
    for tr in range(H):
        for tc in range(W):
            t = str(tile[tr][tc])
            src = src_cell(tr, tc)
            if src is None:
                # ring / pad / threshold cells — born from the ruling
                if t == "4":
                    ns[tr][tc] = "w"
                elif t == "1":
                    ns[tr][tc] = "1"
                elif t.startswith("p"):
                    n = t[1:]
                    ns[tr][tc] = "p" if not n else "p:%s" % n
                continue
            r, c = src
            s_orig = grid_get(S, r, c, "0").strip()
            e = eff(s_orig)
            if t == "4":
                ns[tr][tc] = s_orig if e >= wall_h else "w"
            elif t == "1":
                ns[tr][tc] = s_orig if 1 <= e < wall_h else "1"
            elif t.startswith("p"):
                ns[tr][tc] = s_orig if s_orig == "p" or s_orig.startswith("p:") else ("p" if t == "p" else "p:%s" % t[1:])
            else:
                ns[tr][tc] = "0"
            uv = grid_get(U, r, c).strip()
            if uv and uv != "0":
                nu[tr][tc] = uv
            iv = grid_get(I, r, c).strip()
            if iv and iv != "0":
                ni[tr][tc] = bump_rot(iv) if rotated else iv

    maxh = 1
    for line in ns:
        for v in line:
            maxh = max(maxh, eff(v))
    changed = (ns != [[str(v) for v in rrow] for rrow in S]
               or [[(x if x != "0" else "") for x in rrow] for rrow in nu] != [[str(grid_get(U, r2, c2)).strip() for c2 in range(W)] for r2 in range(H)])
    # honest change detection: compare against originals padded to the new shape
    def norm(g, blank):
        return [[(grid_get(g, r2, c2, blank).strip() or blank) for c2 in range(W)] for r2 in range(H)]
    same = (ns == norm(S, "0")
            and nu == [[("" if v in ("", "0") else v) for v in line] for line in norm(U, "")]
            and ni == [[("" if v in ("", "0") else v) for v in line] for line in norm(I, "")]
            and len(S) == H and (len(S[0]) if S else 0) == W)
    dims = (md.get("map_info", {}).get("dimensions") or {})
    dims_ok = int(dims.get("width", -1)) == W and int(dims.get("depth", -1)) == H
    if same and dims_ok:
        return None

    md["layers"]["structure"] = ns
    md["layers"]["utilities"] = nu
    md["layers"]["interactables"] = ni
    md.setdefault("map_info", {})["dimensions"] = {"width": W, "depth": H, "max_height": maxh}
    return md


def compact(md: dict) -> str:
    s = json.dumps(md, indent=1, ensure_ascii=False)
    def one_line(m):
        inner = re.sub(r"\s+", " ", m.group(1)).strip()
        return "[ " + inner + " ]"
    return re.sub(r"\[((?:\s+\"[^\]]*?)+)\s+\]", one_line, s) + "\n"


def main() -> int:
    apply = "--apply" in sys.argv
    plan = json.loads((ROOT / "ada_run" / "_trial_map_plan.json").read_text(encoding="utf-8"))
    rows = {r["map"]: r for r in plan["plans"] if r.get("authored") == "map"}

    r = subprocess.run(["git", "status", "--porcelain", "--"] +
                       [f"commons/maps/{m}/map_data.json" for m in rows],
                       capture_output=True, text=True, cwd=ROOT)
    dirty = {pathlib.Path(l[3:]).parts[-2] for l in r.stdout.splitlines() if l.strip()}

    written, skipped_dirty, unchanged = [], [], []
    for m, row in sorted(rows.items()):
        if m in dirty:
            skipped_dirty.append(m)
            continue
        md = rewrite_map(m, row)
        if md is None:
            unchanged.append(m)
            continue
        w = md["map_info"]["dimensions"]["width"]
        h = md["map_info"]["dimensions"]["depth"]
        led = row.get("_ruling") or {}
        note = []
        if led.get("rotated"):
            note.append("rot90")
        if led.get("pad"):
            note.append("pad+%d" % led["pad"])
        if led.get("ring"):
            note.append("ring:" + led["ring"])
        if "dressing" in row:
            note.append(row["dressing"])
        print("  %-46s -> %dx%d  %s" % (m, w, h, " · ".join(note) or "merge only"))
        if apply:
            p = ROOT / "commons" / "maps" / m / "map_data.json"
            raw = p.read_text(encoding="utf-8")
            nl = "\r\n" if "\r\n" in raw else "\n"
            p.write_text(compact(md).replace("\n", nl), encoding="utf-8", newline="")
        written.append(m)

    print("\n%s %d maps · unchanged %d · skipped dirty %d: %s"
          % ("WROTE" if apply else "would write", len(written), len(unchanged),
             len(skipped_dirty), ", ".join(skipped_dirty)))
    if not apply:
        print("(dry run — pass --apply to write)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
