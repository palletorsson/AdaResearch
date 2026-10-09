# A colour with an opening — 2 October 2026

The supplied Turrell collages continue the artist-reference studies. Develop the installed Color_Flashlight annex, where illumination has already become something the visitor can enter. This is an original Godot study.

## Spatial decisions

- Keep the white room, central changing source, existing entrance, connecting passage and ramp.
- Add a 5.8 m wide, 3.2 m high opening into a roughly 1.1 m deep recess within the first room. The original back wall bounds it. Two fixed pink washes and a thin luminous lip make a stable source to compare with the changing room.
- Move the bench to the opposite wall, away from the recess approach.
- Close the two vertical stages between the roof slabs. Each slab now spans the same outer footprint, producing one stepped well and one top opening rather than three floating slabs with sky visible around their outer edges.
- Bring the three roof hues closer together. A viewer can follow one change in light and one change in viewpoint.
- Concealed washes have no shadow maps. The central source retains shadows. The thin emissive roof lips sit below the solid slabs, avoiding overlapping coplanar faces.

## Reference verification

[Häusler Contemporary](https://haeusler-contemporary.com/james-turrell-ganzfeld-aural-en) identifies Aural as a walk-in Ganzfeld installation at the Jewish Museum, Berlin, in 2018. It is a physical installation; the collage's description as VR is not supported by this source.

[Rice's account of Twilight Epiphany](https://moody.rice.edu/james-turrell-twilight-epiphany-skyspace) describes a ceiling light sequence around a roof aperture that meets natural twilight. Our sky is the museum's rendered sky, and our receiving surfaces use Godot RGB lighting. No natural-daylight or perceptual equivalence is claimed. The other collage photographs remain visual leads: individual works have not all been identified.

## Capability and placement

Installed in Colour → Color_Flashlight, after the handheld-light comparison and before Nails. Coordinates and transformations allow the change in viewpoint; Point Zero's frame loop supports the slow cycle; Colour supplies the light-versus-material comparison. This is a return through existing capabilities, with no new prerequisite or map.

The openings use strips of BoxMesh geometry. A Boolean cutter is not needed to build these rectangles. The relationship to the later Boolean sequence is the question of a boundary and its visible depth, rather than a new operation taught out of order.

## Evidence

Figures are native Godot 4.6 Compatibility renders of the actual endless_museum assembly, with private runtime state. The probe checks solid backing, clear recess/doorway space, floor support, an open sky ray, a closed well side, route footprint and rendered light changes with fixed receiving material. The standing capsule tests sampled positions; they do not certify an entire walked route or tracked-controller experience.

The first capture run froze inherited processing and thereby removed CollisionObject3D bodies from the physics world. The final probe keeps the room active for physics while freezing its colour loop. The failure was in the photographic setup, and the final collision checks pass. No user Godot process, live control, save or bake was changed.
