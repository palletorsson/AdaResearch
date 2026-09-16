# One mark, three rules

Start with the implemented comparison in `final.md`: P1, PM, PG, HOLD, source paint and UNDO. This placement uses `#lesson:symmetry_compare`; other tile editors retain their existing controls.

The source is a 4 by 4 palette-index array. `WallpaperGroups.get_symmetric_color` reads this array using a selected rule. P1 wraps source coordinates. PM reverses x in odd source blocks. PG also shifts the source row by two, wrapping at four. `VRTileEditor._update_carpet_texture` samples 32 by 32 pixels. The live wall panel and carpet share that image; HOLD copies its pixels into a separate texture.

The console offers 16 source addresses, four paint colours, three rules, HOLD, UNDO and RESET. Undo retains up to 32 changes including the held sample. Reset restores the initial source and P1, keeping the held sample. No headset buttons or keyboard navigation are required by this lesson. The nested legacy cube editor is hidden and suspended here to avoid competing edits.

A source block is not always the translation unit cell. PM and PG reverse every other x block; the x translation period generally spans two blocks. A symmetric source can add symmetries beyond those supplied by the selected construction. Classification concerns the symmetry of the resulting whole field, not merely its selected button.

Only the three selected renderers are checked in this lesson. The other exhibits remain available as supporting material; their full set of numerical wallpaper renderers has not been certified by this comparison. The cage supplies a diagram of the crystallographic restriction. Neither counting enum values nor reading that diagram proves the seventeen-group theorem.

Continue to Ribbon_Patterns_01, then the other ribbon halls before Change. Headset reach and gesture work remain deferred.
