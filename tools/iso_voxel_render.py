"""Isometric voxel renderer for map structure layers.

Each cell becomes a 1×h×1 cube drawn in standard isometric projection
(30° elevation, 45° azimuth). Cubes are drawn from far to near so closer
ones correctly occlude farther ones. No GPU, no engine — pure PIL.

Use:
    from iso_voxel_render import render_iso
    render_iso(heights, "out.png", cell_px=18)
"""
from __future__ import annotations

from pathlib import Path
import math


# Camera. Shifted from classic 30° iso (gentle elevation) to a steeper
# ~42° elevation so that at thumbnail size more of the FLOOR is visible
# and the spawn/teleport markers read clearly. Azimuth stays at 45°
# (cubes' edges align to screen diagonals — symmetric, no preferred side).
COS_AZ = math.cos(math.radians(45))     # ≈ 0.707
SIN_EL = math.sin(math.radians(42))     # ≈ 0.669 (was 0.5 at 30°)


def project(wx: float, wy: float, wz: float, scale: float) -> tuple[float, float]:
    """World → screen (relative). Origin at world (0, 0, 0)."""
    sx = (wx - wz) * COS_AZ * scale
    sy = ((wx + wz) * SIN_EL - wy) * scale
    return sx, sy


# Per-face shading (top brightest, right darkest), so cubes read as 3D.
def shade(base: tuple[int, int, int], factor: float) -> tuple[int, int, int]:
    return tuple(max(0, min(255, int(c * factor))) for c in base)  # type: ignore


# Match the Three.js HEIGHT_COLORS in /map-3d/[name]/page.tsx exactly so
# thumbnails and the live 3D viewer use the same palette.
#   "0" 0x141620   "1" 0x6e8294   "2" 0x9bafc4
#   "3" 0xbed0e2   "4" 0x3a4250   "5" 0x2a3040
HEIGHT_BASE = {
    0: (0x14, 0x16, 0x20),
    1: (0x6e, 0x82, 0x94),
    2: (0x9b, 0xaf, 0xc4),
    3: (0xbe, 0xd0, 0xe2),
    4: (0x3a, 0x42, 0x50),
    5: (0x2a, 0x30, 0x40),
}


def render_iso(heights, out_path: str | Path, cell_px: int = 18,
               background: tuple[int, int, int] = (16, 18, 24),
               margin: int = 12,
               utilities: list | None = None,
               interactables: list | None = None,
               supersample: int = 2) -> bool:
    """Render an isometric voxel preview.

    `supersample`: render at this multiple of the target pixel size, then
    downsample with bilinear filtering. supersample=2 is the AA sweet
    spot — cleaner edges, ~30% more time. supersample=1 = no AA.
    """
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return False
    # Render-time cell size is supersampled; we rescale at save.
    render_px = cell_px * max(1, supersample)
    render_margin = margin * max(1, supersample)
    cell_px = render_px       # used everywhere below
    margin = render_margin

    rows = len(heights)
    cols = max((len(r) for r in heights), default=0) if rows else 0
    if rows == 0 or cols == 0: return False

    def cell_h(r: int, c: int) -> int:
        if r < 0 or r >= rows: return 0
        row = heights[r]
        if c < 0 or c >= len(row): return 0
        v = row[c]
        if isinstance(v, int): return max(0, min(5, v))
        try: return max(0, min(5, int(str(v))))
        except Exception: return 0

    # Compute screen extents over all cube corners we'll draw.
    pts: list[tuple[float, float]] = []
    for r in range(rows):
        for c in range(cols):
            h = cell_h(r, c)
            for dx, dy, dz in (
                (0, 0, 0), (1, 0, 0), (0, 0, 1), (1, 0, 1),
                (0, h, 0), (1, h, 0), (0, h, 1), (1, h, 1),
            ):
                pts.append(project(c + dx, dy, r + dz, cell_px))
    if not pts:
        pts.append((0.0, 0.0))
    min_x = min(p[0] for p in pts)
    max_x = max(p[0] for p in pts)
    min_y = min(p[1] for p in pts)
    max_y = max(p[1] for p in pts)
    width = int(max_x - min_x) + 2 * margin
    height = int(max_y - min_y) + 2 * margin

    img = Image.new("RGB", (width, height), background)
    draw = ImageDraw.Draw(img)
    ox = margin - min_x
    oy = margin - min_y

    def to_screen(wx: float, wy: float, wz: float) -> tuple[float, float]:
        sx, sy = project(wx, wy, wz, cell_px)
        return (sx + ox, sy + oy)

    # Painter's algorithm — far cubes first. Iso depth ≈ x + z, larger
    # values are farther; we want to draw THEM FIRST so near ones overpaint.
    order: list[tuple[int, int]] = sorted(
        ((r, c) for r in range(rows) for c in range(cols)),
        key=lambda rc: -(rc[1] + rc[0]),   # farthest (largest x+z) first
    )

    for r, c in order:
        h = cell_h(r, c)
        if h <= 0:
            continue
        base = HEIGHT_BASE.get(h, HEIGHT_BASE[1])
        outline = shade(base, 0.45)

        # ONE solid prism per cell, but skip faces that are HIDDEN by an
        # equal-or-taller neighbour. A wall composed of identical cells
        # then reads as a single block silhouetted against its lower
        # neighbours, with no internal grid lines.
        right_neighbour_h = cell_h(r, c + 1)        # blocks our +X face
        left_neighbour_h  = cell_h(r + 1, c)        # blocks our +Z face

        c1 = (c + 1, 0, r); c2 = (c, 0, r + 1); c3 = (c + 1, 0, r + 1)
        t0 = (c, h, r); t1 = (c + 1, h, r)
        t2 = (c, h, r + 1); t3 = (c + 1, h, r + 1)

        # The right face is visible only above the neighbour's height,
        # so its bottom is at y=neighbour_h (clamped to 0).
        if right_neighbour_h < h:
            y_floor = max(0, right_neighbour_h)
            br_lo = (c + 1, y_floor, r)
            br_hi = (c + 1, y_floor, r + 1)
            right_pts = [to_screen(*br_lo), to_screen(*br_hi),
                         to_screen(*t3), to_screen(*t1)]
            draw.polygon(right_pts, fill=shade(base, 0.78), outline=outline)
        if left_neighbour_h < h:
            y_floor = max(0, left_neighbour_h)
            bl_lo = (c, y_floor, r + 1)
            bl_hi = (c + 1, y_floor, r + 1)
            left_pts = [to_screen(*bl_lo), to_screen(*bl_hi),
                        to_screen(*t3), to_screen(*t2)]
            draw.polygon(left_pts, fill=shade(base, 0.62), outline=outline)
        # Top face: filled with no outline, then silhouette edges added
        # only where the neighbour is lower (so equal-height neighbours
        # form a single plateau without internal grid lines).
        top_pts = [to_screen(*t0), to_screen(*t1), to_screen(*t3), to_screen(*t2)]
        draw.polygon(top_pts, fill=shade(base, 1.15))
        north_h = cell_h(r - 1, c)
        west_h  = cell_h(r, c - 1)
        # north edge (t0 → t1)
        if north_h < h:
            draw.line([to_screen(*t0), to_screen(*t1)], fill=outline, width=1)
        # west edge (t0 → t2)
        if west_h < h:
            draw.line([to_screen(*t0), to_screen(*t2)], fill=outline, width=1)
        # east edge (t1 → t3) — only if right neighbour lower
        if right_neighbour_h < h:
            draw.line([to_screen(*t1), to_screen(*t3)], fill=outline, width=1)
        # south edge (t2 → t3) — only if south neighbour lower
        if left_neighbour_h < h:
            draw.line([to_screen(*t2), to_screen(*t3)], fill=outline, width=1)

    # ── Markers on top of voxels (matches the Three.js 3D viewer) ────
    def cell_str(layer, r: int, c: int) -> str:
        if layer is None: return ""
        if r < 0 or r >= len(layer): return ""
        row = layer[r]
        if c < 0 or c >= len(row): return ""
        v = row[c]
        return str(v).strip() if v is not None else ""

    def marker_centre(c: int, r: int, h: int) -> tuple[float, float]:
        return to_screen(c + 0.5, h, r + 0.5)

    # Pass marker positions in the same painter order so they don't get
    # overpainted by later voxels.
    # Marker palette + sizes match /map-3d/[name]/page.tsx:
    #   spawn  = 0x22c55e cylinder radius 0.25, height 1.2
    #   tele   = 0xf59e0b cylinder radius 0.30, height 0.20
    #   artif  = 0x60a5fa sphere   radius 0.18
    spawn_rgb = (0x22, 0xc5, 0x5e)
    tele_rgb  = (0xf5, 0x9e, 0x0b)
    art_rgb   = (0x60, 0xa5, 0xfa)
    for r, c in order:
        h = cell_h(r, c)
        cx, cy = marker_centre(c, r, max(1, h))
        # Spawn — green pillar standing on the cell top, ~1.2 cells tall.
        if cell_str(utilities, r, c) in ("s", "sp"):
            half_w = cell_px * 0.22                    # was 0.18 — bolder
            top_y = cy - cell_px * 1.3                  # was 1.2 — taller
            # Pillar body — a vertical rectangle outlined.
            draw.rectangle([cx - half_w, top_y, cx + half_w, cy],
                           fill=spawn_rgb, outline=shade(spawn_rgb, 0.35))
            r1 = half_w
            draw.ellipse([cx - r1, top_y - r1 * 0.5, cx + r1, top_y + r1 * 0.5],
                         fill=shade(spawn_rgb, 1.15), outline=shade(spawn_rgb, 0.35))
            draw.ellipse([cx - r1, cy - r1 * 0.5, cx + r1, cy + r1 * 0.5],
                         fill=shade(spawn_rgb, 0.6), outline=shade(spawn_rgb, 0.35))
        elif cell_str(utilities, r, c) == "t":
            r1 = cell_px * 0.42                         # was 0.34 — bigger
            draw.ellipse([cx - r1, cy - r1 * 0.55, cx + r1, cy + r1 * 0.55],
                         fill=tele_rgb, outline=shade(tele_rgb, 0.4))
            # Inner ring so the teleport reads as a portal, not a coin.
            r2 = r1 * 0.5
            draw.ellipse([cx - r2, cy - r2 * 0.55, cx + r2, cy + r2 * 0.55],
                         fill=shade(tele_rgb, 0.55), outline=None)
        # Artifact — small blue sphere floating just above the cube top.
        if interactables is not None:
            tok = cell_str(interactables, r, c)
            if tok and tok != " ":
                r1 = cell_px * 0.22                     # was 0.18 — bolder
                lift = cell_px * 0.35
                draw.ellipse([cx - r1, cy - r1 - lift,
                              cx + r1, cy + r1 - lift],
                             fill=art_rgb, outline=shade(art_rgb, 0.5))
                # Tiny highlight dot for readability.
                hr = r1 * 0.35
                draw.ellipse([cx - hr * 1.2, cy - r1 * 0.6 - lift,
                              cx + hr * 0.4, cy - r1 * 0.05 - lift],
                             fill=shade(art_rgb, 1.5), outline=None)

    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    if supersample > 1:
        # Bilinear downsample → cheap, effective AA.
        target_w = max(1, img.width // supersample)
        target_h = max(1, img.height // supersample)
        img = img.resize((target_w, target_h), Image.BILINEAR)
    img.save(out_path)
    return True
