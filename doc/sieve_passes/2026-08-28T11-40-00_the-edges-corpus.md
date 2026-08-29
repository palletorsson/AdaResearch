# Sieve pass — the edges corpus

_Recorded 2026-08-28T11:40:00_

**Target:** 269 sentences, one per map across all 24 chapters, each naming the
dependency that map cannot absorb — what its object needs in order to exist and
cannot itself supply. Written into `commons/data/book/*.json`, editable at
`/edges`, assembled as `doc/book/FIELD_NOTES.md`.

**Occasioned by:** Palle, after the corpus was written — *"how can we improve this
in relation to the meaning of ada research"*. The pass is on the corpus and on the
apparatus around it, not on any single sentence.

**Change made during the walk:** `tools/edge_gate.py`. Described in Q3.

---

## 1. Does this thicken the cognitive water?

> What relational handles does it add?
> What ways of moving through become possible?
> What new things does it make thinkable?

**A second axis through the corpus.** The book is ordered by the walk — chapter,
then pearl, then line. The edges add an ordering by *dependency*: which maps lean
on a frame, which on a sample rate, which on a budget, which on somebody's
default. A reader can now cross the spine sideways. Nothing else in the project
offers that cut.

**The criticality was shown to be already in the material, and measurably.** Of
250 sentences written by the multi-agent pass, 249 came out of the maps
themselves and exactly one needed the project's theory as a fallback. The largest
single source was not the criticism but the *code*: 106 edges came from an
artifact's own `.gd` header, against 87 from `critical.md`. That is the double
thread of `doc/THE_DOUBLE_THREAD.md` confirmed from a different instrument — the
politics did not have to be fetched from the grant, it was sitting in the file
that draws the thing.

**Two sentences came back as findings rather than readings**, which is the
strongest evidence the pass was reading properly:

- `change/Change_Intro` — the map that teaches the derivative hardcodes its own
  answer, `var slope = cos(x_curve) * amplitude`, because the curve was chosen as
  `sin`. It shows a rate only for functions already differentiated on paper, and
  never takes the limit it is named for.
- `symmetry/Symmetry_Motif` — four "different" patterns are one scene at
  `tile_size 4` differing by a `repeat_mode` integer held in the registry,
  outside the square you painted.

Neither is a critique of the subject. Both are the lesson finishing.

---

## 2. What is foreclosed?

> What thinking becomes harder under this structure?
> What habit does it suppress?
> What cognitive grammar does it install — and at what cost?

**This is the sharp one, and the fault is in the form rather than the content.**

The brief installed a grammar: *one map, one edge, one sentence, under forty
words* — and then a linter that turns red past it. What that forecloses:

- **A map with no edge.** Every map now has one, whether or not it earned one.
  Silence is no longer sayable, and silence is a legitimate finding.
- **A map with three.** `Primitives_Ignorance` plausibly has several — the
  sphere's polygon budget, the taxonomy closing at five, the honest low-poly. It
  got one, and the other two were competed away.
- **An edge that is not a sentence.** A drawing, a walk, a measured silence, a
  pair of frames. The register is fixed at prose.
- **Disagreement.** There is one slot per map, so a second reading must *displace*
  the first rather than stand beside it. The book carries `by` on its lines
  precisely because who spoke matters; the edges carry no such thing.

The thesis this project runs on is *inference is compression is entropy; the queer
is the irreducible*. The corpus took the irreducible and made it a fixed-width
field. That is the compression the project argues against, performed on the
project's own argument. **Not deliberate — a default that came in with the schema
and was not noticed until the sieve.**

Costs paid knowingly, and worth it: uniformity is what made 250 comparable, made
duplication detectable (zero near-duplicates at 0.42 Jaccard), and made the whole
readable in one sitting. The foreclosure is real, and so is the gain. It should
be *opened*, not reversed.

---

## 3. What lives in the dark spot?

> What does the encoding hide?
> Is it generative habitat or sterilising seal?

**What was hidden: which sentences could be wrong.**

All 269 read as equally confident. 21% name a number or an identifier — something
checkable. The other 79% cannot be wrong in any way a machine or a walk could
detect. Provenance was recorded at generation time and then *thrown away*: the
`note` in the book said nothing about where it came from or how sure it was. A
corpus that uniform invites being read as settled, which is a sterilising seal —
and the edges were, on the day they were written, **the only thing made in that
session with no gate at all**. Prose that could not be wrong, in a project whose
whole method is that a claim which cannot fail was never verified.

**What was done about it, in the same walk.**

`tools/edge_gate.py`. Every edge now records an *anchor* — the file it was read
out of and the words it was read from, verbatim, stored beside it in the book as
`note_src` / `edge_src`. The gate does not read the sentence; no parser is going
to decide whether *"the trace has no origin, only a sampling rate"* is true. It
asks the narrower and more useful question: **are those words still there?**

Four verdicts: `HELD` (verbatim), `NEAR` (every content word present, wording
moved), `LOST` (the ground is gone), `UNGROUNDED` (no anchor — a to-do, named).
Exit 1 on any `LOST`.

Baseline at the time of writing: **254 HELD, 12 NEAR, 3 LOST, 0 UNGROUNDED.**

The point is not validation. It is that **when somebody fixes `Change_Intro` to
actually take a limit, that edge fails — and the failure is the curriculum
moving.** The sentence is not wrong; it has become out of date, and someone should
walk the room again and say so. A gate that fires when the world moves is worth
more than one that scores prose. That turns the dark spot from a seal into
habitat: the corpus can now be *argued with by the repository itself*.

**And the instrument had to be checked before it was believed.** The first matcher
written for the gate reported that 21% of quotes were missing from their own
files. Three spot-checks found all three present and the matcher at fault: a quote
spanning two comment lines carries a `##` into the middle of itself once
whitespace collapses, and a markdown quote loses its `**` emphasis on the way into
a model's mouth. With comment lead-ins and emphasis stripped, the same corpus read
94% held. **Every number the gate prints depends on its `norm()` being right about
what a source file looks like** — which is the standing lesson from the DNA work,
arriving again in a new place.

---

## What remains open

Named here rather than quietly carried:

1. **The one-per-map schema stands.** Zero, one, or several — and a second edge
   allowed to disagree with the first, carrying `by` — is the honest fix to Q2 and
   has not been made.
2. **An edge cannot be said in the room.** It is `note`, the second register,
   revealed on click; and for the 51 chamber pearls it cannot be said at all,
   because they carry no lines. The grant's project is walked, not read. An edge
   annotated onto a hall is criticism *about* it; an edge you walk into is the
   work.
3. **Nobody has judged the sentences.** The critic that should have was lost to a
   serialization bug — an array passed where `agent()` needs a string, so its
   prompt arrived as the literal `[object]`. The mechanical half was done in code;
   the question code cannot answer — *does this name a dependency, or merely
   describe the map well?* — is unanswered for all 269.
