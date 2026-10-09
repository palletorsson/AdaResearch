# Flow Field · a wall monitor

Review dated 4 October 2026. [Open the before/after page](index.html) through `/book-review/doc/book/iterations/2026-10-04-flow-wall-monitor/index.html`.

This is a runtime display and placement improvement in the existing Endless Museum hall. A roughly 4.8 × 3.2 metre wall monitor occupies the west side of the first bay, while the existing controls stay on a separate waist-height console. The field sampler, particles, trails and time controls remain the basis of the encounter. This review is separate from acceptance of the [two Change teaching proposals](../2026-10-04-change-capacity-return/index.html).

## Captures

- Before: [before/standing.png](before/standing.png), the horizontal canvas and control table.
- After: [after/standing.png](after/standing.png), the vertical monitor and console.
- Closer after view: [after/near.png](after/near.png).
- Both phases capture the current real museum hall at their respective stages on 4 October 2026. Neither is a standalone substitute or a historical replay.
- Both use a standing viewpoint. The camera positions differ because the display was moved; these are not fixed-camera images. Exact camera records are saved beside the images.

## Verification

The before run passed 13 checks; the final after run passed all 45 checks with no failures. Both runs finished successfully with source fingerprints stable during capture.

The final checks cover the real hall and retained artifact placements, vertical screen position, the existing sampler and particle update, held and evolving field time, button events, slider callbacks and four standing pointer rays. The six control centres are between 1.115 and 1.199 metres above the floor. This establishes their tested desktop placement and callbacks, not headset comfort.

The before and after particle records are byte-identical after the same seeded 120 updates at 1/60 second per update. This verifies the recorded local simulation state despite the changed display transform and museum viewpoint. [Particle comparison](after/particle-parity.json): SHA-256 `7d346b5683346a4d6e10dcc75e42f10ad3c023a97366a17d5657171c3c5e6c70` for both records.

The runtime probe and source records are owned by the capture task. This review page writes no approvals and changes no canonical teaching plans or memory. No headset session or learner trial is claimed.

Evidence remains inside this review folder:

- [Before checks](before/checks.json) and [after checks](after/checks.json).
- [Before source fingerprints](before/source-manifest.json) and [after source fingerprints](after/source-manifest.json).
- [Before run](before/run.json) and [after run](after/run.json).
- [Before camera](before/standing-camera.json), [after camera](after/standing-camera.json), and [closer camera](after/near-camera.json).
- [Before particle record](before/particles.json) and [after particle record](after/particles.json).

The HTML uses only local images, native links, a native disclosure and embedded CSS. No script, external asset or approval request is used. Only `index.html` and this README belong to the review-page task.
