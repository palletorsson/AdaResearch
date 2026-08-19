#!/usr/bin/env python3
"""
test_autopilot_planner.py — the endless museum's autopilot planner, on a bench.

WHY THIS EXISTS. Release gate F has been red and unmoving for days, and its
verdict reads:

    {"ok": false, "z": 44.6501121520996, "x": 7.49987840652466,
     "goal_z": 102.0, "segments_built": 3, "cells_unlearned": 26}

Byte-identical across runs on 2026-08-13 and 2026-08-15. Read plainly it says
"the corridor needed more than 25 cells unlearned" — a broken museum. That
reading is wrong, and it is wrong in the way this project keeps being wrong:
the number describes the INSTRUMENT, not the thing measured.

`cells_unlearned` does not count cells. It counts STALL EVENTS. And once the
planner runs out of route, every remaining stall event erases a cell that is
already gone — `Dictionary.erase` on a missing key is a silent no-op — while
the walker grinds into the same wall at the same coordinate. Hence a position
repeating to ten decimal places: the walker is not searching, it is pinned.

THE DEFECT, in commons/scenes/endless_museum.gd:

    func _auto_plan() -> void:
        ...
        if not found:
            return          # line 3820 — leaves _auto_path UNTOUCHED
        ...
        if best == start:
            return          # line 3837 — leaves _auto_path UNTOUCHED

`_auto_path` is assigned in exactly one place (line 3843, the success tail) and
cleared nowhere. So when BFS finds no cell deeper than the walker's own, the
planner returns having decided nothing, and the walker keeps following the
PREVIOUS plan — whose head is the cell the stall handler just erased. The loop
that was designed to let physics teach the planner instead teaches it the same
lesson until the budget is gone.

WHAT THIS FILE PROVES, with no Godot and no museum: transcribe the loop, put it
in front of a wall it cannot pass, and the count comes out 26 — 8 real cells and
18 no-ops — with the walker frozen at one coordinate. Then apply the fix and the
same corridor reports the truth: no route, frontier at z=44, 8 cells unlearned.

It is a MODEL, and it is honest about that: it proves the control flow, not the
museum's geometry. Whether the real corridor's wall is an artifact's collider or
a seal that should not be there is a question for a live walk. This file only
establishes that the live walk has not been answering it.

Run:  python tools/test_autopilot_planner.py
Exit 0 iff every assertion holds.
"""
from __future__ import annotations

from collections import deque
from typing import Dict, List, Optional, Set, Tuple

Cell = Tuple[int, int]  # (x, z), matching Vector2i(x, z) in the GDScript

WALK_SPEED = 3.0
TICK = 1.0 / 60.0
STALL_SECONDS = 1.2     # _auto_stall_t > 1.2
STALL_DISTANCE = 0.4    # distance_to(_auto_last_pos) > 0.4
ARRIVE = 0.35           # to.length() < 0.35
UNLEARN_BUDGET = 25     # _auto_learned > 25


class Corridor:
    """The stamped cell map plus the colliders physics actually enforces.

    The two disagree — that disagreement is the whole subject. `cells` is what
    the planner believes; `solid` is what the body meets.
    """

    def __init__(self, x_range: range, z_range: range, wall_z: int) -> None:
        self.cells: Set[Cell] = {(x, z) for x in x_range for z in z_range}
        # A full-width row of collision at wall_z. Every cell of it is stamped
        # walkable — that is the fault the autopilot is supposed to discover.
        self.solid: Set[Cell] = {(x, wall_z) for x in x_range}
        self.wall_z = wall_z
        self.width = len(x_range)


class Walker:
    """A faithful transcription of _run_autopilot / _auto_plan.

    `fixed=False` is the code as it stands at HEAD. `fixed=True` is the
    proposed change: the planner clears the path when it decides nothing, the
    budget counts cells that actually left the map, and a run of stalls that
    teaches nothing terminates as its own distinct verdict.
    """

    INEFFECTIVE_LIMIT = 8  # only consulted when fixed=True

    def __init__(self, corridor: Corridor, start: Tuple[float, float],
                 goal_z: float, fixed: bool) -> None:
        self.c = corridor
        self.fixed = fixed
        self.x, self.z = start
        self.goal_z = goal_z
        self.path: List[Tuple[float, float]] = []
        self.replan = True
        self.last_pos = (0.0, 0.0)
        self.stall_t = 0.0
        self.learned = 0          # the verdict's `cells_unlearned`
        self.stalls = 0           # every stall event, effective or not
        self.ineffective = 0      # consecutive stalls that erased nothing
        self.distinct: Set[Cell] = set()
        self.verdict = ""
        self.t = 0.0

    # -- physics ---------------------------------------------------------
    def _try_move(self, dx: float, dz: float) -> None:
        """move_and_slide, reduced to what matters here: a solid cell is a wall.

        Each axis is tried on its own, which is what sliding amounts to when
        the obstacle is axis-aligned.
        """
        nx, nz = self.x + dx, self.z + dz
        if (int(nx // 1), int(self.z // 1)) not in self.c.solid:
            self.x = nx
        if (int(self.x // 1), int(nz // 1)) not in self.c.solid:
            self.z = nz

    # -- the planner -----------------------------------------------------
    def _plan(self) -> None:
        start = (int(self.x // 1), int(self.z // 1))
        if start not in self.c.cells:
            found = None
            for r in range(1, 4):
                for dz in range(-r, r + 1):
                    for dx in range(-r, r + 1):
                        if (start[0] + dx, start[1] + dz) in self.c.cells:
                            found = (start[0] + dx, start[1] + dz)
                            break
                    if found:
                        break
                if found:
                    break
            if not found:
                if self.fixed:
                    self.path = []          # <-- the fix, at line 3820
                return
            start = found

        prev: Dict[Cell, Cell] = {start: start}
        q = deque([start])
        best = start
        while q:
            cur = q.popleft()
            if cur[1] > best[1]:
                best = cur
            for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (cur[0] + d[0], cur[1] + d[1])
                if n in self.c.cells and n not in prev:
                    prev[n] = cur
                    q.append(n)

        if best == start:
            if self.fixed:
                self.path = []              # <-- the fix, at line 3837
                self.frontier = best[1]
            return

        path: List[Tuple[float, float]] = []
        cur = best
        while cur != start:
            path.insert(0, (cur[0] + 0.5, cur[1] + 0.5))
            cur = prev[cur]
        self.path = path

    # -- the stall handler ------------------------------------------------
    def _on_stall(self) -> bool:
        """Returns False when the run is over. Mirrors lines 3767-3784."""
        self.stalls += 1
        erased = False
        if self.path:
            blocked = (int(self.path[0][0] // 1), int(self.path[0][1] // 1))
            if blocked in self.c.cells:
                self.c.cells.discard(blocked)
                self.distinct.add(blocked)
                erased = True

        if self.fixed:
            # The budget is spent on information, not on grinding. A stall that
            # erased nothing is not a lesson, and eight of them in a row means
            # the planner has nothing left to say.
            if erased:
                self.learned += 1
                self.ineffective = 0
            else:
                self.ineffective += 1
                if self.ineffective >= self.INEFFECTIVE_LIMIT:
                    self.verdict = "no_route"
                    return False
        else:
            self.learned += 1           # counts stalls, calls them cells

        self.stall_t = 0.0
        self.replan = True
        if self.learned > UNLEARN_BUDGET:
            self.verdict = "unlearn_budget"
            return False
        return True

    # -- the frame loop ---------------------------------------------------
    def run(self, max_seconds: float = 120.0) -> str:
        self.frontier = -1
        while self.t < max_seconds:
            self.t += TICK
            if self.z >= self.goal_z:
                self.verdict = "pass"
                return self.verdict

            here = (self.x, self.z)
            moved = ((here[0] - self.last_pos[0]) ** 2
                     + (here[1] - self.last_pos[1]) ** 2) ** 0.5
            if moved > STALL_DISTANCE:
                self.last_pos = here
                self.stall_t = 0.0
            else:
                self.stall_t += TICK
                if self.stall_t > STALL_SECONDS:
                    if not self._on_stall():
                        return self.verdict

            if self.replan or not self.path:
                self.replan = False
                self._plan()
            if not self.path:
                continue                    # velocity = ZERO

            wx, wz = self.path[0]
            tx, tz = wx - self.x, wz - self.z
            if (tx * tx + tz * tz) ** 0.5 < ARRIVE:
                self.path.pop(0)
                continue
            n = (tx * tx + tz * tz) ** 0.5
            self._try_move(tx / n * WALK_SPEED * TICK, tz / n * WALK_SPEED * TICK)
        self.verdict = "timeout"
        return self.verdict


def _corridor() -> Corridor:
    # Eight cells wide, the width the real corridor reports, and a sealed row
    # at z=45 — the boundary the live walker dies against at z=44.65.
    return Corridor(range(4, 12), range(0, 61), wall_z=45)


def test_head_burns_the_budget_on_one_cell() -> None:
    """The code at HEAD: 26 'cells unlearned', 8 cells actually unlearned."""
    w = Walker(_corridor(), start=(7.5, 0.5), goal_z=102.0, fixed=False)
    verdict = w.run()

    assert verdict == "unlearn_budget", verdict
    assert w.learned == 26, f"expected the reported 26, got {w.learned}"
    assert len(w.distinct) == 8, f"expected 8 real cells, got {len(w.distinct)}"
    # This is the whole finding: the verdict over-reports by the width of the
    # wall it never mentions.
    assert w.learned > len(w.distinct) * 3
    # And the walker is pinned, not searching — it dies against the wall row.
    assert 44.0 <= w.z < 45.0, w.z
    print(f"  HEAD      : verdict={verdict:16s} reported={w.learned:3d} "
          f"real={len(w.distinct):2d} stalls={w.stalls:3d} z={w.z:.4f}")


def test_head_grinds_after_the_route_dies() -> None:
    """Once BFS has nothing deeper, every further stall is a no-op.

    Proven by the gap between stall events and cells removed, and by the
    walker's position not changing across the tail of the run.
    """
    w = Walker(_corridor(), start=(7.5, 0.5), goal_z=102.0, fixed=False)
    w.run()
    no_ops = w.stalls - len(w.distinct)
    assert no_ops == 18, f"expected 18 no-op stalls, got {no_ops}"
    print(f"  HEAD      : {no_ops} of {w.stalls} stall events erased nothing")


def test_fix_reports_no_route_instead() -> None:
    """The fix: the same corridor, told truthfully and told sooner."""
    w = Walker(_corridor(), start=(7.5, 0.5), goal_z=102.0, fixed=True)
    verdict = w.run()

    assert verdict == "no_route", verdict
    assert w.learned == len(w.distinct) == 8, (w.learned, len(w.distinct))
    assert w.learned < UNLEARN_BUDGET, "the budget must survive an honest failure"
    assert w.frontier == 44, f"frontier should be the last reachable z, got {w.frontier}"
    assert w.stalls < 26, f"the fix must fail sooner, not later ({w.stalls})"
    print(f"  FIXED     : verdict={verdict:16s} reported={w.learned:3d} "
          f"real={len(w.distinct):2d} stalls={w.stalls:3d} frontier=z{w.frontier}")


def test_fix_still_fails_a_genuinely_broken_corridor() -> None:
    """The negative test that makes the fix worth landing.

    A fix to a gate is only trustworthy if it cannot turn red into green. Here
    the wall is wider than the budget: every stall unlearns a real cell, so the
    ineffective-stall path is never taken and the budget still fires.
    """
    c = Corridor(range(0, 40), range(0, 61), wall_z=45)   # 40 cells of wall
    w = Walker(c, start=(20.5, 0.5), goal_z=102.0, fixed=True)
    verdict = w.run(max_seconds=240.0)

    assert verdict == "unlearn_budget", verdict
    assert w.learned == 26, w.learned
    assert len(w.distinct) == 26, len(w.distinct)
    print(f"  FIXED/neg : verdict={verdict:16s} reported={w.learned:3d} "
          f"real={len(w.distinct):2d} — a real 26-cell wall still fails")


def test_fix_does_not_disturb_a_clear_corridor() -> None:
    """And it must not touch a corridor that was already walkable."""
    c = Corridor(range(4, 12), range(0, 61), wall_z=45)
    c.solid.clear()
    for fixed in (False, True):
        cc = Corridor(range(4, 12), range(0, 61), wall_z=45)
        cc.solid.clear()
        w = Walker(cc, start=(7.5, 0.5), goal_z=59.0, fixed=fixed)
        verdict = w.run()
        assert verdict == "pass", (fixed, verdict, w.z)
        assert w.learned == 0, (fixed, w.learned)
    print("  BOTH      : an unobstructed corridor still passes, 0 unlearned")


def main() -> int:
    tests = [
        test_head_burns_the_budget_on_one_cell,
        test_head_grinds_after_the_route_dies,
        test_fix_reports_no_route_instead,
        test_fix_still_fails_a_genuinely_broken_corridor,
        test_fix_does_not_disturb_a_clear_corridor,
    ]
    print("autopilot planner bench — endless_museum.gd _run_autopilot/_auto_plan")
    failed = 0
    for t in tests:
        try:
            t()
        except AssertionError as e:
            failed += 1
            print(f"  FAIL {t.__name__}: {e}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
