# Context, mapping and a stated shading model

Primary anchors remain SimultaneousContrast and MetamerismLab. This room enables opt-in context/carrier lessons in their existing scene scripts; other placements retain the legacy demonstrations. Both new lessons use framed displays and pointer buttons on plinths.

Context: two targets and a connector have the same unshaded RGB (0.5,0.5,0.5). SURROUNDS toggles dark/light versus neutral grey, SWAP exchanges the backgrounds, and CONNECT toggles the shared-colour bar. No target value changes. UNDO retains 32 states; RESET restores the start. The program verifies assigned values, not the viewer's perception.

Carrier: a 4x4 palette texture is shared by a 4x2-metre QuadMesh and a half-cylinder with radius 4/PI and a four-metre arc. The curve has 64 segments and UV.x follows arc length. Both UV domains run from zero to one. Four/eight horizontal repeats give one-metre/fifty-centimetre spacing on either carrier; the two vertical repeats stay one metre tall. Texture filtering is nearest. GRID draws repeat boundaries, not collision or source-cell boundaries. The open half-cylinder has edges; it does not establish seam closure.

carrier_comparison.gdshader runs unshaded with an explicitly calculated factor: 0.18 + 0.82 * max(dot(normalized local normal, normalized local light direction), 0). FLAT bypasses that factor. LIGHT SIDE changes local x between -0.7 and +0.7, retaining y=0.5,z=1.0. Plane normals face +Z and get the same factor for either side; curved normals vary. This is an analytic directional model, independent of museum lights. It does not simulate spectra, gloss, fibres or deformation.

The legacy MetamerismLab animation displayed assigned RGB colours and decorative sine waves, not a spectral calculation. The new placement's text does not use its name as evidence of metamerism. Its source is retained elsewhere; before snapshots preserve the earlier map configuration.

The neighbouring spherecolors title previously used fixed_size and no_depth_test, covering this comparison from far away. This placement now opts into label_in_space so its title respects distance and occlusion. Other instances retain their settings.

Next: Ribbon_Patterns_03, the planned closing shader/fabric studio. Headset and deliberate gesture tests remain deferred; no garment transfer is claimed here.
