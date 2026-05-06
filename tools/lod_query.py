#!/usr/bin/env python3
"""
LOD Query Tool for Ada Research.

Navigates the LOD tree at doc/LOD_TREE.json and returns context
at the appropriate depth. Output is Markdown optimized for Claude's
context window — concise, linked, actionable.

Usage:
  python tools/lod_query.py                              # LOD 0: project overview
  python tools/lod_query.py mosaicanalysis               # LOD 1: sequence detail
  python tools/lod_query.py MANN_Gallery_Museum           # LOD 2: map detail
  python tools/lod_query.py pompeii_mosaic_floor          # LOD 3: artifact detail
  python tools/lod_query.py pompeii_mosaic_floor._build   # LOD 4: function detail
  python tools/lod_query.py meander                       # fuzzy: finds all matches
  python tools/lod_query.py --list sequences              # list all sequence IDs
  python tools/lod_query.py --list maps                   # list all map names
  python tools/lod_query.py --list artifacts              # list all artifact names
"""

import json
import sys
import io
from pathlib import Path

# Force UTF-8 output on Windows
if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
TREE_PATH = ROOT / "doc" / "LOD_TREE.json"
DISCOVERIES_PATH = ROOT / "doc" / "LOD_DISCOVERIES.json"


def load_tree():
    """Load the LOD tree."""
    if not TREE_PATH.is_file():
        print(f"ERROR: LOD tree not found at {TREE_PATH}")
        print("Run: python tools/lod_tree_generator.py")
        sys.exit(1)
    with open(TREE_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def fuzzy_match(query, text):
    """Check if query fuzzy-matches text (case-insensitive substring)."""
    q = query.lower()
    t = text.lower()
    if q in t:
        return True
    # Also match with underscores replaced by spaces
    if q.replace("_", " ") in t.replace("_", " "):
        return True
    # Word-boundary matching: all query words must appear
    words = q.split()
    if len(words) > 1:
        return all(w in t for w in words)
    return False


def find_matches(tree, query):
    """Search the entire tree for nodes matching the query.
    Returns list of (level, path, node) tuples."""
    matches = []
    q = query.lower()

    for seq_node in tree["lod0"].get("children", []):
        seq_id = seq_node.get("id", "")
        seq_text = f"{seq_id} {seq_node.get('lod1', '')}"

        if fuzzy_match(query, seq_text):
            matches.append(("sequence", seq_id, seq_node))

        # Search maps
        for map_node in seq_node.get("children", []):
            map_id = map_node.get("id", "")
            map_text = f"{map_id} {map_node.get('lod2', '')}"
            if fuzzy_match(query, map_text):
                matches.append(("map", f"{seq_id}/{map_id}", map_node))

            # Search artifacts listed in map
            for art_name in map_node.get("artifacts", []):
                if fuzzy_match(query, art_name):
                    # Find the artifact detail node
                    art_node = find_artifact_detail(seq_node, art_name)
                    if art_node:
                        matches.append(("artifact", f"{seq_id}/{map_id}/{art_name}", art_node))
                    else:
                        matches.append(("artifact_ref", f"{seq_id}/{map_id}/{art_name}", {"id": art_name}))

        # Search artifact details
        for art_node in seq_node.get("artifact_details", []):
            art_id = art_node.get("id", "")
            art_text = f"{art_id} {art_node.get('lod3', '')} {art_node.get('essence', '')}"
            if fuzzy_match(query, art_text):
                if not any(m[2].get("id") == art_id for m in matches if m[0] == "artifact"):
                    matches.append(("artifact", f"{seq_id}/{art_id}", art_node))

            # Search functions (LOD 4)
            for fn_name, fn_desc in art_node.get("lod4", {}).items():
                if fuzzy_match(query, f"{fn_name} {fn_desc}"):
                    matches.append(("function", f"{art_id}.{fn_name}", {
                        "artifact": art_id,
                        "function": fn_name,
                        "description": fn_desc,
                        "file": art_node.get("file", ""),
                    }))

    # Deduplicate by id
    seen = set()
    unique = []
    for level, path, node in matches:
        key = f"{level}:{node.get('id', path)}"
        if key not in seen:
            seen.add(key)
            unique.append((level, path, node))

    return unique


def find_artifact_detail(seq_node, art_name):
    """Find artifact detail node within a sequence."""
    for art in seq_node.get("artifact_details", []):
        if art.get("id") == art_name:
            return art
    return None


def find_exact_sequence(tree, seq_id):
    """Find exact sequence node by id."""
    for node in tree["lod0"].get("children", []):
        if node.get("id") == seq_id:
            return node
    return None


def find_exact_map(tree, map_id):
    """Find exact map node by id across all sequences."""
    for seq_node in tree["lod0"].get("children", []):
        for map_node in seq_node.get("children", []):
            if map_node.get("id") == map_id:
                return seq_node, map_node
    return None, None


def find_exact_artifact(tree, art_id):
    """Find exact artifact detail node by id."""
    for seq_node in tree["lod0"].get("children", []):
        for art_node in seq_node.get("artifact_details", []):
            if art_node.get("id") == art_id:
                return seq_node, art_node
    return None, None


def render_lod0(tree):
    """Render project overview."""
    lod0 = tree["lod0"]
    stats = lod0["stats"]
    lines = [
        "# Ada Research — Project Overview (LOD 0)",
        "",
        lod0["summary"],
        "",
        "## Stats",
        f"- **Sequences:** {stats['sequences']}",
        f"- **Maps (in sequences):** {stats['maps_in_sequences']}",
        f"- **Maps (on disk):** {stats['maps_on_disk']}",
        f"- **Artifacts:** {stats['artifacts_registered']}",
        "",
        "## Key Paths",
    ]
    for label, path in lod0.get("key_paths", {}).items():
        lines.append(f"- `{label}`: `{path}`")

    lines.extend(["", "## Sequences"])
    for seq in lod0.get("children", []):
        sid = seq.get("id", "?")
        if sid == "_orphan_maps":
            lines.append(f"- **{sid}**: {seq.get('map_count', 0)} orphan maps")
        else:
            lines.append(f"- **{sid}** ({seq.get('map_count', 0)} maps): {seq.get('lod1', '')[:100]}")

    lines.extend([
        "",
        "## Drill Down",
        "```",
        "python tools/lod_query.py <sequence_id>    # sequence detail",
        "python tools/lod_query.py <map_name>        # map detail",
        "python tools/lod_query.py <artifact_name>   # artifact detail",
        "python tools/lod_query.py <search_term>     # fuzzy search",
        "```",
    ])

    # Recent discoveries
    if DISCOVERIES_PATH.is_file():
        try:
            with open(DISCOVERIES_PATH, "r", encoding="utf-8") as f:
                disc = json.load(f)
            if disc.get("discoveries"):
                lines.extend(["", "## Recent Session Discoveries"])
                for d in disc["discoveries"][-5:]:
                    lines.append(f"- [{d.get('topic', '?')}] {d.get('insight', '')} (LOD {d.get('lod', '?')})")
        except Exception:
            pass

    return "\n".join(lines)


def render_sequence(seq_node):
    """Render sequence detail (LOD 1)."""
    lines = [
        f"# {seq_node.get('lod1', seq_node['id'])} (LOD 1)",
        "",
    ]
    if seq_node.get("truth"):
        lines.extend([f"> {seq_node['truth']}", ""])

    lines.append(f"**Layer:** {seq_node.get('layer', '?')} | "
                 f"**Difficulty:** {seq_node.get('difficulty', '?')} | "
                 f"**Maps:** {seq_node.get('map_count', 0)}")

    if seq_node.get("prerequisites"):
        lines.append(f"**Prerequisites:** {', '.join(seq_node['prerequisites'])}")
    if seq_node.get("unlocks"):
        lines.append(f"**Unlocks:** {', '.join(seq_node['unlocks'])}")

    lines.extend(["", "## Maps"])
    for map_node in seq_node.get("children", []):
        mid = map_node.get("id", "?")
        desc = map_node.get("lod2", "")
        arts = map_node.get("artifacts", [])
        dims = map_node.get("dimensions", "")
        dim_str = f" [{dims}]" if dims else ""
        art_str = f" — artifacts: {', '.join(arts[:5])}" if arts else ""
        if len(arts) > 5:
            art_str += f" +{len(arts) - 5} more"
        lines.append(f"- **{mid}**{dim_str}: {desc[:120]}{art_str}")

    # Artifact summary
    art_details = seq_node.get("artifact_details", [])
    if art_details:
        lines.extend(["", f"## Artifacts in this Sequence ({len(art_details)})"])
        for art in art_details:
            aid = art.get("id", "?")
            adesc = art.get("lod3", "")[:100]
            lines.append(f"- **{aid}**: {adesc}")

    lines.extend(["", "## Drill Down",
                   f"```",
                   f"python tools/lod_query.py <map_name>      # map detail",
                   f"python tools/lod_query.py <artifact_name>  # artifact detail",
                   f"```"])

    return "\n".join(lines)


def render_map(seq_node, map_node):
    """Render map detail (LOD 2)."""
    mid = map_node.get("id", "?")
    lines = [
        f"# {mid} (LOD 2)",
        "",
        map_node.get("lod2", ""),
        "",
        f"**Sequence:** {seq_node.get('id', '?')}",
    ]
    if map_node.get("dimensions"):
        lines.append(f"**Dimensions:** {map_node['dimensions']}")

    lines.append(f"**Path:** `commons/maps/{mid}/map_data.json`")

    arts = map_node.get("artifacts", [])
    if arts:
        lines.extend(["", f"## Artifacts ({len(arts)})"])
        for art_name in arts:
            # Find detail if available
            art_detail = find_artifact_detail(seq_node, art_name)
            if art_detail:
                lines.append(f"- **{art_name}**: {art_detail.get('lod3', '')[:100]}")
            else:
                lines.append(f"- **{art_name}**")

    lines.extend(["", "## Drill Down",
                   f"```",
                   f"python tools/lod_query.py {mid.split('/')[0] if '/' in mid else arts[0] if arts else 'artifact'}  # artifact detail",
                   f"```"])

    return "\n".join(lines)


def render_artifact(seq_node, art_node):
    """Render artifact detail (LOD 3)."""
    aid = art_node.get("id", "?")
    lines = [
        f"# {aid} (LOD 3)",
        "",
        art_node.get("lod3", ""),
        "",
    ]
    if art_node.get("essence"):
        lines.extend([f"> {art_node['essence']}", ""])

    if seq_node:
        lines.append(f"**Sequence:** {seq_node.get('id', '?')}")
    if art_node.get("category"):
        lines.append(f"**Category:** {art_node['category']}")
    if art_node.get("class_name"):
        lines.append(f"**Class:** `{art_node['class_name']}`")
    if art_node.get("file"):
        lines.append(f"**File:** `{art_node['file']}`")

    exports = art_node.get("exports", [])
    if exports:
        lines.extend(["", "## Exports"])
        for exp in exports:
            lines.append(f"- `{exp}`")

    lod4 = art_node.get("lod4", {})
    if lod4:
        lines.extend(["", "## Key Functions (LOD 4)"])
        for fname, fdesc in lod4.items():
            lines.append(f"- **`{fname}()`**: {fdesc}")

    lines.extend(["", "## Drill Down",
                   f"```",
                   f"python tools/lod_query.py {aid}.<function_name>  # function detail",
                   f"```"])

    return "\n".join(lines)


def render_function(fn_info):
    """Render function detail (LOD 4)."""
    lines = [
        f"# {fn_info.get('artifact', '?')}.{fn_info.get('function', '?')} (LOD 4)",
        "",
        fn_info.get("description", "No description available."),
        "",
    ]
    if fn_info.get("file"):
        lines.append(f"**File:** `{fn_info['file']}`")
    lines.extend([
        "",
        "To see the implementation, read the file directly:",
        f"```",
        f"Read {fn_info.get('file', '<file_path>')}",
        f"```",
    ])
    return "\n".join(lines)


def render_search_results(query, matches):
    """Render fuzzy search results."""
    lines = [
        f"# Search Results for \"{query}\"",
        "",
        f"Found {len(matches)} match(es):",
        "",
    ]

    # Group by level
    by_level = {}
    for level, path, node in matches:
        by_level.setdefault(level, []).append((path, node))

    for level in ["sequence", "map", "artifact", "artifact_ref", "function"]:
        items = by_level.get(level, [])
        if not items:
            continue
        lines.append(f"## {level.replace('_', ' ').title()}s")
        for path, node in items[:20]:  # limit results
            nid = node.get("id", path)
            desc = (node.get("lod1", "") or node.get("lod2", "") or
                    node.get("lod3", "") or node.get("description", ""))
            lines.append(f"- **{nid}**: {desc[:120]}")
        if len(items) > 20:
            lines.append(f"  ... and {len(items) - 20} more")
        lines.append("")

    lines.extend([
        "## Drill Down",
        "```",
        "python tools/lod_query.py <exact_id>  # get full detail",
        "```",
    ])
    return "\n".join(lines)


def list_items(tree, item_type):
    """List all items of a given type."""
    lines = []
    if item_type == "sequences":
        lines.append("# All Sequences")
        for seq in tree["lod0"].get("children", []):
            sid = seq.get("id", "?")
            if sid != "_orphan_maps":
                lines.append(f"  {sid}")
    elif item_type == "maps":
        lines.append("# All Maps")
        for seq in tree["lod0"].get("children", []):
            for m in seq.get("children", []):
                lines.append(f"  {m.get('id', '?')}")
    elif item_type == "artifacts":
        lines.append("# All Artifacts (in sequence maps)")
        seen = set()
        for seq in tree["lod0"].get("children", []):
            for art in seq.get("artifact_details", []):
                aid = art.get("id", "?")
                if aid not in seen:
                    seen.add(aid)
                    lines.append(f"  {aid}")
    return "\n".join(lines)


def main():
    tree = load_tree()

    # Handle --list flag
    if "--list" in sys.argv:
        idx = sys.argv.index("--list")
        item_type = sys.argv[idx + 1] if idx + 1 < len(sys.argv) else "sequences"
        print(list_items(tree, item_type))
        return

    # No query = LOD 0
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not args:
        print(render_lod0(tree))
        return

    query = args[0]

    # Check for function-level query: artifact.function
    if "." in query:
        parts = query.split(".", 1)
        art_id = parts[0]
        fn_query = parts[1]

        seq_node, art_node = find_exact_artifact(tree, art_id)
        if art_node:
            lod4 = art_node.get("lod4", {})
            # Fuzzy match function name
            for fn_name, fn_desc in lod4.items():
                if fuzzy_match(fn_query, fn_name):
                    print(render_function({
                        "artifact": art_id,
                        "function": fn_name,
                        "description": fn_desc,
                        "file": art_node.get("file", ""),
                    }))
                    return
            # Not found, show artifact instead
            print(render_artifact(seq_node, art_node))
            return

    # Try exact sequence match
    seq_node = find_exact_sequence(tree, query)
    if seq_node:
        print(render_sequence(seq_node))
        return

    # Try exact map match
    seq_node, map_node = find_exact_map(tree, query)
    if map_node:
        print(render_map(seq_node, map_node))
        return

    # Try exact artifact match
    seq_node, art_node = find_exact_artifact(tree, query)
    if art_node:
        print(render_artifact(seq_node, art_node))
        return

    # Fuzzy search
    matches = find_matches(tree, query)
    if matches:
        # If exactly one match, render it directly
        if len(matches) == 1:
            level, path, node = matches[0]
            if level == "sequence":
                print(render_sequence(node))
            elif level == "map":
                seq_n, map_n = find_exact_map(tree, node.get("id", ""))
                if map_n:
                    print(render_map(seq_n, map_n))
                else:
                    print(render_search_results(query, matches))
            elif level == "artifact":
                seq_n, art_n = find_exact_artifact(tree, node.get("id", ""))
                if art_n:
                    print(render_artifact(seq_n, art_n))
                else:
                    print(render_search_results(query, matches))
            elif level == "function":
                print(render_function(node))
            else:
                print(render_search_results(query, matches))
        else:
            print(render_search_results(query, matches))
    else:
        print(f"No matches found for \"{query}\".")
        print("Try: python tools/lod_query.py --list sequences")


if __name__ == "__main__":
    main()
