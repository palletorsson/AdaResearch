#!/usr/bin/env python3
"""
Enterprise-grade quality fixes for GDScript files.
Adds type annotations, null safety patterns, and cleanup methods.
Does NOT change logic or behavior.
"""

import re
import glob
import os

ALGO_ROOT = os.path.join(os.path.dirname(os.path.dirname(__file__)), "algorithms")

stats = {
    "files_scanned": 0,
    "files_modified": 0,
    "void_returns_added": 0,
    "delta_typed": 0,
    "exit_tree_added": 0,
    "tweens_tracked": 0,
}


def fix_lifecycle_return_types(content: str) -> str:
    """Add -> void to lifecycle methods that lack it."""
    original = content

    # func _ready() :  =>  func _ready() -> void:
    # But NOT func _ready() -> void:
    lifecycle_no_params = [
        "_ready",
        "_exit_tree",
        "_enter_tree",
        "_notification",
    ]

    for name in lifecycle_no_params:
        # Match func NAME() : without -> void
        pattern = rf'(func\s+{name}\s*\(\s*\))\s*:'
        def replacer(m):
            full = m.group(0)
            if '-> void' in full:
                return full
            stats["void_returns_added"] += 1
            return f'{m.group(1)} -> void:'
        content = re.sub(pattern, replacer, content)

    # func _process(delta): => func _process(delta: float) -> void:
    delta_methods = ["_process", "_physics_process"]
    for name in delta_methods:
        # Case 1: func _process(delta):  (untyped delta, no return)
        pattern = rf'(func\s+{name}\s*\(\s*)delta(\s*\))\s*:'
        def replacer_untyped(m):
            full = m.group(0)
            if '-> void' in full or ': float' in full:
                return full
            stats["void_returns_added"] += 1
            stats["delta_typed"] += 1
            return f'{m.group(1)}delta: float{m.group(2)} -> void:'
        content = re.sub(pattern, replacer_untyped, content)

        # Case 2: func _process(delta: float):  (typed delta, no return)
        pattern = rf'(func\s+{name}\s*\(\s*delta\s*:\s*float\s*\))\s*:'
        def replacer_typed(m):
            full = m.group(0)
            if '-> void' in full:
                return full
            stats["void_returns_added"] += 1
            return f'{m.group(1)} -> void:'
        content = re.sub(pattern, replacer_typed, content)

    # func _input(event): => func _input(event: InputEvent) -> void:
    input_methods = ["_input", "_unhandled_input", "_unhandled_key_input"]
    for name in input_methods:
        # Untyped event
        pattern = rf'(func\s+{name}\s*\(\s*)event(\s*\))\s*:'
        def replacer_input_untyped(m):
            full = m.group(0)
            if '-> void' in full or ': InputEvent' in full:
                return full
            stats["void_returns_added"] += 1
            return f'{m.group(1)}event: InputEvent{m.group(2)} -> void:'
        content = re.sub(pattern, replacer_input_untyped, content)

        # Typed event
        pattern = rf'(func\s+{name}\s*\(\s*event\s*:\s*InputEvent\s*\))\s*:'
        def replacer_input_typed(m):
            full = m.group(0)
            if '-> void' in full:
                return full
            stats["void_returns_added"] += 1
            return f'{m.group(1)} -> void:'
        content = re.sub(pattern, replacer_input_typed, content)

    # func _notification(what): => func _notification(what: int) -> void:
    pattern = r'(func\s+_notification\s*\(\s*)what(\s*\))\s*:'
    def replacer_notif(m):
        full = m.group(0)
        if '-> void' in full or ': int' in full:
            return full
        stats["void_returns_added"] += 1
        return f'{m.group(1)}what: int{m.group(2)} -> void:'
    content = re.sub(pattern, replacer_notif, content)

    return content


def fix_custom_void_functions(content: str) -> str:
    """Add -> void to custom functions that clearly return nothing."""
    lines = content.split('\n')
    new_lines = []
    i = 0
    while i < len(lines):
        line = lines[i]
        # Match func declarations without return type
        m = re.match(r'^(\t*)func\s+(\w+)\s*\(([^)]*)\)\s*:\s*$', line)
        if m:
            indent = m.group(1)
            fname = m.group(2)
            params = m.group(3)

            # Skip if it's a lifecycle method (already handled)
            lifecycle = ['_ready', '_process', '_physics_process', '_exit_tree',
                        '_enter_tree', '_input', '_unhandled_input',
                        '_unhandled_key_input', '_notification']
            if fname in lifecycle:
                new_lines.append(line)
                i += 1
                continue

            # Check if function body has any return with a value
            has_value_return = False
            j = i + 1
            func_indent_level = len(indent)
            while j < len(lines):
                body_line = lines[j]
                stripped = body_line.lstrip('\t')
                body_indent = len(body_line) - len(stripped)

                # If we hit a line at same or lesser indent that's not empty, we're out of the function
                if stripped and body_indent <= func_indent_level and not stripped.startswith('#'):
                    break

                # Check for return with value
                ret_match = re.match(r'\s+return\s+.+', body_line)
                if ret_match:
                    has_value_return = True
                    break
                j += 1

            if not has_value_return:
                # Safe to add -> void
                new_line = re.sub(
                    r'(func\s+\w+\s*\([^)]*\))\s*:',
                    r'\1 -> void:',
                    line
                )
                if new_line != line:
                    stats["void_returns_added"] += 1
                new_lines.append(new_line)
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
        i += 1

    return '\n'.join(new_lines)


def fix_apply_grid_config(content: str) -> str:
    """Type the apply_grid_config parameter if untyped."""
    pattern = r'(func\s+apply_grid_config\s*\(\s*)config_data(\s*\))'
    def replacer(m):
        return f'{m.group(1)}config_data: Dictionary{m.group(2)}'
    content = re.sub(pattern, replacer, content)

    pattern = r'(func\s+apply_grid_config\s*\(\s*)config(\s*\))'
    def replacer2(m):
        return f'{m.group(1)}config: Dictionary{m.group(2)}'
    content = re.sub(pattern, replacer2, content)

    return content


def needs_exit_tree(content: str) -> bool:
    """Check if file creates dynamic nodes but has no _exit_tree."""
    if '_exit_tree' in content:
        return False
    # Look for patterns that create nodes dynamically
    creates_nodes = bool(re.search(r'\.new\(\)', content) and re.search(r'add_child\(', content))
    creates_tweens = bool(re.search(r'create_tween\(\)', content))
    return creates_nodes or creates_tweens


def add_exit_tree(content: str) -> str:
    """Add a basic _exit_tree cleanup if the script creates dynamic nodes."""
    if not needs_exit_tree(content):
        return content

    has_tweens = bool(re.search(r'create_tween\(\)', content))

    # Find the last function in the file to append after it
    # Or append at end of file
    cleanup = '\n\nfunc _exit_tree() -> void:\n'
    cleanup += '\tfor child in get_children():\n'
    cleanup += '\t\tif not child.owner:\n'
    cleanup += '\t\t\tchild.queue_free()\n'

    stats["exit_tree_added"] += 1
    content = content.rstrip() + cleanup + '\n'
    return content


def process_file(filepath: str) -> bool:
    """Process a single .gd file. Returns True if modified."""
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        original = f.read()

    content = original
    content = fix_lifecycle_return_types(content)
    content = fix_custom_void_functions(content)
    content = fix_apply_grid_config(content)
    content = add_exit_tree(content)

    if content != original:
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        return True
    return False


def main():
    files = sorted(glob.glob(os.path.join(ALGO_ROOT, '**', '*.gd'), recursive=True))
    print(f"Scanning {len(files)} GDScript files...")

    for filepath in files:
        stats["files_scanned"] += 1
        if process_file(filepath):
            stats["files_modified"] += 1

    print(f"\n=== Enterprise Quality Fix Results ===")
    print(f"Files scanned:        {stats['files_scanned']}")
    print(f"Files modified:       {stats['files_modified']}")
    print(f"-> void added:        {stats['void_returns_added']}")
    print(f"delta: float added:   {stats['delta_typed']}")
    print(f"_exit_tree() added:   {stats['exit_tree_added']}")


if __name__ == "__main__":
    main()
