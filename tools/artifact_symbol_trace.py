"""Artifact symbols traced from captures, drawn like the badge coins' symbols (pilot, 2026-11-18).

Palle asked for a symbol for every artifact, traced from its capture, living on the badges first. A badge symbol sits
in the coin's upper middle (badge-coins.ts SYMBOL_ZONE: x 25-75, y 8-50 on a 100-unit coin), drawn in the family
colour and ink with strokes of 1.2-2.6 units. This tool reads an artifact's multi-angle capture, separates the subject
from the flat capture background, and keeps a few marker strokes: the silhouette (filled in the family colour, inked)
and the longest inner edges (ink only). Everything is written in coin units, so a face can drop it straight into the
symbol zone.

  python tools/artifact_symbol_trace.py <token> [<token> ...] [--out=ada_run/artifact_symbols/pilot] [--angle=front]

Writes <out>/symbols.json (token -> angle, fill polygons, inner lines, subject share) and <out>/sheet.png (each
capture beside its symbol on a coin). Tokens with no capture are listed, not guessed.
"""
import json
import os
import sys

import cv2
import numpy as np

MS = os.path.expandvars(r'%APPDATA%/Godot/app_userdata/Ada Research Zero One/multi_shots')
ZONE = (30.0, 13.0, 70.0, 50.0)         # inside badge-coins.ts SYMBOL_ZONE (25-75 x 8-50), clear of the round rim
ANGLES = ['front', 'left', 'right', 'front_mid', 'left_mid']
PINK, INK = (169, 77, 233), (41, 33, 29)   # BGR: the complex family's pink, the coins' ink


RENDERS = 'ada_run/artifact_symbols/renders'    # three.js renders from the encyclopedia's /artifact-symbols/render


def subject_mask(img, hud=True):
    """Pixels that differ from the capture's flat background, the HUD corner removed."""
    h, w = img.shape[:2]
    border = np.concatenate([img[:6].reshape(-1, 3), img[-6:].reshape(-1, 3), img[:, :6].reshape(-1, 3), img[:, -6:].reshape(-1, 3)])
    bg = np.median(border, axis=0)
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB).astype(np.int16)
    bg_lab = cv2.cvtColor(bg.reshape(1, 1, 3).astype(np.uint8), cv2.COLOR_BGR2LAB).astype(np.int16)[0, 0]
    diff = np.abs(lab - bg_lab).max(axis=2)
    mask = (diff > 22).astype(np.uint8) * 255
    if hud:
        mask[int(h * 0.94):, : int(w * 0.18)] = 0                 # the HUD line in the lower left of a capture
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((9, 9), np.uint8))
    n, lab_im, stats, _ = cv2.connectedComponentsWithStats(mask)
    if n <= 1:
        return mask * 0
    areas = stats[1:, cv2.CC_STAT_AREA]
    keep = [i + 1 for i, a in enumerate(areas) if a >= max(areas.max() * 0.04, 120)]
    return np.isin(lab_im, keep).astype(np.uint8) * 255


def best_capture(token, angle=None, source='captures'):
    if source == 'renders':                                   # one picture per model, the subject alone on white
        p = os.path.join(RENDERS, f'{token}.png')
        img = cv2.imread(p) if os.path.isfile(p) else None
        if img is None:
            return None
        m = subject_mask(img, hud=False)
        share = float((m > 0).mean())
        return (share if share >= 0.005 else -1, 'three.js', img, m, share)
    folder = os.path.join(MS, token)
    if not os.path.isdir(folder):
        return None
    tries = [angle] if angle else ANGLES
    best = None
    for a in tries:
        p = os.path.join(folder, f'{a}.png')
        img = cv2.imread(p) if os.path.isfile(p) else None
        if img is None:
            continue
        m = subject_mask(img)
        share = float((m > 0).mean())
        # a readable silhouette: big enough to trace, not filling the frame; front wins ties
        score = share if 0.01 <= share <= 0.7 else -1
        if best is None or score > best[0] * 1.15:
            best = (score, a, img, m, share)
    return best


def trace(img, mask):
    h, w = mask.shape
    outer, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    outer = sorted(outer, key=cv2.contourArea, reverse=True)[:4]
    fills = []
    for c in outer:
        if cv2.contourArea(c) < 0.02 * cv2.contourArea(outer[0]):
            continue
        eps = 0.006 * cv2.arcLength(c, True)
        approx = cv2.approxPolyDP(c, eps, True).reshape(-1, 2)
        while len(approx) > 40:
            eps *= 1.4
            approx = cv2.approxPolyDP(c, eps, True).reshape(-1, 2)
        fills.append(approx.astype(float))
    # inner edges: shading and part boundaries inside the silhouette, the longest few
    x, y, bw, bh = cv2.boundingRect(mask)
    diag = (bw * bw + bh * bh) ** 0.5
    inner = cv2.erode(mask, np.ones((11, 11), np.uint8))
    gray = cv2.GaussianBlur(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), (5, 5), 0)
    edges = cv2.Canny(gray, 30, 90) & inner
    # a textured surface (patterns, screens, text) gives edges everywhere: then the silhouette alone is the symbol
    density = float((edges > 0).sum()) / max(1, int((inner > 0).sum()))
    if density > 0.06:
        return fills, [], (x, y, bw, bh), density
    edges = cv2.dilate(edges, np.ones((3, 3), np.uint8))
    cs, _ = cv2.findContours(edges, cv2.RETR_LIST, cv2.CHAIN_APPROX_NONE)
    lines = []
    for c in sorted(cs, key=lambda c: cv2.arcLength(c, False), reverse=True)[:3]:
        if cv2.arcLength(c, False) < 0.35 * diag:            # a dilated edge is counted twice round: half a diagonal of line
            break
        pts = cv2.approxPolyDP(c, 0.015 * diag, False).reshape(-1, 2)
        if len(pts) > 24:                                     # a wandering edge is texture, not a part boundary
            continue
        # a dilated edge comes back as a thin loop: keep the half that runs out
        half = pts[: max(2, len(pts) // 2 + 1)]
        lines.append(half.astype(float))
    return fills, lines, (x, y, bw, bh), density


def flags(img, mask, box, share, density):
    """Why a traced symbol should be looked at before it is used (empty = clean)."""
    h, w = mask.shape
    x, y, bw, bh = box
    out = []
    if x <= 2 or y <= 2 or x + bw >= w - 2 or y + bh >= h - 2:
        out.append('cut by the frame')
    if share > 0.45:
        out.append('fills the frame')
    n = cv2.connectedComponents(mask)[0] - 1
    if n > 3:
        out.append(f'{n} separate parts')
    if density > 0.06:
        out.append('textured: silhouette only')
    return out


def to_zone(fills, lines, box):
    x, y, bw, bh = box
    zx0, zy0, zx1, zy1 = ZONE
    s = min((zx1 - zx0) / bw, (zy1 - zy0) / bh)
    ox = zx0 + ((zx1 - zx0) - bw * s) / 2 - x * s
    oy = zy0 + ((zy1 - zy0) - bh * s) / 2 - y * s
    f = lambda arr: [[round(px * s + ox, 1), round(py * s + oy, 1)] for px, py in arr]
    return [f(a) for a in fills], [f(a) for a in lines]


def draw_coin(sym, token, size=240):
    k = size / 100.0
    im = np.full((size, size, 3), 248, np.uint8)
    P = lambda pts: (np.array(pts) * k).astype(np.int32)
    cv2.circle(im, (size // 2, size // 2), int(47 * k), PINK, int(4.5 * k))
    for poly in sym['fill']:
        cv2.fillPoly(im, [P(poly)], (226, 196, 246))
        cv2.polylines(im, [P(poly)], True, INK, max(1, int(1.6 * k)), cv2.LINE_AA)
    for ln in sym['lines']:
        cv2.polylines(im, [P(ln)], False, INK, max(1, int(1.2 * k)), cv2.LINE_AA)
    if sym.get('flags'):
        cv2.putText(im, 'LOOK: ' + sym['flags'][0][:22], (int(18 * k), int(78 * k)), cv2.FONT_HERSHEY_SIMPLEX, 0.36, (40, 40, 200), 1, cv2.LINE_AA)
    label = token.upper().replace('_', ' ')[:18]
    (tw, _), _ = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.42, 1)
    cv2.putText(im, label, ((size - tw) // 2, int(63 * k)), cv2.FONT_HERSHEY_SIMPLEX, 0.42, INK, 1, cv2.LINE_AA)
    return im


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    opt = dict(a[2:].split('=', 1) for a in sys.argv[1:] if a.startswith('--') and '=' in a)
    if 'list' in opt:                                         # a JSON array of tokens
        args += json.load(open(opt['list'], encoding='utf8'))
    out = opt.get('out', 'ada_run/artifact_symbols/pilot')
    os.makedirs(out, exist_ok=True)
    result, missing, cells = {}, [], []
    for token in args:
        got = best_capture(token, opt.get('angle'), opt.get('source', 'captures'))
        if not got or got[0] < 0:
            missing.append(token)
            continue
        _, angle, img, mask, share = got
        fills, lines, box, density = trace(img, mask)
        zf, zl = to_zone(fills, lines, box)
        sym = {'angle': angle, 'subject_share': round(share, 4), 'fill': zf, 'lines': zl,
               'points': sum(len(p) for p in zf) + sum(len(p) for p in zl), 'flags': flags(img, mask, box, share, density)}
        result[token] = sym
        x, y, bw, bh = box
        pad = int(0.08 * max(bw, bh))
        crop = img[max(0, y - pad): y + bh + pad, max(0, x - pad): x + bw + pad]
        sc = 240 / max(crop.shape[:2])
        crop = cv2.resize(crop, (max(1, int(crop.shape[1] * sc)), max(1, int(crop.shape[0] * sc))), interpolation=cv2.INTER_AREA)
        left = np.full((240, 240, 3), 255, np.uint8)
        oy, ox = (240 - crop.shape[0]) // 2, (240 - crop.shape[1]) // 2
        left[oy: oy + crop.shape[0], ox: ox + crop.shape[1]] = crop
        cells.append(np.hstack([left, np.full((240, 8, 3), 255, np.uint8), draw_coin(sym, token)]))
    json.dump({'_doc': 'pilot: artifact symbols traced from captures, in badge coin units (SYMBOL_ZONE 25-75 x 8-50)',
               'symbols': result, 'missing_capture': missing}, open(os.path.join(out, 'symbols.json'), 'w'), indent=1)
    if cells:
        cols, per = int(opt.get('cols', 2)), int(opt.get('per_sheet', 40))
        pages = [cells[i:i + per] for i in range(0, len(cells), per)]
        for pi, page in enumerate(pages):
            while len(page) % cols:
                page.append(np.full_like(cells[0], 255))
            rows = [np.hstack([np.pad(c, ((10, 10), (10, 10), (0, 0)), constant_values=255) for c in page[i:i + cols]]) for i in range(0, len(page), cols)]
            name = 'sheet.png' if len(pages) == 1 else f'sheet_{pi + 1:02d}.png'
            cv2.imwrite(os.path.join(out, name), np.vstack(rows))
    print(f'{len(result)} traced, {len(missing)} without a capture: {missing}')
    for t, s in result.items():
        print(f"  {t:24} {s['angle']:10} subject {s['subject_share']:.3f}  {len(s['fill'])} fill, {len(s['lines'])} lines, {s['points']} points  {'; '.join(s['flags']) or 'clean'}")


if __name__ == '__main__':
    main()
