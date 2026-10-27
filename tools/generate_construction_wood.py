"""Bake a deterministic weathered scaffold-board material, shared by Godot and GLB.

This is a procedural material, not a photograph from the reference image.
One tile covers 1.65 x 2.4 metres: five narrow boards with staggered butt joints.
"""
from pathlib import Path
import numpy as np
from PIL import Image


def generate():
    rng = np.random.default_rng(4681)
    size = 1024
    y, x = np.mgrid[:size, :size] / size

    def noise(w, h):
        data = rng.integers(0, 256, (h, w), dtype=np.uint8)
        return np.asarray(Image.fromarray(data).resize((size, size), Image.Resampling.BICUBIC), dtype=float) / 255 - .5

    broad = noise(24, 12)
    grain = noise(200, 14)
    fine = noise(700, 64)
    pores = noise(1024, 1024)
    brightness = .07 * broad + .13 * grain + .07 * fine + .026 * pores
    board_id = np.minimum((x * 5).astype(int), 4)
    brightness += np.array([-.025, .035, -.015, .012, -.045])[board_id]
    flow = x * 700 + 2.2 * np.sin(y * 8 + board_id) + broad * 4
    # Lenticular growth rings and occasional dark knots follow each board's grain.
    for cx, cy in [(.09, .31), (.34, .78), (.54, .17), (.73, .59), (.91, .85)]:
        dx, dy = x - cx, y - cy
        dist = np.sqrt((dx * 22) ** 2 + (dy * 4) ** 2)
        local = np.exp(-dist * 1.5)
        flow += local * np.sin(np.arctan2(dy, dx) * 2) * 4
        brightness -= .18 * np.exp(-dist * 9)
        brightness += np.sin(dist * 35) * local * .026
    brightness += np.sin(flow) * .028 + np.sin(flow * 2.71) * .01
    seams = np.minimum((x * 5) % 1, 1 - (x * 5) % 1)
    brightness -= np.exp(-seams * 330) * .30
    joints = np.array([.69, .28, .80, .43, .19])[board_id]
    brightness -= np.exp(-np.abs(y - joints) * 900) * .22
    # Two recessed nail heads near the ends of each board.
    for board in range(5):
        for nx in [(board + .14) / 5, (board + .86) / 5]:
            for ny in [.025, .975]:
                d = ((x - nx) ** 2 + (y - ny) ** 2) ** .5
                brightness -= .29 * np.exp(-(d / .0026) ** 4)
    colour = np.array([.57, .49, .37])[None, None, :] + brightness[:, :, None]
    # Chalky, sun-bleached patches rather than saturated varnish.
    bleach = np.maximum(noise(15, 7), 0)[:, :, None] * .13
    colour = np.clip(colour + bleach * np.array([.7, .85, 1.1]), 0, 1)
    dest = Path(__file__).resolve().parents[1] / 'commons/void/textures/construction_wood.png'
    dest.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray((colour * 255).astype(np.uint8)).save(dest)
    print(dest)


if __name__ == '__main__':
    generate()
