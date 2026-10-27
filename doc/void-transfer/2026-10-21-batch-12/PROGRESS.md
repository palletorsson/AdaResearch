# Batch 12 progress

- All five originals placed; source audit 42/42 passes.
- Claude delivered Tutorial_Tiling_Floor fragment and handoff. Codex reviewed IDs,
  config, linked study, actual bounds and monitor clearance; merged both floors.
- Original flight enclosure requires 14 m storeys; source row uses 72 m depth.
  Main tower and original maps/texts remain unchanged.
- Native interaction checks run with mouse and synthetic tracked XR. Fixed the
  test driver switching from camera-relative flight to ordinary walking and
  matching ground arrival tolerance to the existing walking probe.
- Native walking exposed a real FloorSign collision through a pattern field.
  Added optional floor_sign_positions layout setting and moved this trial sign
  to [16,-8]. Other sign defaults are unchanged.
- Accepted: 42 source checks, 105 native checks (zero engine errors), 8 editor
  checks. Exported 40 real GLBs including the shared prop library; zero failures.
  Save/reload, Desktop mirror, copy/move/rotate and stale-save protection pass.
- Browser verification complete: both floors show real models and editable transforms.
  Review gallery and editor delivered; physical headset, curation and texts deferred.
- Next batch candidate: Tutorial_Tiling_Walls and Tutorial_Disco.
