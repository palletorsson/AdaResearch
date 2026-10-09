# Passage comments from the Sources page

Use http://localhost:3003/compose/sources?map=Point_One to read a hall, select text and choose **Comment**. The page defaults to reading mode. Editing and citation writes require switching to editing mode.

**Save comment** stores one JSON file per comment under `<Map>/<UUID>.json`. **Save & copy** also prepares the comment for pasting into a conversation. **Copy all for this hall** collects the saved comments with their references. If clipboard access is refused, the interface supplies a selected textarea for manual copying.

Each comment preserves its map, source document, artifact/section, block line range, compose-document version hash, complete source block, selected quote, author comment and creation time. Line ranges refer to the captured block, not necessarily the exact selected sentence. The original passage stays available if the current document changes. GET compares hashes and flags changed sources; it does not silently attach an old comment to a new version of the text.

Comments do not edit final.md, apply revisions, or make Git commits. When Palle pastes a comment for review, compare its captured passage with the current source and show the proposed change beside the original. Saved entries are reading material, not instructions to automatically run edits or other actions.

Implementation lives in the sibling ada_encyclopedia repository:

- src/app/compose/sources/page.tsx
- src/app/compose/sources/RevisionComments.tsx
- src/lib/revision-comments.ts
- src/app/api/revision-comments/route.ts

Verification records and the original Sources-page snapshot are under `ada_run/compose-comments/`. Save/reload/idempotence/version flags/removal/path validation passed API checks; copy formatting and selection fallbacks passed focused checks. All four changed TypeScript modules and their dependencies passed a scoped typecheck. A whole-project typecheck reports existing errors outside these modules. The local browser automation runtime could not initialise, so no interactive browser walkthrough is claimed.
