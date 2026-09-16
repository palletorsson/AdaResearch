"""Reapply the two verified head-fade fixes after updating the ignored XRTools addon.

Use --check to verify without editing, or --apply to patch the known source.
Unexpected upstream changes fail closed; no fuzzy matching or whole-file replacement.
"""
import argparse
from pathlib import Path

TARGET = Path(__file__).resolve().parents[1] / 'addons/godot-xr-tools/player/player_body.gd'
PATCHES = [
    (
        '\t\tvar safe := min(_head_shape_cast.get_closest_collision_safe_fraction(), max_head_distance / target_move_distance)',
        '\t\t# A stationary, non-colliding cast can report a zero safe fraction.\n'
        '\t\t# That is not a head obstruction (and dividing by zero is undefined).\n'
        '\t\tvar safe := 1.0\n'
        '\t\tif _head_shape_cast.is_colliding():\n'
        '\t\t\tsafe = _head_shape_cast.get_closest_collision_safe_fraction()\n'
        '\t\tif target_move_distance > 0.0001:\n'
        '\t\t\tsafe = minf(safe, max_head_distance / target_move_distance)',
    ),
    (
        '\t\t_fade_value = max(_fade_value + delta * 3.0, 0.0)',
        '\t\t# Opacity cannot exceed one. Accumulating beyond it kept the headset\n'
        '\t\t# black for seconds after teleporting out of a long head collision.\n'
        '\t\t_fade_value = clampf(_fade_value + delta * 3.0, 0.0, 1.0)',
    ),
]


def patch_text(text):
    for before, after in PATCHES:
        if after in text:
            continue
        if text.count(before) != 1:
            raise ValueError('XRTools source differs from the reviewed version; inspect before patching.')
        text = text.replace(before, after, 1)
    return text


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true')
    mode.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    raw = TARGET.read_bytes()
    original = raw.decode('utf-8').replace('\r\n', '\n')
    updated = patch_text(original)
    if original == updated:
        print('XRTools head-fade fixes are installed.')
    elif args.check:
        raise SystemExit('XRTools needs the head-fade fixes: run tools/patch_xrtools_head_fade.py --apply')
    else:
        newline = '\r\n' if b'\r\n' in raw else '\n'
        TARGET.write_bytes(updated.replace('\n', newline).encode('utf-8'))
        print('Applied the two XRTools head-fade fixes.')
