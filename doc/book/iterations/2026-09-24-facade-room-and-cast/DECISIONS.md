# The room and its volume — 24 September 2026

## What was built

A registered paired artifact, facade_room_cast, contains an inhabitable room at local x=-6 and its solid positive at x=6. The two roots start from the same 8 x 5 x 7 stock and call the same _interior() function. That definition includes a main room, a spherical alcove, a doorway, a window, a stepped window reveal, and subtractions that leave a skirting edge and a high wall rail in the room. The corresponding marks indent the positive.

The room uses difference B minus V. The positive uses intersection B intersect V. This retains the actual removed portion within B instead of displaying the whole cutting tool beyond the stock. The two forms remain present; no occupied volume is switched to solid.

## Reuse of the existing facade works

The author's direction was to start with existing work. Reused OpeningParts.rect_window, OpeningParts.single_door, CorniceParts.cornice_shelf, dentil_band and string_course. The existing NYC tenement plan supplies its wall colour and ground-floor window parameters. This adapts the vocabulary to a one-storey fragment with a doorway; it does not reproduce the complete 8 x 16 m facade or its exact placement plan.

The factory's visual window pane and door backing/panels/handle are removed only from these local instances. The new actual CSG openings supply depth and sightlines. Existing facade factories, presets and previous facade maps are unchanged. The earlier prefab_sculpture cast mode is also unchanged; it is not used as proof of a real negative/positive relation.

## Experience and presentation

The artifact supplies a common level floor, collidable room and positive, restrained materials, local lighting and two short labels. The standalone study includes surrounding ground. It has no object-state dashboard. Walk into the room, return through its door, look through its window, then approach and walk around the corresponding solid.

First renders were overlit and lost their plaster detail. Reduced the lights and adjusted the study background; reran the checks and native captures. A test-script type annotation was corrected before the first completed validation. None of these test runs touched a running museum session.

## Placement and text

- Production: commons/artifacts/facade_room_cast/.
- Registry: commons/artifacts/registry/facade_room_cast.json.
- New development map: Boolean_Facade_Cast; linked from Boolean_Colour_Spaces_II, with a return portal.
- Companion documents and an illustrated final.md belong to that new map.
- Existing canonical Boolean sequence membership, primary roles and chapter texts are unchanged. This new encounter is staged for museum-loader and headset review before a canonical placement decision.

## Verification

The isolated scene uses the current production files and the existing facade-part dependencies. The probe checks generated meshes, the shared void definition, partition samples across the stock, matching doorway/window/interior landmarks, the rail indentation, and the positive's clipped bounds. Its ray-parity sample is a finite check of the output meshes, not a proof of all geometry.

A 1.8 m tall / 0.30 m radius capsule enters the room, visits the alcove and returns. The window sill blocks walking through, the positive doorway blocks entry, and the positive can be circumnavigated on supported ground. A ray passes through the actual room window. Native views are captured by the same isolated scene.

See runtime.json for the final records and manifest.json for tested-source and image hashes. This does not certify headset experience, Quest performance, the full museum loader, a learner's interpretation or every possible route.

## Whiteread and the writing

Primary references were inspected in the preceding source discussion: Ghost at the National Gallery of Art and House's construction account at Artangel. The text distinguishes the specific material histories of those works from this invented digital room. No earlier inhabitants or social history are invented for the study. The visitor's recent experience supplies a small real memory with which to recognise the corresponding positive.

The writing now follows the encountered doorway, window, rail and alcove. Shared native images illustrate the same artifact in the study chapter and this review.
