#!/usr/bin/env python3
"""
Convert BBCode tutorial files (.gd) to Markdown (.md) files.

Usage:
    python convert_bbcode_to_markdown.py [--dry-run]
    
This script converts tutorial text files from:
    commons/context/clipboard/tutorial_text/*.gd (BBCode format)
to:
    commons/context/clipboard/tutorial_text/*.md (Markdown format)
"""

import os
import re
import argparse
from pathlib import Path

def convert_bbcode_to_markdown(bbcode_text: str) -> str:
    """Convert BBCode formatted text to Markdown."""
    lines = bbcode_text.splitlines()
    md_lines = []
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Header Detection: Standalone [b]...[/b]
        # logic: if the line starts with [b] and ends with [/b] (ignoring whitespace)
        # convert to # Header or ## Header
        header_match = re.match(r'^\s*\[b\](.*?)\[/b\]\s*$', line)
        if header_match:
            header_text = header_match.group(1)
            # If it's the very first line, treat as Title (H1)
            if i == 0:
                 md_lines.append(f"# {header_text}")
            else:
                 # Otherwise treat as Section Header (H2)
                 md_lines.append(f"## {header_text}")
            continue
            
        md_lines.append(line)
        
    md = '\n'.join(md_lines)
    
    # Bold: [b]text[/b] -> **text** (Inline only now, since headers handled above)
    md = re.sub(r'\[b\](.*?)\[/b\]', r'**\1**', md, flags=re.DOTALL)
    
    # Italic: [i]text[/i] -> text (Stripped as per request for clarity)
    md = re.sub(r'\[i\](.*?)\[/i\]', r'\1', md, flags=re.DOTALL)
    
    # Code blocks: [code]...[/code] -> ```...```
    # Ensure newlines around fenced blocks
    def replace_code_block(match):
        code = match.group(1).strip()
        return f'\n```\n{code}\n```\n'

    md = re.sub(r'\[code\](.*?)\[/code\]', replace_code_block, md, flags=re.DOTALL)

    # Cleanup: Remove lines that just say "Code" (redundant context)
    md = re.sub(r'\nCode\s*\n', '\n', md)
    
    # Horizontal rule: [hr] -> ---
    md = re.sub(r'\[hr\]', '\n---\n', md)
    
    # Color tags: [color=xxx]text[/color] -> text (strip color, keep text)
    md = re.sub(r'\[color=[^\]]+\](.*?)\[/color\]', r'\1', md, flags=re.DOTALL)
    
    # Underline: [u]text[/u] -> <u>text</u> (HTML fallback or ignore)
    # Using italic/emphasis instead for better markdown compatibility? No, keep html or strip.
    md = re.sub(r'\[u\](.*?)\[/u\]', r'*\1*', md, flags=re.DOTALL)
    
    # Strikethrough: [s]text[/s] -> ~~text~~
    md = re.sub(r'\[s\](.*?)\[/s\]', r'~~\1~~', md, flags=re.DOTALL)
    
    # URLs: [url=xxx]text[/url] -> [text](xxx)
    md = re.sub(r'\[url=([^\]]+)\](.*?)\[/url\]', r'[\2](\1)', md, flags=re.DOTALL)
    
    # Images: [img]path[/img] -> ![](path)
    md = re.sub(r'\[img\](.*?)\[/img\]', r'![](\1)', md, flags=re.DOTALL)
    
    # Center: [center]text[/center] -> text (strip, markdown doesn't support)
    md = re.sub(r'\[center\](.*?)\[/center\]', r'\1', md, flags=re.DOTALL)
    
    # Clean up any remaining BBCode tags
    md = re.sub(r'\[/?[a-z_]+(?:=[^\]]+)?\]', '', md, flags=re.IGNORECASE)
    
    # Post-process: Remove excessive newlines
    # Replace 3 or more newlines with 2 (max one blank line)
    md = re.sub(r'\n{3,}', '\n\n', md)
    
    return md.strip()

def extract_text_from_gd_file(filepath: Path) -> str:
    """Extract the text content from a tutorial .gd file."""
    content = filepath.read_text(encoding='utf-8')
    
    # Look for: var text = '''...''' or var text = """..."""
    match = re.search(r"var\s+text\s*=\s*['\"\"\"]+(.*?)['\"\"\"]+'*\"*", content, re.DOTALL)
    
    if match:
        return match.group(1)
    
    # Try single quotes with triple quotes
    match = re.search(r"var\s+text\s*=\s*'''(.*?)'''", content, re.DOTALL)
    if match:
        return match.group(1)
    
    # Try double-quote string
    match = re.search(r'var\s+text\s*=\s*"""(.*?)"""', content, re.DOTALL)
    if match:
        return match.group(1)
    
    return ""

def convert_file(gd_file: Path, output_dir: Path, dry_run: bool = False) -> bool:
    """Convert a single .gd file to .md format."""
    bbcode_text = extract_text_from_gd_file(gd_file)
    
    if not bbcode_text:
        print(f"  ⚠ Could not extract text from: {gd_file.name}")
        return False
    
    markdown_text = convert_bbcode_to_markdown(bbcode_text)
    
    # Create output filename
    md_filename = gd_file.stem + '.md'
    md_file = output_dir / md_filename
    
    if dry_run:
        print(f"  Would create: {md_file.name} ({len(markdown_text)} chars)")
    else:
        md_file.write_text(markdown_text, encoding='utf-8')
        print(f"  ✓ Created: {md_file.name}")
    
    return True

def main():
    parser = argparse.ArgumentParser(description='Convert BBCode tutorial files to Markdown')
    parser.add_argument('--dry-run', action='store_true', help='Preview changes without writing files')
    args = parser.parse_args()
    
    # Paths
    script_dir = Path(__file__).parent
    tutorial_dir = script_dir / 'commons' / 'context' / 'clipboard' / 'tutorial_text'
    
    if not tutorial_dir.exists():
        # Try from project root
        tutorial_dir = Path('commons/context/clipboard/tutorial_text')
    
    if not tutorial_dir.exists():
        print(f"Error: Tutorial directory not found: {tutorial_dir}")
        return
    
    print(f"Converting BBCode tutorials to Markdown...")
    print(f"Source directory: {tutorial_dir}")
    print(f"{'DRY RUN - no files will be written' if args.dry_run else ''}")
    print()
    
    # Find all .gd files (excluding template and special files)
    gd_files = sorted(tutorial_dir.glob('*.gd'))
    gd_files = [f for f in gd_files if not f.name.startswith('_')]
    
    converted = 0
    failed = 0
    
    for gd_file in gd_files:
        if convert_file(gd_file, tutorial_dir, args.dry_run):
            converted += 1
        else:
            failed += 1
    
    print()
    print(f"Conversion complete: {converted} converted, {failed} failed")
    
    if not args.dry_run:
        print()
        print("Next steps:")
        print("1. Review the generated .md files")
        print("2. Update TutorialTextLibrary.gd to load .md files")
        print("3. Remove or deprecate the old .gd files")

if __name__ == '__main__':
    main()
