Concept: Facade_Florence_Marble is a *surfaced actualization* of the facade assembly principle in its smooth-marble voice. Where Facade_Rustication concentrates the surface axis through Naples-style diamond bossing — projecting carved pyramids, defensive-decorative texture — this map concentrates the same axis through Florence's smooth dressed-marble vocabulary. Same compositional logic at the surface axis, different material argument. The Pitti and the Strozzi say wealth through rough stone; the Medici-Riccardi and Santa Maria Novella's marble facade say wealth through polished panels. Both are surfaced.

Actualizes: Facade_Assembly_Principle, in the *surfaced* mode (smooth-marble variant). The position in the virtual field is where the rustication axis is held at "smooth ashlar marble" rather than at "Naples diamond bossing." Other axes (rhythm, hierarchy, column-order, fenestration, cornice) sit at canonical Italian-Renaissance values. The surfaced tag's vocabulary is not exhausted by one material; this map demonstrates that the tag has a range.

Sequence role: Stamp-test variant in the facade_assembly branch, demonstrating that the surfaced tag accommodates multiple material vocabularies within the same axis-position. Not yet in the canonical sequence walk; lives as a sibling of Facade_Rustication for the player who wants to walk both surface-mode expressions.

Technical angle: Dispatches `facade_builder` with `plan_path=res://commons/facade_parts/presets/florence_marble.json`. The preset uses `dressed_stone` and `marble_panel` surface parts in the part library, with `pilaster` column parts and `dentil_cornice` framing. Composed by FacadeComposer at the front edge of a 10×6 room per the R4 template. The map was stamped from `commons/maps/rules/facade_placement.md` rules R2 (tag→preset lookup with override to florence_marble.json), R3 (room dimensions for surfaced tag = 10×6×3), R4 (placement template), R6 (intent.md schema), R7 (blurb shape).

Critical angle: Florence and Naples are both Italian-Renaissance, both surfaced, both Quattrocento wealth-as-architecture. The difference between them is *what wealth chose to project*: Naples chose density (the diamond grid as an army of carved pyramids, defensive-decorative double); Florence chose flatness (the smooth panel surviving the gaze, the cost in the polish not the projection). The surfaced tag carries both. The rule set's `alternates` list in R2 is what makes this legible — the tag is a *region of the virtual*, not a single position.

Key artifacts:
- facade_builder dispatching to commons/facade_parts/presets/florence_marble.json
- science_screen for orientation text

Gap: none. This is a stamp-test map: rules R1-R10 covered everything. If visual capture later reveals a mismatch between the marble vocabulary and the 10×6 room (e.g., proportions feel wrong for marble's smoothness), that becomes input for an R3 refinement.
