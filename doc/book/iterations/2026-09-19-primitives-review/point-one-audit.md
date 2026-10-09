# Point One: same point, two addresses

Read-only audit, 2026-09-19. Scope: the local/world coordinate comparison in Point One. No manuscript, map, artifact or test was changed by this audit. The Ada dispatcher and auditor skills guided the source check.

## Finding and decision

The encounter already tracks the right point. The missing opportunity is a simultaneous numerical comparison. Preserve the existing argument and add a LOCAL card beside the WORLD card, then verify the assembled museum placement. This is a staging improvement to mature material, not a reason to cut the passage.

`final.md:110–132` moves from holding one point, to rounded WORLD values, to the coloured frame's origin, orientation and scale. Its claim about different addresses is technically supported. However, the frame is deliberately configured without ticks, labels or its panel. The local address can currently be inferred from coloured guides, but cannot be read numerically alongside the world address.

## Evidence

| Layer | What is present | Source |
|---|---|---|
| Space | One WORLD card at map `(2,9)`; frame at `(4,12)`; named hand-held point at `(8,5)` | `commons/maps/Point_One/map_data.json:123–130` |
| Binding | Point ID, frame's external-point ID and readout channel all use `point_one_main`; `floating_point:0` prevents a second frame-owned point | same map tokens |
| Local frame | `tick_step:0`, `labels:0`, `panel:0`; graphical guides remain | frame map token |
| Selection | External point lookup filters by the named coordinate ID | `algorithms/vectors/00_coordinates/CoordinateSystem3M.gd:513–531` |
| Computation | `to_local(pt.global_position)` includes the frame's actual transform; guides follow this local coordinate | same script, `591–663` |
| Numeric feed | Matching channel required; a pinned WORLD card receives `global_position`, a LOCAL card receives `lp` | same script, `667–687` |
| Display | Card already supports `space:world` and `space:local`, with visible captions and two-decimal output | `commons/primitives/point/coordinate_readout.gd:39–57,125–145` |
| Extents | Default card is `0.72 × 0.60 m` multiplied by `display_scale:2.4`; the current token's final `:2` doubles it again | same script, `20–29,65–85`; map token; museum loader |
| Loader | Fourth token field becomes the uniform scale; authored maps retain source cells plus four vestibule rows | `commons/scenes/endless_museum.gd:11007–11043` |
| Actual placement policy | Cards can slide or be refused when sealing blocks the walk route; source coordinates alone do not prove final placement | same script, `11145–11200` |

The frame's default `display_scale` is 1.5 (`CoordinateSystem3M.gd:39,145–147`). A local unit therefore spans 1.5 room metres when no further ancestor scale is applied. The existing manuscript correctly names the frame's scale. A later teaching experiment can isolate translation, rotation or scaling of the reference frame, but no new frame-control interface is required to make the current comparison useful.

## Minimal placement proposal

Use the same card artifact twice, one encounter in the book:

- WORLD at map `(2,9)`.
- LOCAL at map `(2,11)`.
- Both face `90°`, centre at `y = 1.4`, uniform token scale `1`, display scale `2.4`, no plinth, channel `point_one_main`.
- Tokens: `coordinate_readout:90:1.4:1#plinth:0#display_scale:2.4#readout_channel:point_one_main#space:world` and the same ending `#space:local`.

Each card then measures 1.728 m wide by 1.44 m high. Two metres between centres gives a 0.272 m gap. The existing token instead produces 3.456 m by 2.88 m; putting another unmodified copy in the next cell would overlap substantially.

Before any runtime sliding, their hall-segment positions are `(2.5,1.4,13.5)` and `(2.5,1.4,15.5)`, both facing +X. A useful first capture position is segment-local eye `(7.5,1.65,14.5)`, aimed at `(2.5,1.4,14.5)`. Their combined horizontal field of view is about 41 degrees there. The observer's floor cell and actual final node transforms must be checked in the assembled hall. The nearer position `(6.5,1.65,14.5)` coincides with the drag target and should not be the default viewing station.

The WORLD card occupies `(2,9)` and the proposed LOCAL cell `(2,11)` was empty; both lie on structure `1`, and their adjacent approach column `x = 3` is also floor. The suggested eye is over empty floor at source cell `(7,10)`. Once a fresh capture proves the pair fits, `#pin:1` on these two cards is appropriate: preserving their arrangement is part of the comparison. A pin can cause placement refusal instead of relocation, so the validation must assert that both actually exist. Other artifacts need no new pin.

Do not infer the frame's final world Y from its source offset alone: its anchor is in the L-shaped zero region and it carries a 1.90 m offset. The actual loader decides basin support. Inspect the instantiated frame.

## Review boundaries

- Keep the rabbit, counter, folding past, invisible point and critical questions unchanged.
- Keep a single point binding. The invisible point remains undrawn and is unrelated to the hand-held point feeding the cards.
- If a paired card is implemented, only adapt the nearby singular/plural staging sentences and introduce the LOCAL caption. The same-point/different-addresses argument already holds.
- `coordinate_readout.gd` has stale identity comments saying the feed requires a frame-owned point and is always frame-local. Correcting those comments is useful maintenance, independent of the prose.
- Its explanatory comment about moving the frame also assumes the point moves with the frame. In this map the point is external: holding that point still while moving the reference frame keeps WORLD fixed and changes LOCAL. Do not turn the old comment into a new learner instruction.
- Existing automated Point One tests cover coordinate binding, local/world values, channel isolation and pickup-style reparenting. They do not establish full-hall readability or comfort. This audit did not rerun them or claim headset evidence.
- `ada_run/em_bake.json` still lists an older Point One artifact arrangement. `em_pack_report.json` lists the newer card/frame anchors without sliding, but is also a previous report. Neither is a substitute for a fresh assembled-hall capture.

Success for the next implementation: the two cards appear together without overlapping; both update from the same held point; the WORLD and LOCAL labels remain readable; entering and leaving the coloured frame changes no binding; the pair does not obstruct the route. Physical VR legibility remains a separate observation until tested in the headset.
