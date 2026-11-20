"""From a chosen line to a line the game sings.

A sequence's handover (doc/book/opera-frame-handovers/<sequence>.md) lists under each frame the lines that frame
sings, in order. `opera_frame_handovers.py review` shows where that file differs from the game. This applies the
song lines of that difference, which nothing did before: a changed or added line stayed a sentence in a file.

    python tools/opera_takes.py check                          the game's own loading rule, over the whole edition
    python tools/opera_takes.py plan  --sequence primitives    what would change; writes nothing
    python tools/opera_takes.py apply --sequence primitives    [--frame <id> ...]
    python tools/opera_takes.py journey --sequence primitives [--floors 2,5-12] [--write]
                                                               the journey's lines, first under their frames

How a writer says it, in the handover:
  * the Song text lines under a frame, top to bottom, are what the frame sings, first visit first;
  * a line whose text is the text of one of the frame's takes or proposals is that take, whatever its comment says;
  * a line whose text is anything else becomes a NEW take (id <frame>__h<8 hex of the text>), whatever id its
    comment carries - write `<!-- take new -->` for an added line, or just change the words of an existing one.
    The take it replaced is not deleted: it stays among the frame's proposals, only no longer enabled.

What a new take needs before the game can sing it, and where each lands:
  1. a voice plan, from build_opera_chapters.make_phrase (pronunciation of every word, 8 seconds at most);
  2. every word in the live voice's word table, audio/voice_scores/aligned_words.json; a missing word is taught
     by tools/probes/build_aligned_words.gd in a staged copy and only the new word models are added to the table;
  3. its phrase in a score bank the game loads: audio/voice_scores/encounters_handover.json. A frame that gets a
     handover line moves to that bank whole (inner_opera.gd looks for EVERY enabled take of a banked frame in its
     bank, and one missing take refuses the whole score), so all its other proposals are copied there too;
  4. the edition, commons/data/opera/encounter_lines.json: proposals, proposal_texts, proposal_banks, enabled.
They are written in that order, so the game never reads an edition that names a phrase it cannot find, and the
files as they were are kept under ada_run/opera-takes/<time>/. Run `check` afterwards; apply does.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_opera_chapters import make_phrase  # noqa: E402
import opera_frame_handovers as handovers  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OPERA = ROOT / "commons/data/opera"
SCORES = ROOT / "audio/voice_scores"
EDITION = OPERA / "encounter_lines.json"
TABLE = SCORES / "aligned_words.json"
BANK = "handover"
RUN = ROOT / "ada_run/opera-takes"
WORD = re.compile(r"[a-z]+(?:'[a-z]+)?")


def load(path):
    return json.loads(Path(path).read_bytes())


def write_whole(path, text):
    """Beside the file, then swapped in: a reader sees the old file or the new one, never a part of either."""
    json.loads(text)
    temp = path.with_name(path.name + ".opera-takes.tmp")
    temp.write_text(text, encoding="utf-8", newline="\n")
    os.replace(temp, path)
    json.loads(path.read_bytes())


class Scores:
    """The phrases the game can load: the main score, and a bank per frame that has one."""

    def __init__(self):
        self.edition = load(EDITION)
        self.bindings = load(OPERA / "tower_bindings.json")
        self.main_path = ROOT / self.bindings["score"].removeprefix("res://")
        self._main = None
        self._banks = {}

    @property
    def main(self):
        if self._main is None:
            self._main = {p["object_id"]: p for p in load(self.main_path)["phrases"]}
        return self._main

    def bank(self, name):
        if name not in self._banks:
            path = SCORES / f"encounters_{name}.json"
            self._banks[name] = load(path) if path.is_file() else {}
        return self._banks[name]

    def phrase(self, base, take):
        """As inner_opera.gd finds it: a banked frame's other takes in its bank, everything else in the main score."""
        bank = self.edition.get("proposal_banks", {}).get(base)
        if bank and take != base:
            return self.bank(bank).get(take)
        return self.main.get(take)

    def anywhere(self, take):
        if take in self.main:
            return self.main[take]
        return next((self.bank(name)[take] for name in sorted(set(self.edition.get("proposal_banks", {}).values()) | {BANK})
                     if take in self.bank(name)), None)


def phrase_words(phrase):
    return [row["text"] for row in phrase.get("words", [])] or WORD.findall(phrase["text"].lower())


def check(scores=None, quiet=False):
    """The game's rule (inner_opera._read_bindings + inner_voice_godot.load_score + AlignedVoice.render_phrase)."""
    scores = scores or Scores()
    edition = scores.edition
    table = load(TABLE)["words"]
    wrong = []
    takes = 0
    for base, enabled in edition["enabled"].items():
        for take in enabled:
            takes += 1
            phrase = scores.phrase(base, take)
            if phrase is None:
                where = "bank " + str(edition["proposal_banks"].get(base)) if edition["proposal_banks"].get(base) and take != base else "the main score"
                wrong.append(f"{base}: enabled take {take} is not in {where}")
                continue
            unknown = sorted({w for w in phrase_words(phrase) if w not in table})
            if unknown:
                wrong.append(f"{base}: {take} needs words the live voice was never taught: {', '.join(unknown)}")
    if not quiet:
        for line in wrong:
            print("  WRONG", line)
        print(f"check: {len(edition['enabled'])} frames, {takes} enabled takes, {len(wrong)} the game could not sing")
    return wrong


def dictionary():
    words = load(OPERA / "chapter_pronunciations.json")
    for word, phones in load(OPERA / "trajectory_pronunciations.json")["words"].items():
        words.setdefault(word, phones)
    cmu = ROOT / "ada_run/trajectory-world/cmudict.dict"
    if cmu.is_file():
        for row in cmu.read_text(encoding="utf8").splitlines():
            tokens = row.partition("#")[0].split()
            if len(tokens) > 1:
                words.setdefault(re.sub(r"\(\d+\)$", "", tokens[0]), tokens[1:])
    for uk, us in [("neighbour", "neighbor"), ("centre", "center"), ("colour", "color")]:
        if us in words:
            words.setdefault(uk, words[us])
    return words


def take_id(base, text):
    return f"{base}__h{hashlib.sha1(text.encode('utf-8')).hexdigest()[:8]}"


def read_handover(sequence):
    path = handovers.DEFAULT_DIR / f"{sequence}.md"
    if not path.is_file():
        raise SystemExit(f"no handover for {sequence}: {path}")
    return path, handovers.parse(path.read_text(encoding="utf-8-sig"))


def plan(sequence, only=()):
    """Per frame: the takes it should sing, in order, and the phrases that have to be made for that."""
    scores = Scores()
    edition = scores.edition
    path, maps = read_handover(sequence)
    words = None
    changes, refused = [], []
    for map_id, floor in maps.items():
        for base, entry in floor["frames"].items():
            if only and base not in only:
                continue
            if not entry["songs"]:
                continue
            current = edition["enabled"].get(base, [base])
            wanted, made, renamed = [], {}, {}
            known = {}
            for take in dict.fromkeys([base] + edition["proposals"].get(base, []) + current):
                phrase = scores.phrase(base, take) or scores.anywhere(take)
                if phrase is not None:
                    known.setdefault(" ".join(phrase["text"].split()), take)
            for written_id, lyric in entry["songs"].items():
                lyric = " ".join(lyric.split())
                if lyric in known:
                    if known[lyric] not in wanted:
                        wanted.append(known[lyric])
                    if known[lyric] != written_id:
                        renamed[written_id] = known[lyric]
                    continue
                new = take_id(base, lyric)
                renamed[written_id] = new
                wanted.append(new)
                already = scores.bank(BANK).get(new)
                if already is not None and already["text"] == lyric and new in edition["proposals"].get(base, []):
                    continue
                like = scores.main.get(base) or next((scores.anywhere(t) for t in edition["proposals"].get(base, []) if scores.anywhere(t)), None)
                try:
                    words = words or dictionary()
                    phrase = make_phrase(dict(object_id=new, tag=(like or {}).get("object_label") or entry["title"], text=lyric, floor=floor["floor"]),
                                         words, (like or {}).get("options") or scores.bindings["voice"])
                except ValueError as wrong:
                    refused.append(f"{map_id} / {base}: \"{lyric}\" - {wrong}")
                    wanted.pop()
                    renamed.pop(written_id)
                    continue
                made[new] = phrase
            if wanted != current or made or renamed:
                changes.append(dict(map=map_id, floor=floor["floor"], base=base, title=entry["title"], was=current, wanted=wanted, made=made, renamed=renamed))
    return scores, path, changes, refused


def report(scores, changes, refused, table):
    for change in changes:
        print(f"floor {change['floor']} {change['map']} / {change['base']}")
        for take in change["wanted"]:
            phrase = change["made"].get(take) or scores.phrase(change["base"], take) or scores.bank(BANK).get(take) or {}
            mark = "NEW " if take in change["made"] else ("    " if take in change["was"] else "back")
            print(f"    {mark} {take}: {phrase.get('text', '?')}")
        for take in change["was"]:
            if take not in change["wanted"]:
                print(f"    off  {take}: {(scores.phrase(change['base'], take) or {}).get('text', '?')}")
    teach = sorted({w for c in changes for p in c["made"].values() for w in phrase_words(p) if w not in table})
    for line in refused:
        print("  REFUSED", line)
    print(f"{len(changes)} frames change, {sum(len(c['made']) for c in changes)} takes to make, "
          f"{len(teach)} words to teach{': ' + ', '.join(teach) if teach else ''}, {len(refused)} lines refused")
    return teach


def teach(phrases, missing, keep):
    """Missing word models, made by the game's own teacher in a staged project; only the new words come back."""
    from render_encounter_audition import render_inputs
    stage = RUN / "voice"
    if stage.exists():
        shutil.rmtree(stage)
    files = render_inputs()
    for name in ["tools/probes/build_aligned_words.gd", "tools/voice_memory_speech.ps1"]:
        files[Path(name)] = (ROOT / name).read_bytes()
    for rel, data in files.items():
        target = stage / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    (stage / "project.godot").write_text('config_version=5\n[application]\nconfig/name="Opera takes: word teacher"\n'
                                         '[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf8")
    (stage / "commons/data/opera").mkdir(parents=True, exist_ok=True)
    (stage / "commons/data/opera/tower_bindings.json").write_text(json.dumps({"score": "res://score.json"}), encoding="utf8")
    (stage / "score.json").write_text(json.dumps({"phrases": [{"voice_plan": p["voice_plan"]} for p in phrases]}), encoding="utf8")
    godot = (os.environ.get("GODOT_EXE") or os.environ.get("GODOT_PATH") or shutil.which("godot")
             or str(Path.home() / "Desktop/Godot_v4.6-stable_win64.exe"))
    log = RUN / "teacher.log"
    proc = subprocess.run([godot, "--headless", "--audio-driver", "Dummy", "--path", str(stage), "--log-file", str(log),
                           "--script", "res://tools/probes/build_aligned_words.gd"], capture_output=True, timeout=240)
    text = log.read_text(encoding="utf8", errors="replace") if log.is_file() else ""
    if proc.returncode or "SCRIPT ERROR" in text or "ERROR:" in text:
        raise SystemExit("the word teacher failed; nothing was written\n" + text[-1600:])
    taught = load(stage / "audio/voice_scores/aligned_words.json")["words"]
    still = [w for w in missing if w not in taught]
    if still:
        raise SystemExit("the word teacher left words untaught; nothing was written: " + ", ".join(still))
    document = load(TABLE)
    shutil.copy2(TABLE, keep / TABLE.name)
    for word in missing:
        document["words"].setdefault(word, taught[word])
    document["words"] = dict(sorted(document["words"].items()))
    write_whole(TABLE, json.dumps(document, ensure_ascii=False, separators=(",", ":")))


def rename_in_handover(path, changes, seen):
    """The handover names the take the game now sings, so `review` is quiet about these lines."""
    if os.path.getmtime(path) != seen:
        print("  the handover changed while this ran; its take comments were left as they are - run apply again")
        return 0
    text = path.read_bytes().decode("utf-8-sig")
    count = 0
    for change in changes:
        start = text.find(f"<!-- frame {change['base']} -->")
        if start < 0:
            continue
        ends = [i for i in (text.find("\n- **Title**", start), text.find("\n## ", start)) if i >= 0]
        end = min(ends) if ends else len(text)
        block = text[start:end]
        for old, new in change["renamed"].items():
            if f"<!-- take {old} -->" in block:
                block = block.replace(f"<!-- take {old} -->", f"<!-- take {new} -->", 1)
                count += 1
        text = text[:start] + block + text[end:]
    handovers.parse(text)
    data = text.encode("utf-8")
    with open(path, "r+b") as stream:
        stream.write(data)
        stream.truncate(len(data))
    handovers.parse(path.read_text(encoding="utf-8-sig"))
    return count


def apply(sequence, only=()):
    before = check(quiet=True)
    path = handovers.DEFAULT_DIR / f"{sequence}.md"
    seen = os.path.getmtime(path) if path.is_file() else 0
    scores, path, changes, refused = plan(sequence, only)
    table = load(TABLE)["words"]
    missing = report(scores, changes, refused, table)
    if not changes:
        return 1 if refused else 0
    keep = RUN / time.strftime("%Y%m%dT%H%M%S")
    keep.mkdir(parents=True, exist_ok=True)
    made = [p for c in changes for p in c["made"].values()]
    if missing:
        teach(made, missing, keep)
    # the bank: every proposal of a frame that moves to it, then the new takes
    bank_path = SCORES / f"encounters_{BANK}.json"
    bank = dict(scores.bank(BANK))
    if bank_path.is_file():
        shutil.copy2(bank_path, keep / bank_path.name)
    edition = scores.edition
    shutil.copy2(EDITION, keep / EDITION.name)
    for change in changes:
        base = change["base"]
        for take in dict.fromkeys(edition["proposals"].get(base, []) + change["was"] + change["wanted"]):
            if take == base or take in change["made"] or take in bank:
                continue
            phrase = scores.phrase(base, take) or scores.anywhere(take)
            if phrase is None:
                if take in change["wanted"]:
                    raise SystemExit(f"{base}: {take} has no phrase anywhere; nothing was written")
                continue
            bank[take] = phrase
        bank.update(change["made"])
    write_whole(bank_path, json.dumps(bank, ensure_ascii=False, indent=1) + "\n")
    for change in changes:
        base = change["base"]
        proposals = edition["proposals"].setdefault(base, list(change["was"]))
        for take in change["wanted"]:
            if take not in proposals:
                proposals.append(take)
        for take, phrase in change["made"].items():
            edition.setdefault("proposal_texts", {})[take] = phrase["text"]
        edition.setdefault("proposal_banks", {})[base] = BANK
        edition["enabled"][base] = change["wanted"]
    write_whole(EDITION, json.dumps(edition, ensure_ascii=False, indent=2) + "\n")
    renamed = rename_in_handover(path, changes, seen)
    (keep / "applied.json").write_text(json.dumps([{k: (sorted(v) if k == "made" else v) for k, v in c.items()} for c in changes],
                                                  ensure_ascii=False, indent=1), encoding="utf8")
    after = check()
    fresh = [line for line in after if line not in before]
    print(f"applied: {len(changes)} frames, {len(made)} new takes, {len(missing)} words taught, {renamed} take comments renamed; "
          f"as it was: {keep.relative_to(ROOT).as_posix()}")
    if fresh:
        print("  THIS RUN BROKE SOMETHING - restore from the folder above:")
        for line in fresh:
            print("   ", line)
    return 1 if fresh or refused else 0


def from_journey(sequence, floors, write):
    """The journey's line for a frame, written first under that frame in the handover (the takes already there follow)."""
    journey = load(OPERA / "journey.json")
    runtime = load(ROOT / "commons/data/encounters/trajectory_runtime.json")
    song_of = {}
    for coin in runtime["coins"]:
        for key in (coin.get("trajectory_entry"), coin["id"].removeprefix("encounter-")):
            if key and coin.get("song"):
                song_of.setdefault(key, coin["song"])
    stops = next((seq["stops"] for act in journey["acts"] for seq in act["sequences"] if sequence in (seq.get("id"), seq.get("sequence"))), None)
    if stops is None:
        raise SystemExit(f"the journey has no sequence {sequence}")
    path, maps = read_handover(sequence)
    seen = os.path.getmtime(path)
    text = path.read_bytes().decode("utf-8-sig")
    newline = chr(13) + chr(10) if chr(13) + chr(10) in text else chr(10)
    added = 0
    for stop in stops:
        floor = maps.get(stop["map"])
        if floor is None or (floors and floor["floor"] not in floors):
            continue
        for line in stop.get("song", {}).get("lines", []):
            base = song_of.get(line["at"])
            frame = floor["frames"].get(base)
            if frame is None:
                print(f"  floor {floor['floor']}: no frame for {line['at']} - \"{line['text']}\"")
                continue
            if line["text"] in [" ".join(t.split()) for t in frame["songs"].values()]:
                continue
            start = text.find(f"<!-- frame {base} -->")
            ends = [i for i in (text.find(newline + "- **Title**", start), text.find(newline + "## ", start)) if i >= 0]
            at = text.find(newline + "  - **Song text** ", start, min(ends) if ends else len(text))
            if at < 0 or "new" in frame["songs"]:
                print(f"  floor {floor['floor']} / {base}: no sung line to stand before, left alone - \"{line['text']}\"")
                continue
            text = text[:at] + f"{newline}  - **Song text** {line['text']} <!-- take new -->" + text[at:]
            added += 1
            print(f"  floor {floor['floor']} / {base}: {line['text']}")
    handovers.parse(text)
    if write and added:
        if os.path.getmtime(path) != seen:
            raise SystemExit("the handover changed while this ran; nothing written")
        data = text.encode("utf-8")
        with open(path, "r+b") as stream:
            stream.write(data)
            stream.truncate(len(data))
        handovers.parse(path.read_text(encoding="utf-8-sig"))
    print(f"{added} journey lines {'written into' if write and added else 'would enter'} {path.name}")
    return 0


def floors_of(value):
    out = set()
    for part in filter(None, value.split(",")):
        low, _, high = part.partition("-")
        out.update(range(int(low), int(high or low) + 1))
    return out


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("check")
    for name in ("plan", "apply"):
        action = commands.add_parser(name)
        action.add_argument("--sequence", required=True)
        action.add_argument("--frame", action="append", default=[])
    action = commands.add_parser("journey", help="put the journey's lines first under their frames in the handover")
    action.add_argument("--sequence", required=True)
    action.add_argument("--floors", default="", help="e.g. 2,5-12; all floors of the sequence when left out")
    action.add_argument("--write", action="store_true")
    args = parser.parse_args()
    if args.command == "check":
        return 1 if check() else 0
    if args.command == "journey":
        return from_journey(args.sequence, floors_of(args.floors), args.write)
    if args.command == "plan":
        scores, _, changes, refused = plan(args.sequence, args.frame)
        report(scores, changes, refused, load(TABLE)["words"])
        return 1 if refused else 0
    return apply(args.sequence, args.frame)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
