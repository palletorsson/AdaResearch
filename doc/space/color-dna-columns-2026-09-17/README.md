# Taller gallery DNA columns

17 September 2026. Palle requested replacing the last 4-by-2 repeat group with richer combinations, a longer hall, more art DNA examples and a taller ps07_kras_rainbow.

The map is now 23 × 61 m, extended by 18 m. Fifteen earlier chroma_stack studies are retained. Eight distinct color_dna_stack studies replace the eight repeated translation columns and use the added length. The room still contains 23 individual columns; there are now 23 placements rather than two placements each containing four copies.

## Route

- Rows 6,12,18,26: colour assignments, primitive alphabets, fixed transforms and richer stacks.
- Row 35: Mondrian / Albers / Memphis / tall Bauhaus gallery studies, 5.0 / 5.2 / 5.4 / 5.6 m tall.
- Row 44: blues at 6.0 m and the Kraš rainbow column at 6.2 m.
- Row 53: rainbow + Bauhaus (7.2 m), Memphis + rainbow + red beads (7.4 m).
- Exit at (11,58), with the original central aisle continued to the new far wall.

Seven actual JSON configs are snapshotted from primitive-stack-gallery and loaded through the existing primitive_stack.build function. This is not a second rendering implementation. Config names retain source traceability. Gallery works named after art/design references are adaptations, not replicas. The Kraš adaptation explicitly raises the shaft and sets cap radius, shaft radius and cap thickness. Vertical-stack studies are uniformly scaled to the authored height. Composite studies place multiple sources above one another using measured bounds. There is no motion or physical balance simulation.

Primary families and book sections are now chroma_stack and color_dna_stack. The old translation passage and placements remain in before/. Other maps' book, role and core records were compared and preserved.

## Validation

691 checks passed in the actual endless-museum build, in headless and rendered runs: placement counts, intended heights, combined-part joins, all per-mesh collider transforms, gallery footprint bounds, the retained static comparisons, supporting floor, continuous 0.5 m wide body passage, plate approach and circulation around every column. Rainbow studies retain 30 stripes and a cap, with six stripe colours. Rendered views were visually inspected.

Human headset comfort, reach and performance remain untested. Existing project UID / registry / utility warnings and renderer shader-cache write errors remain in the full logs; the target hall builds and captures complete. No project-wide clean-run claim is made.

Review index.html for screenshots and current prose; references.json for source hashes; studies.json in the artifact directory for heights and adaptations; placements.json for exact map tokens; runtime-checks.json for checks; revision.json for source hashes.
