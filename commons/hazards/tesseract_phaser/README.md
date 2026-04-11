# Tesseract Phaser

Wireframe tesseract (4D hypercube) projected into 3D — 4D rotation causes parts to phase in and out.

## Behavior

Extends `HazardCreatureBase`. Higher Dimensions hazard.

- 16 vertices and 32 edges forming a 4D hypercube
- 4D rotation angles (xw, yw) continuously change the 3D projection
- Edge alpha varies by 4D projection depth — some edges visible, others faded
- Only hittable when a face is fully projected into 3D
- Teaches dimensional projection and higher geometry

## Files

| File | Purpose |
|------|---------|
| `tesseract_phaser.gd` | Main script — 4D vertex generation, projection math |
| `tesseract_phaser.tscn` | Scene |
