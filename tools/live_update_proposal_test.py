"""live_update_proposal_test.py — the end-to-end check of the PROPOSAL lane.

2026-10-22. The lane: a proposal is filed from the CLI (tools/live_update_propose.py
-> POST /api/live-update/proposals -> ada_run/live_proposals/<id>.json), a PERSON
accepts it in /lab-editor?mode=void through the browser (the Proposals strip),
the editor applies it through its own save path (POST /api/void-layout: revision
check, validator, publish), the desktop game answers update_ack, and the decision
lands as a {k:"proposal"} row in ada_run/live_updates.jsonl beside that ack.
Then a second proposal is rejected, and a third (the move back) accepted so the
file ends byte-identical.

This script does everything EXCEPT the clicks: it starts the bridge and the game
if asked, files the proposals, prints the editor URL, waits for the decisions,
and checks the ledger after each. Report: ada_run/live_update_proposal_test_<stamp>.md.

  python tools/live_update_proposal_test.py                 # starts the game; the bridge must know /proposal
  python tools/live_update_proposal_test.py --no-game       # a Void game is already attached (yours)
  python tools/live_update_proposal_test.py --floor 3 --id museum-point_lines-31-12 --dx 1

Needs the encyclopedia dev server on localhost:3003 (ADA_ENC_URL).
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from live_update_test import BRIDGE, ENC, LOG, acks_for, bridge_state, http, launch_void, say, wait_for  # noqa: E402

LEDGER = ROOT / "ada_run" / "live_updates.jsonl"
STORE = ROOT / "ada_run" / "live_proposals"


def ledger_rows(pred) -> list[dict]:
    if not LEDGER.exists():
        return []
    out = []
    for line in LEDGER.read_text(encoding="utf-8").splitlines():
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if pred(row):
            out.append(row)
    return out


def file_proposal(args_list: list[str]) -> str:
    cmd = [sys.executable, str(ROOT / "tools" / "live_update_propose.py"), *args_list]
    r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8")
    say("  $ " + " ".join(a if " " not in a else repr(a) for a in cmd[1:]))
    for line in (r.stdout + r.stderr).strip().splitlines():
        say("    " + line)
    m = re.search(r"filed (prop-[0-9TZ]+-[0-9a-f]+)", r.stdout)
    if r.returncode != 0 or not m:
        raise SystemExit("the CLI did not file the proposal")
    return m.group(1)


def proposal(pid: str) -> dict:
    code, j = http("GET", f"{ENC}/api/live-update/proposals?id={pid}", timeout=5)
    return (j.get("proposal") or {}) if code == 200 else {}


def wait_decision(pid: str, timeout: float) -> dict:
    got: dict = {}

    def decided() -> bool:
        nonlocal got
        got = proposal(pid)
        return got.get("status") in ("accepted", "rejected")
    wait_for(decided, f"a decision on {pid} in the editor", timeout, every=1.5)
    return got


def check(cond: bool, what: str, fails: list[str]) -> None:
    say(f"  {'PASS' if cond else 'FAIL'}: {what}")
    if not cond:
        fails.append(what)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--floor", type=int, default=10)
    ap.add_argument("--id", help="the artifact to move (default: the floor's last artifact)")
    ap.add_argument("--dx", type=float, default=1.5)
    ap.add_argument("--no-game", action="store_true", help="a Void game is already attached")
    ap.add_argument("--no-bridge", action="store_true", help="never start vr_link.py")
    ap.add_argument("--wait", type=float, default=900.0, help="seconds to wait for each decision (a person clicks)")
    ap.add_argument("--ack-timeout", type=float, default=25.0)
    ap.add_argument("--attach-timeout", type=float, default=90.0)
    args = ap.parse_args()

    stamp = time.strftime("%Y%m%d-%H%M%S")
    report = ROOT / "ada_run" / f"live_update_proposal_test_{stamp}.md"
    say(f"# Proposal lane test — {stamp}")
    say("")
    fails: list[str] = []
    procs: list[subprocess.Popen] = []
    rooms_file = ROOT / "commons" / "void" / "rooms.json"
    text0 = rooms_file.read_text(encoding="utf-8")

    try:
        # ── the bridge, and does it know /proposal? ───────────────────────
        if not bridge_state():
            if args.no_bridge:
                say("bridge is down and --no-bridge given")
                return 1
            procs.append(subprocess.Popen([sys.executable, str(ROOT / "tools" / "vr_link.py")], cwd=ROOT,
                                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
            say("bridge launched: tools/vr_link.py")
            if not wait_for(lambda: bool(bridge_state()), "the bridge", 20):
                return 1
        code, j = http("POST", f"{BRIDGE}/proposal", {}, timeout=5)
        knows = code == 400 and "decision" in str(j.get("error", ""))
        check(knows, f"the running bridge knows POST /proposal ({code} {j.get('error', '')!s:.40})", fails)
        if not knows:
            say("  restart python tools/vr_link.py on the current code")
            return 1

        # ── the game ───────────────────────────────────────────────────────
        if not args.no_game:
            procs.append(launch_void(args.floor))
            say(f"desktop game launched: void.tscn --void-start-floor={args.floor} --vr-link")

        def attached() -> bool:
            st = bridge_state()
            return bool(st.get("connected")) and (st.get("pose") or {}).get("proj") == "void" and int(st.get("games", 0)) >= 1
        if not wait_for(attached, "the Void to attach (pose proj=void)", args.attach_timeout, every=2.0):
            return 1
        st = bridge_state()
        say(f"attached: games={st.get('games')} names={st.get('game_names')} proj=void")
        time.sleep(4.0)

        # ── which artifact ─────────────────────────────────────────────────
        floors = json.loads(text0).get("floors", [])
        fl = floors[args.floor]
        rec = next((a for a in fl["artifacts"] if a.get("id") == args.id), None) if args.id else (fl["artifacts"] or [None])[-1]
        if not rec:
            say(f"no artifact {args.id!r} on floor {args.floor}")
            return 1
        rid_art = rec["id"]
        pos0 = list(rec.get("position", [0, 0]))
        say(f"subject: {rid_art} ({rec.get('artifact')}) on floor {args.floor} at {pos0}")
        url = f"{ENC}/lab-editor?mode=void&floor={args.floor}"
        common = ["--void", "--floor", str(args.floor), "--as", "cli:proposal-test"]

        # ── 1. file A (+dx) and B (+2dx), the person accepts A ────────────
        say("")
        say(f"## 1. file proposal A: move {rid_art} by +{args.dx} in x")
        a_id = file_proposal([*common, "--move", rid_art, "--dx", str(args.dx), "--note", f"test A: move +{args.dx} m in x (accept this one)"])
        say("")
        say(f"## 2. file proposal B: move {rid_art} by +{2 * args.dx} in x — to be REJECTED")
        b_id = file_proposal([*common, "--move", rid_art, "--dx", str(2 * args.dx), "--note", "test B: a second move (reject this one)"])
        code, j = http("GET", f"{ENC}/api/live-update/proposals?target=void&floor={args.floor}", timeout=5)
        pending = [p["id"] for p in j.get("proposals", [])]
        check(a_id in pending and b_id in pending, f"GET lists both as pending for floor {args.floor} ({len(pending)} pending)", fails)
        say("")
        say(f"**Now, in the browser:** open {url} — the Proposals strip shows A and B. Press **Accept** on A, **Reject** on B.")
        say("")

        t_before = time.time()
        a = wait_decision(a_id, args.wait)
        d = a.get("decision") or {}
        check(a.get("status") == "accepted", f"A {a_id} accepted by {d.get('by')} -> {d.get('revision_id')}", fails)
        rev_a = d.get("revision_id") or ""
        check(bool(rev_a), "the accept carries the revision id the editor's save produced", fails)
        check(d.get("ledger") is True, f"the decision reached the bridge's ledger (ledger={d.get('ledger')} {d.get('ledger_error', '')})", fails)
        if rev_a:
            acks: list[dict] = []

            def have() -> bool:
                nonlocal acks
                acks = [x for x in acks_for(rev_a, since=t_before) if x.get("device") == "Windows"]
                return bool(acks)
            wait_for(have, f"the desktop's update_ack for {rev_a}", args.ack_timeout)
            last = acks[-1] if acks else {}
            check(last.get("status") == "applied", f"desktop ack for {rev_a}: {last.get('name', last.get('device'))} {last.get('status')} {last.get('mode', '')} — {last.get('detail', '')}", fails)
            rows = ledger_rows(lambda r: (r.get("revision_id") or (r.get("env") or {}).get("revision_id")) == rev_a)
            kinds = [r.get("k") for r in rows]
            prop_rows = [r for r in rows if r.get("k") == "proposal"]
            check(bool(prop_rows) and prop_rows[-1].get("id") == a_id and prop_rows[-1].get("decision") == "accept",
                  f"ada_run/live_updates.jsonl holds the proposal row beside the ack: {kinds}", fails)
            moved = json.loads(rooms_file.read_text(encoding="utf-8"))["floors"][args.floor]
            now = next((x for x in moved["artifacts"] if x.get("id") == rid_art), {}).get("position")
            check(now == [round(pos0[0] + args.dx, 3), pos0[1]], f"rooms.json now places {rid_art} at {now}", fails)

        # ── 3. B rejected ──────────────────────────────────────────────────
        say("")
        say("## 3. B rejected")
        b = wait_decision(b_id, args.wait)
        d = b.get("decision") or {}
        check(b.get("status") == "rejected", f"B {b_id} rejected by {d.get('by')}", fails)
        prow = ledger_rows(lambda r: r.get("k") == "proposal" and r.get("id") == b_id)
        check(bool(prow) and prow[-1].get("decision") == "reject", "the reject is a {k:proposal} row in the ledger", fails)
        unchanged = json.loads(rooms_file.read_text(encoding="utf-8"))["floors"][args.floor]
        now = next((x for x in unchanged["artifacts"] if x.get("id") == rid_art), {}).get("position")
        check(now == [round(pos0[0] + args.dx, 3), pos0[1]], f"the reject changed nothing: {rid_art} still at {now}", fails)

        # ── 4. C: the move back, accepted ──────────────────────────────────
        say("")
        say(f"## 4. file proposal C: move {rid_art} back by -{args.dx} — accept it")
        c_id = file_proposal([*common, "--move", rid_art, "--dx", str(-args.dx), "--note", "test C: move back (accept)"])
        say(f"**In the browser:** Accept C.")
        t_c = time.time()
        c = wait_decision(c_id, args.wait)
        d = c.get("decision") or {}
        rev_c = d.get("revision_id") or ""
        check(c.get("status") == "accepted" and bool(rev_c), f"C {c_id} accepted -> {rev_c}", fails)
        if rev_c:
            acks = []

            def have_c() -> bool:
                nonlocal acks
                acks = [x for x in acks_for(rev_c, since=t_c) if x.get("device") == "Windows"]
                return bool(acks)
            wait_for(have_c, f"the desktop's update_ack for {rev_c}", args.ack_timeout)
            last = acks[-1] if acks else {}
            check(last.get("status") == "applied", f"desktop ack for {rev_c}: {last.get('status')} {last.get('mode', '')} — {last.get('detail', '')}", fails)
        text1 = rooms_file.read_text(encoding="utf-8")
        check(text1 == text0, "rooms.json byte-identical to the start", fails)

        say("")
        say("## Verdict")
        say("**PASS**" if not fails else "**FAIL**: " + "; ".join(fails))
        return 0 if not fails else 1
    finally:
        for p in procs:
            try:
                p.terminate()
            except OSError:
                pass
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text("\n".join(LOG) + "\n", encoding="utf-8")
        print(f"report: {report}")


if __name__ == "__main__":
    sys.exit(main())
