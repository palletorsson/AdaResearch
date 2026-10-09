# Museum curtain portals â€” 28 September 2026

The next-hall doorway now uses the map's original `t` marker. Plain plaster jambs and lintel share the museum wall material; the flush landing shares the deck material. The existing animated pink curtain remains. Both directions use pink; small NEXT HALL / PREVIOUS HALL labels distinguish the journey.

The chrome lacing, torus rings, luminous border and walking arrows were removed. This reduces each doorway from 17 mesh instances to 6, without adding lights, particles or a portal camera.

## Placement

- Read the same user:// map override as the museum, with res:// as fallback.
- Use plain t, or a named t targeting the next map. Restart/side-trip teleports are not sequence exits.
- For multiple t cells, try the farthest row and centre first, then the remaining authored cells.
- Keep exact X/Z; turn toward a supported, unobstructed approach (including side-wall exits).
- Add a flush solid slab over the old teleport hole. Never place the door at the pit bottom.
- If no usable t exists, retain safe automatic placement. An obstructed authored t produces a warning; it is not silently reported as successful authored placement.
- Crossing detection uses the doorway's orientation rather than assuming world Z.
- `sp` entrances, entry cages, the Point Zero drop and one-resident-hall loading remain.

## Verification

Five round-trip regression routes passed: Point Zero to Point One; Point One to Point Lines; Polyhedra to Animated Cube; Color Walls to Biome Ladder Color; Transformation Introduction to Translation. Each checks the exact authored exit cell, full XR physics body, supported arrival and return, late staging, no immediate bounce, and at most one resident hall.

The first Color run had an outdated expected next-map name (Chamber_Color). The active sequence correctly led to Biome_Ladder_Color; the fixture was corrected and rerun successfully.

Screenshots are from the live Godot museum. No physical headset acceptance claimed. See verification.json and reports/ for frozen evidence. Android installation status is recorded separately when complete.

## Quest deployment

The verified APK was installed successfully into `com.example.adaresearchzeroone` at 2026-09-28T19:54:39.304198. Its portal bytecode matches the exported assets, the audio generator is present, and its UID cache contains no archived doc resource mappings. The two temporary entrance overrides matched the packaged maps exactly and were backed up and removed. Quest asks for awake controllers before launching; physical headset acceptance remains open.
