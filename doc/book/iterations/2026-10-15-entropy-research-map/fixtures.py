"""Exact authored examples for the entropy brief, not a game/learner trial."""
from collections import Counter, defaultdict
from itertools import combinations
from math import comb, isclose, log, log2
from pathlib import Path
import json


def entropy(counts):
    total = sum(counts)
    return -sum((n / total) * log2(n / total) for n in counts if n) if total else 0.0


def conditional_cyclic(record, history):
    groups = defaultdict(Counter)
    for i, symbol in enumerate(record):
        context = tuple(record[(i - history + j) % len(record)] for j in range(history))
        groups[context][symbol] += 1
    return sum(sum(c.values()) / len(record) * entropy(c.values()) for c in groups.values())


records = {}
for name, text in [("alternating", "01010101"), ("paired", "00110011")]:
    record = list(map(int, text))
    records[name] = {
        "record": text,
        "boundary": "cyclic; last symbol precedes the first",
        "H_symbol_bits": entropy(Counter(record).values()),
        "H_next_given_one_bits": conditional_cyclic(record, 1),
        "H_next_given_two_bits": conditional_cyclic(record, 2),
    }
assert records["alternating"]["H_symbol_bits"] == records["paired"]["H_symbol_bits"] == 1.0
assert records["alternating"]["H_next_given_one_bits"] == 0.0
assert records["paired"]["H_next_given_one_bits"] == 1.0
assert records["alternating"]["H_next_given_two_bits"] == records["paired"]["H_next_given_two_bits"] == 0.0

enumerated = Counter(sum(site < 8 for site in occupied) for occupied in combinations(range(16), 8))
multiplicity = []
for k in range(9):
    omega = comb(8, k) * comb(8, 8 - k)
    assert enumerated[k] == omega
    multiplicity.append({"A_in_left": k, "omega": omega, "ln_omega": log(omega)})
assert sum(enumerated.values()) == comb(16, 8) == 12870
assert enumerated[8] == 1 and enumerated[4] == 4900
weights = [4, 2, 1, 1]
assert isclose(entropy(weights), 1.75)
assert -log2(max(weights) / sum(weights)) == 1.0

result = {
    "status": "calculated authored fixtures; not observed game, thermal or learner outcomes",
    "cyclic_records": records,
    "sixteen_site_model": {
        "sites_per_compartment": 8,
        "total_A": 8,
        "total_B": 8,
        "global_colour_entropy_bits": 1.0,
        "arrangements_enumerated": sum(enumerated.values()),
        "macrostate_multiplicities": multiplicity,
        "limit": "Occupancy configurations only; no temperature, energy or physical dynamics modelled.",
    },
    "declared_probability_law": {"p": [0.5, 0.25, 0.125, 0.125], "shannon_bits": 1.75, "min_entropy_bits": 1.0},
}
path = Path(__file__).with_name("fixtures.json")
path.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
print("PASS: cyclic conditional examples; all 12,870 site arrangements; Shannon/min-entropy comparison.")
print("No game run or learner result is implied.")
