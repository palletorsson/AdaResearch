# Richer stacks, still stacks

17 September 2026. Follow-up to the static column hall. Palle pointed to primitive-stack-gallery and clarified: richer forms, still stacks.

The first three groups retain their simple comparisons: four colour assignments, three alphabets, then four static poses. At row 26, four richer stacks follow: beads (six pieces), discs (eight), offset (seven) and festival (eight). Row 35 compares two four-copy translations with kept versus displacement colour. Seventeen artifact instances, twenty-three physical columns. Central aisle, entrance and exit are unchanged.

Richer stacks extend chroma_stack rather than add a separate generator. Each piece can carry height, width, depth, local X/Z offset, yaw and paint. The new composed rule uses that paint; other colour rules still work. All shapes are static. These are authored constructions, not a balance or gravity simulation. The original three stack configurations retain their default geometry and colour assignments. Longer recipes clamp taper at 0.25 so upper pieces cannot invert.

The chapter now moves from equal-level comparisons to varied proportions and composition, then returns to the simpler column to isolate colour and translation. Primary families remain chroma_stack and chroma_translation. All earlier drafts and the previous layout remain in before/; the earlier collection archive also remains available.

## Validation

See runtime-checks.json and render-console.txt for the latest museum run. The probe loads the real endless museum, checks placements, transforms, collision/mesh alignment, all richer pieces' vertical bounds, paint and footprint, a 0.5 m wide body's complete aisle, each plate approach and circulation around every single stack. A label obstruction found in the first render was corrected by extending the richer stacks' plate mounts; the final probe checks a clear line to their plates. The image views are rendered Godot screenshots. No human headset, comfort or performance test was performed.

Startup emits existing project UID / registry warnings. The renderer also reports inability to write its shader cache in this environment; capture and the tested hall complete. Full diagnostics remain in the logs. No claim of a clean project-wide run.

## Review

index.html contains the new museum views, progression and current prose. references.json identifies the gallery studies used as references. No historical-object reconstruction is claimed. revision.json records source hashes at completion.
