#!/usr/bin/env python3
"""Build the MkDocs source folder of the Godot course site.

    python build_site.py            # writes docs/ beside this file
    python build_site.py --check    # writes nothing; exits 1 if docs/ would change

Reads the course's own files in the Ada Research repository (the folder four
levels up from this file, or $ADA_REPO):

    doc/book/course/opening.json                         the short track, 17 stops
    doc/book/course/opening/*.md, *.png, *.jpg           the hand-written opening pages
    doc/book/iterations/claude-course-braid-2026-09-30/course.json
                                                         the whole course, 46 chapters
    doc/book/course/kits.json, kits_checked.json         which kit is which chapter, and
                                                         how each kit's build ended
    doc/book/studies/<kit>/                              the kits: TUTORIAL.md, README.md,
                                                         verification.json, project.godot
    doc/book/day-zero.md, commons/maps/<Hall>/tutorial.md
                                                         the lessons of four short-track stops
    doc/book/course/TAPE.md, field_notes/                material for teachers

and the hand-written files beside this script: static/ (stylesheet, script, logo),
pictures/ (stop pictures that are not elsewhere in the repository).

It writes docs/ and nothing else: the Markdown pages, the pictures next to the page that
shows them, one zip per kit in docs/downloads/, and docs/_nav.json, which hooks.py turns
into the navigation. Same input, same output: no clock, no random, files in sorted order,
zip entries with a fixed date. Only files whose bytes change are rewritten, so a running
`mkdocs serve` reloads only when something changed.

Needs nothing outside the Python standard library and never contacts the encyclopedia.
"""
from __future__ import annotations

import argparse
import io
import json
import os
import posixpath
import re
import sys
import zipfile
from dataclasses import dataclass, field
from pathlib import Path

SITE = Path(__file__).resolve().parent
REPO = Path(os.environ.get("ADA_REPO") or SITE.parents[3]).resolve()
DOCS = SITE / "docs"
STATIC = SITE / "static"
PICTURES = SITE / "pictures"

OPENING_JSON = "doc/book/course/opening.json"
OPENING_DIR = "doc/book/course/opening"
COURSE_JSON = "doc/book/iterations/claude-course-braid-2026-09-30/course.json"
KITS_JSON = "doc/book/course/kits.json"
CHECKED_JSON = "doc/book/course/kits_checked.json"
STUDIES = "doc/book/studies"
TAPE_MD = "doc/book/course/TAPE.md"
FIELD_NOTE_MD = "doc/book/course/opening/FIELD_NOTE.md"
INTRO_MD = "doc/book/course/opening/INTRO.md"
PLATE_MD = "doc/book/course/opening/PLATE.md"
WORKED_NOTE_MD = "doc/book/course/field_notes/2026-10-01-pyramid-family.md"

# What a kit download leaves out: the encyclopedia's isExcludedKitEntry
# (ada_encyclopedia/src/lib/course.ts), plus stills/, which every kit's .gitignore names.
EXCLUDED_DIRS = {".godot", ".git", ".import", "node_modules", "__pycache__", "stills"}
EXCLUDED_NAMES = {".gitignore", ".ds_store", "thumbs.db"}
EXCLUDED_SUFFIXES = (".uid", ".import", ".log")
ZIP_DATE = (1980, 1, 1, 0, 0, 0)
ZIP_WARN_TOTAL = 150 * 1024 * 1024

# Stop pictures named "/course/<name>" in opening.json live in the encyclopedia's public/
# folder. These are the same pictures where the repository has them; the rest were copied
# once into pictures/ beside this script (see pictures/SOURCES.txt).
PICTURE_SOURCES = {
    "body-of-parts.png": "doc/book/studies/body-of-parts/process.png",
    "chessboard.png": "doc/book/studies/chessboard/process.png",
    "collage.png": "doc/book/studies/collage/process.png",
    "family.png": "doc/book/studies/family/process.png",
}

IMAGE_EXT = {".png", ".jpg", ".jpeg", ".gif", ".svg", ".webp"}
CODE_EXT = {".gd", ".tscn", ".tres", ".gdshader", ".gdshaderinc", ".shader", ".cfg",
            ".godot", ".json", ".py", ".txt", ".csv", ".glb", ".gltf", ".obj", ".import"}

STOP_SLUGS = {
    "P00_the_plate": "the-plate",
    "W01_break_it_on_purpose": "break-it-on-purpose",
    "CP1_opening": "checkpoint",
    "W02_decide_and_note": "decide-and-note",
}

STATUS_WORDS = {
    "runnable": "runnable",
    "draft": "draft",
    "being built": "being built",
    "planned": "planned",
}

WARNINGS: list[str] = []


def warn(msg: str) -> None:
    WARNINGS.append(msg)


# ---------------------------------------------------------------------------
# Reading
# ---------------------------------------------------------------------------

def repo_path(rel: str) -> Path:
    return REPO.joinpath(*rel.split("/"))


def read_text(path: Path) -> str:
    text = path.read_text(encoding="utf-8-sig")
    return text.replace("\r\n", "\n").replace("\r", "\n")


def load_json(rel: str):
    path = repo_path(rel)
    try:
        return json.loads(read_text(path))
    except FileNotFoundError:
        warn(f"missing {rel}")
        return None
    except json.JSONDecodeError as exc:
        warn(f"unreadable {rel}: {exc}")
        return None


def norm(rel: str) -> str:
    """Normalise a repository-relative posix path ('a/b/../c' -> 'a/c')."""
    out = posixpath.normpath(rel)
    return "" if out == "." else out


def esc(text) -> str:
    """Plain prose from the course data, made safe to drop into Markdown."""
    if text is None:
        return ""
    s = str(text)
    s = s.replace("\\", "\\\\")
    for ch in "*_[]`|":
        s = s.replace(ch, "\\" + ch)
    s = s.replace("<", "&lt;")
    return s


def indent(md: str, n: int = 4) -> str:
    pad = " " * n
    return "\n".join((pad + line) if line.strip() else "" for line in md.split("\n"))


def human_size(n: int) -> str:
    if n >= 1024 * 1024:
        return f"{n / (1024 * 1024):.1f} MB"
    if n >= 1024:
        return f"{round(n / 1024)} KB"
    return f"{n} bytes"


def short_title(title: str) -> str:
    """The part of a title before its first colon, for the left tree."""
    head = title.split(":", 1)[0].strip()
    return head or title


def hall_one_break(hall: str, longer_than: int = 30) -> str:
    """A hall name for a table cell. A long one gets a single break opportunity, after the
    underscore nearest its middle; shorter ones none, so they never split."""
    if len(hall) <= longer_than or "_" not in hall:
        return esc(hall)
    mid = len(hall) / 2
    cut = min((i for i, ch in enumerate(hall) if ch == "_"), key=lambda i: abs(i + 1 - mid))
    return esc(hall[:cut + 1]) + "<wbr>" + esc(hall[cut + 1:])


def plain(md: str) -> str:
    """Markdown inline text as plain text: no emphasis marks, code ticks or escapes."""
    s = re.sub(r"\\(.)", r"\1", md)
    s = re.sub(r"[`*]", "", s)
    return re.sub(r"\s+", " ", s).strip()


def title_head(h1: str) -> str:
    """The name part of a lesson's title, for the left tree: 'Point Zero — Hello, world.' -> 'Point Zero'."""
    p = plain(h1)
    head = re.split(r"\s+[—–]\s+|:\s", p, maxsplit=1)[0].strip()
    return head or p


def part_name(title: str) -> str:
    """A part's title without its parenthesis: 'Place and join (primitives)' -> 'Place and join'."""
    return re.sub(r"\s*\(.*\)\s*$", "", title).strip() or title


# ---------------------------------------------------------------------------
# Kits
# ---------------------------------------------------------------------------

@dataclass
class Kit:
    name: str
    rel: str
    folder: Path
    exists: bool = False
    tutorial: str | None = None          # repo-relative path of TUTORIAL.md
    readme: str | None = None
    verification: dict | None = None
    checked: dict = field(default_factory=dict)
    main_scene: str | None = None
    project_name: str | None = None
    zip_rel: str | None = None           # docs-relative path of the zip
    zip_size: int = 0
    zip_files: int = 0

    @property
    def checks(self) -> tuple[int, int] | None:
        v = self.verification
        if not isinstance(v, dict):
            return None
        lst = v.get("checks")
        if isinstance(lst, list) and lst:
            total = len(lst)
            ok = sum(1 for c in lst if isinstance(c, dict) and c.get("passed") is True)
            return ok, total
        run = v.get("checks_run")
        failed = v.get("checks_failed")
        if isinstance(run, int):
            return run - (len(failed) if isinstance(failed, list) else int(failed or 0)), run
        return None

    @property
    def passed(self) -> bool | None:
        v = self.verification
        if not isinstance(v, dict):
            return None
        if isinstance(v.get("passed"), bool):
            return v["passed"]
        c = self.checks
        return (c[0] == c[1]) if c else None

    @property
    def status(self) -> str:
        if not self.exists:
            return "planned"
        if self.tutorial and self.passed:
            return "runnable"
        if self.tutorial:
            return "draft"
        return "being built"


def kit_files(folder: Path) -> list[tuple[str, Path]]:
    """The files a kit ships, as the encyclopedia's walkKit lists them."""
    out: list[tuple[str, Path]] = []

    def visit(d: Path, prefix: str, depth: int) -> None:
        if depth > 8:
            return
        try:
            entries = sorted(d.iterdir(), key=lambda p: p.name)
        except OSError:
            return
        for e in entries:
            if e.is_symlink():
                continue
            rel = f"{prefix}/{e.name}" if prefix else e.name
            if e.is_dir():
                if e.name in EXCLUDED_DIRS:
                    continue
                visit(e, rel, depth + 1)
            elif e.is_file():
                low = e.name.lower()
                if low in EXCLUDED_NAMES or low.endswith(EXCLUDED_SUFFIXES):
                    continue
                out.append((rel, e))

    visit(folder, "", 0)
    out.sort(key=lambda t: (1 if "/" in t[0] else 0,
                            0 if t[0].lower() == "readme.md" else 1,
                            t[0]))
    return out


def make_zip(kit_name: str, files: list[tuple[str, Path]]) -> bytes:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as zf:
        for rel, path in files:
            info = zipfile.ZipInfo(f"{kit_name}/{rel}", date_time=ZIP_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o644 << 16
            zf.writestr(info, path.read_bytes())
    return buf.getvalue()


def load_kit(name: str, checked_all: dict) -> Kit:
    rel = f"{STUDIES}/{name}"
    folder = repo_path(rel)
    kit = Kit(name=name, rel=rel, folder=folder)
    kit.checked = checked_all.get(name) or {}
    if not folder.is_dir():
        return kit
    kit.exists = True
    if (folder / "TUTORIAL.md").is_file():
        kit.tutorial = f"{rel}/TUTORIAL.md"
    if (folder / "README.md").is_file():
        kit.readme = f"{rel}/README.md"
    vpath = folder / "verification.json"
    if vpath.is_file():
        try:
            kit.verification = json.loads(read_text(vpath))
        except (json.JSONDecodeError, OSError) as exc:
            warn(f"{name}: verification.json unreadable ({exc}); treated as absent")
    ppath = folder / "project.godot"
    if ppath.is_file():
        text = read_text(ppath)
        m = re.search(r'^run/main_scene="([^"]+)"', text, re.M)
        if m and m.group(1).startswith("res://"):
            kit.main_scene = m.group(1)[len("res://"):]
        m = re.search(r'^config/name="([^"]*)"', text, re.M)
        if m:
            kit.project_name = m.group(1)
    return kit


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

class Out:
    def __init__(self) -> None:
        self.files: dict[str, bytes] = {}

    def text(self, rel: str, content: str) -> None:
        if not content.endswith("\n"):
            content += "\n"
        self.files[rel] = content.encode("utf-8")

    def data(self, rel: str, content: bytes) -> None:
        self.files[rel] = content

    def copy(self, rel: str, src: Path) -> None:
        self.files[rel] = src.read_bytes()


def sync(out: Out, dest: Path, check: bool) -> tuple[int, int]:
    """Make dest hold exactly out.files. Returns (written, removed)."""
    assert dest.resolve().parent == SITE, "docs/ must sit beside build_site.py"
    written = removed = 0
    wanted = set(out.files)
    for rel in sorted(out.files):
        data = out.files[rel]
        path = dest.joinpath(*rel.split("/"))
        if path.is_file() and path.read_bytes() == data:
            continue
        written += 1
        if not check:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
    if dest.is_dir():
        for path in sorted(dest.rglob("*"), key=lambda p: len(p.parts), reverse=True):
            rel = path.relative_to(dest).as_posix()
            if path.is_file() and rel not in wanted:
                removed += 1
                if not check:
                    path.unlink()
            elif path.is_dir() and not check:
                try:
                    next(path.iterdir())
                except StopIteration:
                    path.rmdir()
    return written, removed


# ---------------------------------------------------------------------------
# Pages and links
# ---------------------------------------------------------------------------

@dataclass
class PageCtx:
    path: str                 # docs-relative path of the page, e.g. short-track/point-plane/index.md
    track: str                # short | course | teachers | extra | home
    kit: str | None = None    # the kit whose box is on this page
    assets: dict = field(default_factory=dict)   # file name -> source Path
    kit_doc_links: set = field(default_factory=set)  # kit files (README.md, ...) whose links land on the box

    @property
    def dir(self) -> str:
        return posixpath.dirname(self.path)

    def add_asset(self, src: Path) -> str:
        """Copy src next to the page; returns the file name the page uses."""
        name = src.name
        stem, ext = os.path.splitext(name)
        n = 1
        while name in self.assets and self.assets[name] != src:
            n += 1
            name = f"{stem}-{n}{ext}"
        self.assets[name] = src
        return name


class Registry:
    """Where things live on the site: lessons, kits, the course pages."""

    def __init__(self) -> None:
        self.lessons: dict[str, dict[str, str]] = {}   # repo md -> {track: page}
        self.kits: dict[str, dict[str, str]] = {}      # kit name -> {track: page}
        self.chapters: dict[str, tuple[int, str]] = {}  # internal id (ch45) -> (displayed n, page)
        self.course_index = "course/index.md"
        self.short_index = "short-track/index.md"

    def add_lesson(self, src: str, track: str, page: str) -> None:
        self.lessons.setdefault(norm(src), {}).setdefault(track, page)

    def add_kit(self, kit: str, track: str, page: str) -> None:
        self.kits.setdefault(kit, {}).setdefault(track, page)

    @staticmethod
    def pick(options: dict[str, str], track: str) -> str | None:
        for t in (track, "short", "course", "extra", "teachers", "home"):
            if t in options:
                return options[t]
        return None


def rel_link(ctx: PageCtx, target_page: str, fragment: str = "") -> str:
    if target_page == ctx.path:
        return f"#{fragment}" if fragment else posixpath.basename(target_page)
    link = posixpath.relpath(target_page, ctx.dir or ".")
    return link + (f"#{fragment}" if fragment else "")


FENCE_RE = re.compile(r"^(\s*)(`{3,}|~{3,})(.*)$")
CODE_SPAN_RE = re.compile(r"(`+)(.+?)(?<!`)\1(?!`)")
LINK_RE = re.compile(
    r"(!?)\[((?:[^\[\]]|\[[^\[\]]*\])*)\]"
    r"\(\s*<?([^\s<>()]+(?:\([^\s()]*\)[^\s<>()]*)*)>?(?:\s+(?:\"[^\"]*\"|'[^']*'))?\s*\)"
)
HALL_RE = re.compile(r"^commons/maps/([A-Za-z0-9_.-]+)/[^/]+$")
KIT_FILE_RE = re.compile(r"^doc/book/studies/([A-Za-z0-9_.-]+)(?:/(.*))?$")


def hall_text(text: str, hall: str) -> str:
    chip = (f'<span class="hall-ref" title="A hall of the Ada museum; its own text is not on this site">'
            f"{hall}</span>")
    plain = re.sub(r"[`*]", "", text).replace("\\_", "_").strip()
    key = plain.replace(" ", "_").lower()
    if key and (key == hall.lower()
                or (len(key) >= 5 and key in hall.lower() and re.fullmatch(r"[A-Za-z0-9_ ]+", plain)
                    and any(ch.isupper() for ch in plain))):
        return chip
    # The link text says what the hall is to the sentence ("the reading", "its making
    # passage"); the hall's name goes beside it in brackets, so the sentence still reads.
    return f"{text} ({chip})"


# A chapter named by course.json's internal id ("ch12", "ch45's") in prose. Code spans,
# links and HTML tags are matched first so that nothing inside them is touched.
CHREF_RE = re.compile(
    r"(`+).+?(?<!`)\1(?!`)"
    r"|!?\[(?:[^\[\]]|\[[^\[\]]*\])*\]\([^)]*\)"
    r"|<[^>]+>"
    r"|(?<![\w/.#-])ch(\d{1,2})(?![\w-])"
)


def link_chapter_refs(text: str, ctx: PageCtx, reg: Registry) -> str:
    """'ch12' -> '[chapter 29](...)': the site numbers chapters as their pages do."""
    if "ch" not in text or not reg.chapters:
        return text

    def fn(m: re.Match) -> str:
        if m.group(2) is None:
            return m.group(0)
        hit = reg.chapters.get(f"ch{int(m.group(2)):02d}")
        if not hit:
            return m.group(0)
        n, page = hit
        return f"[chapter {n}]({rel_link(ctx, page)})"

    return CHREF_RE.sub(fn, text)


def link_chapter_refs_md(md: str, ctx: PageCtx, reg: Registry) -> str:
    """link_chapter_refs over a whole page, leaving fenced code alone."""
    out = []
    in_fence = False
    fence_char = ""
    fence_len = 0
    for line in md.split("\n"):
        m = FENCE_RE.match(line)
        if in_fence:
            out.append(line)
            if m and m.group(2)[0] == fence_char and len(m.group(2)) >= fence_len and not m.group(3).strip():
                in_fence = False
            continue
        if m:
            in_fence = True
            fence_char = m.group(2)[0]
            fence_len = len(m.group(2))
            out.append(line)
            continue
        out.append(link_chapter_refs(line, ctx, reg))
    return "\n".join(out)


def resolve_link(is_img: bool, text: str, target: str, src_rel: str, ctx: PageCtx,
                 reg: Registry) -> str:
    original = f"{'!' if is_img else ''}[{text}]({target})"
    target = target.strip()
    low = target.lower()

    # In-page anchors and mail stay.
    if target.startswith("#") or low.startswith("mailto:"):
        return original

    # External links stay, except the local machine.
    if re.match(r"^https?://", low):
        if re.match(r"^https?://(localhost|127\.0\.0\.1|\[::1\])(:\d+)?(/|$)", low):
            return text or target
        return original

    path, _, fragment = target.partition("#")

    # Encyclopedia routes.
    if path.startswith("/"):
        if path.rstrip("/") in ("/course/outline", "/course"):
            return f"[{text}]({rel_link(ctx, reg.course_index)})"
        m = re.match(r"^/course/([A-Za-z0-9._-]+\.(?:png|jpe?g|gif|svg|webp))$", path, re.I)
        if m:
            pic = course_picture(m.group(1))
            if pic:
                name = ctx.add_asset(pic)
                return f"{'!' if is_img else ''}[{text}]({name})"
            warn(f"{src_rel}: picture {path} not found; left as text")
            return text
        m = re.search(r"/([A-Za-z0-9._-]+)\.zip$", path)
        if m:
            kit = m.group(1)
            hit = kit_anchor(kit, ctx, reg)
            if hit:
                return f"[{text}]({hit})"
        base = posixpath.basename(path)
        if base and posixpath.splitext(base)[1].lower() in CODE_EXT:
            return f"{text} (`{base}`)" if base not in text else text
        return text

    # Relative to the source file.
    src_dir = posixpath.dirname(src_rel)
    resolved = norm(posixpath.join(src_dir, path)) if path else src_rel
    ext = posixpath.splitext(resolved)[1].lower()

    if is_img or ext in IMAGE_EXT:
        src = repo_path(resolved)
        if src.is_file():
            name = ctx.add_asset(src)
            return f"{'!' if is_img else ''}[{text}]({name})"
        warn(f"{src_rel}: image {target} not found; left as text")
        return text

    if ext == ".md":
        pages = reg.lessons.get(resolved)
        if pages:
            page = Registry.pick(pages, ctx.track)
            return f"[{text}]({rel_link(ctx, page, fragment)})"
        m = KIT_FILE_RE.match(resolved)
        if m:
            hit = kit_anchor(m.group(1), ctx, reg)
            if hit:
                if m.group(1) == ctx.kit and m.group(2):
                    ctx.kit_doc_links.add(m.group(2))
                return f"[{text}]({hit})"
            return text
        m = HALL_RE.match(resolved)
        if m:
            hall = m.group(1)
            return hall_text(text, hall)
        return text

    m = KIT_FILE_RE.match(resolved)
    if m:
        inner = m.group(2) or ""
        if ext == ".zip" or not inner:
            hit = kit_anchor(m.group(1), ctx, reg)
            return f"[{text}]({hit})" if hit else text
        name = inner
        if f"`{name}`" in text or name == text.strip("`"):
            return f"`{name}`"
        return f"{text} (`{name}`)"

    m = HALL_RE.match(resolved)
    if m:
        return hall_text(text, m.group(1))
    return text


def kit_anchor(kit: str, ctx: PageCtx, reg: Registry) -> str | None:
    if ctx.kit == kit:
        return "#the-kit"
    pages = reg.kits.get(kit)
    if not pages:
        return None
    return rel_link(ctx, Registry.pick(pages, ctx.track), "the-kit")


def rewrite_markdown(text: str, src_rel: str, ctx: PageCtx, reg: Registry) -> str:
    out_lines = []
    in_fence = False
    fence_char = ""
    fence_len = 0
    for line in text.split("\n"):
        m = FENCE_RE.match(line)
        if in_fence:
            out_lines.append(line)
            if m and m.group(2)[0] == fence_char and len(m.group(2)) >= fence_len and not m.group(3).strip():
                in_fence = False
            continue
        if m:
            in_fence = True
            fence_char = m.group(2)[0]
            fence_len = len(m.group(2))
            out_lines.append(line)
            continue
        spans = [(s.start(), s.end()) for s in CODE_SPAN_RE.finditer(line)]

        def inside(pos: int) -> bool:
            return any(a <= pos < b for a, b in spans)

        pieces = []
        pos = 0
        for lm in LINK_RE.finditer(line):
            if inside(lm.start()):
                continue
            pieces.append(line[pos:lm.start()])
            pieces.append(resolve_link(lm.group(1) == "!", lm.group(2), lm.group(3), src_rel, ctx, reg))
            pos = lm.end()
        pieces.append(line[pos:])
        out_lines.append(link_chapter_refs("".join(pieces), ctx, reg))
    return "\n".join(out_lines)


def split_h1(text: str) -> tuple[str | None, str]:
    """The lesson's first-level title, and the text after it."""
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if not line.strip() or line.lstrip().startswith("<!--"):
            continue
        if line.startswith("# "):
            return line[2:].strip(), "\n".join(lines[i + 1:]).lstrip("\n")
        break
    return None, text


def insert_after_heading(body: str, heading: str, block: str) -> tuple[str, bool]:
    """Put block after the heading whose text matches; returns (body, placed)."""
    want = re.sub(r"[*_`]", "", heading).strip().lower()
    lines = body.split("\n")
    in_fence = False
    for i, line in enumerate(lines):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = re.match(r"^(#{2,6})\s+(.*)$", line)
        if m:
            got = re.sub(r"[*_`]", "", m.group(2)).strip().lower()
            if got == want or got.startswith(want):
                return "\n".join(lines[:i + 1] + ["", block, ""] + lines[i + 1:]), True
    return body, False


# ---------------------------------------------------------------------------
# Pictures
# ---------------------------------------------------------------------------

def course_picture(name: str) -> Path | None:
    candidates = [repo_path(f"{OPENING_DIR}/{name}")]
    if name in PICTURE_SOURCES:
        candidates.append(repo_path(PICTURE_SOURCES[name]))
    candidates.append(PICTURES / name)
    for c in candidates:
        if c.is_file():
            return c
    return None


# ---------------------------------------------------------------------------
# The course model
# ---------------------------------------------------------------------------

class Course:
    def __init__(self) -> None:
        self.opening = load_json(OPENING_JSON) or {"stops": [], "capabilities": {}}
        self.course = load_json(COURSE_JSON) or {"chapters": [], "parts": []}
        self.kits_map = load_json(KITS_JSON) or {"kits": {}, "extras": []}
        self.checked = load_json(CHECKED_JSON) or {}
        self.caps: dict = self.opening.get("capabilities") or {}
        self.stops: list[dict] = self.opening.get("stops") or []
        self.chapters: dict[str, dict] = {c["id"]: c for c in self.course.get("chapters", [])}
        self.parts: list[dict] = self.course.get("parts") or []
        self.part_of: dict[str, dict] = {p["id"]: p for p in self.parts}
        self.part_no: dict[str, int] = {p["id"]: i + 1 for i, p in enumerate(self.parts)}
        self.chapter_kit: dict[str, str] = dict(self.kits_map.get("kits") or {})
        self.extras: list[dict] = list(self.kits_map.get("extras") or [])
        self.stop_of_chapter: dict[str, dict] = {}
        for ch in self.chapters.values():
            sid = ch.get("opening_stop")
            if sid:
                for s in self.stops:
                    if s["id"] == sid:
                        self.stop_of_chapter[ch["id"]] = s
        self.chapter_of_stop = {s["id"]: cid for cid, s in self.stop_of_chapter.items()}
        self.assemblage = {a["chapter"]: a for a in self.course.get("assemblages") or []}

        names = set(self.chapter_kit.values())
        names.update(e["kit"] for e in self.extras if e.get("kit"))
        for s in self.stops:
            if s.get("kit"):
                names.add(posixpath.basename(s["kit"]))
        self.kits: dict[str, Kit] = {n: load_kit(n, self.checked) for n in sorted(names)}

    def carrier_hall(self, ch: dict) -> str | None:
        for h in ch.get("halls") or []:
            if h.get("role") == "carrier":
                return h.get("map")
        halls = ch.get("halls") or []
        return halls[0].get("map") if halls else None

    def chapter_lesson(self, cid: str) -> str | None:
        """The text a chapter's page shows: its kit's TUTORIAL.md, else its stop's lesson."""
        kit = self.kits.get(self.chapter_kit.get(cid, ""))
        if kit and kit.tutorial:
            return kit.tutorial
        stop = self.stop_of_chapter.get(cid)
        if stop and stop.get("lesson") and repo_path(stop["lesson"]).is_file():
            return stop["lesson"]
        return None

    def chapter_status(self, cid: str) -> str:
        stop = self.stop_of_chapter.get(cid)
        if stop and stop.get("status"):
            return stop["status"]
        kit = self.kits.get(self.chapter_kit.get(cid, ""))
        return kit.status if kit else "planned"

    def chapters_in_order(self) -> list[dict]:
        return sorted(self.chapters.values(), key=lambda c: c.get("n", 0))


def stop_slug(stop: dict) -> str:
    if stop["id"] in STOP_SLUGS:
        return STOP_SLUGS[stop["id"]]
    if stop.get("kit"):
        return posixpath.basename(stop["kit"])
    return re.sub(r"[^a-z0-9]+", "-", stop["id"].lower()).strip("-")


def chapter_slug(course: Course, cid: str) -> str:
    """The chapter's folder: its displayed number, then its kit ('08-extrude').

    Built from the number the page shows, never from course.json's internal id: ch45 is
    chapter 8, and an address bar that says ch45 above a page that says 8 sends a reader
    looking for the wrong chapter."""
    ch = course.chapters.get(cid) or {}
    n = ch.get("n")
    kit = course.chapter_kit.get(cid)
    tail = kit or re.sub(r"[^a-z0-9]+", "-", short_title(ch.get("title") or cid).lower()).strip("-") or cid
    if isinstance(n, int):
        return f"{n:02d}-{tail}"
    return f"{cid}-{kit}" if kit else cid


# ---------------------------------------------------------------------------
# Page parts
# ---------------------------------------------------------------------------

def status_chip(status: str) -> str:
    cls = {"runnable": "runnable", "draft": "draft", "being built": "building"}.get(status, "planned")
    return f'<span class="chip chip--{cls}">{STATUS_WORDS.get(status, esc(status))}</span>'


def stop_status_chip(stop: dict) -> str:
    """A stop's status. "Runnable" is said of a kit; a stop with no kit that is ready says
    there is nothing to install instead, so the chip never sits beside a "No kit" box."""
    status = stop.get("status") or "planned"
    if not stop.get("kit") and status == "runnable":
        return ('<span class="chip chip--read" title="This stop has no kit: it is read, or worked in '
                'an earlier kit">nothing to install</span>')
    return status_chip(status)


def checks_chips(kit: Kit | None, built_before: set | None = None) -> list[str]:
    if not kit or not kit.exists:
        return []
    chips = []
    c = kit.checks
    if c:
        ok, total = c
        cls = "chip--pass" if ok == total and kit.passed else "chip--fail"
        chips.append(f'<span class="chip {cls}" title="verify.gd, as written into the kit\'s verification.json">'
                     f"checks {ok} of {total} passed</span>")
    elif kit.tutorial and built_before and kit.name in built_before:
        chips.append('<span class="chip chip--muted" title="kits.json lists this kit as built before the '
                     'long track, whose kits each write a verification.json; this one has none">'
                     'no verification: built before the long track</span>')
    elif kit.tutorial:
        chips.append('<span class="chip chip--muted">no verification yet</span>')
    ck = kit.checked
    verdict = ck.get("verdict")
    if verdict == "accept":
        problems = ck.get("problems") or 0
        extra = f", {problems} problem{'s' if problems != 1 else ''} noted" if problems else ""
        chips.append(f'<span class="chip chip--pass" title="An independent second session checked the kit">'
                     f"second check: accepted{extra}</span>")
    elif ck:
        if ck.get("builder") == "cut off" or ck.get("converted") == "cut off":
            what = "conversion" if ck.get("converted") == "cut off" else "build"
            chips.append(f'<span class="chip chip--muted" title="kits_checked.json: the agent was cut off before it reported">'
                         f"{what} cut off; second check not run</span>")
        elif ck.get("builder") == "not started":
            pass
        else:
            chips.append('<span class="chip chip--muted">second check: not run</span>')
    held = ck.get("prediction_held")
    if held:
        chips.append(f'<span class="chip chip--muted" title="Did the kit\'s own prediction hold when the sheet was rendered?">'
                     f"prediction held: {esc(held)}</span>")
    return chips


def meta_block(chips: list[str], note: str | None = None) -> str:
    lines = ['<div class="lesson-meta" markdown>', "", " ".join(chips), ""]
    if note:
        lines += [f'<span class="lesson-meta__note">{note}</span>', ""]
    lines.append("</div>")
    return "\n".join(lines)


def kit_box(kit: Kit | None, ctx: PageCtx, main_scene: str | None = None,
            empty_text: str | None = None, shown: str = "TUTORIAL.md") -> str:
    if not kit or not kit.zip_rel:
        text = empty_text or "This page has no kit of its own."
        return "\n".join(['<div class="kit-box kit-box--empty" id="the-kit" markdown>', "",
                          f'<span class="kit-box__label">No kit</span> {text}', "", "</div>"])
    scene = main_scene or kit.main_scene
    link = rel_link(ctx, kit.zip_rel)
    zip_name = posixpath.basename(kit.zip_rel)
    lines = ['<div class="kit-box" id="the-kit" markdown>', ""]
    lines.append(f'<span class="kit-box__label">The kit</span> '
                 f"[Download {zip_name}]({link}){{ .md-button .md-button--primary download=\"{zip_name}\" }} "
                 f'<span class="kit-box__size">{human_size(kit.zip_size)}, {kit.zip_files} files</span>')
    lines.append("")
    facts = []
    if scene:
        facts.append(f"Main scene: `{scene}`")
    if kit.project_name:
        facts.append(f"Project: *{esc(kit.project_name)}*")
    facts.append("Godot 4.6 Standard, GDScript")
    lines.append(" · ".join(facts))
    lines.append("")
    run = f"press **F5** to run `{scene}`" if scene else "press **F5** to run the main scene"
    lines.append(f"**To open it:** unzip it somewhere you can find again. In Godot 4.6, open the "
                 f"Project Manager, choose **Import** and select `{kit.name}/project.godot`, then "
                 f"{run}. Work in a copy and keep a clean one beside it.")
    lines.append("")
    docs = [n for n in kit_documents(kit) if n != shown]
    if docs:
        names = [f"`{n}`" for n in docs]
        listed = names[0] if len(names) == 1 else ", ".join(names[:-1]) + " and " + names[-1]
        one = len(docs) == 1
        line = (f'<span class="kit-box__docs">Also in the zip: {listed}. '
                f"{'It is not a page' if one else 'They are not pages'} of this site")
        linked = sorted(n for n in ctx.kit_doc_links if n in docs)
        if linked:
            line += ("; where the lesson links to it, the link lands on this box" if one else
                     "; where the lesson links to one of them, the link lands on this box")
        lines.append(line + ".</span>")
        lines.append("")
    lines.append("</div>")
    return "\n".join(lines)


def kit_documents(kit: Kit) -> list[str]:
    """The Markdown files at the top of a kit, README first."""
    if not kit.exists:
        return []
    try:
        names = sorted(p.name for p in kit.folder.iterdir() if p.is_file() and p.suffix.lower() == ".md")
    except OSError:
        return []
    return sorted(names, key=lambda n: (n.upper() != "README.MD", n))


def figure(ctx: PageCtx, src: Path | None, alt: str, caption: str | None) -> str:
    if not src:
        return ""
    name = ctx.add_asset(src)
    lines = ['<figure class="stop-figure" markdown="span">', f"  ![{esc(alt)}]({name})"]
    if caption:
        lines.append(f"  <figcaption>{esc(caption)}</figcaption>")
    lines.append("</figure>")
    return "\n".join(lines)


def caps_list(items, caps: dict) -> list[str]:
    out = []
    for c in items or []:
        if isinstance(c, dict):
            if "id" in c:
                label = caps.get(c["id"], c["id"])
            else:
                label = c.get("part") or ""
            depth = c.get("depth")
            out.append(f"{esc(label)} ({esc(depth)})" if depth else esc(label))
        elif c:
            out.append(esc(c))
    return out


def teacher_admonition_stop(stop: dict, caps: dict) -> str:
    t = stop.get("teacher") or {}
    parts = []
    if t.get("why_here"):
        parts.append(f"**Why here.** {esc(t['why_here'])}")
    new = caps_list(t.get("new"), caps)
    if new:
        parts.append("**New here:** " + "; ".join(new) + ".")
    ret = caps_list(t.get("returns"), caps)
    if ret:
        parts.append("**Returns:** " + "; ".join(ret) + ".")
    bor = caps_list(t.get("borrows"), caps)
    if bor:
        parts.append("**Borrowed parts:**\n\n" + "\n".join(f"- {b}" for b in bor))
    if t.get("check"):
        parts.append(f"**Did it work?** {esc(t['check'])}")
    if t.get("contrast"):
        parts.append(f"**Contrast.** {esc(t['contrast'])}")
    if t.get("carries"):
        parts.append(f"**What it carries forward.** {esc(t['carries'])}")
    if t.get("learner_room"):
        parts.append(f"**For the learner's own work.** {esc(t['learner_room'])}")
    if stop.get("status_note"):
        parts.append(f"**Status.** {esc(stop['status_note'])}")
    if t.get("status_detail"):
        parts.append(f"**State of the files and checks.** {esc(t['status_detail'])}")
    ver = stop.get("verified") or {}
    vparts = []
    for key, label in (("native", "in Godot"), ("learner", "with a learner"), ("headset", "in a headset")):
        v = ver.get(key)
        vparts.append(f"{label}: {esc(v)}" if v else f"{label}: not yet")
    parts.append("**Verified** " + "; ".join(vparts) + ".")
    if stop.get("route"):
        parts.append(f"**Route:** {esc(stop['route'])}.")
    body = "\n\n".join(parts) if parts else "No notes for this stop."
    return '??? teacher "For the teacher"\n\n' + indent(body) + "\n"


def teacher_admonition_chapter(course: Course, ch: dict) -> str:
    parts = []
    if ch.get("verb"):
        parts.append(f"**Operation added:** {esc(ch['verb'])}.")
    new = caps_list(ch.get("code_new"), course.caps)
    if new:
        parts.append("**New programming ideas:** " + "; ".join(new) + ".")
    ret = caps_list(ch.get("code_returns"), course.caps)
    if ret:
        parts.append("**Returning:** " + "; ".join(ret) + ".")
    halls = [f"{esc(h.get('map'))} ({esc(h.get('role'))})" for h in ch.get("halls") or []]
    if halls:
        parts.append("**Halls:** " + "; ".join(halls) + ".")
    arg = ch.get("argument") or {}
    if arg:
        vals = " / ".join(esc(v) for v in arg.get("values") or [])
        parts.append(f"**The argument.** Axis: {esc(arg.get('axis'))}. Values: {vals}.")
        if arg.get("predict"):
            parts.append(f"**The prediction the plan wrote.** {esc(arg['predict'])}")
        if arg.get("claim"):
            parts.append(f"**The claim.** {esc(arg['claim'])}")
    if ch.get("debt"):
        parts.append(f"**What it owes.** {esc(ch['debt'])}")
    if ch.get("place"):
        parts.append(f"**Where a body meets it.** {esc(ch['place'])}")
    if ch.get("project_step"):
        parts.append(f"**In the learner's room.** {esc(ch['project_step'])}")
    if ch.get("status_note"):
        parts.append(f"**Status note.** {esc(ch['status_note'])}")
    body = "\n\n".join(parts)
    return '??? teacher "For the teacher"\n\n' + indent(body) + "\n"


def notes_blocks(stop: dict, body: str) -> tuple[str, str]:
    """Put the stop's notes into the lesson. Returns (top block, body)."""
    top = []
    for note in stop.get("notes") or []:
        text = note.get("text") or ""
        block = '!!! kitnote "A note for this page"\n\n' + indent(text) + "\n"
        at = note.get("at")
        if at:
            body, placed = insert_after_heading(body, at, block)
            if placed:
                continue
        top.append(block)
    return "\n".join(top), body


def did_it_work(stop: dict) -> str:
    t = stop.get("teacher") or {}
    if not t.get("check") and not t.get("contrast"):
        return ""
    parts = []
    if t.get("check"):
        parts.append(esc(t["check"]))
    if t.get("contrast"):
        parts.append(f"**A contrasting case.** {esc(t['contrast'])}")
    return '!!! didit "Did it work?"\n\n' + indent("\n\n".join(parts)) + "\n"


def page_head(source_note: str) -> str:
    return f"<!-- Generated by build_site.py from {source_note}. Edit the source, not this file. -->\n\n"


def front_matter(title: str | None = None, hide: list[str] | None = None) -> str:
    lines = []
    if title:
        # A JSON string is a valid YAML double-quoted scalar, colons and quotes included.
        lines.append(f"title: {json.dumps(title, ensure_ascii=False)}")
    if hide:
        lines.append("hide:")
        lines += [f"  - {h}" for h in hide]
    return ("---\n" + "\n".join(lines) + "\n---\n\n") if lines else ""


def page_start(h1: str, source_note: str, title: str | None = None, hide: list[str] | None = None,
               where: str | None = None) -> str:
    """Front matter, the H1, then the generated-file comment.

    The H1 has to be the page's first block: MkDocs 1.6 takes a page's title from its H1
    only then, and a comment above it made every section page "Index". The front-matter
    title is given as well, so the tab and the header do not lean on that rule.

    `where` ("short track, stop 13", "chapter 11") is added to the H1 for search and screen
    readers only, hidden on screen, where the chips already say it. The first 13 lessons
    are on the site twice, and search lists a page under its H1: without it the two
    results carried the same title."""
    hidden = f' <span class="ada-sr">({where})</span>' if where else ""
    return front_matter(title, hide) + f"# {h1}{hidden}\n\n" + page_head(source_note)


# ---------------------------------------------------------------------------
# Building
# ---------------------------------------------------------------------------

class Builder:
    def __init__(self) -> None:
        self.c = Course()
        self.reg = Registry()
        self.out = Out()
        self.nav: list = []
        self.zip_total = 0
        self.counts: dict[str, int] = {}
        self.built_before: set[str] = set(self.c.kits_map.get("built_before") or [])
        self._heads: dict[str, str | None] = {}

    def lesson_h1(self, src_rel: str | None) -> str | None:
        """A lesson file's own H1, as written (cached)."""
        if not src_rel:
            return None
        if src_rel not in self._heads:
            path = repo_path(src_rel)
            self._heads[src_rel] = split_h1(read_text(path))[0] if path.is_file() else None
        return self._heads[src_rel]

    # -- registry --------------------------------------------------------------

    def register(self) -> None:
        c, reg = self.c, self.reg
        reg.add_lesson(INTRO_MD, "short", reg.short_index)
        for s in c.stops:
            page = f"short-track/{stop_slug(s)}/index.md"
            if s.get("lesson"):
                reg.add_lesson(s["lesson"], "short", page)
            if s.get("kit"):
                reg.add_kit(posixpath.basename(s["kit"]), "short", page)
        for ch in c.chapters_in_order():
            page = f"course/{chapter_slug(c, ch['id'])}/index.md"
            if isinstance(ch.get("n"), int):
                reg.chapters[ch["id"]] = (ch["n"], page)
            lesson = c.chapter_lesson(ch["id"])
            if lesson:
                reg.add_lesson(lesson, "course", page)
            kit = c.kits.get(c.chapter_kit.get(ch["id"], ""))
            if kit and kit.exists and (kit.tutorial or ch["id"] in c.stop_of_chapter):
                reg.add_kit(kit.name, "course", page)
        if "the-look" in c.kits:
            k = c.kits["the-look"]
            if k.tutorial:
                reg.add_lesson(k.tutorial, "course", "course/the-look/index.md")
                reg.add_kit("the-look", "course", "course/the-look/index.md")
        for name, page in (("my-room", "your-room/index.md"), ("kit-base", "kit-base/index.md")):
            k = c.kits.get(name)
            if k and k.readme:
                reg.add_lesson(k.readme, "extra", page)
                reg.add_kit(name, "extra", page)
        reg.add_lesson(TAPE_MD, "teachers", "teachers/tape/index.md")
        reg.add_lesson(FIELD_NOTE_MD, "teachers", "teachers/decision/index.md")
        reg.add_lesson(WORKED_NOTE_MD, "teachers", "teachers/field-note/index.md")
        reg.add_lesson(WORKED_NOTE_MD, "short", "teachers/field-note/index.md")

    # -- kits and zips ---------------------------------------------------------

    def build_zips(self) -> None:
        shipped = set()
        for kits in self.reg.kits:
            shipped.add(kits)
        for name in sorted(shipped):
            kit = self.c.kits.get(name)
            if not kit or not kit.exists:
                continue
            files = kit_files(kit.folder)
            if not files:
                continue
            data = make_zip(name, files)
            kit.zip_rel = f"downloads/{name}.zip"
            kit.zip_size = len(data)
            kit.zip_files = len(files)
            self.zip_total += len(data)
            self.out.data(kit.zip_rel, data)

    # -- writing pages ---------------------------------------------------------

    def write_page(self, ctx: PageCtx, content: str) -> None:
        # Every page names chapters by the number its page shows (see link_chapter_refs).
        self.out.text(ctx.path, link_chapter_refs_md(content, ctx, self.reg))
        for name, src in sorted(ctx.assets.items()):
            self.out.copy(posixpath.join(ctx.dir, name) if ctx.dir else name, src)

    def lesson_text(self, src_rel: str, ctx: PageCtx) -> tuple[str | None, str]:
        path = repo_path(src_rel)
        if not path.is_file():
            warn(f"missing lesson {src_rel}")
            return None, ""
        text = read_text(path)
        text = rewrite_markdown(text, src_rel, ctx, self.reg)
        return split_h1(text)

    # -- the short track -------------------------------------------------------

    def short_track(self) -> list:
        c = self.c
        nav: list = [self.reg.short_index]
        ctx = PageCtx(path=self.reg.short_index, track="short")
        h1, body = self.lesson_text(INTRO_MD, ctx)
        body = self.site_version_of_intro(body)
        rows = ["| Stop | | Status | You make |", "|---:|---|---|---|"]
        for s in c.stops:
            page = f"short-track/{stop_slug(s)}/index.md"
            # Named as the stop's page names itself (its lesson's title), as in the tree.
            name = self.lesson_h1(s.get("lesson")) or esc(s["title"])
            rows.append(f"| {s['n']} | [{name}]({rel_link(ctx, page)}) | "
                        f"{stop_status_chip(s)} | {esc(s.get('makes'))} |")
        title = esc(c.opening.get("title") or "The short track")
        content = page_start(h1 or "The short track", INTRO_MD, title="The short track")
        content += meta_block([f'<span class="chip">{len(c.stops)} stops</span>',
                               '<span class="chip">three weeks</span>',
                               '<span class="chip">Godot 4.6, GDScript</span>'],
                              note=title)
        content += "\n\n" + body.rstrip() + "\n\n## The seventeen stops\n\n" + "\n".join(rows) + "\n"
        self.write_page(ctx, content)

        for s in c.stops:
            path, head = self.stop_page(s)
            nav.append({f"{s['n']} · {head}": path})
        return nav

    def site_version_of_intro(self, body: str) -> str:
        """INTRO.md is written for a reader of the repository. Two of its paragraphs tell the
        student to open a folder under doc/book/studies/ and to work in "this repository";
        a reader of the website has neither, only the Download button. While the paragraph
        still says so, the site shows its own version; once INTRO.md is reworded, its own
        words come through unchanged."""
        swaps = (
            ("**The study kits, now.**", "doc/book/studies/",
             "**The study kits, now.** Each stop with a kit has a box near the top of its page with a "
             "**Download** button. Unzip the kit somewhere you can find again, open the Project Manager in "
             "Godot 4.6, choose **Import** and select the kit's `project.godot`. Work in your own copy and "
             "keep a clean one beside it, as Day Zero says. If something breaks badly, the clean copy is "
             "where you start again."),
            ("**The Ada course project, for the xr route.**", "this repository",
             "**The Ada course project, for the xr route.** Held and walked encounters happen in the Ada "
             "Research repository's own Godot project, with its XR player already set up. That project is not "
             "one of the downloads on this site, and it needs the XR Tools add-on on disk, which a fresh clone "
             "of the repository does not include. Without it, follow the desktop route (see *Desktop and xr* "
             "below)."),
        )
        paras = body.split("\n\n")
        for start, tell, replacement in swaps:
            for i, para in enumerate(paras):
                if para.startswith(start):
                    if tell in para:
                        paras[i] = replacement
                    break
            else:
                warn(f"{INTRO_MD}: no paragraph starts {start!r}; nothing replaced")
        return "\n\n".join(paras)

    def stop_page(self, s: dict) -> tuple[str, str]:
        """Writes the stop's page; returns its path and its name for the left tree."""
        c = self.c
        path = f"short-track/{stop_slug(s)}/index.md"
        kitname = posixpath.basename(s["kit"]) if s.get("kit") else None
        kit = c.kits.get(kitname) if kitname else None
        ctx = PageCtx(path=path, track="short", kit=kitname)

        h1, body = (None, "")
        if s.get("lesson"):
            h1, body = self.lesson_text(s["lesson"], ctx)
        title = h1 or esc(s["title"])
        head = title_head(h1) if h1 else short_title(s["title"])

        chips = [f'<span class="chip chip--accent">Short track, stop {s["n"]}</span>']
        cid = c.chapter_of_stop.get(s["id"])
        if cid:
            ch = c.chapters[cid]
            pno = c.part_no.get(ch["part"], 0)
            ptitle = part_name(c.part_of[ch["part"]]["title"]) if ch["part"] in c.part_of else ""
            target = f"course/{chapter_slug(c, cid)}/index.md"
            chips.append(f"[Chapter {ch['n']} · Part {pno}, {esc(ptitle)}]({rel_link(ctx, target)}){{ .chip .chip--link }}")
        else:
            kind = {"workshop": "Workshop", "checkpoint": "Checkpoint"}.get(s.get("kind"), s.get("kind") or "")
            if kind:
                chips.append(f'<span class="chip">{esc(kind)}</span>')
        if s.get("hall"):
            chips.append(f'<span class="chip">Hall <span class="hall-ref">{esc(s["hall"])}</span></span>')
        chips.append(stop_status_chip(s))
        if s.get("route"):
            chips.append(f'<span class="chip">{esc(s["route"])}</span>')
        chips += checks_chips(kit, self.built_before)

        parts = [page_start(title, s.get("lesson") or OPENING_JSON, title=f"Stop {s['n']} · {head}",
                            where=f"short track, stop {s['n']}"),
                 meta_block(chips, esc(s.get("status_note")) if s.get("status_note") else None), ""]
        if kit:
            parts.append(kit_box(kit, ctx, s.get("main_scene")))
        else:
            parts.append(kit_box(None, ctx, empty_text=esc(s.get("makes") or "A page to read; nothing to install.")))
        parts.append("")
        if s.get("image"):
            pic = course_picture(posixpath.basename(s["image"]))
            if pic:
                parts.append(figure(ctx, pic, s["title"], s.get("image_caption")))
                parts.append("")
            else:
                warn(f"stop {s['id']}: picture {s['image']} not found")
        parts.append(link_chapter_refs(teacher_admonition_stop(s, c.caps), ctx, self.reg))
        top_notes, body = notes_blocks(s, body)
        if top_notes:
            parts.append(top_notes)
        if s.get("hall_reading"):
            parts.append(self.hall_reading_block(s, ctx))
        if not body.strip():
            parts.append('!!! notyet "The lesson is not on this site yet"\n\n'
                         + indent(f"The lesson file `{esc(s.get('lesson'))}` was not found when the site was built.") + "\n")
        parts.append(body.rstrip())
        parts.append("")
        dw = did_it_work(s)
        if dw:
            parts.append(dw)
        self.write_page(ctx, "\n".join(parts))
        return path, head

    def hall_reading_block(self, s: dict, ctx: PageCtx) -> str:
        hr = norm(s["hall_reading"])
        note = s.get("hall_reading_note")
        if hr in self.reg.lessons:
            page = Registry.pick(self.reg.lessons[hr], ctx.track)
            text = f"[A full field note from the making of this course]({rel_link(ctx, page)})."
            if note:
                text = esc(note) + f" [Read it]({rel_link(ctx, page)})."
            return '!!! kitnote "Reading beside this stop"\n\n' + indent(text) + "\n"
        m = HALL_RE.match(hr)
        hall = m.group(1) if m else s.get("hall")
        text = (f"The hall's own text, `final.md` in <span class=\"hall-ref\">{esc(hall)}</span>, "
                f"is read in the Ada museum and is not on this site.")
        if note:
            text += " " + esc(note)
        return '!!! kitnote "The hall\'s reading"\n\n' + indent(text) + "\n"

    # -- the whole course ------------------------------------------------------

    def course_pages(self) -> list:
        c = self.c
        nav: list = [self.reg.course_index]
        self.course_index_page()
        for p in c.parts:
            pno = c.part_no[p["id"]]
            ppath = f"course/part-{pno}/index.md"
            self.part_page(p, ppath)
            section: list = [ppath]
            for cid in p.get("chapters") or []:
                ch = c.chapters.get(cid)
                if not ch:
                    warn(f"part {p['id']} names unknown chapter {cid}")
                    continue
                cpath, head = self.chapter_page(ch)
                section.append({f"{ch['n']} · {head}": cpath})
                if cid == "ch03" and "the-look" in c.kits and c.kits["the-look"].tutorial:
                    section.append({"The look (an extra lesson)": self.the_look_page()})
            nav.append({f"Part {pno} · {part_name(p['title'])}": section})
        return nav

    def course_index_page(self) -> None:
        c = self.c
        ctx = PageCtx(path=self.reg.course_index, track="course")
        cc = c.course
        lessons = sum(1 for ch in c.chapters.values() if c.chapter_lesson(ch["id"]))
        lines = [page_start("The whole course", COURSE_JSON, title="The whole course")]
        course_title = esc(cc.get("title") or "")
        note = " ".join(x for x in (f"*{course_title}*." if course_title else "", esc(cc.get("subtitle"))) if x)
        lines.append(meta_block([f'<span class="chip">{len(c.chapters)} chapters</span>',
                                 f'<span class="chip">{len(c.parts)} parts</span>',
                                 f'<span class="chip chip--runnable">{lessons} lessons written</span>',
                                 f'<span class="chip">{len(c.chapters) - lessons} outlines</span>'],
                                note=note or None))
        lines.append("")
        if cc.get("principle"):
            lines.append(link_chapter_refs(esc(cc["principle"]), ctx, self.reg) + "\n")
        lines.append("A chapter whose kit has been built shows its lesson. A chapter whose kit is not built yet "
                     "shows its outline from the course plan, under a notice that says so. The first thirteen "
                     f"chapters of the short track are here too, as chapters; the short track itself is [its own "
                     f"section]({rel_link(ctx, self.reg.short_index)}).\n")
        lines.append("## The nine parts\n")
        lines.append("| Part | | What you can do after it | Chapters |")
        lines.append("|---:|---|---|---|")
        for p in c.parts:
            pno = c.part_no[p["id"]]
            ids = p.get("chapters") or []
            written = sum(1 for cid in ids if c.chapter_lesson(cid))
            lines.append(f"| {pno} | [{esc(part_name(p['title']))}]({rel_link(ctx, f'course/part-{pno}/index.md')}) | "
                         f"{link_chapter_refs(esc(p.get('promise')), ctx, self.reg)} | {written} of {len(ids)} written |")
        lines.append("")
        tracks = cc.get("tracks") or []
        if tracks:
            lines.append("## Two tracks\n")
            for t in tracks:
                lines.append(link_chapter_refs(f"- **{esc(t.get('title'))}** {esc(t.get('length'))}.", ctx, self.reg))
            lines.append("")
        if cc.get("thesis"):
            lines.append("## What the course argues\n")
            lines.append(link_chapter_refs(esc(cc["thesis"]), ctx, self.reg) + "\n")
        self.write_page(ctx, "\n".join(lines))

    def part_page(self, p: dict, path: str) -> None:
        c = self.c
        pno = c.part_no[p["id"]]
        ctx = PageCtx(path=path, track="course")
        title = p.get("title") or p["id"]
        sub = ""
        m = re.match(r"^(.*?)\s*\((.*)\)\s*$", title)
        if m:
            title, sub = m.group(1), m.group(2)
        ids = p.get("chapters") or []
        written = sum(1 for cid in ids if c.chapter_lesson(cid))
        lines = [page_start(f"Part {pno} · {esc(title)}", COURSE_JSON, title=f"Part {pno} · {title}")]
        chips = [f'<span class="chip">{len(ids)} chapters</span>',
                 f'<span class="chip chip--runnable">{written} written</span>']
        if sub:
            chips.append(f'<span class="chip">{esc(sub)}</span>')
        lines.append(meta_block(chips))
        lines.append("")
        lines.append('<p class="lead">' + esc(p.get("promise")) + "</p>\n")
        if p.get("plate_now"):
            lines.append("## The plate, now\n")
            lines.append("What of the plate can you make after this part?\n")
            lines.append('!!! plate ""\n\n' + indent(link_chapter_refs(esc(p["plate_now"]), ctx, self.reg)) + "\n")
            plate_page = f"short-track/{STOP_SLUGS['P00_the_plate']}/index.md"
            lines.append(f"The question comes from [the plate]({rel_link(ctx, plate_page)}), the picture the course opens with.\n")
        if p.get("toolkit_so_far"):
            lines.append("## The toolkit so far\n")
            lines.append(link_chapter_refs(", ".join(esc(t) for t in p["toolkit_so_far"]) + ".", ctx, self.reg) + "\n")
        lines.append("## Chapters\n")
        lines.append("| | Chapter | Operation | Status |")
        lines.append("|---:|---|---|---|")
        for cid in ids:
            ch = c.chapters.get(cid)
            if not ch:
                continue
            target = f"course/{chapter_slug(c, cid)}/index.md"
            # A chapter with a lesson is named as its page names it; one with only an
            # outline by the plan's title, which is also its page's title.
            h1 = self.lesson_h1(c.chapter_lesson(cid))
            name = h1 if h1 else esc(ch["title"])
            lines.append(f"| {ch['n']} | [{name}]({rel_link(ctx, target)}) | {esc(ch.get('verb'))} | "
                         f"{status_chip(c.chapter_status(cid))} |")
            if cid == "ch03" and "the-look" in c.kits and c.kits["the-look"].tutorial:
                lines.append(f"| | [The look: a sky, a light, a palette (an extra lesson)]"
                             f"({rel_link(ctx, 'course/the-look/index.md')}) | look | "
                             f"{status_chip(c.kits['the-look'].status)} |")
        lines.append("")
        self.write_page(ctx, "\n".join(lines))

    def chapter_chips(self, ch: dict, ctx: PageCtx, kit: Kit | None) -> list[str]:
        c = self.c
        pno = c.part_no.get(ch["part"], 0)
        ptitle = part_name(c.part_of[ch["part"]]["title"]) if ch["part"] in c.part_of else ""
        chips = [f'<span class="chip chip--accent">Chapter {ch["n"]} of {len(c.chapters)}</span>',
                 f"[Part {pno}, {esc(ptitle)}]({rel_link(ctx, f'course/part-{pno}/index.md')}){{ .chip .chip--link }}"]
        hall = c.carrier_hall(ch)
        if hall:
            chips.append(f'<span class="chip">Hall <span class="hall-ref">{esc(hall)}</span></span>')
        chips.append(status_chip(c.chapter_status(ch["id"])))
        asm = c.assemblage.get(ch["id"])
        if asm:
            chips.append(f'<span class="chip chip--cyan">assemblage {esc(asm.get("number"))}</span>')
        stop = c.stop_of_chapter.get(ch["id"])
        if stop:
            target = f"short-track/{stop_slug(stop)}/index.md"
            chips.append(f"[short track, stop {stop['n']}]({rel_link(ctx, target)}){{ .chip .chip--link }}")
        chips += checks_chips(kit, self.built_before)
        return chips

    def chapter_page(self, ch: dict) -> tuple[str, str]:
        """Writes the chapter's page; returns its path and its name for the left tree."""
        c = self.c
        cid = ch["id"]
        path = f"course/{chapter_slug(c, cid)}/index.md"
        kitname = c.chapter_kit.get(cid)
        kit = c.kits.get(kitname) if kitname else None
        lesson = c.chapter_lesson(cid)
        stop = c.stop_of_chapter.get(cid)
        ctx = PageCtx(path=path, track="course",
                      kit=kitname if (kit and kit.zip_rel and (lesson or stop)) else None)
        if lesson:
            self.counts["chapters_with_lesson"] = self.counts.get("chapters_with_lesson", 0) + 1
            h1, body = self.lesson_text(lesson, ctx)
            head = title_head(h1) if h1 else short_title(ch["title"])
            parts = [page_start(h1 or esc(ch["title"]), lesson, title=f"Chapter {ch['n']} · {head}",
                                where=f"chapter {ch['n']}"),
                     meta_block(self.chapter_chips(ch, ctx, kit)), ""]
            if kit and kit.zip_rel:
                parts.append(kit_box(kit, ctx, stop.get("main_scene") if stop else None))
            else:
                parts.append(kit_box(None, ctx))
            parts.append("")
            if stop and stop.get("image"):
                pic = course_picture(posixpath.basename(stop["image"]))
                if pic:
                    parts.append(figure(ctx, pic, stop["title"], stop.get("image_caption")))
                    parts.append("")
            # The notice goes with the status the chip shows. A short-track chapter carries
            # the short track's status; its kit may predate verify.gd (kits.json
            # built_before) and then has no verification.json without being a draft.
            if c.chapter_status(cid) == "draft":
                parts.append('!!! notyet "A draft"\n\n' + indent(
                    "This lesson's kit has no passing verification yet: its builder may still be at work, "
                    "or was cut off. Read it as a draft.") + "\n")
            parts.append(link_chapter_refs(teacher_admonition_chapter(c, ch), ctx, self.reg))
            if stop:
                # The chapter is the stop's lesson: the short track's notes for it belong here too.
                top_notes, body = notes_blocks(stop, body)
                if top_notes:
                    parts.append(top_notes)
            parts.append(body.rstrip())
            parts.append("")
            if stop:
                dw = did_it_work(stop)
                if dw:
                    parts.append(dw)
            self.write_page(ctx, "\n".join(parts))
            return path, head

        self.counts["chapters_outline"] = self.counts.get("chapters_outline", 0) + 1
        parts = [page_start(esc(ch["title"]), COURSE_JSON, title=f"Chapter {ch['n']} · {short_title(ch['title'])}",
                            where=f"chapter {ch['n']}"),
                 meta_block(self.chapter_chips(ch, ctx, kit)), ""]
        ck = kit.checked if kit else {}
        if kit and kit.exists:
            state = (f"Its kit, `{kit.name}`, has been started and is being built; the lesson appears here "
                     f"when the kit has a `TUTORIAL.md`.")
        elif ck.get("builder") == "not started" or kitname:
            state = f"Its kit, `{kitname}`, has not been started."
        else:
            state = "No kit is planned for it yet."
        parts.append('!!! notyet "The lesson is not written yet"\n\n' + indent(
            "What follows is the chapter's outline from the course plan, not a lesson to follow. " + state) + "\n")
        parts.append(kit_box(None, ctx, empty_text="Not built yet."))
        parts.append("")
        parts.append(link_chapter_refs(self.outline_body(ch), ctx, self.reg))
        self.write_page(ctx, "\n".join(parts))
        return path, short_title(ch["title"])

    def outline_body(self, ch: dict) -> str:
        lines = []
        if ch.get("body"):
            lines += ["## What you make", "", esc(ch["body"]), ""]
        arg = ch.get("argument") or {}
        if arg:
            lines += ["## The argument", ""]
            if arg.get("axis"):
                lines += [f"**Axis:** {esc(arg['axis'])}", ""]
            vals = arg.get("values") or []
            if vals:
                lines += ["**Values:**", ""] + [f"- {esc(v)}" for v in vals] + [""]
            if arg.get("predict"):
                lines += [f"**Predict before you render.** {esc(arg['predict'])}", ""]
            if arg.get("claim"):
                lines += [f"**The claim.** {esc(arg['claim'])}", ""]
        if ch.get("debt"):
            lines += ["## What it owes", "", esc(ch["debt"]), ""]
        if ch.get("place"):
            lines += ["## Where a body meets yours", "", esc(ch["place"]), ""]
        if ch.get("process"):
            lines += ["## The process strip", "",
                      "One still after each operation, with the operation named under it:", ""]
            lines += [f"{i}. {esc(step)}" for i, step in enumerate(ch["process"], 1)] + [""]
        if ch.get("project_step"):
            lines += ["## In your room", "", esc(ch["project_step"]), ""]
        if ch.get("godot"):
            lines += ["## In Godot", ""] + [f"- {esc(g)}" for g in ch["godot"]] + [""]
        new = caps_list(ch.get("code_new"), self.c.caps)
        if new:
            lines += ["## New programming ideas", "", "; ".join(new) + ".", ""]
        halls = ch.get("halls") or []
        if halls:
            lines += ["## The halls", ""]
            lines += [f'- <span class="hall-ref">{esc(h.get("map"))}</span>, {esc(h.get("role"))}' for h in halls]
            lines += [""]
        return "\n".join(lines)

    def the_look_page(self) -> str:
        c = self.c
        kit = c.kits["the-look"]
        path = "course/the-look/index.md"
        ctx = PageCtx(path=path, track="course", kit="the-look" if kit.zip_rel else None)
        h1, body = self.lesson_text(kit.tutorial, ctx)
        title = next((e.get("title") for e in c.extras if e.get("kit") == "the-look"), None)
        point_one = f"course/{chapter_slug(c, 'ch03')}/index.md"
        chips = ['<span class="chip chip--accent">An extra lesson</span>',
                 f"[after Point One]({rel_link(ctx, point_one)}){{ .chip .chip--link }}",
                 f"[Part 1]({rel_link(ctx, 'course/part-1/index.md')}){{ .chip .chip--link }}",
                 status_chip(kit.status)] + checks_chips(kit, self.built_before)
        parts = [page_start(h1 or esc(title or "The look"), kit.tutorial, title="The look"),
                 meta_block(chips, esc(title) if title else None), "",
                 kit_box(kit, ctx), "", body.rstrip(), ""]
        self.write_page(ctx, "\n".join(parts))
        return path

    # -- extras ----------------------------------------------------------------

    def extra_page(self, name: str, path: str, fallback_title: str, lead: str, nav_title: str) -> str | None:
        c = self.c
        kit = c.kits.get(name)
        if not kit or not kit.readme:
            warn(f"{name}: no README.md; page left out")
            return None
        ctx = PageCtx(path=path, track="extra", kit=name if kit.zip_rel else None)
        h1, body = self.lesson_text(kit.readme, ctx)
        chips = [status_chip("runnable" if kit.passed else "draft")]
        chips += checks_chips(kit, self.built_before)
        parts = [page_start(h1 or fallback_title, kit.readme, title=nav_title), meta_block(chips, lead), "",
                 kit_box(kit, ctx, shown="README.md"), "", body.rstrip(), ""]
        self.write_page(ctx, "\n".join(parts))
        return path

    # -- teachers --------------------------------------------------------------

    def teachers(self) -> list:
        nav: list = ["teachers/index.md"]
        self.teachers_index()
        nav.append({"The outline": self.outline_page()})
        for src, path, title in ((TAPE_MD, "teachers/tape/index.md", "The tape"),
                                 (FIELD_NOTE_MD, "teachers/decision/index.md", "The decision step"),
                                 (WORKED_NOTE_MD, "teachers/field-note/index.md", "A worked field note")):
            ctx = PageCtx(path=path, track="teachers")
            h1, body = self.lesson_text(src, ctx)
            lead = {
                TAPE_MD: "A playback of the short track as one student would meet it, written before anyone took it.",
                FIELD_NOTE_MD: "The step after the comparison: follow or settle, and the note that keeps the reason. "
                               "It is also stop 11 of the short track.",
                WORKED_NOTE_MD: "A full field note from the making of this course, with the first measurement "
                                "that was wrong and what stayed unexplained.",
            }[src]
            body = self.site_notes(src, body, ctx)
            content = page_start(h1 or title, src, title=title) + meta_block(['<span class="chip">for teachers</span>'], lead)
            content += "\n\n" + body.rstrip() + "\n"
            self.write_page(ctx, content)
            nav.append({title: path})
        nav.append({"How the course was built": self.how_built_page()})
        return nav

    # Lines of the teachers' material that were true of the repository when written and are
    # read differently on this site. The source is left as it is; the site adds a short note
    # to the line, for as long as the line still says it.
    SITE_NOTES = {
        TAPE_MD: [
            ("served from one machine, at localhost:3003",
             "these pages are a second way to read the course, generated from the same files by "
             "<code>build_site.py</code>. They are built and served on one machine as well, and are not "
             "published yet."),
        ],
        WORKED_NOTE_MD: [
            ("ada_encyclopedia/captures/",
             "that folder is on the machine where the course was made; its pictures are not published here."),
        ],
    }

    def site_notes(self, src: str, body: str, ctx: PageCtx) -> str:
        notes = self.SITE_NOTES.get(src) or []
        if not notes:
            return body
        lines = body.split("\n")
        for needle, note in notes:
            for i, line in enumerate(lines):
                if needle in line:
                    lines[i] = (line.rstrip() + f' <span class="site-note"><b>On this site:</b> {note}</span>')
                    break
        return "\n".join(lines)

    def teachers_index(self) -> None:
        c = self.c
        ctx = PageCtx(path="teachers/index.md", track="teachers")
        cc = c.course
        lines = [page_start("For teachers", f"{COURSE_JSON}, {OPENING_JSON}", title="For teachers")]
        lines.append(meta_block(['<span class="chip">for teachers</span>']))
        lines.append("")
        lines.append("Every lesson page has a collapsed box, **For the teacher**: why the stop sits where it "
                     "does, what is new and what returns, what is borrowed, what a working result looks like, "
                     "and the state of the kit's checks. These pages hold what does not belong to one lesson.\n")
        lines.append(f"- [The outline]({rel_link(ctx, 'teachers/outline/index.md')}): all "
                     f"{len(c.chapters)} chapters in one table, with their halls, status and whether the kit's "
                     "prediction held.")
        lines.append(f"- [The tape]({rel_link(ctx, 'teachers/tape/index.md')}): the first two weeks played back "
                     "minute by minute for one imagined student, with what each stop costs.")
        lines.append(f"- [The decision step]({rel_link(ctx, 'teachers/decision/index.md')}): follow or settle, "
                     "and the field note.")
        lines.append(f"- [A worked field note]({rel_link(ctx, 'teachers/field-note/index.md')}): the pyramid "
                     "family, from the making of the course.")
        lines.append(f"- [How the course was built]({rel_link(ctx, 'teachers/how-built/index.md')}): its sources, "
                     "its method, and how the kits were made and checked.\n")
        for t in cc.get("tracks") or []:
            lines.append(f"## {esc(t.get('title'))}\n")
            if t.get("length"):
                lines.append(link_chapter_refs(f"**Length:** {esc(t['length'])}", ctx, self.reg) + "\n")
            if t.get("supplied"):
                lines.append(link_chapter_refs(f"**Supplied:** {esc(t['supplied'])}", ctx, self.reg) + "\n")
            if t.get("mini_project"):
                lines.append(link_chapter_refs(f"**The mini project:** {esc(t['mini_project'])}", ctx, self.reg) + "\n")
        self.write_page(ctx, "\n".join(lines))

    def outline_page(self) -> str:
        c = self.c
        path = "teachers/outline/index.md"
        ctx = PageCtx(path=path, track="teachers")
        # No section headings, so no "On this page": the right column is hidden and the
        # table takes its width (the ada-wide box below; see ada.css).
        lines = [page_start("The outline", f"{COURSE_JSON}, {KITS_JSON}, {CHECKED_JSON}",
                            title="The outline", hide=["toc"])]
        lessons = sum(1 for ch in c.chapters.values() if c.chapter_lesson(ch["id"]))
        lines.append(meta_block([f'<span class="chip">{len(c.chapters)} chapters</span>',
                                 f'<span class="chip chip--runnable">{lessons} with a lesson</span>',
                                 f'<span class="chip">{len(c.chapters) - lessons} outline only</span>']))
        lines.append("")
        lines.append("The status is computed when the site is built: **runnable** when the kit has a lesson and its "
                     "`verify.gd` passed, **draft** when it has a lesson and no passing verification, **being "
                     "built** when its folder exists without a lesson, **planned** when there is no folder. "
                     "Short-track chapters carry the status the short track gives them. *Prediction held* is the "
                     "kit builder's own report of whether the lesson's prediction held when the comparison sheet "
                     "was rendered (from `kits_checked.json`); a blank means it was not reported.\n")
        lines.append('<div class="ada-wide outline-table" markdown>')
        lines.append("")
        lines.append("| | Chapter | Part | Hall | Status | Prediction held |")
        lines.append("|---:|---|---|---|---|---|")
        for ch in c.chapters_in_order():
            pno = c.part_no.get(ch["part"], 0)
            kit = c.kits.get(c.chapter_kit.get(ch["id"], ""))
            held = (kit.checked.get("prediction_held") if kit else None) or ""
            hall = c.carrier_hall(ch) or ""
            target = f"course/{chapter_slug(c, ch['id'])}/index.md"
            short = ' <span class="tag-short">short track</span>' if "short" in (ch.get("tracks") or []) else ""
            held_cell = f'<span class="outline-held">{esc(held)}</span>' if held else ""
            lines.append(f"| {ch['n']} | [{esc(ch['title'])}]({rel_link(ctx, target)}){short} | "
                         f'<span class="outline-part" title="Part {pno}">{pno}</span> | '
                         f'<span class="hall-ref">{hall_one_break(hall)}</span> | '
                         f'{status_chip(c.chapter_status(ch["id"]))} | {held_cell} |')
        lines.append("")
        lines.append("</div>")
        lines.append("")
        k = c.kits.get("the-look")
        if k and k.tutorial:
            lines.append(f"Beside the 46 chapters there is one extra lesson, [The look]"
                         f"({rel_link(ctx, 'course/the-look/index.md')}), read after Point One, and two pages "
                         f"that are not lessons: [your room]({rel_link(ctx, 'your-room/index.md')}) and "
                         f"[the kit base]({rel_link(ctx, 'kit-base/index.md')}).\n")
        self.write_page(ctx, "\n".join(lines))
        return path

    def how_built_page(self) -> str:
        c = self.c
        cc = c.course
        path = "teachers/how-built/index.md"
        ctx = PageCtx(path=path, track="teachers")
        L = [page_start("How the course was built",
                        f"{COURSE_JSON} (sources, method, rhythm, spine_relation), {CHECKED_JSON}",
                        title="How the course was built"),
             meta_block(['<span class="chip">for teachers</span>'],
                        "Written for this site from the course plan's own record of its sources and method."), ""]
        L.append("## An order of operations\n")
        L.append("The course began as a survey of Godot tutorials and a contest between candidate orders. "
                 "The winner followed Paul Klee's *Pedagogical Sketchbook* for its first thirty chapters. On "
                 "1 October 2026 Palle Torsson asked for the order to be refined so that a student gains the "
                 "capacity to make different assemblages, in the order Ada's own museum puts the operations of "
                 "form. The second version keeps Klee only where Ada's spine already agrees with him, follows the "
                 "spine everywhere else, and ends every part with an assemblage: a body composed from the "
                 "operations learned so far, made of parts of different origin.\n")
        if cc.get("principle"):
            L.append(f"> {esc(cc['principle'])}\n")
        sr = cc.get("spine_relation") or {}
        if sr:
            L.append(f"Measured against the spine, {round(100 * float(sr.get('order_agreement', 0)))} % of the "
                     f"pairs of chapters come in the spine's order (the first version: "
                     f"{round(100 * float(sr.get('v1_order_agreement_same_metric', 0)))} %). "
                     f"{sr.get('declared_departures', 0)} chapters go back to an earlier hall, and each says so "
                     f"on its page as a return; {sr.get('undeclared_departures', 0)} go back without saying it.\n")
        L.append("## Every chapter, the same rhythm\n")
        strands = cc.get("strands") or {}
        if strands:
            L.append("Each chapter carries four strands:\n")
            for k, v in strands.items():
                L.append(f"- **{esc(k)}.** {esc(v)}")
            L.append("")
        rhythm = cc.get("rhythm") or []
        if rhythm:
            L.append("And it is worked in this order:\n")
            L += [f"{i}. {esc(r)}" for i, r in enumerate(rhythm, 1)]
            L.append("")
        m = cc.get("method") or {}
        if m:
            L.append("## The research method\n")
            L.append(f"The decision step comes from {esc(m.get('name'))}. {esc(m.get('what'))}\n")
            cautions = m.get("cautions") or []
            if cautions:
                L.append("Its cautions, which the lessons keep:\n")
                L += [f"- {esc(x)}" for x in cautions]
                L.append("")
            L.append(f"The template is [the decision step]({rel_link(ctx, 'teachers/decision/index.md')}); the "
                     f"worked example is [the pyramid family]({rel_link(ctx, 'teachers/field-note/index.md')}).\n")
        L.append("## The kits\n")
        run = c.checked.get("_run") or {}
        built = [k for k in c.kits.values() if k.tutorial]
        accepted = [k for k in c.kits.values() if k.checked.get("verdict") == "accept"]
        L.append("Every lesson after the opening was written together with its kit, a small Godot 4.6 project, "
                 "by Claude sessions working from a written brief, several at a time. Each kit ships a "
                 "`verify.gd` that runs the finished study headless and writes `verification.json`, and a "
                 "`sheet.gd` that renders the comparison sheet and the process strip. A builder applied every "
                 "code block of its lesson in page order to a fresh copy and ran each state; then an independent "
                 "second session checked the kit and gave a verdict.\n")
        if run.get("note"):
            L.append(f"The build's own record: {esc(run['note'])}\n")
        L.append(f"When this site was built, {len(built)} kits had a lesson. {self.verification_summary()} "
                 f"{len(accepted)} kits had been accepted by the second check. No kit has been tried by a learner "
                 f"or in a headset unless its page says so.\n")
        srcs = cc.get("sources") or []
        if srcs:
            L.append("## Sources\n")
            L.append("| Source | What the course takes from it |")
            L.append("|---|---|")
            for s in srcs:
                role = s.get("role") or ""
                note = ""
                # course.json names a chapter's kit in prose; kits.json is the record the
                # site follows. Where they part, say so beside the line.
                for m in re.finditer(r"(?<![\w-])(ch\d{2}) runs on the ([A-Za-z0-9_-]+) kit", role):
                    now = c.chapter_kit.get(m.group(1))
                    if now and now != m.group(2):
                        note += (f' <span class="site-note"><b>On this site:</b> kits.json now gives {m.group(1)} '
                                 f"the <code>{esc(now)}</code> kit, and its page uses that one.</span>")
                L.append(f"| {esc(s.get('name'))} | {esc(role)}{note} |")
            L.append("")
        L.append("## This site\n")
        L.append("These pages are generated by `doc/book/course/site/build_site.py` from the course's files in "
                 "the Ada Research repository: the short track (`opening.json` and its pages), the course plan "
                 "(`course.json`), the kit map and check record (`kits.json`, `kits_checked.json`) and the kits "
                 "themselves. Nothing here is written by hand except this page's prose, the home page's "
                 "paragraph and the look. When a kit changes, the site is built again.\n")
        self.write_page(ctx, "\n".join(link_chapter_refs(line, ctx, self.reg) for line in L))
        return path

    def verification_summary(self) -> str:
        """One sentence on verify.gd, the same on the home page and on How the course was built:
        counted over the kits this site ships, and naming the ones without a verification.json."""
        on_site = [self.c.kits[n] for n in sorted(self.c.kits) if self.c.kits[n].zip_rel]
        verified = [k for k in on_site if k.checks]
        passed = [k for k in verified if k.passed]
        none = [k for k in on_site if not k.checks]
        ok = sum(k.checks[0] for k in verified)
        total = sum(k.checks[1] for k in verified)
        s = f"{len(verified)} of the {len(on_site)} kits on this site carry a `verification.json`"
        if verified:
            s += " and all of them pass" if len(passed) == len(verified) else f"; {len(passed)} of them pass"
            s += f" ({ok} of {total} checks)"
        if none:
            names = [f"`{k.name}`" for k in none]
            listed = names[0] if len(names) == 1 else ", ".join(names[:-1]) + " and " + names[-1]
            s += f"; {listed} {'has' if len(none) == 1 else 'have'} none"
        return s + "."

    # -- home ------------------------------------------------------------------

    def home(self) -> None:
        c = self.c
        ctx = PageCtx(path="index.md", track="home")
        haeckel = course_picture("haeckel_tafel_31_cyrtoidea.jpg")
        remake = course_picture("plate_remake.png")
        plate_stop = next((s for s in c.stops if s["id"] == "P00_the_plate"), None)
        title = esc(c.course.get("title") or "The Sketchbook in Drag")
        L = [page_start(title, "the course's files; see build_site.py", hide=["toc"])]
        n_ch = len(c.chapters)
        n_parts = len(c.parts)
        # The title and the lead come first, as on every other page; the plate follows.
        L.append(f'<p class="lead">A course in making bodies with Godot 4.6 and GDScript, for art students who '
                 f"have never programmed. It opens with one picture, Haeckel's plate of radiolaria, which can be "
                 f"read as one body with about ten numbers shown nine times, and asks at the end of every part: what "
                 f"of it can you make now? In {n_ch} chapters and {n_parts} parts it adds one operation of form at a "
                 f"time, in the order of the Ada Research museum: place, join, articulate, repeat, vary, surface, "
                 f"move, disturb, grow, deform, combine, learn. Each chapter is a small Godot project to download and "
                 f"a lesson that builds it, predicts before it looks, and ends with a body you can stand on, carry or "
                 f"walk through.</p>\n")
        L.append('<div class="plate-hero" markdown>')
        L.append("")
        if haeckel:
            L.append(figure(ctx, haeckel, "Ernst Haeckel, Kunstformen der Natur, plate 31: Cyrtoidea",
                            "The plate: Haeckel and Giltsch, Kunstformen der Natur, plate 31, Cyrtoidea, 1904. "
                            "Nine shells of radiolaria. Public domain."))
            L.append("")
        if remake:
            L.append(figure(ctx, remake, "One shell as six operations, and six shells from the same operations",
                            "The remake, made by rule in Godot: one shell, one operation at a time (top), and six "
                            "shells from the same list with other numbers (bottom)."))
            L.append("")
        L.append("</div>")
        L.append("")
        stops = len(c.stops)
        L.append('<div class="ways-in" markdown>')
        L.append("")
        ways = [
            ("The short track", self.reg.short_index,
             f"Three weeks, {stops} stops: from the plate and Day Zero to a first family of bodies of your own."),
            ("The whole course", self.reg.course_index,
             f"{n_parts} parts and {n_ch} chapters, a year's work. Lessons where the kit is built; outlines where "
             f"it is not yet."),
            ("For teachers", "teachers/index.md",
             "The outline of every chapter, the tape of two imagined weeks, the decision step, and how the course "
             "was made and checked."),
        ]
        for title, page, text in ways:
            L.append('<div class="way" markdown>')
            L.append("")
            L.append(f"[{title}]({rel_link(ctx, page)}){{ .way__title }}")
            L.append("")
            L.append(text)
            L.append("")
            L.append("</div>")
            L.append("")
        L.append("</div>")
        L.append("")
        L.append("## Where the course stands\n")
        L.append("Counted from the files when this site was built.\n")
        L += self.progress_table()
        L.append("")
        if plate_stop:
            L.append(f"Start with [the plate]({rel_link(ctx, 'short-track/the-plate/index.md')}): nothing to install, "
                     f"one picture to look at.\n")
        self.write_page(ctx, "\n".join(L))

    def progress_table(self) -> list[str]:
        c = self.c
        stops = c.stops
        st_kits = sum(1 for s in stops if s.get("kit"))
        st_kit_runnable = sum(1 for s in stops if s.get("kit") and s.get("status") == "runnable")
        st_pages = len(stops) - st_kits
        lessons = sum(1 for ch in c.chapters.values() if c.chapter_lesson(ch["id"]))
        all_kits = [c.kits[n] for n in sorted(c.kits)]
        chapter_ids = sorted(c.chapter_kit)
        built = [cid for cid in chapter_ids if c.kits.get(c.chapter_kit[cid]) and c.kits[c.chapter_kit[cid]].exists
                 and c.chapter_lesson(cid)]
        building = [cid for cid in chapter_ids if c.kits.get(c.chapter_kit[cid]) and c.kits[c.chapter_kit[cid]].exists
                    and not c.chapter_lesson(cid)]
        unstarted = [cid for cid in chapter_ids if not (c.kits.get(c.chapter_kit[cid]) and c.kits[c.chapter_kit[cid]].exists)]
        accepted = [k for k in all_kits if k.checked.get("verdict") == "accept"]
        held = {"yes": 0, "partly": 0, "no": 0}
        for k in all_kits:
            h = k.checked.get("prediction_held")
            if h in held:
                held[h] += 1
        zips = [k for k in all_kits if k.zip_rel]
        rows = [
            "| | Where it stands |",
            "|---|---|",
            f"| Short track | {len(stops)} stops: {st_kits} with a kit, {st_kit_runnable} of them runnable; "
            f"{st_pages} with nothing to install |",
            f"| Whole course | {len(c.chapters)} chapters: {lessons} with a lesson, {len(c.chapters) - lessons} with only an outline |",
            f"| Chapter kits | {len(built)} built with their lesson, {len(building)} being built, {len(unstarted)} not started |",
            f"| verify.gd | {self.verification_summary()} |",
            f"| Second check | {len(accepted)} kits accepted by an independent second session |",
            f"| Predictions | held {held['yes']}, partly {held['partly']}, not {held['no']} (as the builders reported) |",
            f"| Downloads | {len(zips)} kits, {human_size(self.zip_total)} in all |",
        ]
        return rows

    # -- nav and static --------------------------------------------------------

    def static_files(self) -> None:
        if not STATIC.is_dir():
            warn("static/ is missing")
            return
        for path in sorted(STATIC.rglob("*")):
            if path.is_file():
                self.out.copy("assets/" + path.relative_to(STATIC).as_posix(), path)

    def run(self) -> None:
        self.register()
        self.build_zips()
        self.home()
        short_nav = self.short_track()
        course_nav = self.course_pages()
        extra_room = self.extra_page("my-room", "your-room/index.md", "My room",
                                     "The learner's own project: every chapter hands it one body.", "Your room")
        extra_base = self.extra_page("kit-base", "kit-base/index.md", "The kit base",
                                     "The supplied parts every kit starts from.", "The kit base")
        teachers_nav = self.teachers()
        nav: list = [{"Home": "index.md"},
                     {"The short track": short_nav},
                     {"The whole course": course_nav}]
        if extra_room:
            nav.append({"Your room": extra_room})
        if extra_base:
            nav.append({"The kit base": extra_base})
        nav.append({"For teachers": teachers_nav})
        self.out.text("_nav.json", json.dumps(nav, indent=1, ensure_ascii=False))
        self.static_files()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--check", action="store_true", help="write nothing; exit 1 if docs/ would change")
    args = ap.parse_args()
    if not repo_path(OPENING_JSON).is_file():
        print(f"build_site: no {OPENING_JSON} under {REPO}; set ADA_REPO to the repository root", file=sys.stderr)
        return 2
    b = Builder()
    b.run()
    written, removed = sync(b.out, DOCS, args.check)
    pages = sum(1 for p in b.out.files if p.endswith(".md"))
    c = b.c
    print(f"build_site: {pages} pages, {len(b.out.files)} files in docs/ "
          f"({'would write' if args.check else 'wrote'} {written}, {'would remove' if args.check else 'removed'} {removed})")
    print(f"  short track: {len(c.stops)} stops")
    print(f"  whole course: {len(c.chapters)} chapters, {b.counts.get('chapters_with_lesson', 0)} with a lesson, "
          f"{b.counts.get('chapters_outline', 0)} with only an outline")
    zips = [k for k in c.kits.values() if k.zip_rel]
    print(f"  kit zips: {len(zips)}, {human_size(b.zip_total)} in all ({b.zip_total} bytes)")
    if b.zip_total > ZIP_WARN_TOTAL:
        print(f"  WARNING: the kit zips pass {human_size(ZIP_WARN_TOTAL)}")
    for w in WARNINGS:
        print(f"  note: {w}")
    if args.check:
        return 1 if (written or removed) else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
