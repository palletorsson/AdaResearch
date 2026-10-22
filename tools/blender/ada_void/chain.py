"""chain.py — the live update chain as the web editor drives it. Pure Python (urllib).

Blender is a THIRD editor on the chain built 2026-10-22 (doc/LIVE_UPDATE_BRIDGE.md):

    GET  <enc>/api/void-layout            -> {rooms, revision, models, ...}
    POST <enc>/api/void-layout            {rooms, revision}  -> {saved, revision, live[]}
         (409 when `revision` is not the sha256 of the file on disk)
    GET  <enc>/api/live-update?id=<rev>   -> the bridge's ledger rows: the request
                                             and one update_ack per game

The save route itself diffs the file per floor, posts the envelopes to
tools/vr_link.py and returns `live` (one entry per changed floor, each with a
revision_id); the acks arrive a moment later and are read back from the ledger.
Nothing here imports bpy, so the test can exercise it from plain Python.
"""
from __future__ import annotations

import json
import time
import urllib.error
import urllib.request

DEFAULT_ENC = "http://localhost:3003"


class ChainError(Exception):
    def __init__(self, status: int, message: str, body: dict | None = None):
        super().__init__(message)
        self.status = status
        self.body = body or {}


def http(method: str, url: str, body: dict | None = None, timeout: float = 30.0) -> tuple[int, dict]:
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method,
                                 headers={"content-type": "application/json"} if data else {})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read().decode("utf-8") or "{}"
            return r.status, _parse(raw)
    except urllib.error.HTTPError as e:
        try:
            return e.code, _parse(e.read().decode("utf-8") or "{}")
        except Exception:  # noqa: BLE001
            return e.code, {}
    except Exception as e:  # noqa: BLE001
        return 0, {"error": repr(e)}


def _parse(raw: str) -> dict:
    try:
        v = json.loads(raw)
        return v if isinstance(v, dict) else {"value": v}
    except json.JSONDecodeError:
        return {"error": raw[:300]}


def layout_url(enc: str, trial: str = "") -> str:
    return f"{enc.rstrip('/')}/api/void-layout" + (f"?trial={trial}" if trial else "")


def get_layout(enc: str = DEFAULT_ENC, trial: str = "", timeout: float = 90.0) -> dict:
    """rooms + revision (+ models = the manifest URL, frame, catalog). The route
    spawns the validator for the catalog, so it takes a few seconds."""
    code, j = http("GET", layout_url(enc, trial), timeout=timeout)
    if code != 200:
        raise ChainError(code, f"GET /api/void-layout failed ({code}): {str(j.get('error', j))[:300]}", j)
    return j


def save_layout(rooms: dict, revision: str, enc: str = DEFAULT_ENC, trial: str = "", timeout: float = 120.0) -> dict:
    """POST {rooms, revision}. 200 -> {saved, revision, warnings, live}; 409 raises
    ChainError(409) (the file changed elsewhere: re-GET and retry on top of it)."""
    code, j = http("POST", layout_url(enc, trial), {"rooms": rooms, "revision": revision}, timeout=timeout)
    if code != 200:
        raise ChainError(code, f"POST /api/void-layout failed ({code}): {str(j.get('error', j))[:300]}", j)
    return j


def acks_for(revision_id: str, enc: str = DEFAULT_ENC, timeout: float = 5.0) -> list[dict]:
    code, j = http("GET", f"{enc.rstrip('/')}/api/live-update?id={revision_id}", timeout=timeout)
    if code != 200 or not j.get("ok"):
        return []
    rows = j.get("rows") or {}
    rows = rows.get("rows", rows) if isinstance(rows, dict) else rows
    return [r for r in rows if isinstance(r, dict) and r.get("k") == "update_ack"]


def wait_acks(revision_id: str, enc: str = DEFAULT_ENC, wait: float = 5.0, every: float = 0.5,
              expect: int = 1) -> list[dict]:
    """Poll the ledger until `expect` devices answered or `wait` seconds passed.
    A device's answer is its last ack."""
    t0 = time.time()
    got: list[dict] = []
    while True:
        got = acks_for(revision_id, enc)
        if len(last_per_device(got)) >= expect:
            break
        if time.time() - t0 >= wait:
            break
        time.sleep(every)
    return last_per_device(got)


def last_per_device(acks: list[dict]) -> list[dict]:
    out: dict[str, dict] = {}
    for a in acks:
        out[str(a.get("name") or a.get("device"))] = a
    return list(out.values())


def bridge_state(enc: str = DEFAULT_ENC) -> dict:
    code, j = http("GET", f"{enc.rstrip('/')}/api/live-update", timeout=5)
    return (j.get("state") or {}) if code == 200 and j.get("ok") else {}


def format_ack(a: dict) -> str:
    who = str(a.get("name") or a.get("device") or "?")
    s = f"{who} {a.get('status')}"
    if a.get("reason"):
        s += f" ({a.get('reason')})"
    if a.get("mode"):
        s += f" {a.get('mode')}"
    return s


def format_live(live_entry: dict, acks: list[dict]) -> str:
    rid = str(live_entry.get("revision_id", ""))
    head = f"floor {live_entry.get('floor')} {rid}: "
    if live_entry.get("error"):
        return head + f"not sent ({live_entry.get('error')})"
    if not acks:
        return head + f"sent to {live_entry.get('transmitted', 0)} game(s), no ack yet"
    return head + " · ".join(format_ack(a) for a in acks)
