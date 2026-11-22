"""tower_atlas.py — Agent CLI for the Void Tower System Atlas (schema v2).

Talks to the live Ada Encyclopedia Agent API (http://localhost:3003/api/tower-atlas/agent)
when the Next.js server is running.

Concurrency & honesty rules (seatbelts, not blocking gates):
- Offline READS always work directly against commons/data/tower_system_atlas.json.
- Live WRITES require --as=<name> and --rev=<N> (expectedRevision -> HTTP 409 on conflict).
- --dry-run validates and prints a real field-by-field before/after diff without writing.
- Setting --evidence above "planned" requires --receipt="<checks.json path | commit | probe>".
- Offline writes require explicit --offline-write and acquire the exact same cross-process
  lockfile (commons/data/.tower_system_atlas.lock) used by the Next.js server.

Examples:
  python tools/tower_atlas.py brief --md
  python tools/tower_atlas.py floor 3 --md
  python tools/tower_atlas.py floor 7 --md
  python tools/tower_atlas.py list --seq=transformation --md
  python tools/tower_atlas.py gaps --md
  python tools/tower_atlas.py breadcrumbs --seq=primitives --missing --md
  python tools/tower_atlas.py machines --seq=primitives --md
  python tools/tower_atlas.py queer --md
  python tools/tower_atlas.py set-floor Point_Lines --plain="..." --as=Codex --rev=3 --dry-run
  python tools/tower_atlas.py set-encounter keeps_door "Reset the line, then walk through the door that stays open." --as=Codex --rev=3
  python tools/tower_atlas.py queer-obs Point_Lines multi-reading "The number clears on RESET while the door stays open." --encounter=keeps_door --as=Codex --rev=3
  python tools/tower_atlas.py note Point_Animatedcube "Verified prefab_belt on F7." --as=fable-prefab-belt --rev=3
"""
from __future__ import annotations

import argparse
import contextlib
import json
import os
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from urllib import parse as urlparse
from urllib import request as urlrequest
from urllib.error import HTTPError, URLError

ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "commons/data/tower_system_atlas.json"
LOCK = ROOT / "commons/data/.tower_system_atlas.lock"
SPINE = ROOT / "commons/void/spine.json"
API = os.environ.get("ADA_ATLAS_API", "http://localhost:3003/api/tower-atlas/agent")


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


@contextlib.contextmanager
def _atlas_lock(actor: str):
    LOCK.parent.mkdir(parents=True, exist_ok=True)
    deadline = time.monotonic() + 2.5
    token = json.dumps({"pid": os.getpid(), "by": actor, "at": _now_iso()}).encode("utf-8")
    fd = None
    while True:
        try:
            fd = os.open(str(LOCK), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.write(fd, token)
            os.close(fd)
            fd = None
            break
        except FileExistsError:
            try:
                if time.time() - LOCK.stat().st_mtime > 15.0:
                    LOCK.unlink(missing_ok=True)
                    continue
            except FileNotFoundError:
                continue
            if time.monotonic() > deadline:
                sys.stderr.write("Lock timeout waiting for commons/data/.tower_system_atlas.lock\n")
                sys.exit(1)
            time.sleep(0.03)
    try:
        yield
    finally:
        try:
            LOCK.unlink(missing_ok=True)
        except OSError:
            pass


def _http_get(params: dict[str, str]) -> tuple[str, str] | None:
    qs = urlparse.urlencode({k: v for k, v in params.items() if v is not None and v != ""})
    url = f"{API}?{qs}" if qs else API
    try:
        with urlrequest.urlopen(url, timeout=12.0) as resp:
            ctype = resp.headers.get("Content-Type", "application/json")
            return resp.read().decode("utf-8"), ctype
    except HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        sys.stderr.write(f"HTTP {exc.code}: {body}\n")
        sys.exit(1)
    except (URLError, TimeoutError, ConnectionError):
        return None


def _http_post(payload: dict) -> dict | None:
    data = json.dumps(payload).encode("utf-8")
    req = urlrequest.Request(API, data=data, headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urlrequest.urlopen(req, timeout=15.0) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        sys.stderr.write(f"HTTP {exc.code}: {body}\n")
        sys.exit(1)
    except (URLError, TimeoutError, ConnectionError):
        return None


def _load_store() -> dict:
    if not STORE.exists():
        return {
            "version": 2,
            "revision": 1,
            "updated": "",
            "orders": [],
            "layers": [],
            "encounterBreadcrumbs": {},
            "songBreadcrumbs": {},
            "floors": {},
            "history": [],
        }
    return json.loads(STORE.read_text(encoding="utf-8"))


def _save_store_atomic(data: dict, by: str, action: str, target: str, summary: str, receipt: str = "") -> int:
    next_rev = int(data.get("revision", 1)) + 1
    data["version"] = max(2, int(data.get("version", 2)))
    data["revision"] = next_rev
    data["updated"] = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    hist = data.get("history")
    if not isinstance(hist, list):
        hist = []
    entry = {"at": _now_iso(), "by": by, "action": action, "target": target, "summary": summary}
    if receipt:
        entry["receipt"] = receipt
    hist.insert(0, entry)
    data["history"] = hist[:300]
    tmp = STORE.with_suffix(f".{os.getpid()}.{uuid.uuid4().hex[:6]}.tmp")
    tmp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    os.replace(tmp, STORE)
    return next_rev


def _resolve_map_offline(target: str) -> str:
    if SPINE.exists():
        sp = json.loads(SPINE.read_text(encoding="utf-8"))
        floors = sp.get("floors", [])
        if target.isdigit():
            n = int(target)
            for row in floors:
                if int(row.get("floor", -1)) == n:
                    return str(row["map"])
        for row in floors:
            if str(row.get("map", "")).lower() == target.lower():
                return str(row["map"])
    return target


def _diff_flat(prefix: str, before, after, out: list[dict]) -> None:
    if json.dumps(before, sort_keys=True) == json.dumps(after, sort_keys=True):
        return
    if isinstance(before, dict) and isinstance(after, dict):
        for k in sorted(set(before.keys()) | set(after.keys())):
            _diff_flat(f"{prefix}.{k}" if prefix else k, before.get(k), after.get(k), out)
        return
    out.append({"path": prefix, "before": before, "after": after})


def _print_result(params: dict[str, str], offline_fallback) -> None:
    res = _http_get(params)
    if res is not None:
        text, _ = res
        print(text, end="" if text.endswith("\n") else "\n")
        return
    out = offline_fallback()
    if isinstance(out, str):
        print(out)
    else:
        print(json.dumps(out, indent=2, ensure_ascii=False))


def _require_offline_write_allowed(args) -> None:
    if not getattr(args, "dry_run", False) and not getattr(args, "offline_write", False):
        sys.stderr.write(
            "Ada Encyclopedia API is offline. Offline READS work automatically, "
            "but offline WRITES require --offline-write (lockfile-guarded) or a live server on :3003.\n"
        )
        sys.exit(1)


def _check_offline_rev(store: dict, args) -> int:
    cur_rev = int(store.get("revision", 1))
    if not getattr(args, "dry_run", False) and args.rev is None:
        sys.stderr.write(f"Missing required --rev for live write (current revision is {cur_rev}).\n")
        sys.exit(1)
    if args.rev is not None and cur_rev != args.rev:
        sys.stderr.write(f"Revision conflict offline: expected {args.rev}, current {cur_rev}\n")
        sys.exit(1)
    return cur_rev


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")
    ap = argparse.ArgumentParser(description="Agent CLI for the Ada Research Void Tower System Atlas (v2).")
    sub = ap.add_subparsers(dest="cmd", required=True)

    p_brief = sub.add_parser("brief", help="Compact 3-Orders x 10-Layers system overview")
    p_brief.add_argument("--md", action="store_true")

    p_floor = sub.add_parser("floor", help="Inspect one floor by number (3, 7, 13) or map name (Point_Lines)")
    p_floor.add_argument("target")
    p_floor.add_argument("--md", action="store_true")

    p_list = sub.add_parser("list", help="Filter compact floor rows")
    p_list.add_argument("--seq", "--sequence", dest="seq", default="")
    p_list.add_argument("--spine", action="store_true")
    p_list.add_argument("--stage", default="")
    p_list.add_argument("--evidence", default="")
    p_list.add_argument("--missing", default="", help="plain_breadcrumb|void_md|queer_operator|machine_coupling|lights|installed_encounters")
    p_list.add_argument("--q", default="")
    p_list.add_argument("--limit", type=int, default=60)
    p_list.add_argument("--md", action="store_true")

    p_gaps = sub.add_parser("gaps", help="Show forward upgrade queue across the tower (never blocking gates)")
    p_gaps.add_argument("--md", action="store_true")

    p_bc = sub.add_parser("breadcrumbs", help="List paired Installed Encounters + terms.json Formulas <-> Plain Breadcrumbs")
    p_bc.add_argument("--seq", "--sequence", dest="seq", default="")
    p_bc.add_argument("--missing", action="store_true")
    p_bc.add_argument("--limit", type=int, default=40)
    p_bc.add_argument("--md", action="store_true")

    p_m = sub.add_parser("machines", help="List live items.json + prefab_belt + registry machine timeline")
    p_m.add_argument("--seq", "--sequence", dest="seq", default="")
    p_m.add_argument("--limit", type=int, default=60)
    p_m.add_argument("--md", action="store_true")

    p_q = sub.add_parser("queer", help="List Queer Ontology (4 modes + competing observations) & Body map")
    p_q.add_argument("--seq", "--sequence", dest="seq", default="")
    p_q.add_argument("--limit", type=int, default=60)
    p_q.add_argument("--md", action="store_true")

    p_pg = sub.add_parser("playground", help="List L9 General Intellect Playground Layer (8 arcs, 26 sequences, Studio Workstations, Template Tables, Worker Assemblages)")
    p_pg.add_argument("--seq", "--sequence", dest="seq", default="")
    p_pg.add_argument("--md", action="store_true")

    def add_write_flags(parser):
        parser.add_argument("--as", dest="actor", required=True, help="Agent/author name (e.g. Codex, fable-prefab-belt, Antigravity, Palle)")
        parser.add_argument("--rev", type=int, help="Current atlas revision (required on all non-dry-run writes)")
        parser.add_argument("--dry-run", action="store_true", help="Validate and return field-level diff without writing")
        parser.add_argument("--offline-write", action="store_true", help="Allow lockfile-guarded direct write if API is offline")

    p_sf = sub.add_parser("set-floor", help="Update a floor's curatorial state (revision-checked)")
    p_sf.add_argument("target", help="Floor number or map name")
    p_sf.add_argument("--stage", choices=["scaffold", "playable", "opera-bound", "void-edition", "frozen"])
    p_sf.add_argument("--evidence", choices=["planned", "desktop", "quest", "human-witnessed", "frozen-edition"])
    p_sf.add_argument("--receipt", help="Evidence receipt (checks.json path, probe result, commit, or forum ID)")
    p_sf.add_argument("--plain", help="Plain easy-to-understand floor breadcrumb")
    p_sf.add_argument("--machine", help="Desiring-machine/robot name")
    p_sf.add_argument("--activates", help="What partial object/capability activates here")
    p_sf.add_argument("--couples-into", dest="couples_into", help="Downstream floor or machine it plugs into")
    p_sf.add_argument("--queer-mode", dest="queer_mode", choices=["denaturalize", "re-couple", "bodily-remainder", "multi-reading"])
    p_sf.add_argument("--queer-note", dest="queer_note")
    p_sf.add_argument("--body", help="Body / wearable / care hook")
    p_sf.add_argument("--note", help="Replace steering note")
    add_write_flags(p_sf)

    p_se = sub.add_parser("set-encounter", help="Set plain observable breadcrumb keyed to an encounter ID (e.g. keeps_door, line_black_box)")
    p_se.add_argument("encounter_id")
    p_se.add_argument("plain")
    add_write_flags(p_se)

    p_ss = sub.add_parser("set-song", help="Set plain breadcrumb keyed to a song object_id")
    p_ss.add_argument("song_id")
    p_ss.add_argument("plain")
    add_write_flags(p_ss)

    p_note = sub.add_parser("note", help="Append a dated steering note to a floor")
    p_note.add_argument("target")
    p_note.add_argument("text")
    add_write_flags(p_note)

    p_qo = sub.add_parser("queer-obs", help="Append a competing or provisional queer observation to a floor (non-overwriting)")
    p_qo.add_argument("target", help="Floor number or map name")
    p_qo.add_argument("mode", choices=["denaturalize", "re-couple", "bodily-remainder", "multi-reading"])
    p_qo.add_argument("observation")
    p_qo.add_argument("--encounter", dest="encounter_id", default="", help="Optional encounter ID this observation attaches to")
    add_write_flags(p_qo)

    args = ap.parse_args()
    fmt = "md" if getattr(args, "md", False) else ""

    if args.cmd == "brief":
        _print_result({"view": "brief", "format": fmt}, lambda: _load_store())
        return
    if args.cmd == "floor":
        _print_result(
            {"floor": args.target, "format": fmt},
            lambda: {
                "offline": True,
                "revision": _load_store().get("revision", 1),
                "map": _resolve_map_offline(args.target),
                "curation": _load_store().get("floors", {}).get(_resolve_map_offline(args.target), {}),
            },
        )
        return
    if args.cmd == "list":
        _print_result(
            {
                "view": "list",
                "sequence": args.seq,
                "spine": "1" if args.spine else "",
                "stage": args.stage,
                "evidence": args.evidence,
                "missing": args.missing,
                "q": args.q,
                "limit": str(args.limit),
                "format": fmt,
            },
            lambda: {"offline": True, "revision": _load_store().get("revision", 1), "curated_floors": list(_load_store().get("floors", {}).keys())},
        )
        return
    if args.cmd == "gaps":
        _print_result({"view": "gaps", "format": fmt}, lambda: {"offline": True, "note": "Start ada_encyclopedia on :3003 for live 210-floor upgrade queue."})
        return
    if args.cmd == "breadcrumbs":
        _print_result(
            {"view": "breadcrumbs", "sequence": args.seq, "missing_plain": "1" if args.missing else "", "limit": str(args.limit), "format": fmt},
            lambda: {
                "offline": True,
                "revision": _load_store().get("revision", 1),
                "encounterBreadcrumbs": _load_store().get("encounterBreadcrumbs", {}),
                "songBreadcrumbs": _load_store().get("songBreadcrumbs", {}),
            },
        )
        return
    if args.cmd == "machines":
        _print_result({"view": "machines", "sequence": args.seq, "limit": str(args.limit), "format": fmt}, lambda: {"offline": True, "floors": _load_store().get("floors", {})})
        return
    if args.cmd == "queer":
        _print_result({"view": "queer", "sequence": args.seq, "limit": str(args.limit), "format": fmt}, lambda: {"offline": True, "floors": _load_store().get("floors", {})})
        return
    if args.cmd == "playground":
        def _offline_pg():
            pg_path = ROOT / "commons/data/playground_layer.json"
            return json.loads(pg_path.read_text(encoding="utf-8")) if pg_path.exists() else {"offline": True, "error": "playground_layer.json not found"}
        _print_result({"view": "playground", "sequence": args.seq, "format": fmt}, _offline_pg)
        return

    # --- WRITE ACTIONS (all validated + revision-checked + real diff preview) ---
    if args.cmd == "set-floor":
        patch: dict = {}
        if args.stage:
            patch["stage"] = args.stage
        if args.evidence:
            patch["evidenceTier"] = args.evidence
        if args.receipt is not None:
            patch["evidenceReceipt"] = args.receipt
        if args.plain is not None:
            patch["plainBreadcrumb"] = args.plain
        if args.body is not None:
            patch["bodyHook"] = args.body
        if args.note is not None:
            patch["note"] = args.note
        if any(x is not None for x in (args.machine, args.activates, args.couples_into)):
            patch["desiringMachine"] = {
                "machine": args.machine or "",
                "activates": args.activates or "",
                "couplesInto": args.couples_into or "",
            }
        if any(x is not None for x in (args.queer_mode, args.queer_note)):
            patch["queerOperator"] = {
                "mode": args.queer_mode or "",
                "note": args.queer_note or "",
            }
        payload: dict = {"action": "update_floor", "map": args.target, "by": args.actor, "patch": patch, "dryRun": args.dry_run}
        if args.rev is not None:
            payload["expectedRevision"] = args.rev
        resp = _http_post(payload)
        if resp is not None:
            print(json.dumps(resp, indent=2, ensure_ascii=False))
            return

        _require_offline_write_allowed(args)
        ctx = _atlas_lock(args.actor) if not args.dry_run else contextlib.nullcontext()
        with ctx:
            store = _load_store()
            cur_rev = _check_offline_rev(store, args)
            map_id = _resolve_map_offline(args.target)
            prev = json.loads(json.dumps(store.get("floors", {}).get(map_id, {})))
            nxt = json.loads(json.dumps(prev))
            nxt.update(patch)
            if patch.get("evidenceTier") and patch["evidenceTier"] != "planned" and not str(nxt.get("evidenceReceipt", "")).strip():
                sys.stderr.write(f"Receipt required when setting evidenceTier={patch['evidenceTier']}. Pass --receipt.\n")
                sys.exit(1)
            diff: list[dict] = []
            _diff_flat(f"floors.{map_id}", prev, nxt, diff)
            if args.dry_run:
                print(json.dumps({"ok": True, "offline": True, "dryRun": True, "revision": cur_rev, "target": map_id, "diff": diff, "proposed": nxt}, indent=2, ensure_ascii=False))
                return
            store.setdefault("floors", {})[map_id] = nxt
            rev = _save_store_atomic(store, args.actor, "update_floor", map_id, f"Updated {', '.join(patch.keys())}", str(nxt.get("evidenceReceipt", "")))
            print(json.dumps({"ok": True, "offline": True, "dryRun": False, "revision": rev, "target": map_id, "diff": diff, "proposed": nxt}, indent=2, ensure_ascii=False))
        return

    if args.cmd == "set-encounter":
        payload = {"action": "set_encounter_breadcrumb", "encounterId": args.encounter_id, "plain": args.plain, "by": args.actor, "dryRun": args.dry_run}
        if args.rev is not None:
            payload["expectedRevision"] = args.rev
        resp = _http_post(payload)
        if resp is not None:
            print(json.dumps(resp, indent=2, ensure_ascii=False))
            return

        _require_offline_write_allowed(args)
        ctx = _atlas_lock(args.actor) if not args.dry_run else contextlib.nullcontext()
        with ctx:
            store = _load_store()
            cur_rev = _check_offline_rev(store, args)
            prev = store.get("encounterBreadcrumbs", {}).get(args.encounter_id, "")
            clean = args.plain.strip()
            diff = []
            _diff_flat(f"encounterBreadcrumbs.{args.encounter_id}", prev, clean, diff)
            if args.dry_run:
                print(json.dumps({"ok": True, "offline": True, "dryRun": True, "revision": cur_rev, "target": args.encounter_id, "diff": diff, "proposed": {"encounterId": args.encounter_id, "plain": clean}}, indent=2, ensure_ascii=False))
                return
            store.setdefault("encounterBreadcrumbs", {})[args.encounter_id] = clean
            rev = _save_store_atomic(store, args.actor, "set_encounter_breadcrumb", args.encounter_id, clean[:120])
            print(json.dumps({"ok": True, "offline": True, "dryRun": False, "revision": rev, "target": args.encounter_id, "diff": diff, "proposed": {"encounterId": args.encounter_id, "plain": clean}}, indent=2, ensure_ascii=False))
        return

    if args.cmd == "set-song":
        payload = {"action": "set_song_breadcrumb", "songId": args.song_id, "plain": args.plain, "by": args.actor, "dryRun": args.dry_run}
        if args.rev is not None:
            payload["expectedRevision"] = args.rev
        resp = _http_post(payload)
        if resp is not None:
            print(json.dumps(resp, indent=2, ensure_ascii=False))
            return

        _require_offline_write_allowed(args)
        ctx = _atlas_lock(args.actor) if not args.dry_run else contextlib.nullcontext()
        with ctx:
            store = _load_store()
            cur_rev = _check_offline_rev(store, args)
            prev = store.get("songBreadcrumbs", {}).get(args.song_id, "")
            clean = args.plain.strip()
            diff = []
            _diff_flat(f"songBreadcrumbs.{args.song_id}", prev, clean, diff)
            if args.dry_run:
                print(json.dumps({"ok": True, "offline": True, "dryRun": True, "revision": cur_rev, "target": args.song_id, "diff": diff, "proposed": {"songId": args.song_id, "plain": clean}}, indent=2, ensure_ascii=False))
                return
            store.setdefault("songBreadcrumbs", {})[args.song_id] = clean
            rev = _save_store_atomic(store, args.actor, "set_song_breadcrumb", args.song_id, clean[:120])
            print(json.dumps({"ok": True, "offline": True, "dryRun": False, "revision": rev, "target": args.song_id, "diff": diff, "proposed": {"songId": args.song_id, "plain": clean}}, indent=2, ensure_ascii=False))
        return

    if args.cmd == "note":
        payload = {"action": "append_note", "map": args.target, "note": args.text, "by": args.actor, "dryRun": args.dry_run}
        if args.rev is not None:
            payload["expectedRevision"] = args.rev
        resp = _http_post(payload)
        if resp is not None:
            print(json.dumps(resp, indent=2, ensure_ascii=False))
            return

        _require_offline_write_allowed(args)
        ctx = _atlas_lock(args.actor) if not args.dry_run else contextlib.nullcontext()
        with ctx:
            store = _load_store()
            cur_rev = _check_offline_rev(store, args)
            map_id = _resolve_map_offline(args.target)
            cur = store.setdefault("floors", {}).setdefault(map_id, {})
            prev = cur.get("note", "")
            line = f"[{datetime.now(timezone.utc).strftime('%Y-%m-%d')} · {args.actor}] {args.text.strip()}"
            nxt = f"{prev.strip()}\n{line}" if prev.strip() else line
            diff = []
            _diff_flat(f"floors.{map_id}.note", prev, nxt, diff)
            if args.dry_run:
                print(json.dumps({"ok": True, "offline": True, "dryRun": True, "revision": cur_rev, "target": map_id, "diff": diff, "proposed": {"note": nxt}}, indent=2, ensure_ascii=False))
                return
            cur["note"] = nxt
            rev = _save_store_atomic(store, args.actor, "append_note", map_id, args.text.strip()[:120])
            print(json.dumps({"ok": True, "offline": True, "dryRun": False, "revision": rev, "target": map_id, "diff": diff, "proposed": {"note": nxt}}, indent=2, ensure_ascii=False))
        return

    if args.cmd == "queer-obs":
        payload = {
            "action": "add_queer_observation",
            "map": args.target,
            "mode": args.mode,
            "observation": args.observation,
            "by": args.actor,
            "dryRun": args.dry_run,
        }
        if args.encounter_id:
            payload["encounterId"] = args.encounter_id
        if args.rev is not None:
            payload["expectedRevision"] = args.rev
        resp = _http_post(payload)
        if resp is not None:
            print(json.dumps(resp, indent=2, ensure_ascii=False))
            return

        _require_offline_write_allowed(args)
        ctx = _atlas_lock(args.actor) if not args.dry_run else contextlib.nullcontext()
        with ctx:
            store = _load_store()
            cur_rev = _check_offline_rev(store, args)
            map_id = _resolve_map_offline(args.target)
            cur = store.setdefault("floors", {}).setdefault(map_id, {})
            obs_list = list(cur.get("queerObservations", []))
            new_obs = {
                "id": f"qobs_{uuid.uuid4().hex[:8]}",
                "mode": args.mode,
                "observation": args.observation.strip(),
                "by": args.actor,
                "at": _now_iso(),
            }
            if args.encounter_id:
                new_obs["encounterId"] = args.encounter_id
            diff = [{"path": f"floors.{map_id}.queerObservations", "before": len(obs_list), "after": new_obs}]
            if args.dry_run:
                print(json.dumps({"ok": True, "offline": True, "dryRun": True, "revision": cur_rev, "target": map_id, "diff": diff, "proposed": new_obs}, indent=2, ensure_ascii=False))
                return
            obs_list.append(new_obs)
            cur["queerObservations"] = obs_list
            rev = _save_store_atomic(store, args.actor, "add_queer_observation", map_id, f"[{args.mode}] {args.observation.strip()[:120]}")
            print(json.dumps({"ok": True, "offline": True, "dryRun": False, "revision": rev, "target": map_id, "diff": diff, "proposed": new_obs}, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
