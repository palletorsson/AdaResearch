#!/usr/bin/env python3
"""
validate_museum_templates.py — the gate the museum tiles pass before the walker does.

Checks every museum-tagged pattern in commons/data/template_patterns.json (or a
candidate JSON given with --candidate) against the rules the endless museum's
walker now physically depends on — collision made these load-bearing:

  dims      w odd 13..17, h 24..36, every row exactly w cells
  vocab     cells in {4, 1, 1s, 2, 2s, 3s} plus ""/" " void (legacy: outside
            the footprint — legal ONLY if walled off from every walkable cell,
            because a reachable void is a hole in the world under collision)
  border    sides walled; entry row (0) and exit row (last) each carry at
            least one walkable run >= 2 wide (full-width open edges are a
            legitimate mechanism — the vestibule seals the jump)
  hero      exactly one 3s
  pockets   every slot (1s/2s/3s) touches >= 1 orthogonal standable cell
  walkable  BFS over standable cells ({1, 1s} — an artifact on a floor slot
            has no collision box) connects the entry gap to the exit gap

Agents SELF-validate before returning; this tool is the orchestrator's
independent check — the loop's law is that a guard unverified against
known-bad input has been hoped at, not tested, so: --selftest corrupts a
known-good tile four ways and must fail all four.

Usage:
  python tools/validate_museum_templates.py                # gate the shipped file
  python tools/validate_museum_templates.py --candidate=X  # gate a candidate pattern JSON
  python tools/validate_museum_templates.py --selftest
Exit code = number of failing templates.
"""
from __future__ import annotations
import json
import sys
from collections import deque
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
VOCAB = {"4", "1", "1s", "2", "2s", "3s", "", " "}
SLOTS = {"1s", "2s", "3s"}
STAND = {"1", "1s"}   # cells a body can occupy: artifacts on floor slots carry no collision
VOID = {"", " "}


def _gaps(row: list[str]) -> list[list[int]]:
    runs, cur = [], []
    for x, c in enumerate(row):
        if c in STAND:
            cur.append(x)
        else:
            if cur:
                runs.append(cur)
            cur = []
    if cur:
        runs.append(cur)
    return runs


def check(key: str, p: dict) -> list[str]:
    issues: list[str] = []
    w, h, tile = int(p.get("w", 0)), int(p.get("h", 0)), p.get("tile", [])
    if w % 2 == 0 or not (13 <= w <= 17):
        issues.append(f"w={w} not odd 13..17")
    if not (24 <= h <= 36):
        issues.append(f"h={h} not 24..36")
    if len(tile) != h:
        issues.append(f"{len(tile)} rows != h={h}")
        return issues
    for y, row in enumerate(tile):
        if len(row) != w:
            issues.append(f"row {y} has {len(row)} cells != w={w}")
            return issues
        for c in row:
            if str(c) not in VOCAB:
                issues.append(f"unknown cell '{c}' at row {y}")
                return issues
    grid = [[str(c) for c in row] for row in tile]
    # sides may be open floor: the scene stamps an outer skin wall at x=-1 and
    # x=w along every segment, so a free-plan tile with a walkable rim
    # (Kanazawa, Neue Nationalgalerie) does not leak the walker into the void
    for name, row in (("entry", grid[0]), ("exit", grid[h - 1])):
        runs = _gaps(row)
        if not any(len(r) >= 2 for r in runs):
            issues.append(f"{name} row has no walkable gap >= 2 wide")
    heroes = sum(1 for row in grid for c in row if c == "3s")
    if heroes != 1:
        issues.append(f"{heroes} hero slots (3s), need exactly 1")
    # stop pockets. A slot is served either by an adjacent standable cell, or
    # by a standable cell one podium further along the same direction — a 0.6 m
    # podium is seen OVER, a 3 m wall is not (display blocks viewed across
    # their own plinth ring are legitimate museum grammar).
    def _pocket(y: int, x: int) -> bool:
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            y1, x1 = y + dy, x + dx
            if not (0 <= y1 < h and 0 <= x1 < w):
                continue
            if grid[y1][x1] in STAND:
                return True
            if grid[y1][x1] in ("2", "2s"):
                y2, x2 = y + 2 * dy, x + 2 * dx
                if 0 <= y2 < h and 0 <= x2 < w and grid[y2][x2] in STAND:
                    return True
        return False
    for y in range(h):
        for x in range(w):
            if grid[y][x] in SLOTS and not _pocket(y, x):
                issues.append(f"slot at ({x},{y}) has no standable pocket (adjacent or over one podium)")
    # a reachable void is a hole in the world under collision
    for y in range(h):
        for x in range(w):
            if grid[y][x] in VOID:
                if any(0 <= yy < h and 0 <= xx < w and grid[yy][xx] in STAND
                       for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1))):
                    issues.append(f"void cell at ({x},{y}) is reachable from walkable floor")
    # BFS over standable cells from entry gap to exit gap
    starts = [(0, x) for x in range(w) if grid[0][x] in STAND]
    goals = {(h - 1, x) for x in range(w) if grid[h - 1][x] in STAND}
    seen, q = set(starts), deque(starts)
    reached = False
    while q:
        y, x = q.popleft()
        if (y, x) in goals:
            reached = True
            break
        for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= yy < h and 0 <= xx < w and (yy, xx) not in seen and grid[yy][xx] in STAND:
                seen.add((yy, xx))
                q.append((yy, xx))
    if starts and goals and not reached:
        issues.append("entry gap cannot reach exit gap over standable floor")
    return issues


LOBBY_W = 17
VEST_H = 4


def chain_check(pats: dict) -> int:
    """Every museum's exit must reach every museum's entry through the vestibule.

    Models the scene's lobby EXACTLY as endless_museum.gd builds it: VEST_H open
    rows of LOBBY_W, side walls at x=0 and x=LOBBY_W-1, an entry-edge strip
    sealing x >= prev_w-1 and an exit-edge strip sealing x >= next_w-1. This
    check exists because the strip logic shipped once with prev_w never set —
    the seal covered the full width and every museum-to-museum crossing was
    walled off, and no per-template validation could see it.
    """
    mus = {k: p for k, p in pats.items() if isinstance(p, dict) and p.get("museum")}
    bad = 0
    for ka, a in sorted(mus.items()):
        for kb, b in sorted(mus.items()):
            wa, wb = int(a["w"]), int(b["w"])
            exit_cells = {x for x, c in enumerate([str(c) for c in a["tile"][-1]]) if c in STAND}
            entry_cells = {x for x, c in enumerate([str(c) for c in b["tile"][0]]) if c in STAND}
            # lobby grid: rows 0..VEST_H-1
            open_col = [[True] * LOBBY_W for _ in range(VEST_H)]
            for zr in range(VEST_H):
                open_col[zr][0] = open_col[zr][LOBBY_W - 1] = False
            for x in range(wa - 1, LOBBY_W):
                open_col[0][x] = False
            for x in range(wb - 1, LOBBY_W):
                open_col[VEST_H - 1][x] = False
            starts = [(0, x) for x in exit_cells if x < LOBBY_W and open_col[0][x]]
            goals = {(VEST_H - 1, x) for x in entry_cells if x < LOBBY_W and open_col[VEST_H - 1][x]}
            seen, q = set(starts), deque(starts)
            ok = False
            while q:
                y, x = q.popleft()
                if (y, x) in goals:
                    ok = True
                    break
                for yy, xx in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
                    if 0 <= yy < VEST_H and 0 <= xx < LOBBY_W and (yy, xx) not in seen and open_col[yy][xx]:
                        seen.add((yy, xx))
                        q.append((yy, xx))
            if not ok:
                print(f"CHAIN FAIL {ka} -> {kb}: exit gap {sorted(exit_cells)} cannot reach entry gap {sorted(entry_cells)}")
                bad += 1
    n = len(mus)
    print(f"chain: {n * n - bad}/{n * n} ordered museum pairs pass the vestibule")
    return bad


def selftest() -> int:
    good = {"w": 13, "h": 24, "tile": []}
    t = [["4"] * 13 for _ in range(24)]
    for y in range(1, 23):
        for x in range(1, 12):
            t[y][x] = "1"
    t[0][6] = t[0][7] = "1"
    t[23][6] = t[23][7] = "1"
    t[5][5] = "3s"
    good["tile"] = t
    assert check("good", good) == [], "known-good tile failed"
    import copy
    fails = 0
    for name, mut in [
        ("sealed exit", lambda g: g["tile"][23].__setitem__(6, "4") or g["tile"][23].__setitem__(7, "4")),
        ("two heroes", lambda g: g["tile"][6].__setitem__(5, "3s")),
        ("walled-in slot", lambda g: [g["tile"][4].__setitem__(5, "4"), g["tile"][6].__setitem__(5, "4"),
                                      g["tile"][5].__setitem__(4, "4"), g["tile"][5].__setitem__(6, "4")]),
        ("cut path", lambda g: [g["tile"][12].__setitem__(x, "4") for x in range(13)]),
    ]:
        g = copy.deepcopy(good)
        mut(g)
        if check(name, g):
            fails += 1
        else:
            print(f"SELFTEST FAILURE: mutation '{name}' passed the gate")
    print(f"selftest: {fails}/4 known-bad mutations caught")
    return 0 if fails == 4 else 1


def main() -> int:
    if "--selftest" in sys.argv or "--self-test" in sys.argv:
        return selftest()
    src = PATTERNS
    for a in sys.argv[1:]:
        if a.startswith("--candidate="):
            src = Path(a.split("=", 1)[1])
    data = json.loads(src.read_text(encoding="utf-8"))
    pats = data.get("patterns", {"candidate": data.get("pattern", data)})
    bad = 0
    for key, p in sorted(pats.items()):
        if not (isinstance(p, dict) and p.get("museum")):
            continue
        issues = check(key, p)
        mark = "ok " if not issues else "FAIL"
        print(f"{mark} {key:40} w={p.get('w')} h={p.get('h')}")
        for i in issues:
            print(f"      - {i}")
        bad += 1 if issues else 0
    print(f"\n{bad} failing museum template(s)")
    bad += chain_check(pats)
    return bad


if __name__ == "__main__":
    raise SystemExit(main())
