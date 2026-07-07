"""tools/render_beat_score.py — render all beats files as a horizontal score.

For every commons/maps/sequences/*.beats.json file, draw the beats as a
horizontal track. Each beat is a coloured block (by register) sized by
intensity, labelled by role. Bleed_from / bleed_to arrows connect tracks.

Output: doc/placement_research/beat_score.svg
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
SEQ_DIR = ROOT / "commons" / "maps" / "sequences"
OUT = ROOT / "doc" / "placement_research" / "beat_score.svg"

REGISTER_COLOR = {
    "teaching":     "#3A7BFF",
    "exploring":    "#7DFFA8",
    "resting":      "#6A6A75",
    "refusing":     "#E63946",
    "synthesizing": "#9B5DE5",
    "catalyst":     "#F4A261",
    "structural":   "#FBE38A",
    "reflecting":   "#A5C8FF",
}

INTENSITY_HEIGHT = {"low": 20, "medium": 36, "high": 52}


def load_all_beats() -> dict[str, dict]:
    out: dict[str, dict] = {}
    for bf in sorted(SEQ_DIR.glob("*.beats.json")):
        try:
            with open(bf, "r", encoding="utf-8") as f:
                data = json.load(f)
            seq = data.get("_meta", {}).get("sequence") or bf.stem.replace(".beats", "")
            out[seq] = data
        except (json.JSONDecodeError, OSError):
            continue
    return out


def render(all_beats: dict[str, dict]) -> str:
    seq_order = list(all_beats.keys())
    track_h = 80
    track_gap = 16
    margin_l = 180
    margin_r = 40
    margin_t = 90
    margin_b = 200

    max_beats = max((len(d.get("beats", [])) for d in all_beats.values()), default=14)
    beat_w = 90
    canvas_w = margin_l + max_beats * beat_w + margin_r
    canvas_h = margin_t + len(seq_order) * (track_h + track_gap) + margin_b

    parts = [f'<rect width="{canvas_w}" height="{canvas_h}" fill="#0A0A0E"/>']
    parts.append(f'<text x="20" y="36" font-family="ui-monospace" font-size="20" '
                 f'font-weight="700" fill="#FFFFFF">Spine beat score</text>')
    parts.append(f'<text x="20" y="58" font-family="ui-monospace" font-size="11" '
                 f'fill="#9090A0">{len(seq_order)} sequence(s) with beats files · '
                 f'block colour = register · block height = intensity · '
                 f'dashed arrows = bleeds</text>')

    # Build beat position index for arrow drawing
    beat_pos: dict[tuple[str, str], tuple[float, float]] = {}   # (seq, beat_id) → (x, y)
    track_y: dict[str, float] = {}

    for ti, seq in enumerate(seq_order):
        data = all_beats[seq]
        beats = data.get("beats", [])
        ty = margin_t + ti * (track_h + track_gap)
        track_y[seq] = ty

        # Sequence label on left
        phase = data.get("_meta", {}).get("phase", "")
        parts.append(f'<text x="{margin_l - 10}" y="{ty + track_h / 2}" '
                     f'font-family="ui-monospace" font-size="12" font-weight="700" '
                     f'fill="#E8E8EE" text-anchor="end">{seq}</text>')
        parts.append(f'<text x="{margin_l - 10}" y="{ty + track_h / 2 + 14}" '
                     f'font-family="ui-monospace" font-size="9" '
                     f'fill="#9090A0" text-anchor="end">{phase}</text>')

        # Track baseline
        parts.append(f'<line x1="{margin_l}" y1="{ty + track_h - 4}" '
                     f'x2="{margin_l + max_beats * beat_w}" y2="{ty + track_h - 4}" '
                     f'stroke="#3A3A45" stroke-width="0.5"/>')

        # Beats
        for bi, b in enumerate(beats):
            bx = margin_l + bi * beat_w + 4
            by_base = ty + track_h - 4
            intensity = b.get("intensity", "medium")
            bh = INTENSITY_HEIGHT.get(intensity, 36)
            by = by_base - bh
            register = b.get("register", "teaching")
            col = REGISTER_COLOR.get(register, "#888888")
            role = b.get("role", "?")
            bid = b.get("id", "?")
            n_maps = len(b.get("maps") or [])

            # Block
            unfilled = (n_maps == 0 and role not in ("PAUSE", "META", "GATEWAY"))
            stroke = "#E63946" if unfilled else col
            stroke_width = 2.5 if unfilled else 1.0
            parts.append(f'<rect x="{bx}" y="{by}" width="{beat_w - 8}" height="{bh}" '
                         f'fill="{col}" fill-opacity="0.7" '
                         f'stroke="{stroke}" stroke-width="{stroke_width}" rx="3"/>')
            # Role text inside block
            parts.append(f'<text x="{bx + (beat_w - 8) / 2}" y="{by + 12}" '
                         f'font-family="ui-monospace" font-size="9" font-weight="700" '
                         f'fill="#0A0A0E" text-anchor="middle">{role}</text>')
            # Beat ID + map count below
            parts.append(f'<text x="{bx + (beat_w - 8) / 2}" y="{by_base + 11}" '
                         f'font-family="ui-monospace" font-size="9" '
                         f'fill="#9090A0" text-anchor="middle">{bid} · {n_maps}m</text>')

            # Save position for arrow drawing (centre of block)
            beat_pos[(seq, bid)] = (bx + (beat_w - 8) / 2, by + bh / 2)

    # Bleed arrows
    for seq, data in all_beats.items():
        for b in data.get("beats", []):
            bid = b.get("id", "?")
            src = beat_pos.get((seq, bid))
            if not src: continue
            for target_seq in (b.get("bleed_to") or []):
                # Try to find a beat in target_seq whose bleed_from contains seq
                target_beats = all_beats.get(target_seq, {}).get("beats", [])
                target_pos = None
                for tb in target_beats:
                    if seq in (tb.get("bleed_from") or []):
                        target_pos = beat_pos.get((target_seq, tb.get("id")))
                        break
                # Fallback: any beat in target track
                if not target_pos and target_beats:
                    target_pos = beat_pos.get((target_seq, target_beats[0].get("id")))
                if target_pos:
                    x1, y1 = src; x2, y2 = target_pos
                    parts.append(f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
                                 f'stroke="#FBE38A" stroke-width="1.2" stroke-dasharray="3,3" '
                                 f'stroke-opacity="0.6"/>')
                    # Arrowhead approximation
                    parts.append(f'<circle cx="{x2}" cy="{y2}" r="2.5" fill="#FBE38A"/>')
            # Implicit reverse arrows: this beat has bleed_from listing other seqs
            for src_seq in (b.get("bleed_from") or []):
                if src_seq in all_beats: continue  # symmetric; skip duplicate render
                # Source sequence has no beats file — draw a hint pointing to a phantom
                parts.append(f'<text x="{src[0]}" y="{src[1] - 20}" '
                             f'font-family="ui-monospace" font-size="8" '
                             f'fill="#FBE38A" text-anchor="middle" fill-opacity="0.6">'
                             f'← {src_seq}</text>')

    # Legend
    leg_y = canvas_h - margin_b + 24
    parts.append(f'<text x="20" y="{leg_y}" font-family="ui-monospace" font-size="12" '
                 f'font-weight="700" fill="#E8E8EE">legend</text>')
    y = leg_y + 20
    for reg, col in REGISTER_COLOR.items():
        parts.append(f'<rect x="20" y="{y}" width="14" height="14" fill="{col}" '
                     f'fill-opacity="0.7"/>')
        parts.append(f'<text x="40" y="{y + 11}" font-family="ui-monospace" '
                     f'font-size="11" fill="#E8E8EE">{reg}</text>')
        y += 18

    parts.append(f'<text x="220" y="{leg_y + 20}" font-family="ui-monospace" '
                 f'font-size="11" fill="#9090A0">block height = intensity (high/med/low)</text>')
    parts.append(f'<text x="220" y="{leg_y + 38}" font-family="ui-monospace" '
                 f'font-size="11" fill="#9090A0">red border = unfilled (declared intent, no map)</text>')
    parts.append(f'<text x="220" y="{leg_y + 56}" font-family="ui-monospace" '
                 f'font-size="11" fill="#FBE38A">yellow dashes = bleed (cross-sequence content)</text>')

    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{canvas_w}" height="{canvas_h}" '
            f'viewBox="0 0 {canvas_w} {canvas_h}">{"".join(parts)}</svg>')


def main():
    all_beats = load_all_beats()
    if not all_beats:
        print("no beats files found")
        return
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(render(all_beats), encoding="utf-8")
    print(f"wrote {OUT.relative_to(ROOT)}")
    print(f"  {len(all_beats)} sequence(s):")
    for seq, data in all_beats.items():
        beats = data.get("beats", [])
        print(f"    {seq}: {len(beats)} beats")


if __name__ == "__main__":
    main()
