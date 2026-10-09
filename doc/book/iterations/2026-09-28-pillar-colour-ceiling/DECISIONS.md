# Colour above, dark ground below

The author proposed moving the palette to the ceiling and using a dark floor. The ceiling now sits at 4.6 m, where the columns reach value 1. At each of the thirty-five pillar addresses, the overhead colour matches the top of the pillar. The same height rule therefore reads in both the samples and the surface that joins them.

The canopy extends beyond the outer columns. Its shader uses mesh positions plus an explicit field offset, so widening the surface does not stretch the colour coordinates. Values clamp along the overhang. A near-black, matte-looking floor replaces the bright V=0.95 floor slice. The existing physical floor still supports walking.

The sampling card, grey reference, named wall swatches and hall placement are preserved. The main text now begins by entering dark ground and looking up. The explanation of a bright slice projected down onto the floor is removed because the colour surface has found its place at the top of the field.

The author also noticed a fog-like loss of the edge where pillar and ceiling meet. The chapter now pauses at this visible effect before explaining the ceiling rule. It distinguishes the geometric boundary from the ability to see it; the fog is a comparison, not an added rendering effect. This follow-up changes prose only.

## Verification

68 focused native checks pass, including all ceiling/pillar colour addresses, surface height, floor support, sampler pickup and RGB/HSV readouts, swatch carrying, three ordinary-controller walks and the unchanged default palette mode. The screenshots show the actual museum. No script or shader errors occurred. The engine log retains its pre-existing unrelated resource UID warning.

The ceiling is a visual canopy; it adds no overhead collision or light source. The dark floor and colour field are unshaded displays. Headset comfort, tracked-hand reach, display calibration and other renderers remain unverified. The rendered test uses Compatibility.
