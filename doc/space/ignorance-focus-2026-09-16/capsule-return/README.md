# The capsule returns to the main encounter

2026-09-16. Palle clarified that the five-segment capsule is essential: understanding cannot simply be folded around the corner, and the form found between familiar forms can be "transcendental inside restrictions".

The supplied review recommended keeping capsule, regular solids and rock peripheral. This revision adopts its useful distinction between an operational construction and a description, and shortens the main discussion of collapsed pole triangles. Palle's clarification takes precedence over the recommendation to keep the capsule peripheral.

## Editorial decision

The capsule is the sixth primary artifact type and closes the main encounter after the sphere comparisons and counter. Its existing placement at (0,16) is unchanged. All 26 placements remain; nine now have primary roles. The book, tutorial, technical explanation, critical reflection, intent, blurb, summary and inventory agree. Field notes record the clarification above the retained history. Other optional studies remain available.

The main discovery is specific: a ridge faces a facet across the capsule's axis. A presumed half-turn correspondence fails. Another view or knowledge of the construction is needed to infer the other side. Five equal angular divisions retain 72-degree rotational symmetry, so the prose distinguishes an absent symmetry from total asymmetry. The user's "uneven" is interpreted here through the odd count and unequal opposite-side encounter, not as unequal angular intervals in the authored mesh.

"Transcendental inside restrictions" names the research possibility of exceeding our initial categories and expectations through forms produced by the available rules. The main text lets the encounter introduce that possibility; the critical text preserves Palle's formulation. This does not require modifying the capsule or inventing new controls.

## Geometry evidence

`measure_capsule.gd` loads the actual `capsule.tscn`, extracts a cross-section from its generated mesh arrays, and checks the angular spacing and rotated point sets. It also tests a six-segment copy as a comparison and invokes the actual spin driver.

- Ten checks pass in `geometry-checks.json`.
- Five-segment cross-section: 72-degree point-set error approximately 3.3e-8 m; 180-degree mismatch approximately 0.1545 m.
- Six-segment comparison: 180-degree error approximately 7.3e-8 m.
- The scene authors five radial segments, five rings, radius 0.25 m, height 1.0 m and spin 45 degrees/s. The default `cast` presentation preserves the authored mesh.

API reference: [Godot 4.6 CapsuleMesh](https://docs.godotengine.org/en/4.6/classes/class_capsulemesh.html). Local source files and runtime checks establish the exhibit's specific settings rather than assuming the API defaults.

## Content and rendering

- Twelve exact before copies and three runtime checksums are recorded in `archive.json`.
- Fifteen checks pass in `content-checks.json`: unchanged map and runtime, scoped role/order changes, preserved spine membership, matching six book tags, live chapter text, live primary card and layout, all placements, retained optional study paragraphs and scoped whitespace checks.
- Thirteen checks pass in `render-checks.json`, using the encyclopedia's ReactMarkdown and remark-gfm. Seven sections render, with four valid footnote references and backlinks.

The legacy API field `from_book` marks only the first hero token. It is not an inventory of every authored book encounter. The capsule is confirmed through its explicit primary role, primary layout card and `<!-- @capsule -->` marker. The first version of the content check assumed the broader meaning; inspecting `tools/artifact_roles.py` corrected the check.

The engine measurement exited successfully. Its startup log includes the resource UID and certificate-store messages also seen in the earlier probe. There is no claim of a clean whole-project boot. Full-room headset legibility and approach remain unverified. No runtime geometry or controls were edited.

[Read the book](http://localhost:3003/book?map=Primitives_Ignorance&section=final) · [See primary artifacts](http://localhost:3003/necklace/thread?map=Primitives_Ignorance&role=primary)
