# 10 PRINT cloth and dressing room

All three dress cuts are floor length, with no exposed stocking or shoe meshes. Their flare, pleats and sleeves distinguish the shapes. The fitting and saved worn dresses use the same extended panels.

Installed through `textile_comparison` in Randomness → Randomness_10_PRINT_Algorithm. The scene now owns its studio script; `dna_comparison.gd` and its other comparison remain unchanged.

Three 1.16 × 1.8 m draped mesh swatches read the same 252 stored 16-bit draws. RIBBON reads the threshold as two diagonal rails, STITCH as horizontal/vertical bars, PIXEL as large/small blocks. Palette and repeat changes keep the draws; SEED + makes another record. The three colours are authored palettes, not additional random draws. This is printed cloth with a fine yarn-like texture, not a Jacquard simulation.

KEEP saves one complete fabric to `user://ada_ten_print_cloth.json`. REPLAY restores it. WEAR snapshots the selected print and A-LINE/GOWN/PLEATED shape through the production costume wardrobe, whose own appearance file survives a restart. Later studio changes leave the worn version alone. TAKE OFF restores the outfit and cloth recorded before this studio first dressed that wearer. Re-entering a scene does not retain that temporary undo history; the saved worn outfit itself does persist.

The changing alcove has two sides and a rear wall, an open front on the existing floor, controls on the right side and a full-length production planar mirror. The mirror sees the live body. In VR it is head-centred, not stereo per eye. The garment torso/legs are inferred by the existing avatar and its sleeves follow the controllers. No new collision body is attached to the wearer. The dress has fixed geometric panels, not cloth physics or measurement-based tailoring.

`print_record.gd` defines a version 2 print record. `cloth_record.gd` accepts it alongside unchanged version 1 woven records. The shared cutting table can also render this record without claiming that its source contains loom picks. Integer samples survive JSON and ConfigFile storage exactly. The three swatches and fitting have UVs; changing repeat multiplies UV addresses on both.

Native evidence and tests: `doc/book/iterations/2026-10-17-ten-print-dressing/`. Runtime tests use isolated save paths, real XR node types, production wardrobe/mirror, actual physics contact and XR pointer dispatch. Physical headset fit, mirror comfort and how the fabric feels to wear need a person in the headset.
