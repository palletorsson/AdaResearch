# Reveal timing — the gate, its labels, and what it is allowed to say

Built 2026-09-19 from the 2026-09-18 review batch. Read
`doc/book/review-feedback/README.md` first: reviews are editorial evidence and leads,
not verification, and nothing here authorises a change to a chapter, a map or an
artifact.

## The finding this measures

Every sequence review caught the same fault somewhere: the chapter asks the visitor
to predict, act and compare, and the apparatus prints the conclusion first. `NEXT`
before the prediction. "Sierpiński" before the resemblance is tested.
`MAX STRENGTH, MIN MATERIAL` on a truss that computes no strength. The reviewers
found these by reading. There are 196 halls.

## Playtest follow-through — 2026-09-19

The first [runtime pilot in CA_SoftRules](../../space/reveal-play-pilot-2026-09-19/README.md) confirmed the early EXCHANGE labels in the built room, changed their reveal timing, and passed 31 checks through synthetic desktop pointer input. The manuscript and artifact collection were retained. Quest and learner checks remain open. Existing label sets and review snapshots remain historical inputs; this result is separate evidence about the current implementation. The static extractor still finds the delayed strings, so their presence alone must not reopen the arrival-timing finding. No TypeSafe request was made.

## Files

| File | What it is |
|---|---|
| `labels.json` | 261 cases pulled from all 24 reviews: hall, token, verdict, the text a visitor reads, the discovery it preempts, the review quote, the code site |
| `labels_clear.json` | the 164 where the review states it outright (`strength: clear`) — 55 give-aways, 109 well-timed |
| `labels_notes.json` | per sequence, what would mislead a gate built from that review's labels |
| `reach.json` | offline check: can the extractor see what the reviewers read? |
| `state_<Hall>.json` | what a visitor can read in that hall, per station |
| `payload_<Hall>.json` | the request that would be sent, for reading before spending anything |
| `validation.json` | agreement with the labels, once a key exists |

## The pipeline

    python tools/reveal_timing_gate.py state --map CA_SoftRules     # assemble
    python tools/reveal_timing_gate.py reach                        # offline check
    python tools/reveal_timing_gate.py ask --map CA_SoftRules       # dry without a key
    python tools/reveal_timing_gate.py validate                     # needs TYPESAFE_API_KEY

State per station: the artifact's own label strings with the function that sets each
one, the caption cells beside it, every caption in the hall, and the `final.md` region
tagged for that artifact. Questions per station: a Noul (does this text state the
chapter's discovery) and a Choice (on arrival / after action / not stated). One request
per hall, state sent once, questions referencing `stations[i]`.

## Reach, 2026-09-19

Over the 48 give-away cases that name an apparatus (labels whose evidence is `final.md`
are judgements about the chapter's timing and have no in-world string to find):

| | |
|---|---:|
| the reviewer's text found at that station | 12 |
| found in part | 10 |
| station reached, other text found | 22 |
| station reached, nothing readable found | 4 |

44 of 48 reach a station with something to judge. The remaining gap is mostly the
reviewer paraphrasing rather than quoting — and in one case the corpus has moved:
the array enclosure the review quotes as `FLY INTO THE THIRD INDEX` now reads
`REACH AN ADDRESS` (`commons/artifacts/regularity/array_flight_lab.gd:14`).

Four extractor faults were found by this check and fixed, each of which had silently
produced a confident empty answer:

- reading only the scene's root script missed `exchange_study.gd`, where the
  `A / EXCHANGE ON` plates are built — one station found in all of CA_SoftRules
- a registry-only lookup returned nothing for `chroma_stack`, which is newer than the
  registry copy and placed 14 times in the first colour hall
- `\blabel\(` never matches `_billboard_label(`, and `\btitle\s*=` never matches
  `instruction_title =`, because `_` is a word character
- plate text kept in `const PLATE_BODY := {...}` has no line mentioning a plate

## What it is not

A string in a script is text the artifact CAN show. Whether it is on the plate when
the visitor walks in is what the `when_stated` question is for, and the function name
carried with every string is the evidence it gets. No headset was worn, no map was
loaded, and a judgement here is a lead of exactly the same standing as the review it
came from.
