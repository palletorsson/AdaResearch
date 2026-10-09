# The last two halls: a changing body and a reason to return

20 September 2026. This completes the current sequence-by-sequence review pass. It does not establish a finished immersive museum or completed learner testing.

## Assembly Laboratory

The existing MolecularDesigner becomes an automatic, two-times-scale assembly in an open 12-by-12 hall. Follow one amber ring as its carrier changes from a body joint into a chair panel. The inventory is mutable: assemblies can retype a carrier and create more. The restriction lies in the catalogue's descriptions rather than a fixed stock of materials. The chapter now makes this distinction through a persistent visible instance.

The floating inventory previously used world coordinates, which could leave its parts outside the hall where the artifact was placed. Inventory coordinates are now local; assembly targets respect the exhibit's complete transform. Changing assembly releases surplus parts from old targets. In the hall's body-study mode, unused pieces move visibly to the sides while the form occupies the centre, then resume floating on release. Eight seconds of floating alternate with eighteen seconds of assembly. Idle drift now uses elapsed time; spring damping remains per-frame, as the prose explains.

The ring and side staging add no new control console. The assembly is still authored and automatic. These visual parts have no supporting collision: a chair cannot yet carry the visitor, and a displayed body cannot be worn. The manuscript's request to imagine another body remains an invitation to future construction.

[Manuscript diff](AdvancedLaboratory_Lab_Equipment_Simulation/final.diff) · [Controller diff](MolecularDesigner.diff) · [Part motion diff](Part.diff)

## Post-Crisis Synthesis

All six existing artifact families remain. The ledger is enlarged and mounted for reading, its headings fit the object, and its examples arrive every six seconds. Its line text respects normal scene occlusion. Reconfiguration preserves museum-added children. The map now declares a spawn and puts floor beneath the return cell.

The ledger remains a cycle of prewritten examples, not a record of the visitor. Six visible entries leave a growing count behind them. The prose keeps that concrete distinction and returns to the opening clock. It also allows desire, rather than only a fault, to locate the next work: a branch one wanted to enter, a body one wanted to inhabit.

The closing lines are:

> Go back to a chosen room with one question, one proposed change and one observable consequence. The museum's next version begins with that specific return.
>
> The clock is still running. There is something you wanted to make.

[Manuscript diff](PostCrisis_Synthesis/final.diff) · [Ledger implementation diff](accountability_ledger.diff)

## Evidence and its limits

- Assembly: 16 runtime checks and seven selected physical walking segments pass.
- Synthesis: 11 runtime checks and seven selected physical walking segments pass.
- Both rendered Godot processes exit 0 with no script or shader errors.
- 64 content and preservation checks pass. All authored artifact families in both halls remain; the other six Post-Crisis maps and manuscripts are byte-preserved from this pass's snapshot. The planned placements, book heroes, trunk speech and primary anchors agree.
- Six real Godot views are retained. Assembly views compare controlled floating/body/chair states; targets are advanced through the same spring calculation for eighteen simulated seconds, and surplus carriers move through the controller's side-staging calculation. The floating view uses seeded inventory positions. Ledger views show the same camera and six further generated examples. These are current-state comparisons, not photographs of a previous build or headset sessions.
- The sequence, registry and derived museum references were refreshed. The private probes did not restart the live game or replace its live bake.

The first capture pass exposed camera placement problems and obscuring surplus pieces; the final captures were inspected after those changes. The walking checks establish the selected routes for the test capsule. They do not establish every path, headset comfort, Quest frame rate or beginner understanding. The synthesis gallery still retains its older raised central structure; its secondary artifacts have not received a new interaction audit here.

The author's correction stands: being able to inspect a model is only one part of the museum's purpose. A walkable rhizome and constructive second acts in the less mature halls remain priorities for the next iteration. The [whole-book reading](../2026-09-20-book-reading/index.html) sets out that assessment.

[Runtime: assembly](AdvancedLaboratory_Lab_Equipment_Simulation-runtime.json) · [Runtime: synthesis](PostCrisis_Synthesis-runtime.json) · [Content checks](content-checks.json) · [Current input hashes](current-inputs.json)
