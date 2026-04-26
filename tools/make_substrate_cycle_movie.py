"""Stitch the substrate-cycle captures into a short mp4 showing the same
spine map redrawn under each visibility expression.

Reads PNGs from `%APPDATA%/Godot/app_userdata/Ada Research Zero One/substrate_cycle/`
(or wherever capture_map_substrate_cycle.gd wrote them), inserts a title card
per pattern showing the pattern name, and writes an mp4 to the encyclopedia
blog dir.

Usage:
    python tools/make_substrate_cycle_movie.py --target CA_Introduction
    python tools/make_substrate_cycle_movie.py --target CA_Introduction --out path.mp4
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

DEFAULT_SHOTS_DIR = Path(os.environ["APPDATA"]) / "Godot" / "app_userdata" / "Ada Research Zero One" / "substrate_cycle"
DEFAULT_OUT_BASE = Path(__file__).resolve().parents[1].parent / "ada_encyclopedia" / "public" / "blog"
FRAME_DURATION = 1.6  # seconds per pattern frame
LABEL_DURATION = 0.9  # seconds for the overlay label between patterns
INTRO_DURATION = 1.8


def find_ffmpeg() -> str:
    for cand in ["ffmpeg", "ffmpeg.exe"]:
        try:
            subprocess.run([cand, "-version"], check=True, capture_output=True)
            return cand
        except (FileNotFoundError, subprocess.CalledProcessError):
            pass
    try:
        import imageio_ffmpeg
        return imageio_ffmpeg.get_ffmpeg_exe()
    except Exception:
        sys.exit("ffmpeg not found")


def load_font(size: int) -> ImageFont.ImageFont:
    for p in [r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\arial.ttf"]:
        if Path(p).exists():
            try:
                return ImageFont.truetype(p, size)
            except OSError:
                continue
    return ImageFont.load_default()


def make_intro_card(target: str, count: int, size: tuple[int, int]) -> Image.Image:
    img = Image.new("RGB", size, (24, 26, 30))
    draw = ImageDraw.Draw(img)
    big = load_font(72)
    sub = load_font(32)
    title = f"{target}"
    subtitle = f"substrate cycle · {count} visibility expressions on the map's grid"
    tw, th = draw.textbbox((0, 0), title, font=big)[2:]
    draw.text(((size[0] - tw) / 2, size[1] / 2 - th - 20), title, font=big, fill=(238, 238, 240))
    sw, sh = draw.textbbox((0, 0), subtitle, font=sub)[2:]
    draw.text(((size[0] - sw) / 2, size[1] / 2 + 20), subtitle, font=sub, fill=(140, 145, 155))
    draw.rectangle([(size[0] / 2 - 80, size[1] / 2 - 4), (size[0] / 2 + 80, size[1] / 2 - 1)], fill=(98, 188, 168))
    return img


def annotate_frame(src: Path, pattern: str) -> Image.Image:
    """Open the capture and burn a small caption on the bottom-left."""
    img = Image.open(src).convert("RGB")
    draw = ImageDraw.Draw(img)
    font = load_font(36)
    label = f"visibility · {pattern}"
    pad = 18
    bbox = draw.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    box_x = pad
    box_y = img.height - pad - th - 14
    draw.rectangle([(box_x - 8, box_y - 8), (box_x + tw + 16, box_y + th + 14)], fill=(20, 22, 26))
    draw.text((box_x, box_y), label, font=font, fill=(238, 238, 240))
    # tiny accent dot
    draw.ellipse([(box_x - 4, box_y + th / 2 - 2), (box_x, box_y + th / 2 + 2)], fill=(98, 188, 168))
    return img


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", required=True, help="Map name (matches the captures' filename prefix)")
    parser.add_argument("--shots-dir", type=Path, default=DEFAULT_SHOTS_DIR)
    parser.add_argument("--out", type=Path, default=None)
    parser.add_argument("--width", type=int, default=1280)
    args = parser.parse_args()

    out = args.out or (DEFAULT_OUT_BASE / f"substrate-cycle-{args.target.lower().replace('_', '-')}.mp4")
    out.parent.mkdir(parents=True, exist_ok=True)

    pngs = sorted(args.shots_dir.glob(f"{args.target}__*.png"))
    if not pngs:
        sys.exit(f"no {args.target}__*.png files found in {args.shots_dir}")
    print(f"found {len(pngs)} captures")

    # Probe first image for size.
    with Image.open(pngs[0]) as im:
        in_size = im.size

    # Annotate each frame (writes to temp PNGs).
    tmp_dir = Path(tempfile.mkdtemp(prefix="substrate_cycle_"))
    plan: list[tuple[Path, float]] = []

    intro_path = tmp_dir / "00_intro.png"
    make_intro_card(args.target, len(pngs), in_size).save(intro_path)
    plan.append((intro_path, INTRO_DURATION))

    for i, src in enumerate(pngs):
        # Pull pattern name from filename: <target>__<pattern>.png
        stem = src.stem
        pattern = stem.split("__", 1)[1] if "__" in stem else stem
        annotated = tmp_dir / f"{i+1:02d}_{pattern}.png"
        annotate_frame(src, pattern).save(annotated)
        plan.append((annotated, FRAME_DURATION))
    print(f"plan: {len(plan)} entries, total {sum(d for _, d in plan):.1f}s")

    # Write concat list.
    concat_path = tmp_dir / "concat.txt"
    lines: list[str] = []
    for p, d in plan:
        lines.append(f"file '{str(p).replace(chr(92), '/')}'")
        lines.append(f"duration {d:.3f}")
    last = plan[-1][0]
    lines.append(f"file '{str(last).replace(chr(92), '/')}'")
    concat_path.write_text("\n".join(lines), encoding="utf-8")

    out_w = args.width
    out_h = int(round(out_w * in_size[1] / in_size[0]))
    if out_h % 2 == 1:
        out_h += 1

    ffmpeg = find_ffmpeg()
    cmd = [
        ffmpeg, "-y",
        "-f", "concat", "-safe", "0",
        "-i", str(concat_path),
        "-vf", f"fps=24,scale={out_w}:{out_h}:flags=lanczos,format=yuv420p",
        "-c:v", "libx264",
        "-preset", "medium",
        "-crf", "20",
        "-movflags", "+faststart",
        str(out),
    ]
    print("ffmpeg…")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(proc.stderr[-1500:])
        sys.exit(f"ffmpeg failed (rc={proc.returncode})")
    print(f"wrote {out} ({out.stat().st_size / 1024:.1f} KiB)")

    # Tidy temp.
    for p in tmp_dir.glob("*"):
        p.unlink(missing_ok=True)
    tmp_dir.rmdir()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
