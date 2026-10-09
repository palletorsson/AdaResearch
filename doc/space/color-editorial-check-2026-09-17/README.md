# Color editorial check - 17 September 2026

This is evidence for a proposed book revision, not a completed hall walkthrough.

Acceptance update, 17 September: the four wording revisions have now been accepted and applied to the working draft. The three Context passages carry visible planned-encounter markers; Walls remains one hall with its revised transition. The results below remain the record of the earlier implementation check, and no new placement or traversal is claimed. See the [placement brief](../../book/review-packets/color-placement-brief-2026-09-17.md).

## Scope and result

- Read the current Color_Context_Placed and Color_Walls final.md files and the chroma_filter, chroma_drum and chroma_life scripts.
- Inspected the current Color_Context_Placed map_data.json. It contains seven chroma_stack and seven chroma_translation tokens, and zero chroma_filter, chroma_drum or chroma_life tokens. A repository JSON/GDScript search found no alternate placements for those three artifacts outside their registry, implementation and standalone test references.
- Ran a separate copy of commons/testing/probe_chroma2.gd, with execution deferred until SceneTree initialization. The original probe and artifact scripts remain unchanged.
- First run: 26 pass, 1 fail. The seed-neighbour expectations in the existing probe are incorrect. Direct counting on its declared five seed cells gives (3,5):3, (3,6):2, (4,4):3, (4,5):4, (5,5):2.
- Corrected only those expectations in the audit copy and reran: 27 pass, 0 fail, process exit 0. See probe-corrected-expectations.txt. The initial failing result is retained in probe-output.txt.
- Startup logged an unrecognized resource UID and a certificate-store error. These were not investigated or fixed in this editorial pass.

## What that establishes

The filter's actual instantiated material uses alpha transparency, multiply blending, unshaded colour and back-face culling. The veil uses alpha 0.5 and mix blending. The drum builds the expected geometry under all six configurations. The Life crowd and field configurations match the expected live cells and neighbour counts; the corrected seed expectations match too.

The filter is an RGB compositing construction, not a spectral model. The fine drum uses 192 alternating blue/yellow stripes, about 3.16 cm wide. Its two source colour triples average arithmetically to (0.54, 0.57, 0.49), which is not an exactly neutral RGB triple. That arithmetic is not a prediction of the final shaded display or perception. Do not promise a particular grey, distance or loss of stripe visibility from this evidence.

## What remains unverified

No rendering capture, headset test, museum placement, route, collision traversal or performance measurement was made. In particular, the crowd's walkable spaces and the fine drum's distant appearance remain untested. The short Life proposal assumes the intended crowd/age configuration, not the artifact's seed/one default. Filter prose assumes two filter configurations (paint and bauhaus), and drum prose assumes fin and fine-shingle configurations; none is currently placed in this map.

The drum's existing fine-shingle plate still promises grey; align that wording with the eventual tested encounter when placing the artifact. Neither plate nor manuscript was edited here.

## Review deliverables

- ../../book/review-packets/color-focused-revisions-2026-09-17.html - originals beside proposed revisions.
- ../../book/review-packets/color-focused-revisions-2026-09-17.json - captured source hashes, exact replacements and scope.

Source final.md files were verified unchanged after preparing the proposals; all artifact anchors and existing code blocks are preserved by the proposed replacements.

Godot blend-mode reference: https://docs.godotengine.org/en/4.6/classes/class_basematerial3d.html#enum-basematerial3d-blendmode
