#!/usr/bin/env python3
"""Generate map_grades.json from map_checklist.py output.

Usage: python scripts/generate_grade_cache.py
Output: commons/maps/catalog/map_grades.json
"""

import json
import os
import re
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHECKLIST_SCRIPT = os.path.join(REPO_ROOT, "scripts", "map_checklist.py")
OUTPUT_PATH = os.path.join(REPO_ROOT, "commons", "maps", "catalog", "map_grades.json")

def main():
    print("Running map_checklist.py --all-curriculum ...")
    result = subprocess.run(
        [sys.executable, CHECKLIST_SCRIPT, "--all-curriculum"],
        capture_output=True, text=True, cwd=REPO_ROOT
    )
    
    # Checklist outputs to stderr on some configs, combine both
    output = (result.stdout or "") + "\n" + (result.stderr or "")
    
    grades = {}
    # Pattern: OK [A] MapName  or  XX [C] MapName
    pattern = re.compile(r"(?:OK|XX)\s+\[([ABCF])\]\s+(\S+)")
    
    for line in output.splitlines():
        m = pattern.search(line)
        if m:
            grade = m.group(1)
            map_name = m.group(2)
            grades[map_name] = grade
    
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        json.dump({"grades": grades, "count": len(grades)}, f, indent=1, sort_keys=True)
    
    # Summary
    counts = {}
    for g in grades.values():
        counts[g] = counts.get(g, 0) + 1
    
    print(f"Generated {OUTPUT_PATH}")
    print(f"  {len(grades)} maps graded: A={counts.get('A',0)} B={counts.get('B',0)} C={counts.get('C',0)} F={counts.get('F',0)}")

if __name__ == "__main__":
    main()
