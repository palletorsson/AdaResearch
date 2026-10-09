# One colour address, two scales

Color_Nails follows the illumination comparison in Color_Flashlight. This time the operation changes material albedo.

The map's nail_salon at (7,9) uses the existing ArrayMesh from `commons/body/hands/right_hand.tscn`. The mesh is shown in its rest pose at 4.3 metres and 0.32 metres high. It is not a tracked skeleton. Surface names identify `Hand` and `Nails.001`; each display mesh receives its own material overrides, leaving the shared source resource intact.

The primary controls stand on separate plinths: `nail_color_controller` at (5,14) and `hand_color_controller` at (9,14). Both use `commons/interfaces/nail_color_controller.gd`; target_surface distinguishes nails from skin. Their half-metre ValueMapper3D boxes convert point coordinates into RGB. In the salon mounting, root y=1.2 places each box from y=0.9 to 1.4, above an approximately 0.8 m plinth. Front and top access remain open. The optional `#mount:salon` hides the generic canopy/light and reduces the swatch; other placements retain their existing presentation.

The existing controller writes its selected colour through GameManager. The salon connects once to `nail_color_changed` and `hand_color_changed`, then updates only the appropriate material list:

```gdscript
func _nail_colour(colour: Color) -> void:
    for material in nail_materials:
        material.albedo_color = colour
```

The matching skin handler uses skin_materials. There is no per-frame salon loop. Geometry scale is independent of the material's RGB values. Gloss, lighting and the size of the viewed patch can still make the two appearances differ.

The table, plinths and stool seats have collision. Brass legs, cushion, tiny bottles and file are set dressing; the bottles are not extra controls. The map leaves a route along either side and reserves this room against automatic sculpture placement. The neighbouring colorballs uses `#case:salon`, constructing a closed glass case before spawning its balls so they cannot bounce into the plinth approach. Other colorballs placements retain their open physics display.

Verification uses `commons/testing/probe_nail_salon.gd`: actual museum loading, dimensions, two controllers, named material surfaces, standing reach, supplied pickup motion through each RGB box, colour propagation and side-route capsule sweeps. The probe restores the user's saved colours after its samples. Tracked controller ergonomics and headset comfort remain untested.
