# Quiet walls — Random Definition

2026-10-15. Palle found the museum's wall frames arbitrary and asked whether they
could be switched off or given a clearer role. After inspecting the native hall,
he chose: **“Quiet walls: turn the frames off and let the artifacts lead.”**

## What the inspection found

The native Random Definition hall generated 35 wall places. Eleven carried older
book lines, including catalogue descriptions and statements about entropy that no
longer followed the current chapter. The other places were empty. Placement came
from wall stretches; available book text was assigned afterwards. An empty frame
still had a caption and a selectable proxy. Small empty label plates were also
generated independently at a fixed interval along wall faces.

The entrance and exit belong to the architecture/navigation system. They can
remain legible when the wall works disappear. The captured exit names Random
Entropy.

## Installed choice

`commons/maps/Random_Definition/map_data.json`, under `map_info.museum`:

```json
"wall_frames": "off"
```

Reload the museum hall to see the change. This hides generated wall frames,
mounts, dark fields, their captions, text and selection targets, and the empty
label plates. It does not delete book text or saved frame placements. The
artifact interfaces, windows, entry/exit signs and architectural door trim stay.

Every hall can now choose:

| Value | Result |
| --- | --- |
| `off` | Quiet walls. No generated wall works or empty label plates. |
| `content` | Keep frames with a book line or a locally authored caption. |
| `all` | Restore the previous wall dressing, including empty frames/plates. |

The museum-wide default is `content`, in `commons/data/em_layout.json` under
`hall.wall_frames`. A map's setting overrides it. These are saved configuration
settings, not a newly added on-screen menu. Direct callers of the detail module
that omit the setting retain its legacy `all` behavior.

Content mode retains frame indices, positions and book-token bindings, so existing
adoptions and saved edits still address the same work. Removed or architecturally
culled places cannot consume a sentence. Empty halls clear their old showing-card
ledger rows rather than leaving stale frames for an editor to display after the
hall is rebuilt.

## Verification

- `tests/test_museum_wall_frames.gd`: passes with the headless and Compatibility
  renderers (`test.log`, `render-test.log`). Checks complete frame removal,
  preserved indices/bindings, caption scope, empty pick-target removal, unchanged
  door heads, thresholds, skirting and bevel geometry, and the existing bare-hall
  override. Headless uses the module's retained transforms because the dummy
  renderer returns identity for MultiMesh readback; the rendered run checks the
  actual MultiMesh transforms.
- `museum_probe.gd`: actual isolated Random Definition load, **11/11 checks** in
  `after-report.json`. No wall works/text/cards remain. The saved editor ledger is
  empty for this hall. The exit still has its destination label, collision frame
  and supported approach. Before/after native images were inspected.
- Captures use the same eye positions. This is a visual/structural check, not a
  headset comfort or human attention result. The existing portal warning about a
  blocked authored `t` marker and the supported fallback exit appears before and
  after this change; its routing has not been changed or traversal-tested here.

Evidence runs:

```
ada_run/encounter_pilot/Random_Definition/wall-roles-before/
ada_run/encounter_pilot/Random_Definition/wall-roles-after/
```

## Next observation

Walk from the entrance past Random Touch and the RAND page to the exit. Does
attention now stay with what each instrument does? Does the next encounter become
easier to find? If an explanation is missed, record the particular uncertainty
before adding a wall text. A future frame should answer a demonstrated need:
orient at an entrance, preserve an observation beside its apparatus, or carry a
question into the next hall. No new wall texts were installed in this pass.

![Entrance after removing the wall frames](entry-after.png)

![Exit after removing the wall frames](exit-after.png)
