#!/usr/bin/env python3
"""Audit map walkability: can the player reach all artifacts and the teleporter from spawn?

Player movement rules:
- Walk between adjacent cells (4-connected) at the SAME height (height > 0)
- Height 0 = void (unwalkable without tc)
- wp (walkable prism) = ramp connecting adjacent cells of DIFFERENT heights
- tc:D:z = transport cube moving D cells along rows (bridges voids + heights)
- tc:D:x = transport cube moving D cells along columns
- tc:D:y = transport cube moving vertically (height change at same/nearby position)
"""

import json, sys, os
from collections import deque

def load_map(path):
    with open(path, 'r', encoding='utf-8-sig') as f:
        return json.load(f)

def parse_height(cell):
    try:
        h = int(str(cell).strip())
        return h if h > 0 else 0
    except:
        return 0

def find_spawn(utils):
    for r, row in enumerate(utils):
        for c, cell in enumerate(row):
            if str(cell).strip().startswith('s'):
                return (r, c)
    return (0, 0)

def audit_walkability(path):
    data = load_map(path)
    name = data.get('map_info', {}).get('lookup_name', os.path.basename(os.path.dirname(path)))
    
    struct = data.get('layers', {}).get('structure', [])
    utils = data.get('layers', {}).get('utilities', [])
    ints = data.get('layers', {}).get('interactables', [])
    
    if not struct:
        return {'name': name, 'status': 'NO_STRUCTURE'}
    
    rows = len(struct)
    cols = max(len(r) for r in struct) if struct else 0
    
    # Height map (0 = void/unwalkable)
    hmap = {}
    for r in range(rows):
        for c in range(min(cols, len(struct[r]))):
            hmap[(r, c)] = parse_height(struct[r][c])
    
    # Parse utilities
    util_map = {}
    for r in range(min(rows, len(utils))):
        for c in range(min(cols, len(utils[r]))):
            cell = str(utils[r][c]).strip()
            if cell and cell != ' ':
                util_map[(r, c)] = cell
    
    # Find wp cells
    wp_cells = set()
    for pos, cell in util_map.items():
        if cell.startswith('wp'):
            wp_cells.add(pos)
    
    # Build tc bridge edges: each tc creates bidirectional connections
    # tc:D:z → connects (r,c) area to (r±D, c) area
    # tc:D:x → connects (r,c) area to (r, c±D) area  
    # tc:D:y → vertical at same position (connects heights)
    # The tc itself is standable even on void
    tc_bridges = []  # list of (pos1, pos2) — bidirectional bridge pairs
    tc_positions = set()
    
    for pos, cell in util_map.items():
        if not cell.startswith('tc'):
            continue
        parts = cell.split(':')
        if len(parts) < 3:
            continue
        try:
            dist = int(parts[1])
            direction = parts[2]
        except:
            continue
        
        r, c = pos
        tc_positions.add(pos)
        
        if direction == 'z':
            # Bridge along rows
            dest1 = (r + dist, c)
            dest2 = (r - dist, c)
            for d in [dest1, dest2]:
                if 0 <= d[0] < rows and 0 <= d[1] < cols:
                    tc_bridges.append((pos, d))
        elif direction == 'x':
            # Bridge along columns
            dest1 = (r, c + dist)
            dest2 = (r, c - dist)
            for d in [dest1, dest2]:
                if 0 <= d[0] < rows and 0 <= d[1] < cols:
                    tc_bridges.append((pos, d))
        elif direction == 'y':
            # Vertical — connects to adjacent cells at different heights
            for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                adj = (r + dr, c + dc)
                if 0 <= adj[0] < rows and 0 <= adj[1] < cols:
                    tc_bridges.append((pos, adj))
    
    # Walkable cells: height > 0 OR has tc on it
    walkable = set()
    for pos, h in hmap.items():
        if h > 0:
            walkable.add(pos)
    for pos in tc_positions:
        walkable.add(pos)
    
    # Find spawn
    spawn = find_spawn(utils)
    if spawn not in walkable:
        # Spawn might be on void with special offset — flag but continue
        walkable.add(spawn)
    
    # Flood fill with walking + wp + tc rules
    visited = set()
    queue = deque([spawn])
    visited.add(spawn)
    
    # Pre-build tc adjacency for fast lookup
    tc_adj = {}  # pos -> set of positions reachable via tc
    for a, b in tc_bridges:
        tc_adj.setdefault(a, set()).add(b)
        tc_adj.setdefault(b, set()).add(a)
    
    while queue:
        pos = queue.popleft()
        r, c = pos
        cur_h = hmap.get(pos, 0)
        
        # Walk to 4-connected neighbors
        for dr, dc in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            nb = (r + dr, c + dc)
            if nb in visited or nb not in walkable:
                continue
            nb_h = hmap.get(nb, 0)
            
            # Same height → walk
            if nb_h == cur_h and nb_h > 0:
                visited.add(nb)
                queue.append(nb)
            # wp at either cell → can traverse height difference
            elif pos in wp_cells or nb in wp_cells:
                if nb_h > 0:  # destination must be walkable
                    visited.add(nb)
                    queue.append(nb)
            # height 1 difference → player can step up/down 1 level
            # (In many VR games including Godot, 1-height-step is walkable)
            # Actually in AdaResearch, heights are 1m cubes, player CAN'T step up
            # Keep strict: require wp/tc for ANY height change
        
        # TC connections from this position
        if pos in tc_adj:
            for dest in tc_adj[pos]:
                if dest not in visited and dest in walkable:
                    visited.add(dest)
                    queue.append(dest)
    
    # Check what's unreachable
    unreachable_arts = []
    for r in range(min(rows, len(ints))):
        for c in range(min(cols, len(ints[r]))):
            cell = str(ints[r][c]).strip()
            if cell and cell != ' ':
                art_name = cell.split(':')[0].split('#')[0]
                if (r, c) not in visited:
                    on_void = hmap.get((r, c), 0) == 0
                    unreachable_arts.append({
                        'name': art_name, 'row': r, 'col': c,
                        'height': hmap.get((r, c), 0),
                        'on_void': on_void
                    })
    
    unreachable_utils = []
    for pos, cell in util_map.items():
        is_exit = cell.startswith('t:') or cell == 't' or cell.startswith('t3:') or cell == 'sp' or cell.startswith('t:lab')
        if is_exit and pos not in visited:
            unreachable_utils.append({
                'name': cell, 'row': pos[0], 'col': pos[1],
                'height': hmap.get(pos, 0)
            })
    
    return {
        'name': name,
        'status': 'OK' if not unreachable_arts and not unreachable_utils else 'FAIL',
        'reached': len(visited),
        'total_walkable': len(walkable),
        'unreachable_arts': unreachable_arts,
        'unreachable_utils': unreachable_utils,
        'has_height_islands': len(visited) < len(walkable)
    }


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: audit_walkability.py <map_data.json ...> | --all-curriculum | --today")
        sys.exit(1)
    
    paths = []
    verbose = '--verbose' in sys.argv
    
    if '--all-curriculum' in sys.argv:
        seq_dir = 'commons/maps/sequences'
        maps = set()
        for sf in os.listdir(seq_dir):
            if not sf.endswith('.json'): continue
            with open(os.path.join(seq_dir, sf), 'r', encoding='utf-8-sig') as f:
                d = json.load(f)
            seqs = d.get('sequences', d)
            if isinstance(seqs, dict):
                for seq in seqs.values():
                    if isinstance(seq, dict):
                        for m in seq.get('maps', []):
                            maps.add(m)
        paths = [f'commons/maps/{m}/map_data.json' for m in sorted(maps) if os.path.isfile(f'commons/maps/{m}/map_data.json')]
    elif '--today' in sys.argv:
        # Maps designed today (ML_, GT_, PG_, SwarmIntelligence_, LSystems_, Critical, Speculative, Advanced)
        today_prefixes = ['ML_', 'GT_', 'PG_', 'SwarmIntelligence_', 'LSystems_AnimatedTree', 
                         'LSystems_CityGenerator', 'LSystems_ContextSensitiveTree', 
                         'LSystems_ForestCompetition', 'LSystems_Hilbert3D',
                         'CriticalAlgorithms_Algorithmic_Bias', 'SpeculativeComputation_Rhizome',
                         'AdvancedLaboratory_Lab']
        for folder in os.listdir('commons/maps'):
            if any(folder.startswith(p) for p in today_prefixes):
                f = f'commons/maps/{folder}/map_data.json'
                if os.path.isfile(f):
                    paths.append(f)
        paths.sort()
    else:
        paths = [a for a in sys.argv[1:] if not a.startswith('--')]
    
    fail_count = 0
    ok_count = 0
    island_count = 0
    
    for path in paths:
        result = audit_walkability(path)
        name = result['name']
        status = result['status']
        
        if status == 'NO_STRUCTURE':
            continue
        
        if status == 'FAIL':
            fail_count += 1
            reached = result['reached']
            total = result['total_walkable']
            print(f"FAIL {name}  (reached {reached}/{total} cells)")
            for art in result['unreachable_arts']:
                v = ' [VOID]' if art['on_void'] else ''
                print(f"  artifact: {art['name']} at ({art['col']},{art['row']}) h={art['height']}{v}")
            for util in result['unreachable_utils']:
                print(f"  utility:  {util['name']} at ({util['col']},{util['row']}) h={util['height']}")
        else:
            ok_count += 1
            if result['has_height_islands']:
                island_count += 1
                if verbose:
                    print(f"ISLE {name}  (reached {result['reached']}/{result['total_walkable']} — unreachable floor cells)")
            elif verbose:
                print(f"OK   {name}  ({result['reached']}/{result['total_walkable']})")
    
    print(f"\n=== {ok_count} OK ({island_count} with unreachable floor), {fail_count} FAIL ===")
