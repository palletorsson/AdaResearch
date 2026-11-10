#!/usr/bin/env python3
"""A REVIEW PDF of one spine sequence's works, in artifact-timeline order, to read and comment on OFFLINE (Palle,
2026-11-10: "make a PDF of the fractal time artifact sequence where we can comment on the artifacts and you can read
later ... this is for offline use").

One page per main work of the sequence's floors (commons/void/layout.json `spine`), in the order of
commons/data/artifact_timeline.json: its timeline number and title, floor and map, a picture, the registry description
and the script's @identity essence, the transition card that falls before it, and FILLABLE fields - a comment box and
keep / improve / remove / move ticks. A last page takes general notes. Fill it in any PDF reader that saves forms
(Acrobat Reader, Edge, Preview, Xodo...), save, and `tools/read_review_pdf.py <pdf>` reads the answers back (sticky
notes too).

Pictures (Palle: "we need to see how the artifact look inside the void tower"): each floor opens with three views of
it in the tower, and each work's large picture is the work where it stands - both from tools/probes/color_survey.gd
run with --out=ada_run/reviews/<seq>/tower --floors=<the sequence's floors>. The small picture is the work alone:
shots/picks.json, else shots/<key>.png (made with --shoot: each scene shot standalone, 4 at a time, under the
watchdog), else the old multi_shots front.png (dated on the page).

    python tools/timeline_review_pdf.py fractals [--shoot] [--only=key,key]   # -> ada_run/reviews/<seq>/<seq>_review.pdf
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import artifact_timeline as at  # noqa: E402

GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
MULTI = Path(os.path.expandvars(r"%APPDATA%/Godot/app_userdata/Ada Research Zero One/multi_shots"))
VERDICTS = ["keep", "improve", "remove", "move"]


def fix_text(s: str) -> str:
    """Titles read as cp1252 somewhere on the way ('MÃ¶bius'): put them back."""
    if s and ("Ã" in s or "â€" in s):
        try:
            return s.encode("cp1252").decode("utf-8")
        except (UnicodeError, ValueError):
            return s
    return s or ""


def pretty(key: str, title: str) -> str:
    t = fix_text(title or key)
    return t.replace("_", " ").strip().capitalize() if t == key else t


def essence(scene: str) -> str:
    """The `# essence:` lines of the scene's root script (@identity), if it has them."""
    p = ROOT / scene.replace("res://", "") if scene.startswith("res://") else None
    if not p or not p.exists():
        return ""
    m = re.search(r'\[ext_resource[^\]]*type="Script"[^\]]*path="(res://[^"]+)"', p.read_text(encoding="utf-8", errors="replace"))
    if not m:
        return ""
    gd = ROOT / m.group(1).replace("res://", "")
    if not gd.exists():
        return ""
    lines, on = [], False
    for line in gd.read_text(encoding="utf-8", errors="replace").splitlines()[:80]:
        s = line.strip()
        if s.startswith("# essence:"):
            on = True
            lines.append(s[len("# essence:"):].strip())
        elif on and s.startswith("#") and not re.match(r"#\s*\w+:", s):
            lines.append(s.lstrip("#").strip())
        elif on:
            break
    return " ".join(lines)


def sequence_rows(seq: str) -> tuple:
    layout = json.loads((ROOT / "commons/void/layout.json").read_text(encoding="utf-8"))
    spine = next((s for s in layout.get("spine", []) if s["id"] == seq), None)
    if not spine:
        raise SystemExit(f"no spine sequence {seq!r}: " + ", ".join(s["id"] for s in layout.get("spine", [])))
    vp = ROOT / "ada_run/artifact_timeline_view.json"   # read only: rebuilding it would rewrite the tracked walk file
    if not vp.exists():
        raise SystemExit("no view yet: run python tools/artifact_timeline.py view")
    view = json.loads(vp.read_text(encoding="utf-8"))
    floors = set(spine["floors"])
    rows = [r for r in view["main"] if r.get("floor") in floors]
    cards = {}
    for c in view.get("cards", []):
        cards.setdefault(c.get("at"), []).append(c)
    titles = {f["floor"]: f for f in view.get("floors", [])}
    return spine, rows, cards, titles


def shoot(rows: list, out: Path) -> dict:
    out.mkdir(parents=True, exist_ok=True)

    def one(r):
        key, scene = r["key"], r.get("scene") or ""
        png = out / f"{key}.png"
        if png.exists():
            png.unlink()
        if not scene.startswith("res://"):
            return key, "no scene"
        cmd = [sys.executable, str(ROOT / "tools/godot_watchdog.py"), f"--expect={png}", "--grace=90", "--stall=90", "--",
               GODOT, "--path", str(ROOT), "--xr-mode", "off", "--resolution", "1280x800",
               "--script", "res://commons/testing/capture_tscn_shot.gd", "--",
               f"--scene={scene}", f"--out={png.as_posix()}", "--frames=60", "--physics=240", "--nocam=true"]
        subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=400)
        return key, "ok" if png.exists() and png.stat().st_size > 2000 else "failed"

    with ThreadPoolExecutor(4) as pool:
        res = dict(pool.map(one, rows))
    (out / "shots.json").write_text(json.dumps(res, indent=1), encoding="utf-8")
    return res


def picture(key: str, shots: Path) -> tuple:
    picks = shots / "picks.json"   # {key: {"path", "note"}}: a better picture chosen by hand (an older angle, a retake)
    if picks.exists():
        pick = json.loads(picks.read_text(encoding="utf-8")).get(key)
        if pick:
            pp = Path(os.path.expandvars(pick["path"]))
            pp = pp if pp.is_absolute() else ROOT / pp
            if pp.exists():
                return pp, (pick.get("note") or "chosen picture") + ", " + datetime.fromtimestamp(pp.stat().st_mtime).strftime("%Y-%m-%d")
    fresh = shots / f"{key}.png"
    if fresh.exists() and fresh.stat().st_size > 2000:
        return fresh, "standalone shot, " + datetime.fromtimestamp(fresh.stat().st_mtime).strftime("%Y-%m-%d")
    old = MULTI / key / "front.png"
    if old.exists():
        return old, "older capture, " + datetime.fromtimestamp(old.stat().st_mtime).strftime("%Y-%m-%d") + " - may predate changes"
    return None, "no picture yet"


def build(seq: str, do_shoot: bool, only: set | None = None) -> Path:
    from reportlab.lib.colors import Color, HexColor
    from reportlab.lib.pagesizes import A4
    from reportlab.lib.units import mm
    from reportlab.lib.utils import ImageReader
    from reportlab.pdfbase import pdfmetrics
    from reportlab.pdfbase.ttfonts import TTFont
    from reportlab.pdfgen import canvas
    from reportlab.platypus import Paragraph
    from reportlab.lib.styles import ParagraphStyle

    spine, rows, cards, titles = sequence_rows(seq)
    reg = at.registry()
    out_dir = ROOT / "ada_run/reviews" / seq
    shots = out_dir / "shots"
    if do_shoot:
        res = shoot([r for r in rows if not only or r["key"] in only], shots)
        print("shots:", sum(v == "ok" for v in res.values()), "of", len(res))
    fonts = Path(os.environ.get("WINDIR", "C:/Windows")) / "Fonts"
    pdfmetrics.registerFont(TTFont("Body", str(fonts / "arial.ttf")))
    pdfmetrics.registerFont(TTFont("Bold", str(fonts / "arialbd.ttf")))
    ink, grey, pink = HexColor("#1d1b20"), HexColor("#6b6570"), HexColor("#ea72ab")
    body = ParagraphStyle("b", fontName="Body", fontSize=9.5, leading=12.5, textColor=ink)
    small = ParagraphStyle("s", fontName="Body", fontSize=8, leading=10.5, textColor=grey)
    card_style = ParagraphStyle("c", fontName="Body", fontSize=9.5, leading=12.5, textColor=ink)

    out_dir.mkdir(parents=True, exist_ok=True)
    pdf_path = out_dir / f"{seq}_review.pdf"
    W, H = A4
    M = 16 * mm
    c = canvas.Canvas(str(pdf_path), pagesize=A4)
    c.setTitle(f"{spine['title']} - artifact timeline review")
    c.setAuthor("Ada Research")
    form = c.acroForm

    def para(text, style, x, y_top, width):
        p = Paragraph(text, style)
        _, h = p.wrap(width, H)
        p.drawOn(c, x, y_top - h)
        return y_top - h

    # cover
    c.setFont("Bold", 22); c.setFillColor(ink)
    c.drawString(M, H - 40 * mm, spine["title"])
    c.setFont("Body", 12); c.setFillColor(grey)
    c.drawString(M, H - 48 * mm, f"Artifact timeline review · floors {min(spine['floors'])}-{max(spine['floors'])} · "
                                 f"{len(rows)} works · {rows[0]['label']}-{rows[-1]['label']} · {date.today().isoformat()}")
    y = para("<b>How to use it.</b> Each work has a page: its number on the timeline, where it stands in the tower, a "
             "picture, what it is meant to show, and the transition card that falls before it. Under each work: tick "
             "<b>keep</b>, <b>improve</b>, <b>remove</b> or <b>move</b>, and write in the comment box. The last page "
             "takes general notes. Fill it in any reader that saves forms (Acrobat Reader, Edge, Preview, Xodo), "
             "<b>save the file</b>, and put it back in <font face='Body'>ada_run/reviews/" + seq + "/</font> (or "
             "anywhere - just say where). Sticky notes are read too.", body, M, H - 62 * mm, W - 2 * M)
    para("Each floor opens with three views of it in the Void tower. On a work's page the large picture is the work "
         "<b>in the tower</b>, where it stands (photographed from 3 m by tools/probes/color_survey.gd); the small one "
         "beside the text is the work alone, its scene shot standalone. A missing tower photo says so.",
         small, M, y - 6 * mm, W - 2 * M)
    c.showPage()

    page_of = {}
    tower = out_dir / "tower"
    shown_floor = None

    jpg_dir = out_dir / "_jpg"

    def fit(path, x, y_top, w, h):
        """Draw a picture fitted into w x h, top-left at (x, y_top); PNGs go in as JPEG (a PDF of 80 lossless
        1600 px PNGs is tens of MB)."""
        path = Path(path)
        if path.suffix.lower() == ".png":
            from PIL import Image
            jpg = jpg_dir / (path.parent.name + "__" + path.stem + ".jpg")
            if not jpg.exists() or jpg.stat().st_mtime < path.stat().st_mtime:
                jpg_dir.mkdir(parents=True, exist_ok=True)
                im = Image.open(path).convert("RGB"); im.thumbnail((1400, 1400))
                im.save(jpg, quality=84)
            path = jpg
        ir = ImageReader(str(path)); iw, ih = ir.getSize()
        s = min(w / iw, h / ih); dw, dh = iw * s, ih * s
        c.drawImage(ir, x + (w - dw) / 2, y_top - dh, dw, dh)
        return dh

    for r in rows:
        key = r["key"]
        place = next((p for p in r.get("places") or [] if p.get("floor") == r.get("floor")), None)
        floor_title = (titles.get(r.get("floor")) or {}).get("map", "")
        if r.get("floor") != shown_floor:   # the floor in the tower, before its works
            shown_floor = r.get("floor")
            views = sorted(tower.glob(f"{shown_floor}__floor_*.png"))
            c.setFillColor(ink); c.setFont("Bold", 18)
            c.drawString(M, H - 22 * mm, f"Floor {shown_floor} · {floor_title}")
            c.setFont("Body", 9); c.setFillColor(grey)
            n_here = sum(1 for x in rows if x.get("floor") == shown_floor)
            c.drawString(M, H - 28 * mm, f"{n_here} works on the timeline here · the floor in the Void tower"
                         + ("" if views else " · no tower views yet"))
            yy = H - 33 * mm
            for v in views[:3]:
                yy -= fit(v, M, yy, W - 2 * M, (H - 40 * mm - M) / 3 - 3 * mm) + 3 * mm
            page_of[str(c.getPageNumber())] = f"_floor_{shown_floor}"
            c.showPage()
        page_of[str(c.getPageNumber())] = key
        # header
        c.setFillColor(pink); c.setFont("Bold", 20)
        c.drawString(M, H - 22 * mm, r["label"])
        c.setFillColor(ink); c.setFont("Bold", 16)
        c.drawString(M + 30 * mm, H - 22 * mm, pretty(key, r.get("title"))[:60])
        c.setFont("Body", 8.5); c.setFillColor(grey)
        where = f"floor {r.get('floor')} · {floor_title}" + (f" · {place['id']}" if place else " · not standing in the tower")
        c.drawString(M, H - 28 * mm, f"{key} · {where}"[:150])
        y = H - 33 * mm
        for card in cards.get(key, []):
            text = (f"<b>Transition</b> · <font face='Bold'>{card.get('formula', '')}</font> - {card.get('motive', '')}"
                    + (f" <font color='#6b6570'>({card.get('said')})</font>" if card.get("said") else ""))
            y = para(text, card_style, M + 3 * mm, y - 1 * mm, W - 2 * M - 6 * mm) - 2 * mm
            c.setStrokeColor(pink); c.setLineWidth(1.2); c.line(M, y + 1 * mm, W - M, y + 1 * mm)
        # the work in the tower (large)
        top = y - 3 * mm
        tower_img = None
        if place:
            tower_img = tower / ("%02d_%s.png" % (int(place["floor"]), str(place["id"]).replace("/", "_")[:40]))
        if tower_img and tower_img.exists():
            y = top - fit(tower_img, M, top, W - 2 * M, 92 * mm)
            note = "in the Void tower, floor %s (%s)" % (place["floor"], place["id"])
        else:
            c.setFillColor(Color(.93, .92, .94)); c.rect(M, top - 30 * mm, W - 2 * M, 30 * mm, stroke=0, fill=1)
            c.setFillColor(grey); c.setFont("Body", 10)
            c.drawCentredString(W / 2, top - 16 * mm, "no tower photo" + ("" if place else ": it stands on no floor"))
            y = top - 30 * mm
            note = ""
        c.setFont("Body", 7); c.setFillColor(grey); c.drawRightString(W - M, y - 3.5 * mm, note)
        # the work alone (small) beside what it is
        y -= 6 * mm
        img, alone_note = picture(key, shots)
        thumb_w, thumb_h = 52 * mm, 34 * mm
        text_x = M
        if img:
            th = fit(img, M, y, thumb_w, thumb_h)
            cap = ParagraphStyle("cap", fontName="Body", fontSize=6.5, leading=8, textColor=grey)
            thumb_bottom = para("alone: " + alone_note, cap, M, y - th - 1 * mm, thumb_w) - 2 * mm
            text_x = M + thumb_w + 5 * mm
        else:
            thumb_bottom = y
        desc = fix_text((reg.get(key) or {}).get("description") or "")
        ess = essence(r.get("scene") or "")
        ty = y
        if desc:
            ty = para(desc, body, text_x, ty, W - M - text_x) - 1.5 * mm
        if ess and ess not in desc:
            ty = para("<i>Essence:</i> " + ess, body, text_x, ty, W - M - text_x) - 1.5 * mm
        flags = [f for f in r.get("flags", []) if f]
        if r.get("note") or flags:
            ty = para(" · ".join(([r["note"]] if r.get("note") else []) + flags), small, text_x, ty, W - M - text_x) - 1 * mm
        y = min(ty, thumb_bottom)
        # the fields
        y -= 3 * mm
        c.setFont("Bold", 9); c.setFillColor(ink)
        x = M
        for v in VERDICTS:
            form.checkbox(name=f"{key}__{v}", x=x, y=y - 4 * mm, size=4.2 * mm, buttonStyle="check",
                          borderColor=grey, fillColor=Color(1, 1, 1), textColor=ink, tooltip=f"{v}: {key}")
            c.drawString(x + 5.5 * mm, y - 3.2 * mm, v)
            x += 28 * mm
        y -= 8 * mm
        field_h = max(28 * mm, y - M)
        c.setFont("Body", 7.5); c.setFillColor(grey); c.drawString(M, y + 0.5 * mm, "Comment")
        form.textfield(name=f"{key}__comment", x=M, y=y - field_h, width=W - 2 * M, height=field_h - 1 * mm,
                       fieldFlags="multiline", fontName="Helvetica", fontSize=10, borderColor=grey,
                       fillColor=Color(.99, .985, .975), textColor=ink, tooltip=f"comment on {key}", value="")
        c.showPage()

    # general notes
    c.setFont("Bold", 16); c.setFillColor(ink); c.drawString(M, H - 22 * mm, "General notes")
    c.setFont("Body", 9); c.setFillColor(grey)
    c.drawString(M, H - 29 * mm, "The sequence as a whole: order, what is missing, what repeats, what should open or close it.")
    form.textfield(name="_general__comment", x=M, y=M, width=W - 2 * M, height=H - 36 * mm - M, fieldFlags="multiline",
                   fontName="Helvetica", fontSize=10, borderColor=grey, fillColor=Color(.99, .985, .975), textColor=ink,
                   value="")
    c.showPage()
    c.setSubject(json.dumps({"ada_review": seq, "made": date.today().isoformat(), "pages": page_of}))   # read_review_pdf.py
    c.save()
    return pdf_path


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    if not args:
        raise SystemExit(__doc__)
    t = time.time()
    only = {k for a in sys.argv if a.startswith("--only=") for k in a[7:].split(",") if k}
    p = build(args[0], "--shoot" in sys.argv, only or None)
    print(f"{p} ({p.stat().st_size // 1024} KB, {time.time() - t:.0f} s)")
