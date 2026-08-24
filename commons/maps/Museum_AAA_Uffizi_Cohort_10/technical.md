# Uffizi Footprint Cohort — Technical Contract

The source of truth is `tools/build_uffizi_footprint_cohort.py`. It performs two explicit passes:

1. `plan_geometry(8, [7] * 10)` creates the artifact-independent Uffizi offer.
2. `load_contracts()` reads each artifact's dressing-room JSON and `negotiate()` derives accepted bays.

The runtime uses the standard `structure`, `utilities`, and `interactables` layers. A fourth `footprints` evidence layer records every reserved preferred zone; GridSystem safely ignores that non-runtime layer.

Support is part of placement. `table`, `pedestal`, `plinth`, and `platform` contracts receive one raised 1 × 1 m structure tile beneath their artifact anchor. Against-wall artifacts are anchored against the north partition of their bay. All other artifacts receive a centered preferred zone.

Generation fails if a footprint overlaps another, enters the clear spine, touches non-floor space, loses required wall/support geometry, or if any doorway invariant is broken. Run:

```powershell
python toolsuild_uffizi_footprint_cohort.py
python tools\map_pathfinder.py check Museum_AAA_Uffizi_Cohort_10
```
