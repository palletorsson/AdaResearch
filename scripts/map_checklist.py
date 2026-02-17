#!/usr/bin/env python3
"""
Comprehensive map checklist — run on every map before committing.

Checks:
  1. SPAWN SAFETY    2x2 floor (h=1) at [0,0]-[1,1]
  2. LAYER DIMS      structure/utilities/interactables same dimensions
  3. EMPTY CELLS     no "0" in utilities or interactables (use " ")
  4. TELEPORTER      at least one t: or t3: in utilities
  5. SCORE POINT     at least one sp in utilities
  6. SPAWN MARKER    s in utilities
  7. ANNOTATION      an in utilities
  8. REGISTRY        all artifacts in interactables registered
  9. WALKABILITY     player can reach all artifacts + teleporter from spawn
 10. NO LIFTS        no l: in utilities (use tc instead)
 11. ARTIFACTS OK    no artifacts placed on void (h=0) cells

Usage:
  python map_checklist.py <map_data.json>
  python map_checklist.py --batch MAP1 MAP2 ...
  python map_checklist.py --today
  python map_checklist.py --all-curriculum
"""

import json, os, sys, glob
from collections import deque

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ─── Registry loader ───

_registry = None
def get_registry():
    global _registry
    if _registry is not None:
        return _registry
    _registry = set()
    for f in glob.glob(os.path.join(PROJECT, 'commons', 'artifacts', 'registry', '*.json')):
        try:
            with open(f, 'r', encoding='utf-8-sig') as fh:
                d = json.load(fh)
            arts = d.get('artifacts', d)
            if isinstance(arts, dict):
                _registry.update(arts.keys())
        except:
            pass
    gf = os.path.join(PROJECT, 'commons', 'artifacts', 'grid_artifacts.json')
    if os.path.isfile(gf):
        try:
            with open(gf, 'r', encoding='utf-8-sig') as fh:
                d = json.load(fh)
            arts = d.get('artifacts', d)
            if isinstance(arts, dict):
                _registry.update(arts.keys())
        except:
            pass
    return _registry


# ─── Walkability flood fill ───

def flood_fill(hmap, wp_cells, tc_edges, spawn, rows, cols):
    walkable = {p for p, v in hmap.items() if v > 0}
    visited = set()
    queue = deque()
    if spawn in walkable:
        visited.add(spawn)
        queue.append(spawn)
    while queue:
        r, c = queue.popleft()
        ch = hmap.get((r, c), 0)
        for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]:
            nb = (r+dr, c+dc)
            if nb in visited or nb not in walkable:
                continue
            nh = hmap[nb]
            if nh == ch:
                visited.add(nb); queue.append(nb)
            elif (r,c) in wp_cells or nb in wp_cells:
                visited.add(nb); queue.append(nb)
        for a, b in tc_edges:
            if (r,c) == a and b not in visited and b in walkable:
                visited.add(b); queue.append(b)
            elif (r,c) == b and a not in visited and a in walkable:
                visited.add(a); queue.append(a)
    return visited


# ─── Main checklist ───

def run_checklist(path):
    results = []
    name = os.path.basename(os.path.dirname(path))

    # Load
    try:
        with open(path, 'r', encoding='utf-8-sig') as fh:
            data = json.load(fh)
    except Exception as e:
        return name, [('FAIL', 'JSON', str(e))], 0

    layers = data.get('layers', {})
    struct = layers.get('structure', [])
    utils = layers.get('utilities', [])
    ints = layers.get('interactables', [])

    if not struct:
        return name, [('FAIL', 'STRUCTURE', 'No structure layer')], 0

    rows = len(struct)
    cols = max(len(r) for r in struct) if struct else 0

    def h(r, c):
        if r < len(struct) and c < len(struct[r]):
            try: return int(str(struct[r][c]).strip())
            except: return 0
        return 0

    def ucell(r, c):
        if r < len(utils) and c < len(utils[r]):
            return str(utils[r][c]).strip()
        return ''

    def icell(r, c):
        if r < len(ints) and c < len(ints[r]):
            return str(ints[r][c]).strip()
        return ''

    passed = 0

    # 1. SPAWN SAFETY: 2x2 at [0,0] must be h=1
    corner = [h(0,0), h(0,1), h(1,0), h(1,1)]
    if all(c == 1 for c in corner):
        results.append(('PASS', 'SPAWN', '2x2 corner all h=1'))
        passed += 1
    else:
        results.append(('FAIL', 'SPAWN', f'2x2 corner = {corner}, need all h=1'))

    # 2. LAYER DIMS
    dim_ok = True
    issues = []
    u_rows = len(utils)
    i_rows = len(ints)
    if u_rows != rows:
        issues.append(f'utils rows={u_rows} != struct rows={rows}')
        dim_ok = False
    if i_rows != rows:
        issues.append(f'ints rows={i_rows} != struct rows={rows}')
        dim_ok = False
    for r in range(rows):
        sc = len(struct[r]) if r < len(struct) else 0
        uc = len(utils[r]) if r < len(utils) else 0
        ic = len(ints[r]) if r < len(ints) else 0
        if uc != sc:
            issues.append(f'row {r}: utils cols={uc} != struct cols={sc}')
            dim_ok = False
            break
        if ic != sc:
            issues.append(f'row {r}: ints cols={ic} != struct cols={sc}')
            dim_ok = False
            break
    if dim_ok:
        results.append(('PASS', 'DIMS', f'{cols}x{rows} all layers match'))
        passed += 1
    else:
        results.append(('FAIL', 'DIMS', '; '.join(issues)))

    # 3. EMPTY CELLS: no "0" in utils/ints
    bad_zeros = 0
    for r in range(rows):
        for c in range(cols):
            if ucell(r, c) == '0': bad_zeros += 1
            if icell(r, c) == '0': bad_zeros += 1
    if bad_zeros == 0:
        results.append(('PASS', 'ENCODING', 'No "0" in utils/ints'))
        passed += 1
    else:
        results.append(('FAIL', 'ENCODING', f'{bad_zeros} cells use "0" instead of " "'))

    # 4. TELEPORTER
    has_tele = False
    for r in range(rows):
        for c in range(cols):
            u = ucell(r, c)
            if u.startswith('t:') or u.startswith('t3:') or u == 't':
                has_tele = True
                break
        if has_tele: break
    if has_tele:
        results.append(('PASS', 'TELEPORTER', 'Found'))
        passed += 1
    else:
        results.append(('FAIL', 'TELEPORTER', 'No teleporter (t: or t3:) in utilities'))

    # 5. SCORE POINT
    has_sp = False
    for r in range(rows):
        for c in range(cols):
            if ucell(r, c) == 'sp':
                has_sp = True; break
        if has_sp: break
    if has_sp:
        results.append(('PASS', 'SCOREPOINT', 'Found'))
        passed += 1
    else:
        results.append(('WARN', 'SCOREPOINT', 'No sp in utilities'))

    # 6. SPAWN MARKER
    has_spawn = False
    for r in range(rows):
        for c in range(cols):
            if ucell(r, c).startswith('s') and not ucell(r, c).startswith('sp') and not ucell(r, c).startswith('sub') and not ucell(r, c).startswith('sc'):
                has_spawn = True; break
        if has_spawn: break
    if has_spawn:
        results.append(('PASS', 'SPAWN_MARKER', 'Found'))
        passed += 1
    else:
        results.append(('WARN', 'SPAWN_MARKER', 'No s in utilities (default [0,0])'))

    # 7. ANNOTATION
    has_an = False
    for r in range(rows):
        for c in range(cols):
            u = ucell(r, c)
            if u.startswith('an'):
                has_an = True; break
        if has_an: break
    if has_an:
        results.append(('PASS', 'ANNOTATION', 'Found'))
        passed += 1
    else:
        results.append(('WARN', 'ANNOTATION', 'No an (annotation board) in utilities'))

    # 8. REGISTRY: all artifacts registered
    registry = get_registry()
    unregistered = []
    for r in range(rows):
        for c in range(cols):
            cell = icell(r, c)
            if cell and cell != ' ':
                art = cell.split(':')[0].split('#')[0]
                if art not in registry:
                    unregistered.append(art)
    unregistered = list(set(unregistered))
    if not unregistered:
        results.append(('PASS', 'REGISTRY', 'All artifacts registered'))
        passed += 1
    else:
        results.append(('FAIL', 'REGISTRY', f'{len(unregistered)} unregistered: {", ".join(sorted(unregistered))}'))

    # 9. WALKABILITY: flood fill from spawn
    hmap = {}
    for r in range(rows):
        for c in range(min(cols, len(struct[r]))):
            hmap[(r, c)] = h(r, c)

    wp_cells = set()
    tc_edges = []
    for r in range(rows):
        for c in range(cols):
            u = ucell(r, c)
            if u.startswith('wp'):
                wp_cells.add((r, c))
            elif u.startswith('tc'):
                parts = u.split(':')
                if len(parts) >= 3:
                    try:
                        dist = int(parts[1])
                        direction = parts[2]
                        if direction == 'z':
                            for d in [(r+dist, c), (r-dist, c)]:
                                if 0 <= d[0] < rows and 0 <= d[1] < cols:
                                    tc_edges.append(((r,c), d))
                        elif direction == 'x':
                            for d in [(r, c+dist), (r, c-dist)]:
                                if 0 <= d[0] < rows and 0 <= d[1] < cols:
                                    tc_edges.append(((r,c), d))
                        elif direction == 'y':
                            for dr2, dc2 in [(-1,0),(1,0),(0,-1),(0,1)]:
                                adj = (r+dr2, c+dc2)
                                if 0 <= adj[0] < rows and 0 <= adj[1] < cols:
                                    tc_edges.append(((r,c), adj))
                    except:
                        pass

    spawn = (0, 0)
    for r in range(rows):
        for c in range(cols):
            u = ucell(r, c)
            if u.startswith('s') and not u.startswith('sp') and not u.startswith('sub') and not u.startswith('sc'):
                spawn = (r, c)
                break

    visited = flood_fill(hmap, wp_cells, tc_edges, spawn, rows, cols)

    # Check artifacts reachable
    unreachable_arts = []
    for r in range(rows):
        for c in range(cols):
            cell = icell(r, c)
            if cell and cell != ' ':
                if (r, c) not in visited:
                    art = cell.split(':')[0].split('#')[0]
                    unreachable_arts.append(f'{art}({c},{r})')

    # Check teleporter/sp reachable
    # Teleporter on void (exit pattern) counts as reachable if any adjacent cell is visited
    unreachable_exits = []
    for r in range(rows):
        for c in range(cols):
            u = ucell(r, c)
            if u.startswith('t:') or u.startswith('t3:') or u == 't' or u == 'sp':
                if (r, c) not in visited:
                    # If on void, check if any adjacent cell is reachable (exit ring pattern)
                    if h(r, c) == 0:
                        ring_reached = any((r+dr, c+dc) in visited 
                                          for dr in [-1,0,1] for dc in [-1,0,1] 
                                          if not (dr==0 and dc==0))
                        if ring_reached:
                            continue  # reachable via ring
                    unreachable_exits.append(f'{u}({c},{r})')

    if not unreachable_arts and not unreachable_exits:
        results.append(('PASS', 'WALKABILITY', 'All targets reachable from spawn'))
        passed += 1
    else:
        issues = unreachable_arts + unreachable_exits
        results.append(('FAIL', 'WALKABILITY', f'{len(issues)} unreachable: {", ".join(issues[:5])}'))

    # 10. NO LIFTS
    has_lift = False
    for r in range(rows):
        for c in range(cols):
            u = ucell(r, c)
            if u == 'l' or u.startswith('l:'):
                has_lift = True; break
        if has_lift: break
    if not has_lift:
        results.append(('PASS', 'NO_LIFTS', 'No l: in utilities'))
        passed += 1
    else:
        results.append(('FAIL', 'NO_LIFTS', 'Uses l: (lift) — replace with tc'))

    # 11. ARTIFACTS NOT ON VOID
    void_arts = []
    for r in range(rows):
        for c in range(cols):
            cell = icell(r, c)
            if cell and cell != ' ' and h(r, c) == 0:
                art = cell.split(':')[0].split('#')[0]
                void_arts.append(f'{art}({c},{r})')
    if not void_arts:
        results.append(('PASS', 'NO_VOID_ART', 'No artifacts on void cells'))
        passed += 1
    else:
        results.append(('FAIL', 'NO_VOID_ART', f'{len(void_arts)} on void: {", ".join(void_arts[:5])}'))

    # 12. EXIT PATTERN: 3x3 floor with void center for teleporter
    # Find teleporter position, check surrounding 3x3
    tele_pos = None
    for r in range(rows):
        for c in range(cols):
            u = ucell(r, c)
            if u.startswith('t:') or u.startswith('t3:') or u == 't':
                tele_pos = (r, c)
                break
        if tele_pos:
            break
    
    if tele_pos:
        tr, tc_ = tele_pos
        exit_ok = True
        issues = []
        # Center must be void (h=0)
        if h(tr, tc_) != 0:
            exit_ok = False
            issues.append(f'teleporter at ({tc_},{tr}) h={h(tr,tc_)}, need h=0')
        # Surrounding 8 cells must be h=1
        for dr in [-1, 0, 1]:
            for dc in [-1, 0, 1]:
                if dr == 0 and dc == 0:
                    continue
                nr, nc = tr + dr, tc_ + dc
                if 0 <= nr < rows and 0 <= nc < cols:
                    ch = h(nr, nc)
                    if ch != 1:
                        exit_ok = False
                        issues.append(f'exit ring ({nc},{nr}) h={ch}, need h=1')
                else:
                    exit_ok = False
                    issues.append(f'exit ring ({tc_+dc},{tr+dr}) out of bounds')
        if exit_ok:
            results.append(('PASS', 'EXIT_PATTERN', f'3x3 exit at ({tc_},{tr}) correct'))
            passed += 1
        else:
            results.append(('FAIL', 'EXIT_PATTERN', '; '.join(issues[:3])))
    else:
        results.append(('WARN', 'EXIT_PATTERN', 'No teleporter found to check'))

    return name, results, passed


# ─── Output ───

def print_results(name, results, passed):
    total = len(results)
    fails = sum(1 for r in results if r[0] == 'FAIL')
    warns = sum(1 for r in results if r[0] == 'WARN')

    if fails == 0 and warns == 0:
        grade = 'A'
    elif fails == 0:
        grade = 'B'
    elif fails <= 2:
        grade = 'C'
    else:
        grade = 'F'

    status = 'OK' if fails == 0 else 'XX'
    print(f'{status} [{grade}] {name}  ({passed}/{total} pass, {warns} warn, {fails} fail)')

    for level, check, msg in results:
        if level == 'FAIL':
            sym = 'X'
        elif level == 'WARN':
            sym = '!'
        else:
            sym = ' ' if '--verbose' not in sys.argv else '+'
            if '--verbose' not in sys.argv:
                continue
        print(f'  {sym} {check}: {msg}')


# ─── CLI ───

if __name__ == '__main__':
    paths = []
    if '--today' in sys.argv:
        prefixes = ['ML_', 'GT_', 'PG_', 'SwarmIntelligence_', 'LSystems_AnimatedTree',
                     'LSystems_CityGenerator', 'LSystems_ContextSensitiveTree',
                     'LSystems_ForestCompetition', 'LSystems_Hilbert3D',
                     'CriticalAlgorithms_Algorithmic_Bias', 'SpeculativeComputation_Rhizome',
                     'AdvancedLaboratory_Lab']
        mdir = os.path.join(PROJECT, 'commons', 'maps')
        for folder in sorted(os.listdir(mdir)):
            if any(folder.startswith(p) for p in prefixes):
                f = os.path.join(mdir, folder, 'map_data.json')
                if os.path.isfile(f):
                    paths.append(f)
    elif '--all-curriculum' in sys.argv:
        seq_dir = os.path.join(PROJECT, 'commons', 'maps', 'sequences')
        maps = set()
        for sf in os.listdir(seq_dir):
            if not sf.endswith('.json'): continue
            with open(os.path.join(seq_dir, sf), 'r', encoding='utf-8-sig') as fh:
                d = json.load(fh)
            seqs = d.get('sequences', d)
            if isinstance(seqs, dict):
                for seq in seqs.values():
                    if isinstance(seq, dict):
                        for m in seq.get('maps', []):
                            maps.add(m)
        paths = [os.path.join(PROJECT, 'commons', 'maps', m, 'map_data.json')
                 for m in sorted(maps)
                 if os.path.isfile(os.path.join(PROJECT, 'commons', 'maps', m, 'map_data.json'))]
    else:
        paths = [a for a in sys.argv[1:] if not a.startswith('--')]

    if not paths:
        print('Usage: map_checklist.py <path> | --today | --all-curriculum [--verbose]')
        sys.exit(1)

    total_pass = 0
    total_fail = 0
    for path in paths:
        name, results, passed = run_checklist(path)
        print_results(name, results, passed)
        if any(r[0] == 'FAIL' for r in results):
            total_fail += 1
        else:
            total_pass += 1

    print(f'\n=== {total_pass} PASS, {total_fail} FAIL out of {len(paths)} maps ===')
