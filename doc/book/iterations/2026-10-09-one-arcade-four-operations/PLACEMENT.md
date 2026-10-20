# What is actually in the museum?

**The latest architecture work added no new installations to the main museum route.** The four operations are built, interactive Godot studies, but remain in separate preview scenes. Their courtyard pictures are preview-room captures.

This list covers the recent creature and architecture experiments in this conversation. It is not an inventory of every artifact in Ada.

| Work | Current status | Where you can find it |
|---|---|---|
| Procedural creature — `omoss` | **Existing artifact upgraded; placed outside the main route** | `Ribbon_Randomness_02`, row 10, column 7 (zero-based), token `omoss:0:1`. Also referenced by the older `TestMap_Unused_12`. |
| The Corridor Has a Spine — `architecture_spine` | **Preview only** | Separate Godot scene: `commons/artifacts/architecture_spine/preview.tscn`. No map placement. |
| Curved court | **Preview only** | CURVE state of `architecture_variations`. |
| Moving-centre / hinged arcade | **Preview only** | HINGE state of `architecture_variations`. |
| Repeated field | **Preview only** | FIELD state of `architecture_variations`. |
| Stretched canopy | **Preview only** | STRETCH state of `architecture_variations`. |

The last four are states of **one artifact**, not four installed rooms. Run `commons/artifacts/architecture_variations/preview.tscn` with F6 for live controls, or inspect the [exported 3D states](/research/architecture-variations/index.html#stretch).

## How the reports will name the status

- **Preview only:** built and viewable, with no artifact token in a map.
- **Placed outside the main route:** has a map placement in a gallery or test map, but that map is absent from the current museum route.
- **On the museum route:** has a map placement in a hall used by the current route. Runtime and headset testing are reported separately.

Being registered, producing a screenshot, or passing code tests does not establish placement. A new installation needs a named hall and actual placement, followed by a view from that hall. These architecture studies currently have no collision on their changing parts; their separate preview floor supports the player.

## Evidence checked

Checked 9 October 2026 against artifact registry entries, `map_data.json` interactable tokens and current `commons/data/long_museum.json`. The older `spine_order_effective.json` also lists candidates; candidate membership is not counted as installation.

- [Creature placement record](../2026-10-09-move-the-centre/museum-placement.json)
- [Hinged corridor placement record](../2026-10-09-the-corridor-has-a-spine/museum-placement.json)
- [Four operations placement record](museum-placement.json)
- [Return to images and making notes](index.html)

This is a source-configuration audit, not a new walkthrough or headset test. No map placement was changed by this clarification.
