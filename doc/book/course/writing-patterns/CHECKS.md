# Writing-pattern page — verification

13 October 2026. Page: http://localhost:3003/writing-patterns

- Targeted TypeScript compilation: zero diagnostics in the new page, API and supporting modules.
- `ada_encyclopedia/tools/check-writing-patterns.cjs`: 15 passing isolated checks for catalogue validity, prerequisite order, scope notices, Markdown export with reserve branches, invalid fields and dependencies, preservation of reference patterns, save/reload, backups, stale revisions and concurrent saves.
- Live API: catalogue loads; cross-origin saves return 403; malformed JSON returns 400.
- Browser: creating a variation, editing its title and hall, moving a prerequisite out of order and back, setting a node aside and restoring it, saving, reloading and comparing routes all verified.
- All six local source/role/plan links used by the interface return 200 after adding the specific files to the review route's existing allowlist.
- The saved Random Definition tutorial variation remains **Untested**. Interface testing is not a ghost-student reading and does not validate the proposed prose.

The [comparison screenshot](images/comparison.jpg) records the page at the normal browser viewport. No museum or student-facing tutorial/final text was changed for this page.

## 13 October 2026 — routes, paragraph moves and source studies

- Added five routes to the existing eight: spiral, braid, consequence-first, delayed discovery and recurrence with variation.
- Added six paragraph patterns and six bounded author studies in `craft.json`. Study locators distinguish adjacent paragraph groups and Carroll's omitted intervening dialogue. Ahmed was rechecked against the previously downloaded PDF after a public-link 403.
- Passed 26 isolated assertions: catalogue validation, all six study adaptations, nested-step copy isolation, invalid paragraph rejection, invalid study rejection, changed-order Markdown export, persistence, snapshots, stale-save rejection and concurrent-save handling. The test uses a temporary directory, not the live experiment file.
- TypeScript semantic/syntactic checks for the four changed writing-pattern files reported zero diagnostics. No claim is made about unrelated project files.
- Live API returned 13 reference routes, six paragraph moves, six studies and the existing one saved variation. The provenance page returned HTTP 200.
- Browser: selected Author studies, adapted Haraway to a separate draft, attached a paragraph move, edited a small instruction, moved Pattern before Scene, and verified the edited order and instruction in Compare. Tests used 127.0.0.1 to avoid the user's localhost draft. No test variation was saved to the live project library.
- Visually inspected the author-study layout and saved `images/author-studies.png`. The user's localhost draft remained intact.
- These checks validate the planning tool. They do not establish literary quality, successful teaching or a preferred prose baseline. Student-facing tutorial/final files were not changed in this pass.
