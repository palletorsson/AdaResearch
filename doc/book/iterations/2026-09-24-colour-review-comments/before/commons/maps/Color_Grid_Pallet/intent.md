Question: what remains at an address when attention moves elsewhere?

Do: select a floor cell, change its colour, leave the address and return. Then apply the rule again.

Observe: the stored exception persists through selection changes; the rule overwrites it without changing the cube's shape or support.

Explain: a spatial coordinate is resolved through GridStructureComponent.cube_positions to a MultiMesh instance index. The rule chooses a palette entry using the remainder of a coordinate sum.

Question the apparatus: the visitor can edit a five-by-five region, while the rule reaches the whole interior floor. Neither permission follows inevitably from a grid. This implementation provides four inks and no history; extensions require code.

Handoff: Color_Pillar supplies position and sampling. Color_Paint supplies a surface on which marks accumulate.
