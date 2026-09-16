# Footnotes for Point → Line → Trace → Grid → Triangle

16 September 2026. Palle supplied two reviews proposing footnotes as a second intellectual layer and asked to add them. This pass adds nineteen notes across seven documents. Seventeen are in the five book chapters; two accompany secondary encounters. Point One's existing thrownness note remains unchanged.

| Text | Added notes |
| --- | --- |
| Point One | Ahmed on orientation and reach; Euclid's point; Haraway on situated knowledge. |
| Line | Euclid's straight-line construction; Ingold's different practices of lines; the substantial Ahmed path note; a short return on deviation leaving marks. |
| Trace | Klee's moving point; Shannon's sampling theorem and its conditions; Godot's spatial quantisation; Freud and Derrida as neighbours to the question of inscription. |
| Grid | Bowker and Star on classification and standards; a short Ahmed return; Scott on legibility; Lefebvre on spatial practice, plans and lived meanings. |
| Triangle | Godot winding and visibility; a possible polygon-triangulation alternative, explicitly not installed. |
| Line workshop reference | Panofsky and the difference between a camera projection and an arrangement. |
| Grid return visits | The Modulor's historical reference and the limits of one represented body. |

The substantial Ahmed note is attached to “The instruction may still have changed how you moved.” The tutorial keeps the distinction between instruction, evaluation, collision and snapping. The notes do not treat these as equivalent forms of enforcement, or declare every departure from a straight line politically emancipatory.

Only footnote references and definitions are added to the seven existing texts. Removing the nineteen new notes and markers recovers their prior text, apart from line endings and terminal whitespace. Code blocks, artifact tags, map data and role assignments are unchanged. The seven prior files are archived byte for byte under `previous/`, with hashes in `before.json`. `added-notes.json` records each anchor and its note.

## Source checks

The notes are selective adaptations of the supplied reviews. Sources were checked during this pass; precise page references are used only where the text was inspected. [sources.md](sources.md) records the checked editions, text locations and access limits. In particular, Ahmed's printed pages 16 and 20 were inspected in the excerpt, Haraway's objectivity argument in the article, and Shannon's Theorem 1 in the original paper. Klee's opening was inspected in the linked edition. Technical notes use Godot 4.6 documentation.

We retain the distinction between classification enabling coordination and excluding differences. Foucault is not added as a generic explanation of Grid. Barycentric coordinates, rasterisation and mesh invariants remain possible later notes when those operations become part of the relevant passage.

## Verification

[validation.json](validation.json) checks that the main prose and archives are preserved, every footnote is referenced and defined, and map/role files are unchanged. The live encyclopedia API returns all five amended chapters exactly as stored in this repository.

[render-validation.json](render-validation.json) records rendering with the encyclopedia's installed ReactMarkdown and remark-gfm packages, checking footnote references, unique targets and backlinks in each amended document and in the five-chapter reading. The [reading preview](opening-reading.html) uses that rendering. The live book reader also supports GFM notes; its underlying app code is unchanged.

This is a source-text and rendering check, not a headset test. No game behavior is changed, no whole-book export is regenerated, and no commit or push is performed. The reusable authoring convention is [FOOTNOTES.md](../../FOOTNOTES.md).
