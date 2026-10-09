# Test a route, then change its height

1. Take the entry ramp onto the raised margin. Choose the far pair of posts as the destination and inspect route A before crossing.
2. Try the terrain at HEIGHT .25. Return to the margin and compare the same route at .90. Record where this particular body reaches; stopping is not proof that every route is blocked.
3. RESET from the margin returns .25, route A and sample 1. Changes to height wait while a detected player body remains on the patch.
4. Read ground_at in final.md: the fixed noise value becomes 1 + height_scale × edge_weight × value. HEIGHT zero gives a level surface while preserving the field's settings.
5. Follow the .75 m transition towards the margin. The edge envelope makes the noise contribution zero at the boundary. This is an authored access condition.
6. Select ROUTE B. Compare its section length and steepest sampled segment with A. The ground and collider do not change. A longer path may still be steeper.
7. SAMPLE selects five positions along the chosen section. Match the yellow marker on the plot with the marker on the actual ground. The readout distinguishes the raw field, edge weight and mesh height.
8. Read the mesh/collision passage. Each triangle is shared between visibility and collision; between vertices, the finite triangle can differ from a newly queried noise value.
9. Look for an overhang, then move to another view. One height per x/z cannot represent both a cave floor and roof there. Recall Noise Voxel's occupied volume.
10. Watch the retained orb when resetting terrain. Its independent pulse continues. Carry this distinction to the generator comparison in Noise_Perlin_Simplex.

The desktop input tests use the real DesktopPlayer rig with synthetic events. Headset movement, comfort, controller reach and Quest performance remain for the later headset session.
