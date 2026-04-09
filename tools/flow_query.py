#!/usr/bin/env python3
"""
Flow Query — CLI for searching and reading thinking paths.

Usage:
  python tools/flow_query.py                     # list all flows
  python tools/flow_query.py screenshot           # search by trigger
  python tools/flow_query.py --id capture-debug   # get one flow (full walkthrough)
  python tools/flow_query.py --new my-flow        # scaffold a new flow
  python tools/flow_query.py --learn "I discovered X solves Y"  # quick-add from discovery
"""
import json
import os
import sys
import glob
from datetime import date

FLOWS_DIR = os.path.join(os.path.dirname(__file__), '..', '.claude', 'flows')

# Fix Windows console encoding
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')


def load_flows():
    flows = []
    for f in glob.glob(os.path.join(FLOWS_DIR, '*.json')):
        try:
            data = json.load(open(f, encoding='utf-8'))
            data['_file'] = os.path.basename(f)
            flows.append(data)
        except Exception:
            pass
    return flows


def list_flows(flows):
    print(f"\n  {len(flows)} flows in .claude/flows/\n")
    # Group by category from triggers
    for f in sorted(flows, key=lambda x: x.get('granularity', '')):
        nodes = len(f.get('nodes', []))
        triggers = ', '.join(f.get('triggers', [])[:3])
        print(f"  {f['id']:<30s} {nodes:>2d} nodes  {f.get('granularity','?'):>5s}  triggers: {triggers}")
    print()


def search_flows(flows, query):
    q = query.lower()
    matches = []
    for f in flows:
        score = 0
        for t in f.get('triggers', []):
            if q in t.lower():
                score += 10
        if q in f.get('title', '').lower():
            score += 5
        if q in f.get('description', '').lower():
            score += 2
        if score > 0:
            matches.append((score, f))

    matches.sort(key=lambda x: -x[0])

    if not matches:
        print(f"\n  No flows match '{query}'. Try: python tools/flow_query.py --list\n")
        return

    print(f"\n  {len(matches)} flows match '{query}':\n")
    for score, f in matches:
        print(f"  [{score:>2d}] {f['id']}")
        print(f"       {f['title']} — {f.get('granularity','?')}, {len(f.get('nodes',[]))} nodes")
        print(f"       triggers: {', '.join(f.get('triggers', []))}")
        print()

    # Auto-show the best match as a walkthrough
    if matches:
        best = matches[0][1]
        print(f"  === Best match: {best['title']} ===\n")
        show_flow(best)


def show_flow(f):
    print(f"  {f['title']}")
    print(f"  {f.get('description', '')}")
    print(f"  Earned from: {f.get('earned_from', '?')}")
    print(f"  Model: {f.get('model_version', '?')} | Updated: {f.get('updated', '?')}")
    print()

    # Build edge map
    edge_map = {}
    for e in f.get('edges', []):
        if e['from'] not in edge_map:
            edge_map[e['from']] = []
        edge_map[e['from']].append(e)

    node_map = {n['id']: n for n in f.get('nodes', [])}

    for node in f.get('nodes', []):
        icon = {'start': 'O', 'action': '>', 'decision': '?', 'end': '.'}
        print(f"  [{icon.get(node['type'], ' ')}] {node['label']}")
        if node.get('detail'):
            # Wrap detail at 70 chars
            detail = node['detail']
            while len(detail) > 70:
                split = detail[:70].rfind(' ')
                if split < 30:
                    split = 70
                print(f"      {detail[:split]}")
                detail = detail[split:].strip()
            if detail:
                print(f"      {detail}")
        if node.get('code'):
            for line in node['code'].split('\n'):
                print(f"      | {line}")

        # Show edges
        for e in edge_map.get(node['id'], []):
            target = node_map.get(e['to'], {})
            label = f" ({e['label']})" if e.get('label') else ""
            print(f"      -> {target.get('label', e['to'])}{label}")
        print()


def get_flow(flows, flow_id):
    for f in flows:
        if f['id'] == flow_id:
            return f
    return None


def scaffold_new(flow_id):
    """Create a new empty flow scaffold."""
    path = os.path.join(FLOWS_DIR, f'{flow_id}.json')
    if os.path.exists(path):
        print(f"  Flow '{flow_id}' already exists at {path}")
        return

    scaffold = {
        "id": flow_id,
        "title": flow_id.replace('-', ' ').title(),
        "description": "TODO: describe this thinking path",
        "triggers": ["TODO"],
        "granularity": "meso",
        "model_version": "opus-4.6",
        "created": str(date.today()),
        "updated": str(date.today()),
        "earned_from": "TODO: which session/experience taught this",
        "nodes": [
            {"id": "start", "type": "start", "label": "Begin"},
            {"id": "step1", "type": "action", "label": "TODO: first step"},
            {"id": "decide", "type": "decision", "label": "TODO: decision point"},
            {"id": "done", "type": "end", "label": "Done"}
        ],
        "edges": [
            {"from": "start", "to": "step1"},
            {"from": "step1", "to": "decide"},
            {"from": "decide", "to": "done", "label": "yes"},
            {"from": "decide", "to": "step1", "label": "no — iterate"}
        ]
    }

    with open(path, 'w', encoding='utf-8') as f:
        json.dump(scaffold, f, indent=2, ensure_ascii=False)

    print(f"  Created scaffold: {path}")
    print(f"  Edit the file, then run: python tools/flow_query.py --id {flow_id}")


def quick_learn(discovery):
    """Quick-add a flow from a one-line discovery."""
    # Parse "X solves Y" pattern
    words = discovery.lower().split()
    flow_id = '-'.join(words[:4]).replace('/', '-').replace('.', '-')

    path = os.path.join(FLOWS_DIR, f'{flow_id}.json')
    today = str(date.today())

    flow = {
        "id": flow_id,
        "title": discovery[:60],
        "description": discovery,
        "triggers": words[:3],
        "granularity": "micro",
        "model_version": "opus-4.6",
        "created": today,
        "updated": today,
        "earned_from": f"quick-learn {today}",
        "nodes": [
            {"id": "start", "type": "start", "label": "Problem encountered"},
            {"id": "fix", "type": "action", "label": discovery},
            {"id": "done", "type": "end", "label": "Fixed"}
        ],
        "edges": [
            {"from": "start", "to": "fix"},
            {"from": "fix", "to": "done"}
        ]
    }

    with open(path, 'w', encoding='utf-8') as f:
        json.dump(flow, f, indent=2, ensure_ascii=False)

    print(f"  Quick flow saved: {path}")
    print(f"  Refine later: python tools/flow_query.py --id {flow_id}")


def main():
    args = sys.argv[1:]

    if not args or args == ['--list']:
        flows = load_flows()
        list_flows(flows)
        return

    if args[0] == '--id' and len(args) > 1:
        flows = load_flows()
        f = get_flow(flows, args[1])
        if f:
            show_flow(f)
        else:
            print(f"  Flow '{args[1]}' not found. Available: {', '.join(f['id'] for f in flows)}")
        return

    if args[0] == '--new' and len(args) > 1:
        scaffold_new(args[1])
        return

    if args[0] == '--learn' and len(args) > 1:
        quick_learn(' '.join(args[1:]))
        return

    # Default: search
    flows = load_flows()
    search_flows(flows, ' '.join(args))


if __name__ == '__main__':
    main()
