# Shaders: form and surface — teaching review

Review date: 2026-10-04. Six existing halls, in canonical order.

The authored teaching plans are updated; lesson adapters are proposed. Exhibit geometry, runtime logic, map order and final manuscripts are unchanged by this publisher.

- Open `index.html` through `/book-review/doc/book/iterations/2026-10-04-shaders-form-and-surface/index.html`.
- Teaching guide snapshot: [teaching-guide.md](teaching-guide.md), served beside this review.
- Editable working memory: `/project-memory?scope=sequence%3Ashaders`.
- The page uses native anchors and `<details>`; it has no scripts, event handlers, remote fonts or external dependencies.

## Inputs and provenance

- `doc/book/course/storyboards/growth.json`: the six shader summaries, learning fields and references. SHA-256: `3632e0c4bc97417ba50d602f9b8139d24804ea8c3fd3eaa73090f8882b2b692f`.
- `teaching-guide.md`: an exact byte-for-byte snapshot dated 2026-10-04 of canonical `doc/book/course/storyboards/SHADERS.md`. SHA-256: `547f5dfd899708a408914afbf352c025923a312b893d023478241fcbc5bf2b10`. The canonical source is preserved; this copy makes the guide available within the review server's supported document roots.
- `doc/book/iterations/2026-10-04-museum-tutorial-storyboards/route.json`: first existing capture for each hall, including original capture date.
- Images are linked from that publication's `images/` directory; none are copied or represented as captures of the revised teaching plans.
- Exact implementation paths are plain text because `commons/` source links do not resolve through `/book-review`. No source snapshots are created.
- Prior hall links target `/project-memory?scope=map%3A…`. Tutorial reference links use HTTPS.

## Regenerate

From the repository root:

```powershell
python -X utf8 doc/book/iterations/2026-10-04-shaders-form-and-surface/publish.py
```

The publisher validates the six-hall order, the revised teaching fields, reference schemes and capture paths/dates. It writes only `index.html`, this README and the exact `teaching-guide.md` snapshot in its own directory. It does not run Godot, change canonical teaching plans or validate implementation of proposed adapters.
