# The chapter's voice: a decision

Palle, 8 October 2026, after a reading of the fifteen Primitives halls' `final.md` and
`tutorial.md` as the book's first chapter: "If there is good writing we can consider
steering towards that ... write the decision down and pilot the cut on Lines."

**Scope.** The hall texts, `commons/maps/<Hall>/final.md` and `tutorial.md`: the book's
chapters. The course lessons under `doc/book/course` keep `SHORT_SPEAK.md` (lines in a
tree, 2 October); this decision does not change that form. A hall tutorial keeps
paragraph prose, measured against the sample below, until the day it is rewritten into
the course form.

## final.md: keep the voice

Golden samples: `commons/maps/Point_Zero/final.md` and `commons/maps/Point_Trace/final.md`.
`Primitives_Portals/final.md` for a technical idea carried whole in 1,100 words.

What they do, and what every `final.md` in the chapter should do:

- One or two works a hall, followed deep. A hall with eight works does not get eight
  visits. Measured 8 October: Lines (1,935 words) and Ignorance (1,995) are tours;
  Portals (1,107) is not.
- The handoff. The first line answers the previous hall's last line; the last line hands
  something to the next hall. Point Zero's counter returns in Melencolia: the chapter has
  a bookend, and keeps it.
- A question only where the text has earned it. Not at every paragraph's end (Ignorance
  ends nine paragraphs on one).
- A footnote opens a door: the text to read, and one sentence on why it is a neighbour.
  Never the sentence "this does not establish ..."; that hedge belongs in `technical.md`.
- Standard terms. The aphorism at most once a section.

## tutorial.md: Point One is the measure

Golden sample: `commons/maps/Point_One/tutorial.md`, the 6 October edition.

- Under 700 words of prose. One complete script, then `Run it. <what appears>.`
- One idea per section. Each edit is predict, run, restore.
- A part carried from an earlier hall is named and linked to the hall that printed it,
  never reprinted. Measured 8 October: `line_skin.gd` is printed in full nine times across
  the sequence, `point_body.gd` and `face_body.gd` five times each, `trace_archive.gd`
  four. A part that is new, or supplied for the first time, is printed here in full.
- Admin is said once, then called by name (SHORT_SPEAK, 2 October). The paragraphs
  "Create the following files together ..." and "Source and scope", repeated verbatim in
  nine lessons, go.
- The `<!-- student-code:name -->` blocks are the source `tools/build_student_starter.py`
  reads. A cut never touches a code block or its marker.
- The last lines: `Keep <files>. <Next hall> will ...`

## How a cut is made

By hand, one hall at a time, minimal. Every kept sentence byte-identical; only
duplicates, repeated claims, admin and reprints go; nothing is re-voiced. A receipt
(every changed line: old, new, which rule) is shown before the next hall is touched.
Pilot: `Point_Lines/tutorial.md`, 8 October.

## Repairs this decision asks for next

1. The Godot, Columns, Profiles seam: the three new halls have no handoff lines, and
   Portals still opens on Ignorance's closing question.
2. Melencolia's survey paragraph (Alhambra, Escher, Malevich, af Klint, Clark), cut to the
   one it needs.
3. Day Zero back to one page; its revision history to a README.

Written by claude-edges-pilot at Palle's request. The samples and rules are the reading's
proposal, written down so they can be corrected; forum 261008-jo3tm.
