#!/usr/bin/env python3
"""test_vr_narrator.py — the hall reader, proven without a voice.

The text cleaning is checked against real final.md files (Point_One's two
chapters, Random_Walk's headed body, Trans_Pre with no notes). The narrator's
behaviour — settle, flicker, switch mid-reading, not-again, two halls of one
map, vestibules, pre-rendered audio, off — runs against a NullSpeaker whose
fake processes finish at once or wait to be released.

Run:  python tools/test_vr_narrator.py        exit 0 iff every check holds
"""
from __future__ import annotations

import json
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import vr_narrator as vn  # noqa: E402

FAILS: list[str] = []


def check(cond: bool, what: str) -> None:
    print(("  ok   " if cond else "  FAIL ") + what)
    if not cond:
        FAILS.append(what)


def test_text_point_one() -> None:
    print("text: Point_One")
    chs = vn.chapters_for("Point_One")
    check(len(chs) == 2, "two chapters: the essay and the notes (got %d)" % len(chs))
    body, notes = chs[0], chs[1]
    check(body.kind == "body" and notes.kind == "notes", "in that order")
    check(body.words > 1500, "the body keeps its words (%d)" % body.words)
    for bad in ("```", "<!--", "[^", "](", "`", "**"):
        check(bad not in body.text, "no %r left in the body" % bad)
    check(vn.CODE_CUE in body.text, "code listings are announced, not spelled")
    check("Engine dot get process frames" in body.text, "inline code is read as words")
    check(body.text.startswith("Point One."), "a body without an H1 is introduced by the map's name")
    check(notes.text.count("Note ") == 4, "four notes, numbered")
    check("Note 1. Heidegger" in notes.text and "Note 4. Donna Haraway" in notes.text,
          "notes numbered by first mention in the body")
    check("Being and Time, §29" in notes.text and "beyng.com" not in notes.text, "links become their text")
    only_body = vn.chapters_for("Point_One", notes=False)
    check(len(only_body) == 1, "--no-notes leaves the essay alone")
    with_code = vn.chapters_for("Point_One", read_code=True)[0].text
    check(vn.CODE_CUE not in with_code and "count += 1" in with_code, "--read-code keeps the listing")


def test_text_headed_and_plain() -> None:
    print("text: headings and a map without notes")
    chs = vn.chapters_for("Random_Walk")
    check(chs[0].title == "The trail is already elsewhere", "the H1 is the chapter title")
    check("Somewhere to start." in chs[0].text, "an H2 is read as a sentence")
    check(not chs[0].text.startswith("Random Walk"), "a titled body is not introduced by the map name")
    tp = vn.chapters_for("Trans_Pre")
    check(len(tp) == 1 and tp[0].kind == "body", "no footnotes: one chapter")
    check(vn.chapters_for("No_Such_Map_Xyz") == [], "no final.md: nothing to read")
    title, body, notes = vn.clean_markdown("# T\n\nSee [x](http://a) and *this* and __that__ `a_b()`.\n\n"
                                          "> quoted\n\n- item one\n\n<b>tag</b>\n\n[^n]: note [y](u)\n\nRef[^n].")
    check(title == "T" and "See x and this and that a b." in body, "inline forms cleaned: %r" % body)
    check("quoted" in body and "item one" in body and "tag" in body and "<b>" not in body, "quote, bullet, tag")
    check(notes == ["Note 1. note y"], "note text cleaned too")
    check("Ref." in body, "the footnote mark leaves the sentence intact")


class Clock:
    """Poses at will: the narrator reads time.time(), so the tests sleep for real
    but keep every wait short by using a small settle."""

    @staticmethod
    def pose(map_name: str = "", pearl: str = "", index: int = -1, hall_map: str = "",
             vestibule: bool = False) -> dict:
        """A pose as vr_link.gd sends it: `map` always; in the museum a `hall`
        record, whose pearl is "" between segments (the vestibule)."""
        d = {"k": "pose", "map": map_name or hall_map or "EndlessMuseum"}
        if pearl or hall_map or vestibule:
            d["hall"] = {"pearl": pearl, "map": hall_map, "index": index}
        return d


def feed(n: vn.Narrator, pose: dict, seconds: float, hz: float = 20.0) -> None:
    t0 = time.time()
    while time.time() - t0 < seconds:
        n.on_pose(pose)
        time.sleep(1.0 / hz)


def test_narrator_settle_and_switch() -> None:
    print("narrator: settle, flicker, switch, not again")
    sp = vn.NullSpeaker()
    logs: list[str] = []
    n = vn.Narrator(sp, voice_dir=Path(tempfile.mkdtemp()), settle=0.2, gap=0.0, log=logs.append)
    feed(n, Clock.pose("Point_One"), 0.1)
    check(sp.spoken == [], "a hall not yet held for the settle is not read")
    feed(n, Clock.pose("Point_One"), 0.3)
    n.wait(5)
    check(len(sp.spoken) == 2, "held: Point_One's two chapters are spoken (%d)" % len(sp.spoken))
    check(sp.spoken[0].startswith("Point One.") and sp.spoken[1].startswith("Notes for Point One."),
          "essay, then notes")
    check(("map", "Point_One") in n.heard, "…and the hall is marked heard")
    before = len(sp.spoken)
    feed(n, Clock.pose("Trans_Pre"), 0.1)     # a threshold crossed and re-crossed
    feed(n, Clock.pose("Point_One"), 0.3)
    n.wait(2)
    check(len(sp.spoken) == before, "a flicker into the next hall reads nothing")
    feed(n, Clock.pose("Trans_Pre"), 0.35)
    n.wait(5)
    check(len(sp.spoken) == before + 1 and sp.spoken[-1].startswith("Trans Pre."), "the next hall, held, is read")
    check(any("left Point_One" in m for m in logs), "leaving a hall is logged")
    feed(n, Clock.pose("Point_One"), 0.35)
    n.wait(2)
    check(len(sp.spoken) == before + 1, "a hall already read is not read again")
    check(any("already read" in m for m in logs), "…and says so")
    n2 = vn.Narrator(vn.NullSpeaker(), voice_dir=Path(tempfile.mkdtemp()), settle=0.2, gap=0.0,
                     repeat=True, log=lambda m: None)
    feed(n2, Clock.pose("Trans_Pre"), 0.35); n2.wait(5)
    feed(n2, Clock.pose("Point_One"), 0.35); n2.wait(5)
    feed(n2, Clock.pose("Trans_Pre"), 0.35); n2.wait(5)
    check(len(n2.speaker.spoken) == 4, "--repeat reads it again (%d)" % len(n2.speaker.spoken))


def test_narrator_interrupt() -> None:
    print("narrator: a hall change stops the reading mid-word")
    sp = vn.NullSpeaker(hold=True)
    logs: list[str] = []
    n = vn.Narrator(sp, voice_dir=Path(tempfile.mkdtemp()), settle=0.2, gap=0.0, log=logs.append)
    feed(n, Clock.pose("Point_One"), 0.35)
    time.sleep(0.2)
    check(len(sp.spoken) == 1 and sp.procs[0].poll() is None, "the essay is being spoken")
    feed(n, Clock.pose("Trans_Pre"), 0.35)
    time.sleep(0.3)
    check(sp.procs[0].killed, "the essay's process was terminated")
    check(len(sp.spoken) == 2 and sp.spoken[-1].startswith("Trans Pre."), "the next hall started")
    check(not any(s.startswith("Notes for Point One") for s in sp.spoken), "Point_One's notes were never begun")
    check(("map", "Point_One") not in n.heard, "an interrupted hall is not marked heard (it will be read again)")
    n.stop()
    time.sleep(0.2)
    check(sp.procs[-1].killed and n.current is None, "stop() ends the reading")


def test_narrator_museum_and_audio() -> None:
    print("narrator: halls, vestibules, audio files, off")
    sp = vn.NullSpeaker()
    n = vn.Narrator(sp, voice_dir=Path(tempfile.mkdtemp()), settle=0.2, gap=0.0, log=lambda m: None)
    feed(n, Clock.pose(pearl="point", hall_map="Point_One", index=3), 0.35); n.wait(5)
    k1 = len(sp.spoken)
    feed(n, Clock.pose(vestibule=True), 0.35)       # the vestibule: a hall record, no pearl
    check(n.current == ("hall", "point", "Point_One", 3) and len(sp.spoken) == k1,
          "between halls the reading is kept, nothing new starts")
    feed(n, Clock.pose(pearl="point again", hall_map="Point_One", index=9), 0.35); n.wait(5)
    check(len(sp.spoken) == k1 + 2, "a second hall of the same map is a second reading")
    check(vn.hall_key({"map": "X"}) == ("map", "X") and vn.hall_key({"hall": {"pearl": ""}}) is None
          and vn.hall_key({}) is None, "hall_key: map outside the museum, None between halls")

    vd = Path(tempfile.mkdtemp())
    (vd / "Point_One").mkdir()
    (vd / "Point_One" / "02-notes.wav").write_bytes(b"x")
    (vd / "Point_One" / "01-body.mp3").write_bytes(b"x")
    (vd / "Point_One" / "01-body.wav").write_bytes(b"x")
    files = vn.find_audio("Point_One", vd)
    check([f.name for f in files] == ["01-body.mp3", "02-notes.wav"], "audio in order, mp3 preferred: %s"
          % [f.name for f in files])
    (vd / "point_one-extra.mp3").write_bytes(b"x")
    check([f.name for f in vn.find_audio("Trans_Pre", vd)] == [], "no files for another map")
    vd2 = Path(tempfile.mkdtemp())
    (vd2 / "mp3").mkdir()
    (vd2 / "mp3" / "point_one_essay.mp3").write_bytes(b"x")
    check([f.name for f in vn.find_audio("Point_One", vd2)] == ["point_one_essay.mp3"],
          "a flat <map>*.mp3 under mp3/ is found, case-insensitively")
    sp2 = vn.NullSpeaker()
    n2 = vn.Narrator(sp2, voice_dir=vd, settle=0.2, gap=0.0, log=lambda m: None)
    feed(n2, Clock.pose("Point_One"), 0.35); n2.wait(5)
    check(sp2.spoken == [] and [p.name for p in sp2.played] == ["01-body.mp3", "02-notes.wav"],
          "a rendered hall is played, not spoken")

    sp3 = vn.NullSpeaker()
    n3 = vn.Narrator(sp3, voice_dir=Path(tempfile.mkdtemp()), settle=0.2, gap=0.0, enabled=False,
                     log=lambda m: None)
    feed(n3, Clock.pose("Point_One"), 0.35); n3.wait(2)
    check(sp3.spoken == [], "off: nothing is read")
    st = n2.state()
    check(st["on"] and "Point_One" in st["heard"] and st["speaker"] == "null", "state() reports: %s" % st)


def test_preview_and_mute() -> None:
    print("narrator: --preview and --mute")
    sp = vn.NullSpeaker()
    n = vn.Narrator(sp, voice_dir=Path(tempfile.mkdtemp()), settle=0.2, gap=0.0, preview=40,
                    log=lambda m: None)
    feed(n, Clock.pose("Point_One"), 0.35); n.wait(5)
    check(len(sp.spoken) == 2 and all(len(t.split()) <= 41 for t in sp.spoken),
          "preview speaks the first 40 words of each chapter (%s)" % [len(t.split()) for t in sp.spoken])
    check(sp.spoken[0].startswith("Point One.") and sp.spoken[0].endswith("…"), "…and marks the cut")
    logs: list[str] = []
    m = vn.make_speaker(mute=True, log=logs.append)
    check(isinstance(m, vn.MuteSpeaker) and m.name == "mute", "make_speaker(mute=True) is the mute speaker")
    n2 = vn.Narrator(m, voice_dir=Path(tempfile.mkdtemp()), settle=0.2, gap=0.0, log=logs.append)
    feed(n2, Clock.pose("Trans_Pre"), 0.35); n2.wait(5)
    check(any("would speak" in l for l in logs) and any("finished Trans_Pre" in l for l in logs),
          "mute logs what it would have said and finishes at once")


def test_render() -> None:
    print("render: files and a manifest")
    out = Path(tempfile.mkdtemp())
    sp = vn.NullSpeaker()
    man = vn.render_map("Point_One", sp, out, mp3=False, log=lambda m: None)
    d = out / "Point_One"
    check((d / "01-body.wav").exists() and (d / "02-notes.wav").exists(), "one WAV per chapter")
    m = json.loads((d / "manifest.json").read_text(encoding="utf-8"))
    check([c["kind"] for c in m["chapters"]] == ["body", "notes"] and m["chapters"][0]["wav"] == "01-body.wav",
          "the manifest names them")
    check([f.name for f in vn.find_audio("Point_One", out)] == ["01-body.wav", "02-notes.wav"],
          "…and the narrator would find them")
    check(vn.sequence_maps("primitives")[:2] == ["Point_One", "Point_Lines"], "--seq resolves a sequence's maps")


def main() -> int:
    test_text_point_one()
    test_text_headed_and_plain()
    test_narrator_settle_and_switch()
    test_narrator_interrupt()
    test_narrator_museum_and_audio()
    test_preview_and_mute()
    test_render()
    print()
    if FAILS:
        print("FAILED %d:" % len(FAILS))
        for f in FAILS:
            print("  - " + f)
        return 1
    print("OK — every check holds")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
