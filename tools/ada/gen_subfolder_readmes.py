#!/usr/bin/env python3
"""Generate READMEs for algorithm subfolders."""

import os
import sys
from pathlib import Path

def get_description_from_gd(gd_path):
    """Extract description from GDScript file header comments."""
    try:
        with open(gd_path, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()[:30]
        
        desc_lines = []
        in_doc = False
        
        for line in lines:
            stripped = line.strip()
            
            # Handle ## docstrings
            if stripped.startswith('##'):
                desc_lines.append(stripped[2:].strip())
                in_doc = True
            # Handle # comments at start
            elif stripped.startswith('#') and not in_doc:
                comment = stripped.lstrip('#').strip()
                if comment and not any(x in comment.lower() for x in ['extends', 'class_name', '!', 'copyright', 'license']):
                    desc_lines.append(comment)
            # Stop at actual code
            elif stripped and not stripped.startswith('#') and not stripped.startswith('extends') and not stripped.startswith('class_name') and not stripped.startswith('@'):
                if not in_doc:
                    break
        
        return ' '.join(desc_lines[:3]) if desc_lines else ''
    except:
        return ''


def scan_folder(folder_path):
    """Scan a folder for README and code files."""
    folder = Path(folder_path)
    
    # Check for any README file
    readmes = list(folder.glob('README*.md')) + list(folder.glob('readme*.md'))
    
    # Recursively find files
    gd_files = list(folder.rglob('*.gd'))
    tscn_files = list(folder.rglob('*.tscn'))
    
    # Filter out .uid files
    gd_files = [f for f in gd_files if not str(f).endswith('.uid')]
    
    return {
        'has_readme': len(readmes) > 0,
        'readme_files': [r.name for r in readmes],
        'gd_files': gd_files,
        'tscn_files': tscn_files
    }


def generate_readme(folder_path):
    """Generate README content for a subfolder."""
    folder = Path(folder_path)
    name = folder.name
    info = scan_folder(folder)
    
    if info['has_readme']:
        return None  # Already has README
    
    gd_files = info['gd_files']
    tscn_files = info['tscn_files']
    
    if not gd_files and not tscn_files:
        return None  # Empty folder
    
    # Try to get description from main GD file
    desc = ''
    main_gd = None
    
    # Look for file matching folder name
    for gd in gd_files:
        if gd.stem.lower().replace('_', '') == name.lower().replace('_', ''):
            main_gd = gd
            break
    
    if not main_gd and gd_files:
        # Use first non-test file
        for gd in gd_files:
            if 'test' not in gd.stem.lower():
                main_gd = gd
                break
        if not main_gd:
            main_gd = gd_files[0]
    
    if main_gd:
        desc = get_description_from_gd(main_gd)
    
    # Format name for title
    title = name.replace('_', ' ').title()
    
    # Build README
    lines = [f'# {title}', '']
    
    if desc:
        lines.extend([desc, ''])
    
    # List scripts
    if gd_files:
        lines.append('## Scripts')
        lines.append('')
        for gd in sorted(gd_files, key=lambda x: x.name):
            rel_path = gd.relative_to(folder)
            lines.append(f'- `{rel_path}`')
        lines.append('')
    
    # List scenes
    if tscn_files:
        lines.append('## Scenes')
        lines.append('')
        for tscn in sorted(tscn_files, key=lambda x: x.name):
            rel_path = tscn.relative_to(folder)
            lines.append(f'- `{rel_path}`')
    
    return '\n'.join(lines)


def process_algorithm_folder(algo_folder, dry_run=True):
    """Process all subfolders of an algorithm folder."""
    algo_path = Path(algo_folder)
    
    if not algo_path.exists():
        print(f"Folder not found: {algo_folder}")
        return 0
    
    created = 0
    for sub in sorted(algo_path.iterdir()):
        if sub.is_dir():
            readme_content = generate_readme(sub)
            if readme_content:
                readme_path = sub / 'README.md'
                if dry_run:
                    print(f"Would create: {readme_path.relative_to(algo_path.parent.parent)}")
                else:
                    with open(readme_path, 'w', encoding='utf-8') as f:
                        f.write(readme_content)
                    print(f"Created: {readme_path.relative_to(algo_path.parent.parent)}")
                created += 1
    
    return created


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('folder', help='Algorithm folder to process')
    parser.add_argument('--write', action='store_true', help='Actually write files (default: dry run)')
    args = parser.parse_args()
    
    count = process_algorithm_folder(args.folder, dry_run=not args.write)
    print(f"\n{'Created' if args.write else 'Would create'}: {count} READMEs")
