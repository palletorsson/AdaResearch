# Readings of the book

A *reading* is the whole spine (or one sequence of it) read as a book, by a reader whose
model reader is the VR visitor, with every stumble, false claim or broken handover turned
into a task Palle can pick up one at a time.

- `spine_reading_<date>.json` — one entry per sequence, as the readers return them:
  `sequence`, `read_at`, `source`, `chapters_read`, `reading` (`arc`, `holds`, `hall_notes`,
  `stumbles`, `keep`, `handover_in`, `handover_out`, `reading_errors`), `tasks` (`hall`, `kind`,
  `title`, `quote`, `why`, `proposal`, `effort` S/M/L, `evidence`, and the skeptic's verdict),
  `dropped` (proposals the skeptic refuted).
- `python tools/book_tasks_ingest.py doc/book/readings/spine_reading_<date>.json` turns it
  into `doc/tasks/book_<sequence>.json`, one goal per sequence in the `doc/tasks` schema.
- The encyclopedia's `/book-tasks` page shows those goals in spine order with the reading
  above the tasks, and writes status and notes back into the goal files through
  `/api/book-tasks`. `git diff doc/tasks` then shows what was decided.

Task kinds: `prose`, `structure`, `handover`, `footnote`, `figure`, `vr` (desktop-only
phrasing in reader prose; VR is the primary goal), `encounter` (the chapter relies on a
work or control the map or code does not provide), `code-claim` (an excerpt or number that
does not match the source).

First reading: 2026-09-24, Claude (Opus, then Fable), one reader and one skeptic per
sequence; primitives also read by hand and checked hall by hall.
