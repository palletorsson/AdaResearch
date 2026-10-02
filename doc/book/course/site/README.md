# The course site

The Godot course of Ada Research as a documentation website: a left tree of the course, the
lesson in the middle, "On this page" on the right, dark, after the layout of the
[s&box documentation](https://sbox.game/dev/doc/editor/asset-previews) and in the course's
own colours. It is an [MkDocs](https://www.mkdocs.org/) site with the
[Material](https://squidfunk.github.io/mkdocs-material/) theme, so
[Read the Docs](https://about.readthedocs.com/) can host it without any change to the content.

Nothing here is published. It is built and served on this machine.

## Build and preview

Once, to make the Python environment (Python 3.10 or later):

```
cd doc/book/course/site
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements.txt
```

Every time (Windows paths; on macOS or Linux use `.venv/bin/python`):

```
.venv\Scripts\python build_site.py                 # writes docs/ from the course's files
.venv\Scripts\python -m mkdocs serve               # http://127.0.0.1:8008/
.venv\Scripts\python -m mkdocs build --strict      # the static site in _build/, warnings fail
```

In Claude Code the preview is the launch configuration **course-docs** in
`.claude/launch.json`: it runs `build_site.py` and then `mkdocs serve` on port 8008.

`mkdocs serve` watches `docs/`, not the course's files. After a lesson or a kit changes, run
`build_site.py` again; it rewrites only the files whose bytes changed, and the open page
reloads. `python build_site.py --check` writes nothing and exits 1 if `docs/` is out of date.

MkDocs Material 9.7 prints a banner about MkDocs 2.0 at every run. It is not a warning of
this build and does not fail `--strict`; set `NO_MKDOCS_2_WARNING=1` to hide it. The
requirements pin MkDocs 1.6.1, because 2.0 removes the plugin and theme systems used here.

## What is in this folder

| path | what it is |
|---|---|
| `build_site.py` | the generator: reads the course, writes `docs/`. Standard library only. |
| `mkdocs.yml` | the site: Material theme, dark only, Poppins and JetBrains Mono, the Markdown extensions, strict link checks |
| `hooks.py` | takes the left tree from `docs/_nav.json`, which the generator writes in the course's order |
| `overrides/` | theme overrides: the header with its row of section links, and the dark-only meta tags |
| `static/` | hand-written files copied to `docs/assets/`: `ada.css` (the look, including each code block's strip with its language and Copy), `ada.js` (the "Filter pages" box on wide screens, and the fade on code blocks whose lines run past the edge), `logo.svg` |
| `pictures/` | nine stop pictures that exist only in the encyclopedia's `public/course/`, copied once; see `pictures/SOURCES.txt` |
| `requirements.txt` | the Python packages, pinned |
| `readthedocs.example.yaml` | what would go at a repository root as `.readthedocs.yaml` (not in use) |
| `docs/`, `_build/`, `.venv/` | generated or local; ignored by git |

## What the generator reads

All paths are in this repository; the generator never needs the encyclopedia.

- `doc/book/course/opening.json`: the short track, 17 stops in order. Each stop page is the
  stop's lesson, with the stop's chapter, part, hall, status, kit checks, a download box, its
  picture and caption, its notes (placed under the heading they name), the teacher notes as
  a collapsed **For the teacher** box, and **Did it work?** at the end.
- `doc/book/course/opening/`: `INTRO.md` (the short track's first page), `PLATE.md`,
  `W01_break_it_on_purpose.md`, `CP1_opening.md`, `FIELD_NOTE.md`, and the plate pictures.
- The lessons the stops name outside the course folder: `doc/book/day-zero.md` and
  `commons/maps/<Hall>/tutorial.md` for Point Zero, Point One, Point Coordinates and Point Lines.
- `doc/book/iterations/claude-course-braid-2026-09-30/course.json`: the whole course, 46
  chapters in 9 parts. A part page shows the part's promise, *The plate, now* and its chapters.
- `doc/book/course/kits.json`: which kit folder under `doc/book/studies/` belongs to which
  chapter, and the extras (`the-look`, `my-room`, `kit-base`).
- `doc/book/course/kits_checked.json`: how each kit's builder ended, the second check's
  verdict, whether the prediction held.
- Each kit folder `doc/book/studies/<kit>/`: `TUTORIAL.md` (the lesson), `README.md`,
  `verification.json` (checks passed), `project.godot` (main scene and name), and every file
  the kit download ships.
- `doc/book/course/TAPE.md` and `doc/book/course/field_notes/` for the teachers' pages.

A chapter whose kit has a `TUTORIAL.md` shows that lesson; a short-track chapter without one
shows its stop's lesson; any other chapter shows its outline from `course.json` (what you
make, the argument with its axis, values and prediction, the debt, the place, the process
strip) under a notice that the lesson is not written yet. Kits are being built while this is
written, so the count moves: run the generator again and the pages follow.

Status is computed at build time: **runnable** when the kit has a lesson and its
`verification.json` passed, **draft** when it has a lesson without a passing verification,
**being built** when the folder has no lesson yet, **planned** when there is no folder.
Short-track pages, and the chapters that are short-track stops, carry the status
`opening.json` gives them; a stop with no kit that is ready says **nothing to install**
instead of runnable. The "A draft" notice on a chapter goes with the status its chip shows,
so a kit listed in `kits.json` `built_before` (made before `verify.gd` existed, no
`verification.json`) is shown as runnable with the chip "no verification: built before the
long track", not as a draft.

### Addresses and names

- A chapter's folder is its displayed number and its kit, `course/08-extrude/`, never the
  plan's internal id (`ch45` is chapter 8). Stops are `short-track/<kit>/`, or a fixed name
  for the four stops without a kit.
- The left tree names a page with a lesson by its lesson's title up to the dash ("2 · Point
  Zero"); a chapter with only an outline by the plan's title up to the colon.
- Every page carries a front-matter `title:` ("Stop 9 · Point Plane", "Chapter 33 · Rules
  in time", "Part 1 · Place and join", "The short track"), used by the browser tab and the
  header, and its H1 is its first block, so MkDocs never falls back to the file name
  ("Index"). The generated-file comment comes after the H1.
- Prose that names a chapter by the plan's id (`ch12`, `ch45's`) in a lesson or in
  `course.json` is rewritten to a link with the number the site shows ("chapter 29"); code is
  left alone.

### Links

The lessons are written for the repository, so every relative link is rewritten:

- a link to another lesson or course page goes to its page on the site (the page in the
  same track when the lesson is on the site twice, as the first 13 chapters are);
- a link to a kit file (`README.md`, `FIELD_NOTE.md`, `CONSTRUCTION.md`, a zip) goes to the
  download box of the page that ships that kit, and the box lists the Markdown files that
  are in the zip and says they are not pages of the site; a script or scene becomes code text;
- a link to a museum hall's `final.md` or `tutorial.md` becomes the hall's name, marked in
  cyan; when the link text is something else ("the reading", "its making passage"), the
  text stays and the hall's name follows it in brackets; the hall texts are not on the site;
- links into the encyclopedia (`/course/...`, `/book-review/...`, `localhost`) become plain
  text, except `/course/outline`, which is the whole course here, and `/course/<picture>`,
  which is copied;
- `https` links stay; pictures a lesson shows are copied next to its page.

### Where the site says something the source does not

A few lines were true of the repository and read differently on a website. The source files
are left as they are; the generator adds to them only while the line still says it:

- `INTRO.md`, *Two working places*: the two paragraphs that send the student to
  `doc/book/studies/` and to "this repository" are replaced by a site version (the Download
  button, Import in the Project Manager; the XR project is not a download here). Once
  `INTRO.md` is reworded, its own words come through.
- `TAPE.md` ("served from one machine, at localhost:3003") and the worked field note (the
  `ada_encyclopedia/captures/` folder) get a short cyan **On this site** note on that line.
- *How the course was built*, sources table: where `course.json` says "chNN runs on the X
  kit" and `kits.json` gives that chapter another kit, a note says which one the page uses.
- Short-track notes for a lesson (`opening.json` `notes`) and its **Did it work?** appear
  on the chapter page of the same lesson as well as on the stop page.

### Kit downloads

`build_site.py` writes one zip per kit to `docs/downloads/`, each holding the kit folder as
`<kit>/...`: the files the encyclopedia's download ships (`isExcludedKitEntry` and `walkKit`
in `ada_encyclopedia/src/lib/course.ts`), so no `.godot/`, `.git/`, `.import/`, `*.uid`,
`*.import`, `*.log`, `.gitignore`, and also no `stills/`, which every kit's `.gitignore`
names. Entries carry a fixed date, so the same kit gives the same zip. A chapter whose kit
has no lesson yet gets no download. On 2026-10-02 the 32 zips came to 4.4 MB; the build prints
the total and warns past 150 MB.

## Publishing on Read the Docs (later, by Palle)

Nothing below has been done. The account and the project are Palle's to create, and the
choice between the two routes is his.

**What Read the Docs offers.** The Community plan is free and builds public repositories
only; it shows a small ad on every page (EthicalAds). A private repository, or a site without
ads, needs a paid plan (Read the Docs for Business). Read the Docs builds MkDocs sites
natively: it installs the requirements, runs any `build.jobs` you list, then runs
`mkdocs build` with the configuration you name, and serves the result at
`https://<project>.readthedocs.io/`.

**Before either route.** The kits and the course folder must be committed and pushed: the
build sees only what is in the pushed commit, and today the course commits are not pushed and
several kits are untracked (`day-zero`, `point-one`, `point-coordinates`, among others). A kit
missing from the commit does not break the build; its pages lose their download and a
chapter falls back to its outline. The nine pictures in `pictures/` travel with this folder.

### Route A: build from the AdaResearch repository

The repository is public on GitHub, so the Community plan can build it, but it is about
790 MB packed. Read the Docs clones it for every build (shallowly, but the working tree of a
commit is still large), so builds will be slow and may run into the build time and disk
limits.

1. Sign in at <https://app.readthedocs.org/> with GitHub and allow access to the repository.
2. Copy `doc/book/course/site/readthedocs.example.yaml` to the repository root as
   `.readthedocs.yaml`, commit and push it. Its `pre_build` job runs `build_site.py`.
3. In Read the Docs choose **Add project**, pick the AdaResearch repository, name the project
   (for example `sketchbook-in-drag`), and set the default branch to the one that carries the
   course (today `palm-scanner-door-entry`, not `main`).
4. Start a build and read its log: `build_site.py` prints the page count, the zip total and a
   note for every missing file. `fail_on_warning: true` makes a broken link fail the build.
5. Every push to that branch rebuilds the site through the webhook Read the Docs installs.

### Route B: a small public repository with only the site

Faster builds and no large clone, at the price of a copy step after each change.

1. Make a new public GitHub repository, for example `sketchbook-in-drag-site`.
2. In AdaResearch, run `build_site.py` (and `mkdocs build --strict` to be sure), then copy to
   the new repository's root: `mkdocs.yml`, `hooks.py`, `requirements.txt`, `overrides/` and
   the generated `docs/` (with its `downloads/`). Remove `docs/` from that repository's
   `.gitignore`, if you copy this one: there `docs/` is the source.
3. Add `.readthedocs.yaml` from the route B block at the end of `readthedocs.example.yaml`
   (the same file without the `pre_build` job and with root paths). Commit and push.
4. Import that repository in Read the Docs as in route A, steps 1, 3 and 4.
5. After each change to the course: build here, copy `docs/` over, commit, push.

The kit zips (4.4 MB today) live in `docs/downloads/` and are committed with the site in
route B. If they grow large, they could be attached to GitHub releases instead and the
download box pointed there; the generator does not do that yet.

Either way the site's address can be set as `site_url`; `mkdocs.yml` takes it from
`READTHEDOCS_CANONICAL_URL`, which Read the Docs sets during the build.
