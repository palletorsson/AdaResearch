#!/usr/bin/env python3
"""Batch-add apply_grid_config() stubs to algorithm .gd files that extend Node3D (or subclasses)."""

import os
import re
import sys

ALGORITHMS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "algorithms")

# Types that are NOT Node3D-derived — skip these
NON_3D_TYPES = {
    "Node2D", "Control", "Node", "RefCounted", "Resource",
    "EditorScript", "SceneTree",
    # Control subclasses
    "HBoxContainer", "VBoxContainer", "PanelContainer", "Panel",
    "MarginContainer", "CenterContainer", "GridContainer",
    "SubViewport", "TextureRect", "ColorRect",
    "Label", "RichTextLabel", "Button", "BaseButton",
    "LineEdit", "TextEdit", "OptionButton", "CheckBox",
    # Node2D subclasses
    "Sprite2D", "AnimatedSprite2D", "Line2D", "Path2D",
    "TileMap", "Camera2D", "CollisionObject2D",
    "CharacterBody2D", "RigidBody2D", "StaticBody2D", "Area2D",
}

STUB = '''
func apply_grid_config(config: Dictionary) -> void:
\tpass
'''

def get_extends_type(content):
    """Extract the extends type from the first extends line."""
    for line in content.split('\n'):
        line = line.strip()
        if line.startswith('extends '):
            ext = line[8:].strip()
            # Could be a quoted path like "res://..."
            if ext.startswith('"') or ext.startswith("'"):
                return ext  # script path
            return ext
    return None

def has_apply_grid_config(content):
    return 'func apply_grid_config' in content

def is_3d_type(ext_type):
    """Return True if this extends type is likely a Node3D subclass."""
    if ext_type is None:
        return False
    # Script paths — assume 3D unless we know otherwise
    if ext_type.startswith('"') or ext_type.startswith("'"):
        return True
    if ext_type in NON_3D_TYPES:
        return False
    # Everything else under algorithms is likely 3D
    return True

def add_stub(filepath):
    """Add apply_grid_config stub to end of file. Returns True if modified."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    ext_type = get_extends_type(content)
    if not is_3d_type(ext_type):
        return False, f"skip-non3d ({ext_type})"

    if has_apply_grid_config(content):
        return False, "skip-already-has"

    # Add stub at end of file
    # Ensure file ends with newline before adding
    if not content.endswith('\n'):
        content += '\n'

    content += STUB

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

    return True, "added"

def main():
    modified = 0
    skipped_non3d = 0
    skipped_has = 0
    errors = 0

    # Collect category stats
    category_counts = {}

    for root, dirs, files in os.walk(ALGORITHMS_DIR):
        for fname in sorted(files):
            if not fname.endswith('.gd'):
                continue
            filepath = os.path.join(root, fname)
            relpath = os.path.relpath(filepath, ALGORITHMS_DIR)
            category = relpath.split(os.sep)[0]

            try:
                success, reason = add_stub(filepath)
                if success:
                    modified += 1
                    category_counts[category] = category_counts.get(category, 0) + 1
                elif reason == "skip-already-has":
                    skipped_has += 1
                else:
                    skipped_non3d += 1
            except Exception as e:
                print(f"ERROR: {relpath}: {e}", file=sys.stderr)
                errors += 1

    print(f"\n=== Results ===")
    print(f"Modified:       {modified}")
    print(f"Already had:    {skipped_has}")
    print(f"Skipped non-3D: {skipped_non3d}")
    print(f"Errors:         {errors}")
    print(f"\nBy category:")
    for cat in sorted(category_counts.keys()):
        print(f"  {cat}: {category_counts[cat]}")

if __name__ == "__main__":
    main()
