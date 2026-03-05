# Marching Cubes Portal Landscape

Marching cubes at landscape scale. A terrain field — noise-driven, continuous — gets sliced at a threshold. Where the function crosses zero, triangles appear. Ground forms. But cut the threshold differently and holes open. Portals. Passages through solid rock that exist because the math said "boundary here."

The algorithm walks a 12×12 grid, interrogating each voxel: inside or outside? Eight corners, 256 possible configurations, one lookup table. It doesn't know what a landscape is. It doesn't know what a portal is. It only knows where the sign flips. Everything else — caves, cliffs, doorways — is emergent geometry.

A portal is just a place where two boundaries got close enough to merge. Topology as architecture. The terrain doesn't contain the passage — the passage was always latent in the field.