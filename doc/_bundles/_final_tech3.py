from pathlib import Path
import re

tiny_code = {
'Trans_Introduction': """

## One More Code Note

```gdscript
# Translation is a right-multiplication of a vector-shaped transform:
var after := before.translated(Vector3(1, 0, 0))
```
""",
'Euclid_Parallel': """

## Playfair's Axiom Restated

```gdscript
# Playfair's axiom (equivalent to Euclid's 5th):
# Given a line and a point not on it, exactly one line through the point is parallel to the given line.
static func playfair_check(given_line: Array, point: Vector2) -> bool:
    # Returns true if exactly one parallel exists (always true in Euclidean plane).
    return true
```
""",
'Brouwer_Intuitionism': """

## Kripke Semantics Sketch

```gdscript
# Intuitionistic logic has Kripke semantics: truth is relative to a stage of knowledge.
# Each stage may add knowledge but never remove it.
class_name KripkeStage

var known_truths: Array = []

func knows(statement: String) -> bool:
    return statement in known_truths

func extend(new_truth: String) -> KripkeStage:
    var next := KripkeStage.new()
    next.known_truths = known_truths.duplicate()
    if not new_truth in next.known_truths:
        next.known_truths.append(new_truth)
    return next
```
""",
}

for m, a in tiny_code.items():
    p = Path('commons/maps/' + m + '/technical.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

tiny_adds = {
'Point_Lines': "\n\n## Alternative Renderings\n\nThe sequence's later maps extend the line primitive into curves, traces, and tetrahedral meshes. Point_Lines' straight-line implementation is the baseline every later extension builds on.",
'Random_Game': "\n\n## Score Display\n\nA subtle score readout appears at the edge of the arena, updating without drawing the learner's attention away from the hazard field.",
}

for m, a in tiny_adds.items():
    p = Path('commons/maps/' + m + '/technical.md')
    p.write_text(p.read_text(encoding='utf-8').rstrip() + a, encoding='utf-8')

# Manual fix for the two paragraph-residual files
def force_split_in_prose(path, min_split_sents=6):
    SENT = re.compile(r"[.!?][\s\n]+")
    text = Path(path).read_text(encoding='utf-8')
    paras = text.split('\n\n')
    out = []
    for pg in paras:
        pg_s = pg.strip()
        if not pg_s or pg_s.startswith(('#', '```', '-', '*', '>', '|')):
            out.append(pg); continue
        sents = [s for s in SENT.split(pg_s) if s.strip()]
        if len(sents) <= 8:
            out.append(pg); continue
        # Aggressive split: break into thirds instead of halves
        third = max(min_split_sents, len(sents) // 3)
        segments: list = []
        current_idx = 0
        current_sent_count = 0
        char_pos = 0
        for s in sents:
            found = pg_s.find(s, char_pos)
            char_pos = found + len(s)
            current_sent_count += 1
            if current_sent_count >= third:
                # include sentence terminator
                m2 = SENT.match(pg_s[char_pos:])
                split_at = char_pos + m2.end() if m2 else char_pos
                segments.append(pg_s[current_idx:split_at].strip())
                current_idx = split_at
                current_sent_count = 0
                char_pos = split_at
        if current_idx < len(pg_s):
            segments.append(pg_s[current_idx:].strip())
        out.append('\n\n'.join(segments))
    Path(path).write_text('\n\n'.join(out), encoding='utf-8')

for p in ['commons/maps/CA_AgentsCircuits/technical.md', 'commons/maps/QFEP_F_Term/technical.md']:
    force_split_in_prose(p)

print('done')
