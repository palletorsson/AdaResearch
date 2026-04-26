"""Stitch the grid-mutator capture shots into a short mp4 for the blog.

Reads PNGs from `%APPDATA%/Godot/app_userdata/Ada Research Zero One/mutator_shots/`
(or wherever the capture script wrote them), groups them by channel
(color / visibility / transform / combined / triple), inserts a title card
between sections, and writes an mp4 via ffmpeg.

Usage:
    python tools/make_mutator_movie.py
    python tools/make_mutator_movie.py --shots-dir <dir> --out <path>

Default output: <ada_encyclopedia>/public/blog/mutator-tour.mp4
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

DEFAULT_SHOTS_DIR = Path(os.environ["APPDATA"]) / "Godot" / "app_userdata" / "Ada Research Zero One" / "mutator_shots"
DEFAULT_OUT = Path(__file__).resolve().parents[1].parent / "ada_encyclopedia" / "public" / "blog" / "mutator-tour.mp4"
W, H = 1800, 1061

# Section -> (filename prefix, frame duration in seconds)
SECTIONS = [
    ("color",      "color_",      0.55),
    ("visibility", "visibility_", 0.80),
    ("transform",  "transform_",  0.80),
    ("combined",   "combined_",   0.55),
    ("triple",     "triple_",     1.00),
    ("floorplan",  "floorplan_",  1.00),
]

SECTION_TITLES = {
    "color":      ("color channel", "10 palette + gradient + sphere expressions"),
    "visibility": ("visibility channel", "rule_30 · sierpinski · checkerboard · rings · menger · shell · BFS"),
    "transform":  ("transform channel", "rotate · lift · scale · force_field"),
    "combined":   ("two channels at once", "color × visibility on one MultiMesh"),
    "triple":     ("three channels at once", "color × visibility × transform"),
    "floorplan":  ("pattern as floor plan", "spawn_largest · auto_stitch · algorithm_path"),
}


def find_ffmpeg() -> str:
    """Locate an ffmpeg binary (system PATH first, fall back to imageio_ffmpeg)."""
    for cand in ["ffmpeg", "ffmpeg.exe"]:
        try:
            subprocess.run([cand, "-version"], check=True, capture_output=True)
            return cand
        except (FileNotFoundError, subprocess.CalledProcessError):
            pass
    try:
        import imageio_ffmpeg  # type: ignore
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        sys.exit("ffmpeg not found. Install ffmpeg or `pip install imageio-ffmpeg`.")


def load_font(size: int) -> ImageFont.ImageFont:
    candidates = [
        r"C:\Windows\Fonts\segoeui.ttf",
        r"C:\Windows\Fonts\arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for p in candidates:
        if Path(p).exists():
            try:
                return ImageFont.truetype(p, size)
            except OSError:
                continue
    return ImageFont.load_default()


def make_title_card(title: str, subtitle: str, out_path: Path) -> None:
    img = Image.new("RGB", (W, H), (24, 26, 30))
    draw = ImageDraw.Draw(img)

    title_font = load_font(72)
    sub_font = load_font(36)

    # title centered slightly above middle
    tw, th = draw.textbbox((0, 0), title, font=title_font)[2:]
    draw.text(((W - tw) / 2, H / 2 - th - 20), title, font=title_font, fill=(238, 238, 240))

    sw, sh = draw.textbbox((0, 0), subtitle, font=sub_font)[2:]
    draw.text(((W - sw) / 2, H / 2 + 20), subtitle, font=sub_font, fill=(140, 145, 155))

    # subtle accent line
    draw.rectangle([(W / 2 - 80, H / 2 - 4), (W / 2 + 80, H / 2 - 1)], fill=(98, 188, 168))

    img.save(out_path)


def make_intro_card(out_path: Path, total_shots: int, is_3d: bool) -> None:
    img = Image.new("RGB", (W, H), (24, 26, 30))
    draw = ImageDraw.Draw(img)
    big = load_font(96)
    sub = load_font(40)

    title = "Grid mutators · 3D" if is_3d else "Grid mutators"
    subtitle_base = "one substrate · four channels" if is_3d else "one substrate · three channels"
    subtitle = "%s · %d shots" % (subtitle_base, total_shots)

    tw, th = draw.textbbox((0, 0), title, font=big)[2:]
    draw.text(((W - tw) / 2, H / 2 - th - 30), title, font=big, fill=(238, 238, 240))

    sw, sh = draw.textbbox((0, 0), subtitle, font=sub)[2:]
    draw.text(((W - sw) / 2, H / 2 + 30), subtitle, font=sub, fill=(140, 145, 155))

    # accent
    draw.rectangle([(W / 2 - 100, H / 2 - 4), (W / 2 + 100, H / 2 - 1)], fill=(98, 188, 168))
    img.save(out_path)


def collect_section(shots_dir: Path, prefix: str) -> list[Path]:
    files = sorted(shots_dir.glob(f"{prefix}*.png"))
    return files


def build_concat_list(
    shots_dir: Path,
    cards_dir: Path,
    intro_path: Path,
) -> list[tuple[Path, float]]:
    """Returns ordered (path, duration_seconds) pairs."""
    plan: list[tuple[Path, float]] = []

    plan.append((intro_path, 1.6))

    for section, prefix, duration in SECTIONS:
        files = collect_section(shots_dir, prefix)
        if not files:
            continue
        title, subtitle = SECTION_TITLES[section]
        card = cards_dir / f"card_{section}.png"
        make_title_card(title, subtitle, card)
        plan.append((card, 1.4))
        for f in files:
            plan.append((f, duration))

    return plan


def write_concat_file(plan: list[tuple[Path, float]], path: Path) -> None:
    """ffmpeg concat-demuxer file: each entry gets a duration; last file repeats without duration."""
    lines = []
    for p, d in plan:
        # ffmpeg concat parser is sensitive to backslashes; use forward slashes.
        norm = str(p).replace("\\", "/")
        lines.append(f"file '{norm}'")
        lines.append(f"duration {d:.3f}")
    # repeat the final file so its duration is honoured
    last = plan[-1][0]
    lines.append(f"file '{str(last).replace(chr(92), '/')}'")
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--shots-dir", type=Path, default=DEFAULT_SHOTS_DIR)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--width", type=int, default=1280, help="output width (height auto)")
    parser.add_argument("--keep-intermediate", action="store_true")
    args = parser.parse_args()

    shots_dir = args.shots_dir
    if not shots_dir.exists():
        sys.exit(f"shots dir not found: {shots_dir}")

    pngs = list(shots_dir.glob("*.png"))
    if not pngs:
        sys.exit(f"no PNGs found in {shots_dir}")
    print(f"found {len(pngs)} input PNGs in {shots_dir}")

    out = args.out
    out.parent.mkdir(parents=True, exist_ok=True)

    ffmpeg = find_ffmpeg()
    print(f"ffmpeg: {ffmpeg}")

    # Build title cards in a temp dir.
    cards_root = Path(tempfile.mkdtemp(prefix="mutator_cards_"))
    try:
        intro = cards_root / "intro.png"
        is_3d = any(p.name.startswith("floorplan_") for p in pngs)
        make_intro_card(intro, len(pngs), is_3d)
        plan = build_concat_list(shots_dir, cards_root, intro)
        print(f"plan: {len(plan)} entries, total {sum(d for _, d in plan):.1f}s")

        concat_file = cards_root / "concat.txt"
        write_concat_file(plan, concat_file)

        # Compute output height preserving aspect ratio (1800×1061 -> 1280×755).
        out_w = args.width
        out_h = int(round(out_w * H / W))
        # ensure even (libx264 requires even dims)
        if out_h % 2 == 1:
            out_h += 1

        cmd = [
            ffmpeg, "-y",
            "-f", "concat", "-safe", "0",
            "-i", str(concat_file),
            "-vf", f"fps=24,scale={out_w}:{out_h}:flags=lanczos,format=yuv420p",
            "-c:v", "libx264",
            "-preset", "medium",
            "-crf", "20",
            "-movflags", "+faststart",
            str(out),
        ]
        print("running ffmpeg…")
        proc = subprocess.run(cmd, capture_output=True, text=True)
        if proc.returncode != 0:
            print(proc.stderr[-2000:])
            sys.exit(f"ffmpeg failed (rc={proc.returncode})")
        print(f"wrote {out} ({out.stat().st_size / 1024:.1f} KiB)")
    finally:
        if not args.keep_intermediate:
            for p in cards_root.glob("*"):
                p.unlink(missing_ok=True)
            cards_root.rmdir()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
