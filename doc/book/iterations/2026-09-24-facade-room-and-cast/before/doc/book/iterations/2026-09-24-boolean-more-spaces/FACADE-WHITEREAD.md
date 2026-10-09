# From the facade to the space it holds

The author points out that the facade works already exist. Develop the Whiteread relation through those works, rather than inventing a generic room without a past in the museum.

## What is already here

- `commons/maps/sequences/facade_assembly.json` explicitly identifies Facade Assembly as a branch of Boolean Surfaces. Its eight current maps include Classical, Venetian Gothic, Rustication, Florence Marble, NYC Tenement and Critique.
- `Facade_Classical` and `Facade_NYC_Tenement` already place `facade_builder` using the classical and nyc_tenement plan files in `commons/facade_parts/presets/`.
- `facade_builder.gd` routes plan_path into `FacadeComposer.build_from_file`. That composer reads bays, storeys, materials and part placements. This is the appropriate reuse path for these map artifacts, rather than rebuilding an approximate facade from new blocks.
- The plan composer creates a base wall and attaches architectural parts. The rectangular opening part uses a dark pane and frame pieces. These make a readable architectural face; their names alone do not establish a hole into a complete room. A separate older CSG facade library declares subtractive cutters. Neither is proof that the current facade maps already supply traversable interiors.
- `prefab_sculpture.gd` already names Whiteread in its cast-mode commentary. The implemented `_build_cast()` at line 369 assembles seeded, tapering stacks of box meshes. It does not compute a negative from an existing room. Keep it as an existing sculptural vocabulary, not evidence that the proposed cast relation is already built.

This is source inspection, not a new runtime audit. Existing placements and works are unchanged.

## The spatial argument

A facade lets us recognise a building from outside. Its windows, door, repetitions and ornament suggest a life beyond the face. In CGI that suggestion can precede any interior: there may be no room behind the window yet.

Our new Boolean studies supply a different capacity. They make an interior that can be entered, followed, left and seen from elsewhere. Now join the two: a recognisable exterior can hold an unexpected space. The face need not tell us the whole truth about the body behind it.

Whiteread introduces another operation of attention. A specific interior, with its particular boundaries and traces, becomes something encountered from outside. In Ghost, plaster sections retain impressions of the room; in House, a concrete cast made domestic interior surfaces externally present. These works involve particular places and their histories. Their relevance exceeds the visual resemblance of a pale block to a cast.

Primary references: [Ghost, National Gallery of Art](https://www.nga.gov/artworks/131285-ghost); [Ghost construction account, NGA](https://www.nga.gov/press/first-comprehensive-survey-rachel-whitereads-work-makes-american-debut-national-gallery-art); [House construction, Artangel](https://www.artangel.org.uk/project/house/construction/).

## Proposed next encounter

Start with a small fragment drawn from the existing tenement plan: one ground-level entrance and a recognisable window bay. Retain its proportions and chosen architectural detail. Do not need a full multistorey reconstruction to begin.

1. **Approach the face.** The existing facade is recognisable. A window suggests depth. Walk towards the entrance.
2. **Enter what it holds.** Develop an actual supported room behind that face. A doorway reveal, a window recess and a ceiling detail give this interior its own identity. One part may open into a Boolean curve, so the exterior's regularity does not prescribe the whole interior.
3. **Walk around its counterpart.** Beside the room, expose the positive form corresponding to that same interior. Preserve recognisable details. The doorway is now legible in a mass instead of available as passage. Looking between the two can establish the relation without a dashboard or explanatory animation.

First show the pair in a restrained finish so the correspondence is readable. Then the existing pearl, amber and chrome materials can investigate how an architectural impression acquires bodily, mineral or artificial associations. Colour becomes a second comparison, not a substitute for the first.

The room and positive should derive from shared geometry. If B is the stock and V the void definition, the room is B minus V, while the removed portion is B intersect V. Showing the complete cutter, including extensions outside B, would give a misleading counterpart. Physical casting remains a different material process; this is a digital construction inspired by that relation.

Keep both states available in space. Do not fill an occupied room in place. Reuse the current facade composer and selected parts in an opt-in study; do not globally change facade scenes or their existing materials.

## What this lets the writing ask

*The window has taught you to expect a room. Here you can go behind it. Later, the space you occupied stands beside the building, carrying the window's shape on its surface. You recognise where you were, but you can no longer stand there.*

This is proposed writing for a future verified encounter, not a description promoted to final.md.

The critical questions can stay concrete: how much of an interior does an exterior permit us to infer? What can remain private behind a legible face? What does a cast preserve of a place whose use has gone? The queer possibility lies in a body or interior exceeding what its outward arrangement appears to prescribe; do not equate curved rooms with queer life or regular facades with oppression.

## Scope

Elaborated and grounded in existing source at the author's request. No new room, casting mechanism or facade integration was built in this pass. The six coloured Boolean studies remain available. Next implementation should establish the facade/room/positive correspondence and test entry, support and return before making a canonical chapter claim.
