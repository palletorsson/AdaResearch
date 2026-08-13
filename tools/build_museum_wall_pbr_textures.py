#!/usr/bin/env python3
"""Convert one neutral material source into a compact seamless PBR texture set."""
from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageOps


def mirrored_periodic(image: Image.Image, size: int) -> Image.Image:
    image = ImageOps.fit(image.convert("RGB"), (size, size), method=Image.Resampling.LANCZOS)
    row_a = Image.new("RGB", (size * 2, size))
    row_a.paste(image, (0, 0))
    row_a.paste(ImageOps.mirror(image), (size, 0))
    row_b = ImageOps.flip(row_a)
    tile = Image.new("RGB", (size * 2, size * 2))
    tile.paste(row_a, (0, 0))
    tile.paste(row_b, (0, size))
    # Centre crop crosses all mirrored joins and is periodic at opposite edges.
    return tile.crop((size // 2, size // 2, size + size // 2, size + size // 2))


def build(source: Path, output: Path, size: int, prefix: str, metal: bool) -> None:
    output.mkdir(parents=True, exist_ok=True)
    albedo = mirrored_periodic(Image.open(source), size)
    albedo.save(output / f"{prefix}_albedo.png", optimize=True)

    gray = np.asarray(albedo.convert("L"), dtype=np.float32) / 255.0
    broad = np.asarray(albedo.convert("L").filter(ImageFilter.GaussianBlur(radius=max(2, size // 128))), dtype=np.float32) / 255.0
    detail = np.clip((gray - broad) * 2.2 + 0.5, 0.0, 1.0)
    height = np.clip(0.72 * broad + 0.28 * detail, 0.0, 1.0)
    Image.fromarray(np.uint8(height * 255), "L").save(output / f"{prefix}_height.png", optimize=True)

    # Periodic central differences: derivatives wrap at texture edges.
    dx = np.roll(height, -1, axis=1) - np.roll(height, 1, axis=1)
    dy = np.roll(height, -1, axis=0) - np.roll(height, 1, axis=0)
    strength = 2.6 if metal else 4.2
    nx, ny, nz = -dx * strength, -dy * strength, np.ones_like(height)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    normal = np.stack((nx / length, ny / length, nz / length), axis=-1)
    normal = np.uint8(np.clip(normal * 0.5 + 0.5, 0.0, 1.0) * 255)
    Image.fromarray(normal, "RGB").save(output / f"{prefix}_normal.png", optimize=True)

    # Limestone is broadly rough; subtle mineral variation prevents plastic response.
    if metal:
        roughness = np.clip(0.44 + (0.5 - detail) * 0.24 + (0.52 - broad) * 0.12, 0.26, 0.68)
    else:
        roughness = np.clip(0.78 + (0.5 - detail) * 0.22 + (0.58 - broad) * 0.12, 0.58, 0.96)
    Image.fromarray(np.uint8(roughness * 255), "L").save(output / f"{prefix}_roughness.png", optimize=True)

    # Keep AO restrained: this map adds pore response, not baked scene shadow.
    ao = np.clip(0.96 - np.maximum(0.0, 0.5 - detail) * 0.25, 0.82, 1.0)
    Image.fromarray(np.uint8(ao * 255), "L").save(output / f"{prefix}_ao.png", optimize=True)
    if metal:
        metallic = Image.new("L", (size, size), 255)
        metallic.save(output / f"{prefix}_metallic.png", optimize=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--size", type=int, default=1024)
    parser.add_argument("--prefix", default="aaa_wall_stone")
    parser.add_argument("--metal", action="store_true")
    args = parser.parse_args()
    build(args.source.resolve(), args.output.resolve(), args.size, args.prefix, args.metal)
    print(args.output.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
