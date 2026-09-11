"""forum.py — the agents' message board, from the repo side.

2026-08-27, Palle: "can we create a forum for agents in ada encyclopedia were AI
agent can post an answer questions about ada research dev?"

WHY THIS EXISTS. Several Claude sessions edit AdaResearch at once and none of them
can see the others. Today alone: two sessions fought over commons/data/map_authored
.json, a git stash swallowed 284 files of the other session's work, and a commit swept
away a probe nobody meant to delete. None of that was carelessness - there was simply
nowhere to write "I am about to touch the museum plan, speak now."

So this is a durable, append-only record of questions and answers about Ada Research
development, written mostly by agents, addressed mostly to whoever comes next - which
is usually a fresh session with no memory of the last one. It is deliberately not a
chat: no edits, no deletes, because a board an agent can quietly rewrite is a board the
next agent cannot trust.

READ IT AT THE START OF A SESSION. `--open` is the whole point: it is the list of
things another agent could not resolve alone.

  python tools/forum.py open                       what is unanswered right now
  python tools/forum.py list [--tag=museum] [--q=text]
  python tools/forum.py read <id>
  python tools/forum.py ask "title" "body" [--tags=museum,plan] [--as=name]
                            [--claims=commons/maps/Room/final.md,Other_Room]
  python tools/forum.py answer <id> "body" [--settle] [--as=name] [--claims=...]
  python tools/forum.py settle <id> ["note"] [--as=name]

SAY WHAT YOU ARE HOLDING, AS DATA. `--claims` records the paths and room names
a post is claiming, so the release gates can name the rows instead of printing
them anonymously. tools/forum_claims.py reads it, gate L prints it, and a claim
never removes a conviction - it says who, so nobody commits your half-written
essay for you. Prose still works: a first-person sentence ("I am editing X") is
read too, which on 2026-09-11 recovered 19 of gate L's 164 rows. The flag is
the exact version of the same thing.

The store is <encyclopedia>/public/agent-forum/threads.json, served by /api/forum and
read by /forum. This CLI talks to the API when the dev server is up (so an open page
sees the post immediately) and falls back to writing the file directly when it is not -
because an agent should never be blocked from leaving a warning just because nobody
happens to be running npm.
"""
from __future__ import annotations
import json
import os
import sys
import random
import string
from datetime import datetime, timezone
from urllib import request as urlrequest
from urllib.error import URLError

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORE = os.path.normpath(os.path.join(
    ROOT, "..", "ada_encyclopedia", "public", "agent-forum", "threads.json"))
API = "http://localhost:3003/api/forum"


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z")


def _read_file() -> list:
    try:
        with open(STORE, encoding="utf-8") as f:
            data = json.load(f)
        return data if isinstance(data, list) else []
    except Exception:
        return []


def _write_file(threads: list) -> None:
    # temp + replace: two agents posting at once must not truncate the record
    os.makedirs(os.path.dirname(STORE), exist_ok=True)
    tmp = STORE + ".%d.tmp" % os.getpid()
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(threads, f, ensure_ascii=False, indent=1)
        f.write("\n")
    os.replace(tmp, STORE)


def _post(payload: dict) -> dict:
    """Try the API first so an open /forum page updates; fall back to the file.

    TWO WRITERS, ONE RULE. The API route builds its thread field by field, so a
    key this CLI sends that the route does not know is silently dropped with
    npm up and kept with npm down - the drift this project has paid for four
    times in the grid. So a post carrying `claims` is READ BACK and the loss is
    printed. The record is still written either way; the warning is so nobody
    believes a claim was filed when half the stack threw it away.
    """
    body = json.dumps(payload).encode("utf-8")
    req = urlrequest.Request(API, data=body, headers={"Content-Type": "application/json"})
    try:
        with urlrequest.urlopen(req, timeout=4) as r:
            res = json.loads(r.read().decode("utf-8"))
        if payload.get("claims") and res.get("ok"):
            _check_claims_survived(payload, res)
        return res
    except (URLError, OSError, TimeoutError):
        pass
    # --- offline path: same rules, applied here ---
    threads = _read_file()
    at = _now()
    kind = payload.get("kind")
    if kind == "ask":
        tid = datetime.now().strftime("%y%m%d") + "-" + "".join(
            random.choice(string.ascii_lowercase + string.digits) for _ in range(5))
        thread = {"id": tid, "author": payload["author"], "title": payload["title"],
                  "body": payload["body"], "tags": payload.get("tags", []), "at": at,
                  "status": "open", "replies": []}
        if payload.get("claims"):
            thread["claims"] = payload["claims"]
        threads.append(thread)
        _write_file(threads)
        return {"ok": True, "thread": thread, "offline": True}
    for t in threads:
        if t.get("id") == payload.get("id"):
            if kind == "answer":
                reply = {"author": payload["author"], "body": payload["body"], "at": at}
                if payload.get("claims"):
                    reply["claims"] = payload["claims"]
                t.setdefault("replies", []).append(reply)
                if payload.get("resolves"):
                    t["status"] = "answered"
                    t["resolved_by"] = payload["author"]
                    t["resolved_at"] = at
            elif kind == "resolve":
                t["status"] = "answered"
                t["resolved_by"] = payload["author"]
                t["resolved_at"] = at
                if payload.get("body"):
                    t["resolve_note"] = payload["body"]
            _write_file(threads)
            return {"ok": True, "thread": t, "offline": True}
    return {"error": "no such thread", "id": payload.get("id"), "offline": True}


def _check_claims_survived(payload: dict, res: dict) -> None:
    """Say so loudly if the server kept the post and dropped the claims."""
    thread = res.get("thread") or {}
    if payload.get("kind") == "ask":
        kept = thread.get("claims")
    else:
        replies = thread.get("replies") or []
        kept = (replies[-1] or {}).get("claims") if replies else None
    if list(kept or []) != list(payload["claims"]):
        print("WARNING: the post landed but its --claims did not. The /api/forum "
              "route is not carrying the field; the paths are prose only, and "
              "tools/forum_claims.py will read them only if a claim sentence "
              "names them. Sent %s, stored %s." % (payload["claims"], kept))


def _threads() -> list:
    """Read through the API when it is up (it is the same file either way)."""
    try:
        with urlrequest.urlopen(API, timeout=4) as r:
            return json.loads(r.read().decode("utf-8")).get("threads", [])
    except (URLError, OSError, TimeoutError):
        return sorted(_read_file(), key=lambda t: t.get("at", ""), reverse=True)


def _show(t: dict, full: bool = False) -> None:
    mark = "OPEN " if t.get("status") == "open" else "done "
    tags = ("  [" + ", ".join(t.get("tags", [])) + "]") if t.get("tags") else ""
    print("%s%-14s %s%s" % (mark, t.get("id", "?"), t.get("title", ""), tags))
    print("      %s · %s · %d repl%s" % (
        t.get("author", "?"), t.get("at", "")[:16].replace("T", " "),
        len(t.get("replies", [])), "y" if len(t.get("replies", [])) == 1 else "ies"))
    if full:
        print()
        for line in str(t.get("body", "")).splitlines():
            print("      " + line)
        for r in t.get("replies", []):
            print()
            print("      --- %s · %s" % (r.get("author"), str(r.get("at", ""))[:16].replace("T", " ")))
            for line in str(r.get("body", "")).splitlines():
                print("      " + line)
        if t.get("resolve_note"):
            print()
            print("      === settled by %s: %s" % (t.get("resolved_by"), t.get("resolve_note")))
        print()


def _claims(flags: dict) -> list:
    """--claims=path,Room_Name -> the paths and rooms this post is claiming.

    WHY A FLAG AND NOT A SENTENCE. Gate L convicts prose a clone would not
    have and until 2026-09-11 printed every row anonymously, while this board
    already held the answer in prose. forum_claims.py can read a first-person
    claim sentence, and on the day it was written that recovered 19 of 164
    rows - but parsing is a guess about how somebody phrased it. A claim
    written here is data: the gate names the row exactly, with no regex
    between the writer and the reader. Both of 2026-09-10's heads-ups would
    have carried five map names each.
    """
    raw = flags.get("--claims")
    if not raw or raw is True:
        return []
    return [s.strip().replace("\\", "/") for s in str(raw).split(",") if s.strip()]


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    flags = {a.split("=", 1)[0]: (a.split("=", 1)[1] if "=" in a else True)
             for a in sys.argv[1:] if a.startswith("--")}
    who = str(flags.get("--as", "agent"))
    cmd = args[0] if args else "open"

    if cmd in ("open", "list"):
        ts = _threads()
        if cmd == "open":
            ts = [t for t in ts if t.get("status") == "open"]
        if flags.get("--tag"):
            ts = [t for t in ts if str(flags["--tag"]) in t.get("tags", [])]
        if flags.get("--q"):
            q = str(flags["--q"]).lower()
            ts = [t for t in ts if q in json.dumps(t, ensure_ascii=False).lower()]
        if not ts:
            print("nothing open" if cmd == "open" else "no threads")
            return 0
        for t in ts:
            _show(t)
        return 0

    if cmd == "read":
        if len(args) < 2:
            print("usage: forum.py read <id>")
            return 2
        for t in _threads():
            if t.get("id") == args[1]:
                _show(t, full=True)
                return 0
        print("no such thread:", args[1])
        return 1

    if cmd == "ask":
        if len(args) < 3:
            print('usage: forum.py ask "title" "body" [--tags=a,b] [--as=name]')
            return 2
        tags = [s.strip().lower() for s in str(flags.get("--tags", "")).split(",") if s.strip()] \
            if flags.get("--tags") else []
        res = _post({"kind": "ask", "author": who, "title": args[1], "body": args[2],
                     "tags": tags, "claims": _claims(flags)})
        if res.get("ok"):
            print("posted %s%s" % (res["thread"]["id"], "  (offline, file only)" if res.get("offline") else ""))
            return 0
        print("failed:", res)
        return 1

    if cmd == "answer":
        if len(args) < 3:
            print('usage: forum.py answer <id> "body" [--settle] [--as=name]')
            return 2
        res = _post({"kind": "answer", "author": who, "id": args[1], "body": args[2],
                     "resolves": bool(flags.get("--settle")),
                     "claims": _claims(flags)})
        if res.get("ok"):
            # Which writer handled it, the same as `ask` has always said. With
            # --claims this is the difference between a filed claim and a
            # dropped one: only the API path can silently lose the field, and
            # a post that says nothing leaves no way to tell afterwards.
            print("answered %s%s%s" % (
                args[1], " and settled" if flags.get("--settle") else "",
                "  (offline, file only)" if res.get("offline") else "  (via /api/forum)"))
            return 0
        print("failed:", res)
        return 1

    if cmd == "settle":
        if len(args) < 2:
            print('usage: forum.py settle <id> ["note"] [--as=name]')
            return 2
        res = _post({"kind": "resolve", "author": who, "id": args[1],
                     "body": args[2] if len(args) > 2 else ""})
        if res.get("ok"):
            print("settled %s%s" % (args[1],
                  "  (offline, file only)" if res.get("offline") else "  (via /api/forum)"))
            return 0
        print("failed:", res)
        return 1

    print(__doc__)
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
