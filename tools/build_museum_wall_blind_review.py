#!/usr/bin/env python3
"""Build randomized A/B sheets for hostile museum-wall visual review.

The visible sheets contain only A and B. Source identity is stored separately in
`answer_key.json`, so a reviewer can record a preference before unblinding.
Official reference images are evaluation-only and are never copied to the site.
"""
from __future__ import annotations

import argparse
import json
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_REFERENCES = ROOT / "ada_run/museum_aaa_pass/references_black_ops_7"

CANDIDATES = [
    ("atlas", "museum_wall_kit_capture/museum_wall_kit_atlas.png"),
    ("full_build", "museum_wall_aaa_showcase_capture/museum_wall_aaa_showcase.png"),
    ("solid", "museum_wall_piece_gallery/solid_4m.png"),
    ("feature", "museum_wall_piece_gallery/feature_4m.png"),
    ("window", "museum_wall_piece_gallery/window_4m.png"),
    ("vitrine", "museum_wall_piece_gallery/vitrine_4m.png"),
    ("service", "museum_wall_piece_gallery/service_4m.png"),
    ("portal", "museum_wall_piece_gallery/portal_4m.png"),
    ("endcap", "museum_wall_piece_gallery/endcap_2m.png"),
]


def panel(path: Path, size: tuple[int, int]) -> Image.Image:
    image = Image.open(path).convert("RGB")
    # Contain rather than crop: silhouette and authored framing are evidence.
    return ImageOps.pad(image, size, method=Image.Resampling.LANCZOS, color=(18, 20, 24), centering=(0.5, 0.5))


def add_label(image: Image.Image, label: str) -> None:
    draw = ImageDraw.Draw(image)
    try:
        font = ImageFont.truetype("arial.ttf", 26)
    except OSError:
        font = ImageFont.load_default()
    draw.rounded_rectangle((18, 18, 74, 64), radius=8, fill=(5, 7, 10, 220), outline=(230, 232, 236), width=2)
    draw.text((37, 25), label, fill=(250, 250, 250), font=font)


def build(candidate_root: Path, references: Path, output: Path, seed: int) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    refs = sorted(references.glob("*.webp")) + sorted(references.glob("*.png")) + sorted(references.glob("*.jpg"))
    if not refs:
        raise SystemExit(f"No reference images found under {references}")
    rng = random.Random(seed)
    answer_key: dict[str, dict] = {}
    sheets: list[dict] = []
    for index, (family, relative) in enumerate(CANDIDATES):
        candidate = candidate_root / relative
        if not candidate.exists():
            continue
        reference = refs[index % len(refs)]
        candidate_panel = panel(candidate, (760, 760))
        reference_panel = panel(reference, (760, 760))
        candidate_side = rng.choice(["A", "B"])
        left = candidate_panel if candidate_side == "A" else reference_panel
        right = reference_panel if candidate_side == "A" else candidate_panel
        add_label(left, "A")
        add_label(right, "B")
        sheet = Image.new("RGB", (1540, 760), (8, 10, 13))
        sheet.paste(left, (0, 0))
        sheet.paste(right, (780, 0))
        filename = f"{index + 1:02d}_{family}.jpg"
        sheet.save(output / filename, quality=94, subsampling=0)
        answer_key[family] = {
            "candidate_side": candidate_side,
            "candidate": str(candidate.relative_to(ROOT)).replace("\\", "/"),
            "reference": str(reference.relative_to(ROOT)).replace("\\", "/"),
        }
        sheets.append({"family": family, "image": filename})
    (output / "manifest.json").write_text(json.dumps({"seed": seed, "sheets": sheets}, separators=(",", ":")) + "\n", encoding="utf-8")
    (output / "answer_key.json").write_text(json.dumps(answer_key, separators=(",", ":")) + "\n", encoding="utf-8")
    return {"pairs": len(sheets), "output": str(output), "seed": seed}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate-root", type=Path, default=ROOT / "ada_run/museum_aaa_pass")
    parser.add_argument("--references", type=Path, default=DEFAULT_REFERENCES)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--seed", type=int, default=4067)
    args = parser.parse_args()
    print(json.dumps(build(args.candidate_root.resolve(), args.references.resolve(), args.output.resolve(), args.seed), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
