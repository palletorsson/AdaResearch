"""Generate 100 diverse critter DNA files for the gallery.

Creates JSON files across all 5 kingdoms with varied genes.
Run: python tools/generate_critter_gallery.py
"""

import json, random, os, math

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "ada_encyclopedia", "public", "captures", "critter-gallery", "dna")
# Also write to a flat batch file for perfect_shot
BATCH_FILE = os.path.join(os.path.dirname(__file__), "..", "ada_encyclopedia", "public", "captures", "critter-gallery", "batch.json")

KINGDOMS = {
    0: "tree",
    1: "creature",
    2: "flower",
    3: "fungus",
}

# How many per kingdom + hybrids
COUNTS = {0: 20, 1: 25, 2: 20, 3: 15, "hybrid": 20}

PALETTES = [
    # warm
    [("e84393", "6c5ce7", "fdcb6e"), ("ff6b6b", "c44569", "f8b500"), ("e17055", "d63031", "ffeaa7")],
    # cool
    [("0984e3", "6c5ce7", "00cec9"), ("a29bfe", "6c5ce7", "00b894"), ("74b9ff", "0984e3", "dfe6e9")],
    # earth
    [("2ecc71", "27ae60", "f1c40f"), ("e67e22", "d35400", "2ecc71"), ("8e6e53", "5d4037", "a1887f")],
    # neon
    [("fd79a8", "e84393", "ffeaa7"), ("00cec9", "81ecec", "fdcb6e"), ("a29bfe", "6c5ce7", "fab1a0")],
    # pastel
    [("dfe6e9", "b2bec3", "ffeaa7"), ("fab1a0", "ff7675", "ffeaa7"), ("c7ecee", "dfe6e9", "ffeaa7")],
]

def rand_range(lo, hi):
    return round(random.uniform(lo, hi), 3)

def pick_palette():
    group = random.choice(PALETTES)
    return random.choice(group)

def make_dna(kingdom_float, name_prefix, idx):
    p, s, t = pick_palette()

    # Base DNA with random values
    dna = {
        "body_type": round(kingdom_float, 2),
        "segments": rand_range(2, 10),
        "symmetry": float(random.randint(2, 8)),
        "scale": rand_range(0.5, 2.5),
        "primary_color": p,
        "secondary_color": s,
        "tertiary_color": t,
        "roughness": rand_range(0.1, 0.9),
        "metallic": rand_range(0, 0.3),
        "iridescence": rand_range(0, 0.8),
        "transparency": rand_range(0, 0.4),
        "cracking": rand_range(0, 0.3),
        "mobility": rand_range(0, 1),
        "aggression": rand_range(0, 0.8),
        "sociality": rand_range(0.1, 0.9),
        "curiosity": rand_range(0.1, 0.9),
        "energy_source": rand_range(0, 2.5),
        "efficiency": rand_range(0.6, 1.8),
        "growth_speed": rand_range(0.5, 1.5),
        "fertility": rand_range(0.2, 0.9),
        "branch_angle": rand_range(15, 80),
        "branch_decay": rand_range(0.3, 0.85),
        "leaf_density": rand_range(0, 1),
        "part_length": rand_range(0.2, 1.8),
        "part_width": rand_range(0.1, 0.8),
        "part_curve": rand_range(0, 0.9),
        "part_taper": rand_range(0.2, 0.9),
        "part_twist": rand_range(-30, 30),
        "part_tilt": rand_range(0, 40),
        "phyllotaxis": rand_range(0, 1),
        "edge_type": rand_range(0, 0.8),
        "base_shape": rand_range(0, 0.8),
        "inflorescence": rand_range(0, 0.8),
        "root_type": rand_range(0, 0.8),
        "scent_strength": rand_range(0, 0.8),
        "nectar_quality": rand_range(0, 0.8),
        "pattern_type": rand_range(0, 1),
        "pattern_density": rand_range(0, 0.8),
        "pattern_scale": rand_range(0.4, 2.0),
        "affinity": rand_range(0.2, 0.9),
        "volatility": rand_range(0, 0.7),
        "latent_ability": rand_range(0, 5),
        "generation": random.randint(0, 8),
        "parent_a_id": "",
        "parent_b_id": "",
        "mutations": [],
    }

    # Kingdom-specific biases
    kingdom_int = round(kingdom_float)
    if kingdom_int == 0:  # tree
        dna["mobility"] = rand_range(0, 0.05)
        dna["aggression"] = rand_range(0, 0.1)
        dna["branch_angle"] = rand_range(20, 60)
        dna["leaf_density"] = rand_range(0.3, 0.95)
        dna["root_type"] = rand_range(0.4, 1.0)
        dna["energy_source"] = rand_range(0, 0.3)
    elif kingdom_int == 1:  # creature
        dna["mobility"] = rand_range(0.3, 1.0)
        dna["curiosity"] = rand_range(0.3, 0.95)
        dna["segments"] = rand_range(3, 9)
        dna["part_length"] = rand_range(0.4, 1.5)
    elif kingdom_int == 2:  # flower
        dna["mobility"] = rand_range(0, 0.02)
        dna["symmetry"] = float(random.choice([3, 4, 5, 6, 7, 8]))
        dna["scent_strength"] = rand_range(0.1, 0.4)  # lower = shorter stem
        dna["nectar_quality"] = rand_range(0.3, 0.9)
        dna["branch_angle"] = rand_range(40, 80)
        dna["roughness"] = rand_range(0.05, 0.35)
        dna["transparency"] = rand_range(0, 0.1)  # keep petals visible
        dna["scale"] = rand_range(1.0, 2.0)  # ensure visible size
        dna["part_width"] = rand_range(0.3, 0.8)  # wider petals
        dna["segments"] = rand_range(2, 4)  # fewer rings = bigger petals
    elif kingdom_int == 3:  # fungus
        dna["mobility"] = rand_range(0, 0.01)
        dna["sociality"] = rand_range(0.4, 0.95)
        dna["transparency"] = rand_range(0, 0.5)
        dna["part_curve"] = rand_range(0.3, 0.95)
        dna["energy_source"] = rand_range(1.0, 2.5)

    return dna

def main():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    all_entries = []
    idx = 0

    # Pure kingdoms
    for kingdom_int, kingdom_name in KINGDOMS.items():
        count = COUNTS[kingdom_int]
        for i in range(count):
            idx += 1
            name = f"{kingdom_name}_{idx:03d}"
            dna = make_dna(float(kingdom_int), kingdom_name, idx)

            # Save individual file
            path = os.path.join(OUTPUT_DIR, f"{name}.json")
            with open(path, "w") as f:
                json.dump(dna, f, indent=2)

            all_entries.append({
                "mode": "critter",
                "dna": os.path.abspath(path).replace("\\", "/"),
                "target": name,
                "id": name,
                "kingdom": kingdom_name,
                "body_type": dna["body_type"],
                "generation": dna["generation"],
            })

    # Hybrids
    hybrid_pairs = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (0, 3)]
    for i in range(COUNTS["hybrid"]):
        idx += 1
        a, b = random.choice(hybrid_pairs)
        bt = a + random.uniform(0.3, 0.7)  # Fractional body_type
        if random.random() < 0.5:
            bt = b - random.uniform(0.3, 0.7) if b > a else bt
        bt = max(0.1, min(3.9, bt))

        name = f"hybrid_{idx:03d}"
        dna = make_dna(bt, "hybrid", idx)

        path = os.path.join(OUTPUT_DIR, f"{name}.json")
        with open(path, "w") as f:
            json.dump(dna, f, indent=2)

        all_entries.append({
            "mode": "critter",
            "dna": os.path.abspath(path).replace("\\", "/"),
            "target": name,
            "id": name,
            "kingdom": "hybrid",
            "body_type": dna["body_type"],
            "generation": dna["generation"],
        })

    # Save batch file
    os.makedirs(os.path.dirname(BATCH_FILE), exist_ok=True)
    with open(BATCH_FILE, "w") as f:
        json.dump(all_entries, f, indent=2)

    # Save index for the web gallery
    index_path = os.path.join(os.path.dirname(BATCH_FILE), "index.json")
    with open(index_path, "w") as f:
        json.dump(all_entries, f, indent=2)

    print(f"Generated {len(all_entries)} critter DNAs")
    print(f"  Trees: {COUNTS[0]}")
    print(f"  Creatures: {COUNTS[1]}")
    print(f"  Flowers: {COUNTS[2]}")
    print(f"  Fungi: {COUNTS[3]}")
    print(f"  Hybrids: {COUNTS['hybrid']}")
    print(f"DNA dir: {OUTPUT_DIR}")
    print(f"Batch file: {BATCH_FILE}")
    print(f"\nTo capture all:")
    print(f"  godot --path . --xr-mode off --no-window --script res://commons/testing/perfect_shot.gd -- --mode=batch --targets={BATCH_FILE} --hero-only")

if __name__ == "__main__":
    main()
