# Arrays: capacity carried forward — before/after review

Review date: 2026-10-04. Five existing halls, in canonical order.

Open [index.html](index.html) through `/book-review/doc/book/iterations/2026-10-04-arrays-capacity-return/index.html`.

The review shows the complete before and after summary for every hall, both sequence arcs, each authored change reason, proposed independent check and critical question. Native disclosures contain compact summaries, comparisons of the learning fields, prior hall links, source paths and remaining work.

- Editable working memory: `/project-memory?scope=sequence%3Aarray_tutorial`.
- Editorial report: [REPORT.md](REPORT.md).
- Exact text changes: [summaries.diff](summaries.diff).
- The page uses native anchors and `<details>` with no scripts, event handlers, remote fonts or external dependencies.
- Existing museum images are reference captures shared by the two texts; they are not before/after geometry comparisons or proof that a revised lesson is implemented.
- The old `commons/maps/Tutorial_Disco/tutorial.md` footstep-recording account remains an explicit open contradiction awaiting a full tutorial rewrite.

## Inputs and provenance

- Before: `before/doc/book/course/storyboards/early.json`, SHA-256 `48b49829c8fae14e2d4649060279a01409c17169da5b53d859b8727a8bf06d2d`.
- After: canonical `doc/book/course/storyboards/early.json`, SHA-256 `f17bbc4438553ffae3c3ea3c5fff5bcc45a1b3cd9eeb6039187b41ca87160677`.
- Prior captures: `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`, SHA-256 `e1993887b20769df7be71ed457d556c08dae31707aae3f313eba1c0af9da2444`, with two review-only overrides below. Each image retains its original metadata date. The publisher links the existing image files and copies none; the global route payload is unchanged.
- Floor uses `../2026-09-28-tiling-rule-study/floor-rule-after.png`, dated 2026-09-28, showing the existing 4×4 rule-study controls. Evidence: `floor-source_manifest.json` and `floor-report.json` in that folder. BEFORE / AFTER labels inside the photograph refer to the old rule demonstration, not this summary revision.
- Walls uses `../2026-09-28-tiling-rule-study/wall-eye-chart.png`, dated 2026-09-28, showing the existing eye chart. Evidence: `wall-source_manifest.json` in that folder.
- Runtime source paths are displayed as plain repository paths because those files are outside the review server's supported document roots. Prior halls link to their selected map scope in project memory.

## Regenerate

From the repository root, after the revised canonical teaching data is ready:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-arrays-capacity-return/publish.py
```

The publisher validates the expected five-hall order, revised fields and original capture paths/dates. It writes only `index.html` and this README. It does not change the canonical plans, before snapshot, full tutorials, final manuscripts, museum order or runtime files; it does not run Godot or establish the implementation of proposed learning tasks.
