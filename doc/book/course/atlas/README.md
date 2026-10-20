# Atlas — actual halls and what travels onward

Open [the image atlas](http://localhost:3003/research/ada-relations/index.html?view=images&sequence=graphtheory&map=GT_Matching).

Hall images, Relations, Artist references and Reading method share the selected hall and sequence. Choose one sequence or the whole spine. Open a card for its full photograph, short carry text, next hall, tutorial and reflection. Previous/next crosses sequence boundaries. When an overhead capture exists, the selected card can show the room from above. Selection and view are saved in the URL.

## Authoring

- **Carry text:** edit the hall's `carry` in `doc/book/course/execution-plan/plan.json`, or use the existing tutorial-plan interface linked from the card. `next` supplies the optional next-step explanation. These are lesson declarations; they do not assert a tested handoff or student mastery. No new tutorial subjects are inferred from the photographs.
- **Images:** `atlas-images.json` optionally maps a hall ID to `path` and `evidence`. Both are repository-relative paths. Without an override, the publisher selects from room-specific native capture sessions and the existing storyboard image inventory, preferring recent encounter views. `image-manifest.json` records the actual selection, image hash, source, capture evidence and file save date. An image's date is not a guarantee of the latest layout. A missing capture is displayed honestly.
- **References:** edit `references.json`. Each entry has a stable `id`, a `group` (`networks`, `across-spine` or `method`), and `halls` containing an exact current-spine ID, a short `reason` and a repository-relative `basis` source. Keep `sequences` aligned with those halls. The reference page links to each hall's image; each linked hall shows the reference and its reason in return. Keep the sourced work description, proposed Ada application and representational limit separate. The Jun Seo Hahm load/optimisation attribution remains unresolved; the verified movement work is identified separately. These references do not add edges to the curriculum graph or claim historical influence.
- **Layout and interaction:** `tools/templates/ada-atlas.html`.
- **Ada readings:** each reference's `reading` is our interpretation, separate from its sourced `fact`, proposed `application` and `limit`. `question` carries one short question into the connected hall. Readings appear in full on Artist references and as expandable text beside the hall image.
- **Reading method:** edit `reading-method.json`. Four questions follow encounter → record → arrangement → claim. Each return names an actual hall and its local source. This is a critical reading method; it does not silently introduce new tutorial subjects or declare new runtime behaviour.
- **Publish:** `python tools/publish_ada_atlas.py`. This refreshes the browser relationship snapshot from current project sources, copies resized native captures, and writes the page to the existing encyclopedia `public/research/ada-relations/` directory. The full native originals remain linked. It does not alter the VR scene, canonical tutorial/reflection, curriculum order, native artifact snapshot or earlier test receipts.

`tools/build_ada_relations.py --output PATH` can generate an independent relationship snapshot. Without that option its existing native-output behaviour is unchanged. The Matching publisher also refreshes this browser companion so a later lesson publication does not silently remove the image view.

## Reading the evidence

The image overview follows the actual ordered spine. A next-hall label records adjacency, not a prerequisite. Carry text preserves the current plan's wording, including draft status. Relations retains the original five distinctions: walking order, declared prerequisites, concept returns, shared placement tokens and selected review dates. Every edge keeps its source evidence. An absence in these declarations is not proof that no relationship exists.

**Network references:** Lombardi connects Network Analysis and the Matching atlas to inspectable records; Saraceno's *Hybrid Webs / Webs of At-tent(s)ion* connect Layout and Form-Finding Relaxation to material networks; Shiota connects Layout and Network Analysis to spatial experience, objects and memory. Saraceno's web work takes the network role previously given too broadly to *Aerocene*.

**Elsewhere in the spine:** Donovan links to Array, Tutorial 3D and Legs through repetition, occupancy and support. Lozano-Hemmer's *Pulse Room* links to Point Trace, Array and Tutorial Disco through recording, storage and playback. Hahm's *Walking Follows Form* links to the existing walking bodies in Legs; it supplies no claim that those bodies simulate physical balance. Manovich remains a separate reference for reading the atlas through actual material beside the graph.

Each connection is our proposed reading of a specific hall, not an added tutorial requirement. A numerical edge weight is not automatically mass, structural load or moral importance.

This is the **browser image atlas**. The native table in Matching retains its five relation views. No generated illustrations stand in for museum captures.

## Art as a way to inspect the operation

The Manovich syllabus adds a method, available at `?view=method`: keep the experience, the selected record and the representation distinguishable. Trace, Grid, Array, Colour Grid, Layout, Network Analysis and Matching provide concrete returns within the existing spine. Inspect a relation's existing source ledger in Relations. Time-based capture and grouping photographs by visual resemblance remain proposals, clearly labelled; neither has been implemented by this editorial update.

Two additional references come through the syllabus. Jones, Kaiser and Eshkar's *Ghostcatching* connects Point Trace and Point Line Grid to composing with captured movement. Ada retains positions, not the full-body performance or its timing. Jason Salavon is named in the syllabus; *The Top Grossing Film of All Time, 1 x 1* is our specific selection, connected to Colour Grid's stored colour at an address. The hall does not currently average source images. The artists' own project descriptions and credits are linked on their cards.

The six earlier artist entries now have a short Ada reading too: evidence and visual persuasion (Lombardi), transmitted disturbance (Saraceno), particular objects and memory (Shiota), contacts that support accumulation (Donovan), succession within finite storage (Lozano-Hemmer), and the relation between body and gait (Hahm). These readings are proposals for attention, not claims that the artists illustrate our algorithms or endorse our interpretation.
