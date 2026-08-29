# Evaluating the concordance pipeline

*A brief for an agent who was not in the room when this was built.*

Written 2026-08-29. You need no prior context. Everything here is a command you
can run against the repository at `C:/Users/palle/Documents/GitHub/AdaResearch_46`
and a statement you can prove false.

---

## 0. What the pipeline is, in one page

Ada Research is a Godot VR/desktop "endless museum": halls hung with *wall works*,
each work an *artifact* with a token like `science_screen`. Alongside it is a
Next.js encyclopedia (`../ada_encyclopedia`, dev on port 3003) and a *book* —
`commons/data/book/<chapter>.json`, 24 chapters of pearls and lines, one line per
artifact.

The pipeline answers two questions and keeps them **separate on purpose**:

| register | question | tool | stores |
|---|---|---|---|
| a **finding** | where *might* this work be discussed? | `tools/concord.py` | nothing |
| a **claim** | where *is* it, and a human says so | `tools/cite_gate.py` | `note_src` in the book |

A claim is `{token, file, quote}` — an artifact, a file, and words copied verbatim
out of it. `cite_gate` never reads the sentence; it asks only whether those words
are still in that file. When somebody edits the room, the claim fails, and the
failure means the writing has gone out of date.

Three more tools sit around that:

- `tools/want_gate.py` — **three directions** of travel (a work needing words, a
  line needing a work built, a thought needing a subject), covering the four wants
  `concord.py --wants` prints. It gates **dishonest closure**, not open wants.
- `tools/concord_parity.py` — a second implementation of the mention rule exists in
  TypeScript; this measures how far the two disagree.
- `tools/edge_gate.py` — pre-existing; judges the 269 "edge" sentences in the book.

Web surfaces: `/wall-map` (a panel *this work in the text*), `/book` (renders the
prose), `/lines` (the book as rows). API op `token_text` on `/api/trunk`.

---

## 1. Before you assert anything: which numbers are allowed to move

**This repository is edited by several agents and by a human, concurrently, while
you evaluate it.** Between two runs an hour apart on the day this was written, the
corpus went 2778 → 2779 passages and one want went 1638 → 1649, because a parallel
session placed eleven artifacts and a blog post was committed. An evaluation that
asserts constants will report failures that are not failures.

So every claim below is tagged:

- **INVARIANT** — must hold on any checkout, forever. A violation is a real bug.
- **STABLE** — derived from `commons/data/book/*.json`, which changes rarely.
  Treat a mismatch as *investigate*, not *fail*, and say what moved.
- **DRIFTING** — a live count. **Do not compare to the number printed here.**
  Re-derive it and check the *relationship* the claim states.

Record the checkout you evaluated:

```bash
git -C . rev-parse --short HEAD && git -C . status --porcelain | wc -l
```

A large dirty count is normal here (700+). It is not a problem to fix.

---

## 2. Setup

```bash
cd C:/Users/palle/Documents/GitHub/AdaResearch_46
python --version          # 3.10+ expected
python tools/concord.py --stats
```

The web surfaces need the encyclopedia dev server. **A server may already be
running on 3003 that you must not disturb.** To get your own, use the
`encyclopedia-alt` launch config — it sets `NEXT_DIST_DIR=.next-alt` on port 3013,
which `next.config` honours, so two servers never share a build directory. Do not
start a second `next dev` in the same folder without that.

If you cannot get a server, say so and mark every §6 claim UNTESTED. Do not infer
them from source.

---

## 3. Claims about the finding register (`concord.py`)

**C1 · INVARIANT · The search must not borrow the gate's normaliser.**

`tools/edge_gate.py`'s `norm()` strips markdown emphasis, which deletes every
underscore. Through it `norm("grid_lines") == norm("gridlines")`, and `body_of()`
returns file text containing no underscores at all. Searching there searches a
corpus with the artifact names dissolved.

```bash
grep -nE "from edge_gate import|import edge_gate" tools/concord.py
```

Expected: **no match**. Prove the hazard is real rather than taking my word:

```bash
python -c "import sys;sys.path.insert(0,'tools');from edge_gate import norm;print(norm('grid_lines')==norm('gridlines'))"
```

Expected `True`. If someone has 'unified' the normalisers, C1 fails and every
number downstream is suspect.

**C2 · INVARIANT · Surfaces are disjoint within a token.**

A prior version of this measurement was wrong by 6× (114 artifacts reported where
the truth was 781) because a spaced-form regex accepted `_` as a separator, the two
patterns tied on length, and the alternation broke the tie arbitrarily. Green run,
plausible number, no error.

```bash
python tools/concord.py --stats
```

Expected: `SURFACES within-token disjointness: ok`, and exit code 0.

**C3 · INVARIANT · The boundary rule exists and bites.**

*This claim previously could not fail, and a cold evaluator caught it. It read
`matched` out of `--json` — which is `m.group(0)` over `re.escape(surface)` and so
equals the surface by construction. Mutation-tested: with the boundary rule
deleted, `loose` went 785 to 1306 and the check still printed 0. Never test a
regex through its own `group(0)`.*

```bash
python -c "
import sys; sys.path.insert(0,'tools')
from concord import _pat, corpus
p = _pat('cube')
assert not p.search('pick_up_cube'), 'fired inside pick_up_cube'
assert not p.search('cubes'),        'fired inside cubes'
assert not p.search('4cube'),        'fired after a digit'
assert p.search('a cube here'),      'missed a real cube'
c = corpus()
raw     = sum(d['text'].lower().count('cube') for d in c)
bounded = sum(len(p.findall(d['text'])) for d in c)
print('raw', raw, 'bounded', bounded)
assert bounded < raw, 'the boundary excluded nothing - is it still there?'
print('C3 ok')"
```

Expected `C3 ok`, with `bounded` strictly less than `raw`. Those two counts are
DRIFTING; the inequality and the four assertions are the INVARIANT.

**Why a lookaround rather than a word boundary — the usual reason is wrong, and
was wrong in this document until it was checked.** Because `_` is a word
character there is *no* boundary between `_` and `c`, so a plain word boundary
does not fire inside `pick_up_cube` either; on ASCII prose the two rules are
indistinguishable, byte-identical over 4,484 rows. The real reason is the other
end: 433 registry surfaces begin or end outside `[A-Za-z0-9_]` —
`Mobius Strip (Walkable)`, `Buren Column (1,1)` — where a word boundary cannot
anchor against a leading bracket at all. The lookaround uses `\w` rather than an
ASCII class, so it is Unicode-aware; the ASCII version was *looser* on non-ASCII
adjacency, in exactly the place it was meant to be safer.


**C4 · DRIFTING · The roster rule demotes lists.**

A paragraph naming three or more registry tokens is a catalogue entry, not a
discussion. Without it, one query returned ~50 copies of a generated sentence
("Key artifacts: … library_rack …, science_screen …").

```bash
python tools/concord.py --token=science_screen --json | python -c "
import json,sys;d=json.load(sys.stdin)
print('named',len(d['named']),'roster',d['roster_n'])"
```

Claim to test — **not** the absolute numbers: `roster_n` must be **several times
larger** than `len(named)` for this token, and every `named` excerpt must actually
contain the token it was returned for.

*Do not test "no `named` row starts with a roster heading" — `find()` calls
`is_roster()` before `named` is reachable, so that cannot fail. It also pointed
away from a real miss: `ROSTER_HEAD` was anchored without `re.MULTILINE` until
2026-08-29, so a roster heading below the first line of its paragraph escaped, and
two of this token's twelve `named` rows were catalogue lines from
`Change_Slope_Surface/intent.md` and `Flow_Field/intent.md` — both of which had
been shown to a human as evidence the search worked. Fixed; verify it holds:*

```bash
python -c "
import sys,re; sys.path.insert(0,'tools')
from concord import ROSTER_HEAD
print('ROSTER_HEAD re.M set:', bool(ROSTER_HEAD.flags & re.M))"
```

Expected `True`. Then read five `named` excerpts and judge: are they prose *about* the
work, or a list naming it? Report verbatim what you read. **This is the one place
where your judgement matters more than a number.**

**C5 · INVARIANT · Code is not prose.**

Fenced code and inline backticks are stripped, because a command line naming
`--target=three_body_problem` is a work's address, not a sentence about it.

```bash
python tools/concord.py --file=blog/2026-08-29-the-concordance-axis.md
```

That post contains a code block listing five `pattern_tile_*` tokens. Expected:
**none of the `pattern_tile_*` names appear** in the output. It should name about
seven artifacts, of which the quarantined ones are common English words.

---

## 4. Claims about the claim register (`cite_gate.py`)

**C6 · STABLE · The index exists without anyone writing new JSON.**

The book already carried lines with both a `token` and a `note_src`, written for
earlier work and never read as artifact citations.

```bash
python tools/cite_gate.py --json | python -c "
import json,sys;print(json.load(sys.stdin)['totals'])"
```

At time of writing: `citations 219, HELD 203, NEAR 10, ELSEWHERE 3, LOST 3,
NO SUCH WORK 0, UNGROUNDED 0`. **Claim: `HELD` is the large majority and
`UNGROUNDED` is 0.** Exact values may move if the book is edited.

**C7 · INVARIANT · The gate fails on LOST, and passing is not the goal.**

```bash
python tools/cite_gate.py --quiet >/dev/null 2>&1; echo "exit=$?"
```

Expected `exit=1` while any LOST exists. **A green result here is not better than a
red one** — red means the ground under a written claim has moved and nobody had
been told. If it is green, verify LOST is genuinely 0 rather than that the
collector broke (check `citations > 0`).

**C8 · INVARIANT · ELSEWHERE passes; it is a finding, not a fault.**

An artifact discussed in a map where it does not stand is worth reporting and must
not fail the gate. At writing, all three ELSEWHERE rows were their hall's own
declared *hero* — the work the room is about is not in the room.

```bash
python tools/cite_gate.py | grep -A5 "ELSEWHERE:"
```

**C9 · INVARIANT · `verdict()` is shared, not copied.**

```bash
grep -nE "from edge_gate import" tools/cite_gate.py
```

Expected: it imports `verdict`. A re-implementation would be a second copy of one
rule — the failure mode this repo calls the `long_museum` shape, where a Python
re-derivation of the museum's geometry stayed green for weeks because it compared
itself against its own input.

---

## 5. Claims about the want gate

**C10 · INVARIANT · Open wants are never counted as failures.**

```bash
python tools/want_gate.py --json | python -c "
import json,sys;d=json.load(sys.stdin)
FAIL={'GHOST','ECHO','NO REGISTRY','BROKEN BODY','HERO GHOST'}
v=d['verdicts']
print('fails:',d['fails'])
print('failing verdicts:',{k:n for k,n in v.items() if k in FAIL})
print('open, not counted:',{k:n for k,n in v.items() if k not in FAIL})
print('sum matches:',sum(n for k,n in v.items() if k in FAIL)==d['fails'])"
```

Expected: `sum matches: True`. That is **one** proposition, not two — the
"open, not counted" line is entailed by the same arithmetic, so do not report it
as a second result. What it genuinely tests is that this brief's hardcoded `FAIL`
set still matches `want_gate.py`'s `FAILING`.

**Then the check the tally cannot make on itself.** `fails` counts ROWS, and one
broken thing can raise two of them: an unregistered token is `GHOST` in want 1
*and* `NO REGISTRY` in want 2.

```bash
python tools/want_gate.py --json | python -c "
import json,sys
d=json.load(sys.stdin)
print('failing rows:', d['fails'], ' distinct problems:', d['distinct_problems'])"
```

At writing: 10 rows over 9 distinct problems, `calder_mobile_primaries` counted
twice. Quote the distinct number when saying how much is wrong. If an
open want ever counts as a failure, the tool has become a scoreboard, which the
design explicitly rejects: roughly 1600 works have no words, and that is the shape
of the project, not a debt.

**C11 · INVARIANT · ECHO must not condemn an honest family.**

The anti-cheat is "the same sentence on two works". Applied blindly it fires on 16
lines — and **twelve of those are correct**: `pattern_tile_4x4`, `_brick`,
`_herringbone`, `_mirror`, `_puzzle` all resolve to one `.tscn`. Five registry
names for one object honestly share one sentence.

```bash
python tools/want_gate.py | grep -E "SIBLING|ECHO" | head -20
```

Expected: `SIBLING` rows exist and do **not** count toward `fails`; `ECHO` fires
only where the sharing tokens have **different, non-empty** `scene` values; and
where one or more of them declares **no scene at all**, the verdict is `ECHO?`,
which reports and does not fail. That third outcome was added on 2026-08-29 after
an evaluator found the rule guessing: two different scene-less works collapsed to
one empty scene and were condemned as fraud on no evidence. 30 works in the book
have no scene, so the population is real. A gate may say "I cannot tell"; it may
not guess. Verify one of
each by hand against `commons/artifacts/registry/*.json`.

**C12 · INVARIANT · Verdicts are independent, not first-match.**

An earlier draft short-circuited, so a line that was both SIBLING and ELSEWHERE
reported only the first, and ELSEWHERE read 23 against a true 36. Cross-check the
gate against a direct count:

```bash
python -c "
import sys,json;sys.path.insert(0,'tools')
from concord import registry,placements,book_lines
reg,place=registry(),placements()
n=sum(1 for l in book_lines() if l['token'] and l['map'] and l['token'] in place and l['map'] not in place[l['token']])
print('ELSEWHERE, counted directly:',n)"
python tools/want_gate.py --json | python -c "
import json,sys;print('ELSEWHERE, per the gate  :',json.load(sys.stdin)['verdicts'].get('ELSEWHERE'))"
```

Expected: **the two numbers are equal.** They are DRIFTING; equality is the
INVARIANT.

**C13 · INVARIANT · The detector bites.**

Three failing verdicts sit at or near zero on the real corpus, and a rule at zero
is indistinguishable from a rule that never runs.

```bash
python tools/test_want_gate.py; echo "exit=$?"
```

Expected `exit=0` with every check `ok`, including the pair that matters: SIBLING
fires on two names for one scene *and does not* become ECHO.

---

## 6. Claims about the web surfaces

Use **your own** server (§2). Substitute your port for 3013.

**C14 · The API op returns and does not fall through.**

```bash
curl -s -X POST localhost:3013/api/trunk -H "content-type: application/json" \
  -d '{"op":"token_text","token":"science_screen"}' | head -c 300
```

Expected JSON with keys `token, name, placed_in, book, cited, cited_available,
named, placed, roster_n, loose_n`.

**Then the safety check that matters more than the response.** The bottom of that
route rewrites `commons/data/trunk_branches.json`; a branch that forgets to return
destroys it silently.

```bash
ls -l --time-style=long-iso commons/data/trunk_branches.json   # before
# ...issue several token_text requests...
ls -l --time-style=long-iso commons/data/trunk_branches.json   # after
```

Expected: **mtime unchanged.** This is the highest-severity check in the document.

**C15 · INVARIANT · The token is validated before it reaches a subprocess.**

```bash
curl -s -X POST localhost:3013/api/trunk -H "content-type: application/json" \
  -d '{"op":"token_text","token":"bad; rm -rf /"}'
```

Expected: a 400-shaped JSON error, and no process spawned.

**C16 · `/book` renders six sections.**

*The key list alone cannot fail: `SECTIONS` is a hardcoded constant in
`route.ts`, and the GET handler sets each section to `""` on a read failure, so a
nonexistent map returns the same six keys. Only the LENGTHS are evidence.*

```bash
for M in Point_Lines NO_SUCH_MAP_ZZZ; do
  curl -s "localhost:3013/api/book-text?map=$M" | python -c "
import json,sys
d=json.load(sys.stdin)
print('$M', {k: len(v) for k,v in sorted(d['sections'].items())})"
done
```

Expected: `Point_Lines` returns all six sections **non-empty** (hundreds to
thousands of characters); `NO_SUCH_MAP_ZZZ` returns the same six keys, every one
length **0**. If Point_Lines shows a zero, a section stopped rendering; if the
nonexistent map shows a non-zero, the map-name guard has been widened. `technical` and
`blurb` were added on 2026-08-29; before that only 56% of the concordance's hits
sat in a file any page could render.

**C17 · The panel is reachable by a human.**

In `/wall-map`, the panel *this work in the text* renders only when a wall is
**selected**, and switching halls clears the selection. Selection happens by
clicking the work in the plan/iso/3d view — **not** in the right-hand list.

Load `/wall-map`, choose `primitives · point lines`, click a wall work, and confirm
four groups render: *cited*, *this wall's own line*, *said elsewhere in the book*,
*named in the prose*. Report whether you could do it without these instructions.

---

## 7. Traps that have already fooled a competent reader

Each of these produced a confident wrong answer during construction. If your
evaluation reproduces any, you have found a regression — and if you did *not* hit
them, say which you actively checked.

1. **`d.get("artifacts", d)` on the registry.** `substrate_vectors.json` is a flat
   token→weights sidecar with no `artifacts` key; that fallback silently folds 448
   substrate keys into the denominator. The registry has **2878** tokens.
2. **`doc/artifact_to_maps.json` for a map join.** It keys maps by *display title*
   ("Gallery: QFEP"), which does not join to `commons/maps/<Dir>/`, and it is stale
   by roughly a third. Parse `layers.interactables` directly.
3. **`order_of_things.json` as a vocabulary.** 2815 lookups, **256 of them not
   registry tokens** — DNA variant pseudo-names like `abacus_1_pi_digits`.
4. **An interactables cell is not a bare token.** It is
   `lookup[:rot[:y]][#key:value...]`. Split on **both** `:` and `#`.
5. **`innerText` on the wall-map panel.** During verification it reported the panel
   absent while the DOM plainly contained it. Query the DOM, not `innerText`, or
   you will report a working feature as broken.
6. **An empty denominator prints green.** A scan of nothing tallies exactly like a
   clean corpus. **The positive-denominator assertions live in
   `tools/run_release_gates.py` (gates I, J, K) — NOT in the tools themselves.**
   `cite_gate.py` and `want_gate.py` run against an empty book directory both exit
   0 with a clean report. Check the assertions in the runner, and never read a
   green run of a tool on its own as proof that it read anything.

---

## 8. What is NOT claimed

State these back in your report so it is clear they were not evaluated as working:

- **The concordance does not know what a passage is *about*.** It reports that a
  string appears. Criticism that discusses a work without naming it — which is
  most criticism — is invisible to it, permanently. That is why the claim register
  exists.
- **No gate reads a sentence for truth.** They certify *provenance*: that quoted
  words are still in the file they were quoted from. Whether the sentence still
  *follows* from them is not checked and should not be.
- **Coverage is structurally limited.** Roughly two thirds of the registry is never
  mentioned in any prose. This is the shape of the corpus, not a defect to fix with
  better matching.
- **`doc/` essays have no route.** Around 10 of every 87 named hits land in a file
  no page renders; the panel shows those in place instead of linking.
- **Gate F of the release gates fails for unrelated reasons** (`contended_builder`
  — a second Godot holds the lock). It is not part of this pipeline.

---

## 9. What a good report looks like

1. The checkout you evaluated (`HEAD`, dirty count).
2. Per claim: **PASS / FAIL / UNTESTED**, the command you ran, and the output.
3. For every DRIFTING claim, the number you derived — not the one printed here.
4. Your judgement on **C4** in your own words: are the `named` rows prose about the
   work, or lists naming it? Quote what you read.
5. Anything in §7 you actively checked, and anything you found that this document
   does not mention.
6. Any claim here you believe is **unfalsifiable as written**. That is the most
   useful thing you can return: a claim that cannot fail was never verified, and
   the document should not contain one.
