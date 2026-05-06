#!/usr/bin/env python3
"""
Classify artifacts into 7 natural types by reading their GDScript source.

Types:
  1. interaction_object   — grabbable, throwable, physical feedback
  2. button_simulation    — button/slider triggered, step-by-step
  3. auto_generative      — self-building structures, growth
  4. navigable_landscape  — walkable terrain, spatial experience
  5. floating_data        — abstract visualization, no ground
  6. particle_swarm       — living particles, ambient creatures
  7. minimal_demo         — simple transform, concept in one glance

Usage:
  python tools/classify_artifact_types.py                    # all artifacts
  python tools/classify_artifact_types.py --sequence randomness  # one sequence
  python tools/classify_artifact_types.py --save             # write to registry
"""
import json
import glob
import os
import sys
import re

def classify_from_code(gd_path):
    """Read GDScript and classify by heuristics."""
    if not os.path.exists(gd_path):
        return "unknown", 0.0

    try:
        code = open(gd_path, encoding='utf-8', errors='ignore').read().lower()
    except Exception:
        return "unknown", 0.0

    scores = {
        "interaction_object": 0,
        "button_simulation": 0,
        "auto_generative": 0,
        "navigable_landscape": 0,
        "floating_data": 0,
        "particle_swarm": 0,
        "minimal_demo": 0,
    }

    lines = code.count('\n')

    # Interaction Object signals
    if 'xrtoolspickable' in code or 'grabbed' in code or 'pickup' in code:
        scores["interaction_object"] += 5
    if 'throw' in code or 'toss' in code or 'shake' in code:
        scores["interaction_object"] += 3
    if 'rigidbody' in code and 'apply_impulse' in code:
        scores["interaction_object"] += 2

    # Button Simulation signals
    if 'push_button' in code or 'slider_horizontal' in code:
        scores["button_simulation"] += 5
    if 'button_pressed' in code or 'slider_moved' in code:
        scores["button_simulation"] += 3
    if '_step' in code or 'iteration' in code or 'step_count' in code:
        scores["button_simulation"] += 2

    # Auto Generative signals
    if 'grow' in code or 'generate' in code or 'build' in code:
        scores["auto_generative"] += 2
    if '_step_sim' in code or 'propagat' in code or 'branch' in code:
        scores["auto_generative"] += 3
    if 'arraymesh' in code or 'immediatemesh' in code:
        scores["auto_generative"] += 2
    if 'grid' in code and ('cell' in code or 'automata' in code or 'ca ' in code):
        scores["auto_generative"] += 3

    # Navigable Landscape signals
    if 'terrain' in code or 'landscape' in code or 'heightmap' in code:
        scores["navigable_landscape"] += 5
    if 'planemesh' in code and ('noise' in code or 'height' in code):
        scores["navigable_landscape"] += 3
    if 'staticbody3d' in code and 'collisionshape' in code and 'planemesh' in code:
        scores["navigable_landscape"] += 2

    # Floating Data signals
    if 'distribution' in code or 'histogram' in code or 'probability' in code:
        scores["floating_data"] += 5
    if 'label3d' in code and ('value' in code or 'mean' in code or 'std' in code):
        scores["floating_data"] += 2
    if 'chart' in code or 'axis' in code or 'plot' in code:
        scores["floating_data"] += 3

    # Particle Swarm signals
    if 'particle' in code or 'gpuparticle' in code or 'cpuparticle' in code:
        scores["particle_swarm"] += 5
    if 'spawn' in code and ('creature' in code or 'butterfly' in code or 'bubble' in code):
        scores["particle_swarm"] += 4
    if 'swarm' in code or 'flock' in code or 'boid' in code:
        scores["particle_swarm"] += 3
    if 'trail' in code and 'accumulate' in code:
        scores["particle_swarm"] += 2

    # Minimal Demo signals (fallback for small files)
    if lines < 60:
        scores["minimal_demo"] += 4
    if lines < 30:
        scores["minimal_demo"] += 4
    if 'multimesh' in code and lines < 100:
        scores["minimal_demo"] += 3
    if re.search(r'(rotate|scale|translate|position).*rand', code) and lines < 80:
        scores["minimal_demo"] += 3

    # Pick highest
    best_type = max(scores, key=scores.get)
    best_score = scores[best_type]
    confidence = min(1.0, best_score / 8.0)

    # If nothing scored well, it's minimal_demo
    if best_score < 2:
        return "minimal_demo", 0.3

    return best_type, round(confidence, 2)


def find_gd_from_scene(scene_path, project_root='.'):
    """Find the .gd file for a scene path."""
    # Convert res:// path to filesystem
    if scene_path.startswith('res://'):
        scene_path = scene_path[6:]
    local = os.path.join(project_root, scene_path)
    directory = os.path.dirname(local)

    # Look for .gd in same directory
    if os.path.isdir(directory):
        for f in os.listdir(directory):
            if f.endswith('.gd') and not f.startswith('test'):
                return os.path.join(directory, f)

    # Try replacing .tscn with .gd
    gd_path = local.replace('.tscn', '.gd')
    if os.path.exists(gd_path):
        return gd_path

    return None


def main():
    args = sys.argv[1:]
    filter_seq = None
    save = '--save' in args

    for i, arg in enumerate(args):
        if arg == '--sequence' and i + 1 < len(args):
            filter_seq = args[i + 1]

    # Load all artifacts
    all_arts = []
    for f in glob.glob('commons/artifacts/registry/*.json'):
        data = json.load(open(f, encoding='utf-8'))
        arts = data.get('artifacts', {})
        if not isinstance(arts, dict):
            continue
        for key, art in arts.items():
            if not isinstance(art, dict):
                continue
            if filter_seq and filter_seq not in art.get('map_sequences', []):
                continue
            art['_key'] = key
            art['_file'] = f
            all_arts.append(art)

    # Classify each
    type_counts = {}
    results = []

    for art in all_arts:
        scene = art.get('scene', '')
        gd = find_gd_from_scene(scene)
        if gd:
            art_type, confidence = classify_from_code(gd)
        else:
            art_type, confidence = 'minimal_demo', 0.2

        results.append({
            'name': art['_key'],
            'type': art_type,
            'confidence': confidence,
        })
        type_counts[art_type] = type_counts.get(art_type, 0) + 1

    # Print summary
    seq_label = f" [{filter_seq}]" if filter_seq else ""
    print(f"\n  Classified {len(results)} artifacts{seq_label}\n")

    print("  Type distribution:")
    for t, c in sorted(type_counts.items(), key=lambda x: -x[1]):
        pct = c / max(len(results), 1) * 100
        bar = '#' * int(pct / 2)
        print(f"    {t:<25s} {c:>4d} ({pct:4.1f}%) {bar}")

    print(f"\n  Per artifact:")
    for r in sorted(results, key=lambda x: (x['type'], -x['confidence'])):
        conf_str = f"{r['confidence']:.0%}"
        print(f"    {r['name']:<40s} {r['type']:<25s} {conf_str}")

    # Save to registry if requested
    if save:
        # Group by registry file
        by_file = {}
        for art, res in zip(all_arts, results):
            f = art['_file']
            if f not in by_file:
                by_file[f] = {}
            by_file[f][art['_key']] = res['type']

        for f, type_map in by_file.items():
            data = json.load(open(f, encoding='utf-8'))
            for key, art_type in type_map.items():
                if key in data.get('artifacts', {}):
                    data['artifacts'][key]['artifact_type'] = art_type
            with open(f, 'w', encoding='utf-8') as fh:
                json.dump(data, fh, indent='\t', ensure_ascii=False)
                fh.write('\n')
        print(f"\n  Saved artifact_type to {len(by_file)} registry files")


if __name__ == '__main__':
    main()
