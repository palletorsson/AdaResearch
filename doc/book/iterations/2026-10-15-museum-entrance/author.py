"""Apply the entrance and teleporter cells without reformatting the map."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[4]
path = root / "commons/maps/Random_Definition/map_data.json"
text = path.read_text(encoding="utf-8")
changes = {
    "structure": {(5, 0): "1", (6, 0): "1", (7, 0): "1"},
    "utilities": {(6, 1): " ", (6, 0): "s", (6, 27): " ", (6, 36): "t"},
}
for layer, edits in changes.items():
    start = text.index("[", text.index(f'"{layer}":'))
    rows, length = json.JSONDecoder().raw_decode(text[start:])
    tokens = list(re.finditer(r'"(?:[^"\\]|\\.)*"', text[start:start+length]))
    replacements = []
    for (x, z), value in edits.items():
        index = sum(len(row) for row in rows[:z]) + x
        token = tokens[index]
        replacements.append((start+token.start(), start+token.end(), json.dumps(value)))
    for a, b, value in sorted(replacements, reverse=True):
        text = text[:a]+value+text[b:]
path.write_text(text, encoding="utf-8", newline="\n")
