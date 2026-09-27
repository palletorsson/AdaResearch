#!/usr/bin/env python3
"""vr_narrator.py — the hall you walk into reads you its final.md.

2026-09-27, Palle: "Can we trigger the text of the final.md as text to speech or
mp3 audio file with adb on the desktop when we move around in VR. Best to sync
every new hall, but point_one has two chapters."

THE TRIGGER IS ALREADY ON THE WIRE. commons/bridge/vr_link.gd sends a pose
twenty times a second over the USB cable (adb reverse), and the pose names the
map — and in the endless museum the hall: {pearl, map, index}. A new hall is a
change in that name. Nothing crosses the cable but the position; the reading
happens on the PC, out of the PC's speakers.

WHAT IS READ. commons/maps/<Map>/final.md, the map's essay, cleaned for a
voice: markers and comments go, links become their text, a code listing is
announced rather than spelled, footnote marks leave the body — and the notes
become a SECOND CHAPTER, read after the body while you are still in the hall.
That is Point_One's two chapters: its 2072-word essay and its four notes.
Headings are read as sentences. --text prints exactly what would be spoken.

HOW IT IS READ. A pre-rendered file wins: ada_run/voice/<Map>/*.wav|mp3 (or a
--voice-dir holding <map>*.mp3 / <map>*.wav), played in order. Otherwise the
OS speaks the text — Windows System.Speech, the SAPI tools/tts_radio.ps1
already uses and which ships with Windows; macOS `say`; Linux espeak-ng or
spd-say. Either way the reading is a subprocess, so a hall change stops it
mid-word and the next hall begins: "sync every new hall". A hall you leave
and come back to is not read again in the same session unless --repeat.

A hall must hold you for a moment (--settle, 1.2 s) before it is read: a
threshold crossed and re-crossed is not two halls. Between halls (the museum's
vestibules, where the pose names no pearl) the current reading carries on.

  python tools/vr_link.py --narrate                 # serve the link and read halls
  python tools/vr_narrator.py --listen              # beside a running vr_link.py
  python tools/vr_narrator.py --say Point_One       # hear one map now, no game
  python tools/vr_narrator.py --text Point_One      # print what would be read
  python tools/vr_narrator.py --render Point_One    # WAV (+ mp3 if ffmpeg) into ada_run/voice/
  python tools/vr_narrator.py --render --seq primitives
  python tools/vr_narrator.py --voices              # which voices this PC has

The browser page (localhost:8772) has a "narrate halls" toggle that does the
same without restarting the server.
"""
from __future__ import annotations

import argparse
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Optional

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons" / "maps"
VOICE_DIR = ROOT / "ada_run" / "voice"
WEB_PORT = 8772

#: what the voice says in place of a fenced code block. Reading GDScript aloud
#: through SAPI is noise; the audiobook's Gemini voice can articulate code, the
#: PC's cannot. --read-code keeps the listing.
CODE_CUE = "A short code listing."
AUDIO_EXT = (".mp3", ".wav")


# ─────────────────────────────────────────────────────────────────────────────
# The text — final.md, cleaned for a voice
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Chapter:
    title: str
    kind: str          # "body" | "notes"
    text: str
    words: int


def _inline(t: str) -> str:
    """Markdown inline forms → speech: links to their text, code to its words,
    emphasis marks gone, footnote marks gone, tags gone."""
    t = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", t)                 # images
    t = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", t)              # [text](url)
    t = re.sub(r"\[\^[^\]]+\]", "", t)                          # footnote marks
    t = re.sub(r"`([^`]*)`", lambda m: _code_words(m.group(1)), t)
    t = re.sub(r"<[^>\n]+>", "", t)                             # html tags
    t = re.sub(r"\*\*(.+?)\*\*", r"\1", t)
    t = re.sub(r"__(.+?)__", r"\1", t)
    t = re.sub(r"(?<!\w)\*(?=\S)(.+?)(?<=\S)\*(?!\w)", r"\1", t)
    t = re.sub(r"(?<!\w)_(?=\S)(.+?)(?<=\S)_(?!\w)", r"\1", t)
    t = re.sub(r"[ \t]+", " ", t)
    return t.strip()


def _code_words(s: str) -> str:
    """`Engine.get_process_frames()` → 'Engine dot get process frames': what a
    listener can follow. Underscores are word breaks, calls lose their brackets."""
    s = s.replace("()", "")
    s = s.replace("_", " ").replace(".", " dot ").replace("::", " ")
    return re.sub(r"\s+", " ", s).strip()


def clean_markdown(md: str, read_code: bool = False) -> tuple[str, str, list[str]]:
    """Returns (title, body_text, notes). Title is the first H1, or ''."""
    md = md.replace("\r\n", "\n")
    md = re.sub(r"<!--.*?-->", "", md, flags=re.S)
    # footnote definitions leave the body and become the notes, in order
    notes_by_id: dict[str, str] = {}
    order: list[str] = []
    kept: list[str] = []
    for line in md.split("\n"):
        m = re.match(r"^\[\^([^\]]+)\]:\s*(.*)$", line)
        if m:
            notes_by_id[m.group(1)] = _inline(m.group(2))
            order.append(m.group(1))
            continue
        kept.append(line)
    md = "\n".join(kept)
    # number notes by first mention in the body, then any unmentioned in definition order
    mentioned = [x for x in re.findall(r"\[\^([^\]]+)\]", md) if x in notes_by_id]
    seq: list[str] = []
    for x in mentioned + order:
        if x not in seq:
            seq.append(x)
    notes = ["Note %d. %s" % (i + 1, notes_by_id[x]) for i, x in enumerate(seq)]

    if read_code:
        md = re.sub(r"```[a-zA-Z0-9_-]*\n(.*?)```", lambda m: "\n\n" + _code_words(m.group(1)) + "\n\n", md, flags=re.S)
    else:
        md = re.sub(r"```.*?```", "\n\n" + CODE_CUE + "\n\n", md, flags=re.S)

    title = ""
    out_lines: list[str] = []
    for line in md.split("\n"):
        h = re.match(r"^(#{1,6})\s*(.*?)\s*#*$", line)
        if h:
            text = _inline(h.group(2))
            if not title and len(h.group(1)) == 1:
                title = text
            if text:
                out_lines.append("")
                out_lines.append(text if text[-1] in ".!?…:" else text + ".")
                out_lines.append("")
            continue
        line = re.sub(r"^\s*>\s?", "", line)                    # blockquote
        line = re.sub(r"^\s*[-*+]\s+", "", line)                # bullet
        line = re.sub(r"^\s*\|.*$", "", line)                   # table row
        line = re.sub(r"^\s*[-=*_]{3,}\s*$", "", line)          # rule
        out_lines.append(_inline(line))
    # paragraphs: blank-line separated; single newlines join
    paras: list[str] = []
    cur: list[str] = []
    for line in out_lines:
        if line.strip():
            cur.append(line.strip())
        elif cur:
            paras.append(" ".join(cur))
            cur = []
    if cur:
        paras.append(" ".join(cur))
    body = "\n\n".join(p for p in paras if p)
    return title, body, notes


def humanize(map_name: str) -> str:
    return re.sub(r"[_\-]+", " ", map_name).strip()


def final_path(map_name: str) -> Optional[Path]:
    p = MAPS / map_name / "final.md"
    return p if p.exists() else None


def chapters_for(map_name: str, notes: bool = True, read_code: bool = False) -> list[Chapter]:
    """The map's final.md as chapters: the body, then the notes (if any and
    wanted). Empty when the map has no final.md."""
    p = final_path(map_name)
    if p is None:
        return []
    title, body, note_list = clean_markdown(p.read_text(encoding="utf-8"), read_code=read_code)
    out: list[Chapter] = []
    spoken_title = title or humanize(map_name)
    if body:
        text = body if title else spoken_title + ".\n\n" + body
        out.append(Chapter(title=spoken_title, kind="body", text=text, words=len(text.split())))
    if notes and note_list:
        text = "Notes for %s.\n\n" % spoken_title + "\n\n".join(note_list)
        out.append(Chapter(title="%s — notes" % spoken_title, kind="notes", text=text,
                           words=len(text.split())))
    return out


# ─────────────────────────────────────────────────────────────────────────────
# Pre-rendered audio — a file for the hall wins over live speech
# ─────────────────────────────────────────────────────────────────────────────

def find_audio(map_name: str, voice_dir: Optional[Path] = None) -> list[Path]:
    """Files to play for a map, in order: <dir>/<Map>/*.{mp3,wav}, else any
    <map>*.{mp3,wav} under <dir> (one level of mp3/ or wav/ subfolders too),
    case-insensitively. Same stem in both formats: the mp3."""
    d = Path(voice_dir) if voice_dir else VOICE_DIR
    if not d.is_dir():
        return []
    found: list[Path] = []
    sub = d / map_name
    if sub.is_dir():
        found = [p for p in sub.iterdir() if p.suffix.lower() in AUDIO_EXT]
    if not found:
        low = map_name.lower()
        pools = [d] + [x for x in d.iterdir() if x.is_dir() and x.name.lower() in ("mp3", "wav")]
        for pool in pools:
            for p in pool.iterdir():
                if p.is_file() and p.suffix.lower() in AUDIO_EXT and p.stem.lower().startswith(low):
                    found.append(p)
    by_stem: dict[str, Path] = {}
    for p in sorted(found, key=lambda x: x.name.lower()):
        prev = by_stem.get(p.stem.lower())
        if prev is None or (prev.suffix.lower() == ".wav" and p.suffix.lower() == ".mp3"):
            by_stem[p.stem.lower()] = p
    return [by_stem[k] for k in sorted(by_stem)]


# ─────────────────────────────────────────────────────────────────────────────
# Speakers — the OS voice and the OS player, each a subprocess we can stop
# ─────────────────────────────────────────────────────────────────────────────

class Speaker:
    """speak()/play() start a subprocess and return it; the caller waits on it
    or terminates it. render() writes a WAV. Nothing here blocks the caller."""
    name = "none"

    def speak(self, text: str) -> Optional[subprocess.Popen]:
        raise NotImplementedError

    def play(self, path: Path) -> Optional[subprocess.Popen]:
        raise NotImplementedError

    def render(self, text: str, out_wav: Path) -> bool:
        return False

    def voices(self) -> list[str]:
        return []

    @staticmethod
    def stop(proc) -> None:
        if proc is None:
            return
        try:
            if proc.poll() is None:
                proc.terminate()
                try:
                    proc.wait(timeout=1.5)
                except Exception:
                    proc.kill()
        except Exception:
            pass


_TMP: list[Path] = []


def _remember(p: Path, keep: int = 4) -> Path:
    """Temp files are handed to subprocesses we do not wait for here, so they
    cannot be deleted at once; the last few stay, the rest go."""
    _TMP.append(p)
    while len(_TMP) > keep:
        old = _TMP.pop(0)
        try:
            old.unlink()
        except OSError:
            pass
    return p


def _tmp_text(text: str) -> Path:
    f = tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False, encoding="utf-8")
    f.write(text)
    f.close()
    return _remember(Path(f.name))


def _ps_quote(s: str) -> str:
    return "'" + str(s).replace("'", "''") + "'"


class WindowsSpeaker(Speaker):
    """System.Speech through PowerShell — what tools/tts_radio.ps1 uses. The
    script goes to a temp .ps1 (no quoting on the command line), the text to a
    temp UTF-8 file. Killing powershell.exe stops the voice mid-word."""
    name = "windows-sapi"

    def __init__(self, rate: int = 0, voice: str = "") -> None:
        self.rate = max(-10, min(10, int(rate)))
        self.voice = voice
        self.ffplay = shutil.which("ffplay")

    def _run_ps(self, script: str) -> subprocess.Popen:
        f = tempfile.NamedTemporaryFile("w", suffix=".ps1", delete=False, encoding="utf-8-sig")
        f.write(script)
        f.close()
        _remember(Path(f.name))
        return subprocess.Popen(["powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy",
                                 "Bypass", "-File", f.name],
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def _synth(self) -> str:
        s = ("Add-Type -AssemblyName System.Speech\n"
             "$s = New-Object System.Speech.Synthesis.SpeechSynthesizer\n"
             "$s.Rate = %d\n" % self.rate)
        if self.voice:
            s += "try { $s.SelectVoice(%s) } catch {}\n" % _ps_quote(self.voice)
        return s

    def speak(self, text: str) -> Optional[subprocess.Popen]:
        p = _tmp_text(text)
        return self._run_ps(self._synth()
                            + "$t = [IO.File]::ReadAllText(%s, [Text.Encoding]::UTF8)\n" % _ps_quote(p)
                            + "$s.Speak($t)\n$s.Dispose()\n")

    def play(self, path: Path) -> Optional[subprocess.Popen]:
        path = Path(path)
        if self.ffplay:
            return subprocess.Popen([self.ffplay, "-nodisp", "-autoexit", "-loglevel", "quiet", str(path)],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if path.suffix.lower() == ".wav":
            return self._run_ps("(New-Object System.Media.SoundPlayer %s).PlaySync()\n" % _ps_quote(path))
        # mp3: WPF's MediaPlayer, which a console PowerShell can drive
        uri = path.resolve().as_uri()
        return self._run_ps(
            "Add-Type -AssemblyName PresentationCore\n"
            "$p = New-Object System.Windows.Media.MediaPlayer\n"
            "$p.Open([Uri]%s)\n" % _ps_quote(uri) +
            "$w = 0\nwhile (-not $p.NaturalDuration.HasTimeSpan -and $w -lt 50) { Start-Sleep -Milliseconds 100; $w++ }\n"
            "if (-not $p.NaturalDuration.HasTimeSpan) { exit 1 }\n"
            "$p.Play()\n"
            "Start-Sleep -Milliseconds ([int]$p.NaturalDuration.TimeSpan.TotalMilliseconds + 400)\n"
            "$p.Close()\n")

    def render(self, text: str, out_wav: Path) -> bool:
        p = _tmp_text(text)
        out_wav.parent.mkdir(parents=True, exist_ok=True)
        proc = self._run_ps(self._synth()
                            + "$t = [IO.File]::ReadAllText(%s, [Text.Encoding]::UTF8)\n" % _ps_quote(p)
                            + "$s.SetOutputToWaveFile(%s)\n$s.Speak($t)\n$s.SetOutputToNull()\n$s.Dispose()\n"
                            % _ps_quote(out_wav))
        proc.wait()
        return out_wav.exists() and out_wav.stat().st_size > 1000

    def voices(self) -> list[str]:
        try:
            r = subprocess.run(["powershell", "-NoProfile", "-NonInteractive", "-Command",
                                "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis."
                                "SpeechSynthesizer).GetInstalledVoices() | ForEach-Object { $_.VoiceInfo.Name }"],
                               capture_output=True, text=True, timeout=30)
            return [l.strip() for l in r.stdout.splitlines() if l.strip()]
        except Exception:
            return []


class MacSpeaker(Speaker):
    name = "macos-say"

    def __init__(self, rate: int = 0, voice: str = "") -> None:
        self.wpm = 175 + int(rate) * 15
        self.voice = voice

    def speak(self, text: str) -> Optional[subprocess.Popen]:
        p = _tmp_text(text)
        cmd = ["say", "-r", str(self.wpm), "-f", str(p)]
        if self.voice:
            cmd += ["-v", self.voice]
        return subprocess.Popen(cmd)

    def play(self, path: Path) -> Optional[subprocess.Popen]:
        return subprocess.Popen(["afplay", str(path)])

    def render(self, text: str, out_wav: Path) -> bool:
        p = _tmp_text(text)
        out_wav.parent.mkdir(parents=True, exist_ok=True)
        cmd = ["say", "-r", str(self.wpm), "-f", str(p), "--data-format=LEI16@22050", "-o", str(out_wav)]
        if self.voice:
            cmd += ["-v", self.voice]
        subprocess.run(cmd)
        return out_wav.exists()

    def voices(self) -> list[str]:
        try:
            r = subprocess.run(["say", "-v", "?"], capture_output=True, text=True, timeout=10)
            return [l.split()[0] for l in r.stdout.splitlines() if l.strip()]
        except Exception:
            return []


class LinuxSpeaker(Speaker):
    name = "linux"

    def __init__(self, rate: int = 0, voice: str = "") -> None:
        self.wpm = 165 + int(rate) * 15
        self.voice = voice
        self.tts = shutil.which("espeak-ng") or shutil.which("espeak")
        self.spd = shutil.which("spd-say")
        self.player = next((shutil.which(x) for x in ("ffplay", "mpg123", "paplay", "aplay")
                            if shutil.which(x)), None)

    def speak(self, text: str) -> Optional[subprocess.Popen]:
        p = _tmp_text(text)
        if self.tts:
            cmd = [self.tts, "-s", str(self.wpm), "-f", str(p)]
            if self.voice:
                cmd += ["-v", self.voice]
            return subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if self.spd:
            return subprocess.Popen([self.spd, "-w", "-r", str(int(self.wpm / 4 - 40)), text])
        return None

    def play(self, path: Path) -> Optional[subprocess.Popen]:
        if not self.player:
            return None
        base = os.path.basename(self.player)
        if base == "ffplay":
            return subprocess.Popen([self.player, "-nodisp", "-autoexit", "-loglevel", "quiet", str(path)])
        return subprocess.Popen([self.player, str(path)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def render(self, text: str, out_wav: Path) -> bool:
        if not self.tts:
            return False
        p = _tmp_text(text)
        out_wav.parent.mkdir(parents=True, exist_ok=True)
        cmd = [self.tts, "-s", str(self.wpm), "-f", str(p), "-w", str(out_wav)]
        if self.voice:
            cmd += ["-v", self.voice]
        subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return out_wav.exists()


class NullSpeaker(Speaker):
    """For tests and --text: records what it was asked to say and play, and
    hands back a fake process that finishes at once — or, with `hold`, waits
    to be released, so a switch mid-reading can be proven."""
    name = "null"

    class Proc:
        def __init__(self, hold: bool) -> None:
            self.done = threading.Event()
            self.killed = False
            if not hold:
                self.done.set()

        def poll(self):
            return 0 if self.done.is_set() else None

        def wait(self, timeout=None):
            self.done.wait(timeout)
            return 0

        def terminate(self):
            self.killed = True
            self.done.set()

        def kill(self):
            self.terminate()

    def __init__(self, hold: bool = False) -> None:
        self.spoken: list[str] = []
        self.played: list[Path] = []
        self.rendered: list[Path] = []
        self.procs: list[NullSpeaker.Proc] = []
        self.hold = hold

    def speak(self, text: str):
        self.spoken.append(text)
        p = NullSpeaker.Proc(self.hold)
        self.procs.append(p)
        return p

    def play(self, path: Path):
        self.played.append(Path(path))
        p = NullSpeaker.Proc(self.hold)
        self.procs.append(p)
        return p

    def render(self, text: str, out_wav: Path) -> bool:
        out_wav.parent.mkdir(parents=True, exist_ok=True)
        out_wav.write_bytes(b"RIFF" + b"\0" * 2000)
        self.rendered.append(out_wav)
        return True


def make_speaker(rate: int = 0, voice: str = "") -> Speaker:
    s = platform.system()
    if s == "Windows":
        return WindowsSpeaker(rate, voice)
    if s == "Darwin":
        return MacSpeaker(rate, voice)
    return LinuxSpeaker(rate, voice)


# ─────────────────────────────────────────────────────────────────────────────
# The narrator — a hall change becomes a reading
# ─────────────────────────────────────────────────────────────────────────────

def hall_key(pose: dict) -> Optional[tuple]:
    """What is being stood in. In the museum the hall (pearl, map, index) —
    two halls of one map are two readings; between halls (no pearl) None,
    which means 'no change'. Outside the museum, the map."""
    if not isinstance(pose, dict):
        return None
    hall = pose.get("hall")
    if isinstance(hall, dict):
        if hall.get("pearl"):
            return ("hall", str(hall.get("pearl")), str(hall.get("map", "")), int(hall.get("index", -1)))
        return None
    m = pose.get("map")
    if m:
        return ("map", str(m))
    return None


def key_map(key: tuple) -> str:
    return key[2] if key[0] == "hall" else key[1]


def key_label(key: tuple) -> str:
    if key[0] == "hall":
        return "%s [%s #%d]" % (key[2], key[1], key[3])
    return key[1]


class Narrator:
    def __init__(self, speaker: Speaker, voice_dir: Optional[Path] = None, notes: bool = True,
                 settle: float = 1.2, repeat: bool = False, read_code: bool = False,
                 log=None, enabled: bool = True, gap: float = 0.8) -> None:
        self.speaker = speaker
        self.voice_dir = Path(voice_dir) if voice_dir else VOICE_DIR
        self.notes = notes
        self.settle = settle
        self.repeat = repeat
        self.read_code = read_code
        self.gap = gap
        self.log = log or (lambda m: print("[narrator] " + m))
        self.enabled = enabled
        self.lock = threading.Lock()
        self.heard: set = set()
        self.current: Optional[tuple] = None
        self._pending: Optional[tuple] = None
        self._pending_since = 0.0
        self._proc = None
        self._thread: Optional[threading.Thread] = None
        self._gen = 0
        self.history: list[dict] = []

    # — the 20 Hz entry point: compare, and only act when a hall has held us —
    def on_pose(self, pose: dict) -> None:
        if not self.enabled:
            return
        key = hall_key(pose)
        if key is None:
            return
        now = time.time()
        with self.lock:
            if key != self._pending:
                self._pending = key
                self._pending_since = now
                return
            if key == self.current:
                return
            if now - self._pending_since < self.settle:
                return
        self.begin(key)

    def begin(self, key: tuple) -> None:
        """Start reading a hall now (the settle is the caller's business)."""
        with self.lock:
            self._gen += 1
            gen = self._gen
            was = self.current
            self.current = key
            proc = self._proc
            self._proc = None
        Speaker.stop(proc)
        if was is not None and was != key:
            self.log("left %s" % key_label(was))
        if key in self.heard and not self.repeat:
            self.log("%s — already read this session (--repeat reads again)" % key_label(key))
            return
        playlist = self.playlist(key_map(key))
        if not playlist:
            self.log("%s — no final.md and no audio to read" % key_label(key))
            return
        self.log("reading %s: %s" % (key_label(key), ", ".join(
            "%s (%d words)" % (it["title"], it["words"]) if it["kind"] != "file" else Path(it["path"]).name
            for it in playlist)))
        t = threading.Thread(target=self._run, args=(gen, key, playlist), daemon=True)
        self._thread = t
        t.start()

    def playlist(self, map_name: str) -> list[dict]:
        files = find_audio(map_name, self.voice_dir)
        if files:
            return [{"kind": "file", "path": str(p), "title": p.stem, "words": 0} for p in files]
        return [{"kind": ch.kind, "text": ch.text, "title": ch.title, "words": ch.words}
                for ch in chapters_for(map_name, notes=self.notes, read_code=self.read_code)]

    def _run(self, gen: int, key: tuple, playlist: list[dict]) -> None:
        finished = True
        for i, item in enumerate(playlist):
            with self.lock:
                if gen != self._gen:
                    finished = False
                    break
                proc = self.speaker.play(Path(item["path"])) if item["kind"] == "file" \
                    else self.speaker.speak(item["text"])
                self._proc = proc
            if proc is None:
                self.log("  %s: nothing on this PC can %s it" % (
                    item["title"], "play" if item["kind"] == "file" else "speak"))
                continue
            self.history.append({"t": time.time(), "hall": key_label(key), "item": item["title"],
                                 "kind": item["kind"]})
            try:
                proc.wait()
            except Exception:
                pass
            with self.lock:
                if gen != self._gen:
                    finished = False
                    break
                self._proc = None
            if i < len(playlist) - 1 and self.gap > 0:
                time.sleep(self.gap)
        if finished:
            with self.lock:
                self.heard.add(key)
            self.log("finished %s" % key_label(key))

    def stop(self) -> None:
        with self.lock:
            self._gen += 1
            proc = self._proc
            self._proc = None
            self.current = None
        Speaker.stop(proc)

    def wait(self, timeout: float = 30.0) -> None:
        t = self._thread
        if t is not None:
            t.join(timeout)

    def state(self) -> dict:
        with self.lock:
            return {"on": self.enabled, "speaker": self.speaker.name,
                    "current": key_label(self.current) if self.current else None,
                    "heard": [key_label(k) for k in self.heard],
                    "voice_dir": str(self.voice_dir), "notes": self.notes, "repeat": self.repeat,
                    "settle": self.settle}


# ─────────────────────────────────────────────────────────────────────────────
# Rendering — the halls' voices as files, once
# ─────────────────────────────────────────────────────────────────────────────

def sequence_maps(seq_id: str) -> list[str]:
    p = ROOT / "commons" / "maps" / "sequences" / (seq_id + ".json")
    if not p.exists():
        return []
    d = json.loads(p.read_text(encoding="utf-8"))
    seqs = d.get("sequences", d)
    s = seqs.get(seq_id) if isinstance(seqs, dict) else None
    return list(s.get("maps", [])) if isinstance(s, dict) else []


def _ffmpeg() -> Optional[str]:
    exe = shutil.which("ffmpeg")
    if exe:
        return exe
    try:
        import imageio_ffmpeg  # type: ignore
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        return None


def render_map(map_name: str, speaker: Speaker, out_dir: Optional[Path] = None, notes: bool = True,
               read_code: bool = False, mp3: bool = True, log=print) -> dict:
    out = (Path(out_dir) if out_dir else VOICE_DIR) / map_name
    chapters = chapters_for(map_name, notes=notes, read_code=read_code)
    manifest: dict = {"map": map_name, "speaker": speaker.name, "rendered": time.strftime("%Y-%m-%dT%H:%M:%S"),
                      "chapters": []}
    if not chapters:
        log("%s: no final.md" % map_name)
        return manifest
    ff = _ffmpeg() if mp3 else None
    for i, ch in enumerate(chapters):
        wav = out / ("%02d-%s.wav" % (i + 1, ch.kind))
        ok = speaker.render(ch.text, wav)
        row = {"title": ch.title, "kind": ch.kind, "words": ch.words, "wav": wav.name if ok else None, "mp3": None}
        if ok and ff:
            m = wav.with_suffix(".mp3")
            r = subprocess.run([ff, "-hide_banner", "-loglevel", "error", "-y", "-i", str(wav),
                                "-codec:a", "libmp3lame", "-q:a", "4", str(m)])
            if r.returncode == 0 and m.exists():
                row["mp3"] = m.name
        manifest["chapters"].append(row)
        log("%s: %s — %d words → %s%s" % (map_name, ch.title, ch.words, wav.name if ok else "FAILED",
                                          " + mp3" if row["mp3"] else ""))
    out.mkdir(parents=True, exist_ok=True)
    (out / "manifest.json").write_text(json.dumps(manifest, indent=1, ensure_ascii=False), encoding="utf-8")
    return manifest


# ─────────────────────────────────────────────────────────────────────────────
# Beside a running vr_link.py: listen to its event stream
# ─────────────────────────────────────────────────────────────────────────────

def listen(narrator: Narrator, port: int = WEB_PORT) -> int:
    base = "http://127.0.0.1:%d" % port
    narrator.log("listening to %s/events for poses" % base)
    while True:
        try:
            with urllib.request.urlopen(base + "/events", timeout=60) as r:
                while True:
                    line = r.readline()
                    if not line:
                        break
                    line = line.decode("utf-8", "replace").strip()
                    if not line.startswith("data: "):
                        continue
                    try:
                        ev = json.loads(line[6:])
                    except json.JSONDecodeError:
                        continue
                    if ev.get("k") == "pose":
                        narrator.on_pose(ev)
        except KeyboardInterrupt:
            narrator.stop()
            return 0
        except Exception as e:
            narrator.log("link not reachable (%s) — retrying in 2 s" % e)
            time.sleep(2.0)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--listen", action="store_true", help="read halls as a running vr_link.py reports them")
    ap.add_argument("--say", metavar="MAP", help="speak one map's final.md now")
    ap.add_argument("--text", metavar="MAP", help="print what would be spoken")
    ap.add_argument("--render", nargs="?", const="", metavar="MAP", help="render WAV (+mp3) for a map, or with --seq")
    ap.add_argument("--seq", metavar="SEQ", help="with --render: every map of a sequence")
    ap.add_argument("--all", action="store_true", help="with --render: every map that has a final.md")
    ap.add_argument("--voices", action="store_true", help="list this PC's voices")
    ap.add_argument("--voice", default="", help="voice name (see --voices)")
    ap.add_argument("--rate", type=int, default=0, help="-10..10, 0 is normal")
    ap.add_argument("--voice-dir", default=None, help="where rendered audio lives (ada_run/voice)")
    ap.add_argument("--no-notes", action="store_true", help="skip the notes chapter")
    ap.add_argument("--read-code", action="store_true", help="read code listings instead of announcing them")
    ap.add_argument("--repeat", action="store_true", help="read a hall again on re-entry")
    ap.add_argument("--settle", type=float, default=1.2)
    ap.add_argument("--no-mp3", action="store_true", help="with --render: WAV only")
    ap.add_argument("--port", type=int, default=WEB_PORT)
    args = ap.parse_args()

    if args.text:
        chs = chapters_for(args.text, notes=not args.no_notes, read_code=args.read_code)
        if not chs:
            print("no final.md for '%s'" % args.text)
            return 1
        for ch in chs:
            print("=== %s (%s, %d words) ===" % (ch.title, ch.kind, ch.words))
            print(ch.text)
            print()
        return 0

    speaker = make_speaker(args.rate, args.voice)
    if args.voices:
        for v in speaker.voices():
            print(v)
        return 0

    if args.render is not None:
        maps: list[str] = []
        if args.render:
            maps = [args.render]
        elif args.seq:
            maps = sequence_maps(args.seq)
        elif args.all:
            maps = sorted(p.parent.name for p in MAPS.glob("*/final.md"))
        if not maps:
            print("nothing to render: give a map, --seq <id> or --all")
            return 2
        for m in maps:
            render_map(m, speaker, args.voice_dir, notes=not args.no_notes, read_code=args.read_code,
                       mp3=not args.no_mp3)
        return 0

    narrator = Narrator(speaker, voice_dir=args.voice_dir, notes=not args.no_notes, settle=args.settle,
                        repeat=args.repeat, read_code=args.read_code)
    if args.say:
        narrator.begin(("map", args.say))
        try:
            narrator.wait(timeout=3600)
        except KeyboardInterrupt:
            narrator.stop()
        return 0
    if args.listen:
        return listen(narrator, args.port)
    ap.print_help()
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
