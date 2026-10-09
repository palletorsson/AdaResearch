# Illustrated readings in Ada Encyclopedia

Collection: http://localhost:3003/illustrations

Article: http://localhost:3003/blog/2026-10-06-what-a-picture-has-to-carry

The native Encyclopedia route collects ninety-eight selected comic editions: eight tutorial pages, eighty-nine final-text pages and the ghost-student synopsis. The final-text track now continues through all five Arrays and Regularity halls, eight Colour halls, eight Tiling halls, both Change halls, thirteen Forces halls, six Form Finding halls and twelve Wavefunctions halls. Discarded drafts and museum captures remain in their own galleries. The reader supports sequence and track filters, search, previous/next, a shareable URL for each plate, companion switching and links to the current text, drafting snapshots where available, prompts and provenance.

The collection reads the existing selected-edition manifests from this repository. New plates added to those manifests can join the collection without a second hand-maintained list. Their PNGs remain in their source folders and use the existing read-only /book-review route. Source hashes determine whether a chapter has changed since illustration review; old illustrations are not silently relabelled as current evidence.

The article lives in the Encyclopedia's normal src/content/blog folder and appears in its Blog index. The collection is linked from Present → Illustrations and the Research galleries page. This is the local Encyclopedia; no remote deployment was performed.

Implementation: sibling ada_encyclopedia/src/app/illustrations, src/lib/illustrations.ts and src/content/blog/2026-10-06-what-a-picture-has-to-carry.md. Existing source texts and museum code are unchanged by this collection pass.

Validation: check_collection.py checks selected image hashes and local HTTP routes. typecheck.json scopes TypeScript checking to the new route and its dependencies. checks.json records the results. The in-app browser was used to verify filters, companion switching, next-page navigation and the reader layout.

Sequence filters have shareable URLs, for example /illustrations?sequence=transformation or /illustrations?sequence=change. The selected sequence survives reader navigation and reload.

Forces-only collection: http://localhost:3003/illustrations?sequence=forces. All thirteen canonical halls have a final-text illustration, with saved drafting chapters, prompts and source records.

Form Finding-only collection: http://localhost:3003/illustrations?sequence=formfinding. All six canonical halls have a final-text illustration, with source-checked captions, saved drafting chapters and selected editions.

Wavefunctions-only collection: http://localhost:3003/illustrations?sequence=wavefunctions. All twelve canonical halls have selected final-text pages, with quoted captions, saved chapters and source records.

Randomness-only collection: http://localhost:3003/illustrations?sequence=randomness. All fourteen canonical halls have selected final-text pages.
