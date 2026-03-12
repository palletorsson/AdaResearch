#!/usr/bin/env python3
"""Generate README.md files for commons/artifacts/ directories.

Reads each artifact's .gd source (header comments, exports, class_name)
and registry entry to produce a consistent README.
"""

import json
import os
import glob
import re
import sys

ARTIFACTS_DIR = "commons/artifacts"
REGISTRY_DIR = "commons/artifacts/registry"
GRID_ARTIFACTS = "commons/artifacts/grid_artifacts.json"
SKIP_DIRS = {"catalog", "registry", "placeholders"}


def load_registries():
    """Load all artifact registry entries into a dict keyed by lookup_name."""
    registries = {}

    # Registry JSON files
    for f in glob.glob(os.path.join(REGISTRY_DIR, "*.json")):
        with open(f, encoding="utf-8") as fh:
            data = json.load(fh)
            arts = data.get("artifacts", data)
            if isinstance(arts, dict):
                for k, v in arts.items():
                    if isinstance(v, dict):
                        registries[v.get("lookup_name", k)] = v

    # Legacy grid_artifacts.json
    if os.path.exists(GRID_ARTIFACTS):
        with open(GRID_ARTIFACTS, encoding="utf-8") as fh:
            data = json.load(fh)
            arts = data.get("artifacts", data)
            if isinstance(arts, dict):
                for k, v in arts.items():
                    if isinstance(v, dict):
                        ln = v.get("lookup_name", k)
                        if ln not in registries:
                            registries[ln] = v

    return registries


def parse_gd_file(gd_path):
    """Extract useful info from a GDScript file."""
    with open(gd_path, encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    info = {
        "class_name": None,
        "extends": None,
        "doc_comment": [],
        "exports": [],
        "signals": [],
        "enums": [],
        "has_apply_grid_config": False,
        "has_ready": False,
        "has_process": False,
        "total_lines": len(lines),
        "methods": [],
    }

    in_doc_comment = False
    for line in lines:
        stripped = line.strip()

        # class_name
        m = re.match(r"class_name\s+(\w+)", stripped)
        if m:
            info["class_name"] = m.group(1)

        # extends
        m = re.match(r"extends\s+(\w+)", stripped)
        if m:
            info["extends"] = m.group(1)

        # Doc comments (## lines at top of file)
        if stripped.startswith("##"):
            info["doc_comment"].append(stripped[2:].strip())
            in_doc_comment = True
        elif in_doc_comment and not stripped.startswith("#"):
            in_doc_comment = False

        # @export vars
        m = re.match(r"@export\s+var\s+(\w+)\s*(?::\s*(\w+))?\s*=?\s*(.*)", stripped)
        if m:
            info["exports"].append({
                "name": m.group(1),
                "type": m.group(2) or "",
                "default": re.sub(r'\s*[#].*', '', m.group(3)).strip() if m.group(3) else "",
            })

        # signals
        m = re.match(r"signal\s+(\w+)", stripped)
        if m:
            info["signals"].append(m.group(1))

        # enums
        m = re.match(r"enum\s+(\w+)", stripped)
        if m:
            info["enums"].append(m.group(1))

        # Key methods
        if "func apply_grid_config" in stripped:
            info["has_apply_grid_config"] = True
        if "func _ready" in stripped:
            info["has_ready"] = True
        if "func _process" in stripped or "func _physics_process" in stripped:
            info["has_process"] = True

        # All public methods
        m = re.match(r"func\s+(\w+)", stripped)
        if m and not m.group(1).startswith("_"):
            info["methods"].append(m.group(1))

    return info


def generate_readme(dirname, gd_info, registry_entry):
    """Generate README.md content for an artifact."""
    # Title from registry name or class_name or dirname
    name = registry_entry.get("name", "")
    if not name:
        name = gd_info["class_name"] or dirname.replace("_", " ").title()

    # Description from registry
    description = registry_entry.get("description", "")

    # Category and tags
    category = registry_entry.get("category", "")
    tags = registry_entry.get("tags", [])

    # Doc comment from source
    doc_lines = gd_info["doc_comment"]

    lines = []
    lines.append(f"# {name}")
    lines.append("")

    # Description
    if description:
        lines.append(description)
        lines.append("")

    # Doc comment — only add if substantially different from registry description
    if doc_lines and description:
        doc_text = " ".join(doc_lines)
        # Skip if first 30 chars overlap or doc is subset of description
        desc_lower = description.lower()
        doc_lower = doc_text.lower()
        first_words = doc_lower.split()[:5]
        desc_words = desc_lower.split()[:5]
        if first_words != desc_words and doc_lower[:30] not in desc_lower and desc_lower[:30] not in doc_lower:
            lines.append(doc_text)
            lines.append("")
    elif doc_lines and not description:
        lines.append(" ".join(doc_lines))
        lines.append("")

    # Category/tags
    if category or tags:
        lines.append("## Details")
        lines.append("")
        if category:
            lines.append(f"- **Category:** {category}")
        if tags:
            lines.append(f"- **Tags:** {', '.join(tags)}")
        lines.append(f"- **Extends:** {gd_info['extends'] or 'Node3D'}")
        if gd_info["class_name"]:
            lines.append(f"- **Class:** `{gd_info['class_name']}`")
        lines.append(f"- **Source:** `{dirname}.gd` ({gd_info['total_lines']} lines)")
        lines.append("")

    # Parameters (exports)
    if gd_info["exports"]:
        lines.append("## Parameters")
        lines.append("")
        lines.append("| Export | Type | Default |")
        lines.append("|--------|------|---------|")
        for exp in gd_info["exports"]:
            default = exp["default"] if exp["default"] else "—"
            # Truncate long defaults
            if len(default) > 40:
                default = default[:37] + "..."
            typ = exp["type"] if exp["type"] else "—"
            lines.append(f"| `{exp['name']}` | {typ} | {default} |")
        lines.append("")

    # Features
    features = []
    if gd_info["has_apply_grid_config"]:
        features.append("Grid-configurable via `apply_grid_config()`")
    if gd_info["has_process"]:
        features.append("Animated (updates each frame)")
    if gd_info["has_ready"]:
        features.append("Procedural geometry built in `_ready()`")
    if gd_info["enums"]:
        features.append(f"Enums: {', '.join(gd_info['enums'])}")
    if gd_info["signals"]:
        features.append(f"Signals: {', '.join(gd_info['signals'])}")

    if features:
        lines.append("## Features")
        lines.append("")
        for feat in features:
            lines.append(f"- {feat}")
        lines.append("")

    # Files
    lines.append("## Files")
    lines.append("")
    lines.append(f"- `{dirname}.gd` — Main script")
    lines.append(f"- `{dirname}.tscn` — Scene file")
    lines.append("")

    return "\n".join(lines)


def main():
    registries = load_registries()

    dirs = sorted([
        d for d in os.listdir(ARTIFACTS_DIR)
        if os.path.isdir(os.path.join(ARTIFACTS_DIR, d)) and d not in SKIP_DIRS
    ])

    created = 0
    skipped = 0
    errors = 0

    for dirname in dirs:
        dir_path = os.path.join(ARTIFACTS_DIR, dirname)
        readme_path = os.path.join(dir_path, "README.md")

        # Skip if README already exists
        if os.path.exists(readme_path):
            skipped += 1
            continue

        # Find .gd file
        gd_files = glob.glob(os.path.join(dir_path, "*.gd"))
        if not gd_files:
            print(f"  SKIP {dirname}: no .gd file")
            skipped += 1
            continue

        # Use the main .gd (matching dirname, or first one)
        main_gd = None
        for gf in gd_files:
            if os.path.basename(gf).replace(".gd", "") == dirname:
                main_gd = gf
                break
        if not main_gd:
            main_gd = gd_files[0]

        try:
            gd_info = parse_gd_file(main_gd)
            registry_entry = registries.get(dirname, {})
            readme_content = generate_readme(dirname, gd_info, registry_entry)

            with open(readme_path, "w", encoding="utf-8") as f:
                f.write(readme_content)

            created += 1
            print(f"  OK {dirname}")
        except Exception as e:
            print(f"  ERR {dirname}: {e}")
            errors += 1

    print(f"\nDone: {created} created, {skipped} skipped, {errors} errors")


if __name__ == "__main__":
    main()
