# Grand / Petit

A salon installation for Color_Nails. One existing right-hand ArrayMesh is presented in its rest pose at 4.3 metres and 32 centimetres high. These are display hands, not tracked XR rigs. The nails face the manicure table; the same colour values reach the same named material surfaces at both scales.

The existing `nail_color_controller` and `hand_color_controller` remain separate primary artifacts. `#mount:salon` hides their generic overhead slab and light and reduces the preview swatch; the half-metre RGB coordinate boxes retain their interaction size. In this room they stand at root y=1.2, placing the boxes from y=0.9 to 1.4.

The salon listens to `GameManager.nail_color_changed` and `hand_color_changed`. It duplicates material overrides per hand and assigns albedo independently to the source mesh's `Nails.001` and `Hand` surfaces. It does not mutate the shared mesh or replace the player's tracked hands. Existing controllers retain their normal persistence behaviour.

The table has collision, a hand cushion, tiny decorative polish bottles and a nail file, brass legs and velvet stools. Bottles are set dressing, not additional colour controls. The salon has no per-frame update. The original room is archived under `doc/space/nail-salon-2026-09-10/before/`.

The controls now stand on dedicated open plinths at local (-2,0,5) and (2,0,5), apart from the manicure table and stools. Colour boxes remain from y=0.9 to 1.4. The neighbouring colorballs' opt-in `case:salon` contains its bouncing bodies before they spawn, preserving the right approach.
