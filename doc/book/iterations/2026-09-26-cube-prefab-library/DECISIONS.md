# Again — a library of boxes

The author asked for a collection of box prefabs in the Cube primitive hall: a large shelf with different objects and repeated copies, connecting the pleasure of repetitive creativity to Warhol.

## Built

A 9.12 m, four-tier shelf sits in a widened east gallery of Point_Animatedcube. Its six columns hold 24 individually pickable copies. The first four columns repeat existing cardboard, wooden crate and cargo crate scenes plus a new printed carton. The final two columns vary the crate and carton through their source properties. A separate empty table receives new arrangements. No new panel or button is needed.

The catalogue is `commons/artifacts/prefab_box_library/catalog.json`. Four source scene families yield twelve configured editions. Static authored geometry is cached by edition; individual bodies and transforms remain separate. The source prefab files are unchanged. The original printed AGAIN / OTHER / YET carton is a new graphic study, not a reproduction of a Warhol work.

All fifteen earlier artifact placements and all utility coordinates are preserved. The gallery grows from 13 to 19 columns; its dividing wall opens to the collection. The live and portable museum plans were refreshed only for this room. The library is added after the existing construction group in primary encounter order. Secondary works stay in place.

## Written

The existing outline, editable corner, hidden diagonal and folding-net text is retained verbatim. A new passage introduces scene instances through actual copies: moving one leaves the others behind. Repetition offers familiarity and pleasure. Variations make inherited decisions visible; rearranging copies changes relations without requiring every part to be remade. The existing “A world without composition yet” passage now acknowledges the visitor's table arrangement.

Warhol's box sculptures are identified accurately as fabricated plywood objects carrying commercial packaging imagery. Historical source: The Andy Warhol Museum, [Brillo: Is It Art?](https://www.warhol.org/lessons/brillo-is-it-art/). The digital prefab comparison is an interpretation developed for this encounter, not a claim that Warhol used digital scene instances.

The canonical final.md, technical companion, inventory, curation records and current eleven-hall Primitives capture are updated. A native shelf photograph is shared between the review and the book.

## Evidence and limits

19 native checks completed and passed, including production pickup/release through supplied grabber poses, separate bodies with shared geometry, settling onto the table, two copies stacking physically and a visitor-width walk along the shelf. Four of the checks retain capture cameras. Four original native interior images are published. The initial probe stopped at an unnamed collider lookup; naming the collider made the assertion explicit. The final complete run has no GDScript errors. Existing unrelated UID, furnishing and environment warnings are preserved in the log.

The enclosing box collider deliberately gives each copy a simple pickup volume. It does not preserve the cardboard opening as a collision cavity. The shelf begins with frozen bodies; pickup/release activates their physics. Dropped copies falling below the room or carried beyond 25 m return to their shelf; held copies are excluded from recovery. Arrangements are temporary session state.

The worktop is 0.775 m high. Low tiers provide direct-reach copies; upper tiers rely on existing ranged pickup. Human headset reach, controller targeting, comfort and Quest performance remain unverified. Shared meshes reduce duplicate geometry; 105 geometry surfaces plus labels do not imply 24 draw calls. No claim of full VR acceptance.

No commit or push was made for this addition.
