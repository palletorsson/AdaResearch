#!/usr/bin/env python3
"""Fix duplicate UIDs in Godot scene files"""

import re
from pathlib import Path

# Define unique UIDs for each primitive
uid_mapping = {
    "commons/primitives/tetrahedron/tetrahedron.tscn": "uid://b4tetrahedron4",
    "commons/primitives/octahedron/octahedron.tscn": "uid://b8octahedron8",
    "commons/primitives/cube/cube.tscn": "uid://b6cubehexahedr",
}

# Define what each grab file should reference
grab_references = {
    "commons/primitives/tetrahedron/grab_tetrahedron.tscn": {
        "uid": "uid://b4tetrahedron4",
        "path": "res://commons/primitives/tetrahedron/tetrahedron.tscn"
    },
    "commons/primitives/octahedron/grab_octahedron.tscn": {
        "uid": "uid://b8octahedron8",
        "path": "res://commons/primitives/octahedron/octahedron.tscn"
    },
    "commons/primitives/cube/grab_cube_show.tscn": {
        "uid": "uid://b6cubehexahedr",
        "path": "res://commons/primitives/cube/cube.tscn"
    },
}

def fix_primitive_uid(file_path, new_uid):
    """Replace the UID in the first line of a scene file"""
    content = file_path.read_text()
    content = re.sub(
        r'\[gd_scene load_steps=\d+ format=\d+ uid="uid://[^"]+"\]',
        f'[gd_scene load_steps=2 format=3 uid="{new_uid}"]',
        content,
        count=1
    )
    file_path.write_text(content)
    print(f"✓ Updated {file_path.name} → {new_uid}")

def fix_grab_reference(file_path, new_uid, new_path):
    """Fix the ExtResource reference in grab files"""
    content = file_path.read_text()
    # Find and replace the problematic ExtResource line
    content = re.sub(
        r'\[ext_resource type="PackedScene" uid="uid://[^"]+" path="res://commons/primitives/[^"]+" id="3_[^"]+"\]',
        f'[ext_resource type="PackedScene" uid="{new_uid}" path="{new_path}" id="3_' + file_path.stem[-5:] + '"]',
        content
    )
    file_path.write_text(content)
    print(f"✓ Updated {file_path.name} reference → {new_path}")

if __name__ == "__main__":
    base_path = Path(__file__).parent

    print("=" * 60)
    print("FIXING DUPLICATE UIDs")
    print("=" * 60)
    print("\nStep 1: Fixing primitive scene UIDs...")
    print("-" * 60)

    for file_rel, uid in uid_mapping.items():
        file_path = base_path / file_rel
        if file_path.exists():
            fix_primitive_uid(file_path, uid)
        else:
            print(f"✗ Not found: {file_path}")

    print("\nStep 2: Fixing grab file references...")
    print("-" * 60)

    for file_rel, ref_info in grab_references.items():
        file_path = base_path / file_rel
        if file_path.exists():
            fix_grab_reference(file_path, ref_info["uid"], ref_info["path"])
        else:
            print(f"✗ Not found: {file_path}")

    print("\n" + "=" * 60)
    print("DONE! Now:")
    print("1. Close Godot if it's open")
    print("2. Delete the .godot folder")
    print("3. Reopen your project in Godot")
    print("=" * 60)
