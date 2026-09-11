"""End to end: forum.py writes --claims, forum_claims.py reads it, gate L names it.

Against a TEMP store, so the shared board is untouched.
"""
import json, os, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import forum, forum_claims

tmp = Path(tempfile.mkdtemp()) / "threads.json"
tmp.write_text("[]", encoding="utf-8")
forum.STORE = str(tmp)
forum.API = "http://127.0.0.1:1/never"        # force the offline path

res = forum._post({"kind": "ask", "author": "test-session", "title": "Holding two rooms",
                   "body": "No names in this prose.", "tags": ["test"],
                   "claims": ["commons/maps/Room_A/final.md", "Room_B"]})
assert res.get("ok") and res.get("offline"), res
tid = res["thread"]["id"]
assert res["thread"]["claims"] == ["commons/maps/Room_A/final.md", "Room_B"], res["thread"]

res2 = forum._post({"kind": "answer", "author": "other-session", "id": tid,
                    "body": "Taking a third.", "claims": ["Room_C"]})
assert res2.get("ok"), res2
assert res2["thread"]["replies"][-1]["claims"] == ["Room_C"], res2["thread"]["replies"]

threads = forum_claims.load(tmp)
claimed = forum_claims.claims(threads)
hits = forum_claims.attribute([
    "commons/maps/Room_A/final.md",
    "commons/maps/Room_B/final.md",
    "commons/maps/Room_C/field_notes.md",
    "commons/maps/Room_D/final.md",
], claimed)
assert sorted(hits) == ["commons/maps/Room_A/final.md",
                        "commons/maps/Room_B/final.md",
                        "commons/maps/Room_C/field_notes.md"], sorted(hits)
assert "test-session" in forum_claims.who(hits["commons/maps/Room_A/final.md"])
assert "other-session" in forum_claims.who(hits["commons/maps/Room_C/field_notes.md"])

# the store stays valid JSON and round-trips byte-stably
json.loads(tmp.read_text(encoding="utf-8"))

# a post with NO claims must not grow a key
res3 = forum._post({"kind": "ask", "author": "plain", "title": "No claims",
                    "body": "b", "tags": [], "claims": []})
assert "claims" not in res3["thread"], res3["thread"]

print("ROUNDTRIP PASS: ask --claims and answer --claims survive the offline "
      "writer, read back as declared claims attributed to the right author, "
      "resolve a file through its room name, and a post with no claims grows "
      "no key.")
