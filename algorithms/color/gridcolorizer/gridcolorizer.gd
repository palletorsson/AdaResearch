# gridcolorizer.gd — backwards-compat shim.
#
# All logic now lives in GridColorMutator (commons/grid/mutators/
# grid_color_mutator.gd), which extends the channel-agnostic GridMutatorBase.
# This file preserves the original script path and uid so existing scenes
# (gridcolorizer.tscn, simple_color_test.tscn, gridcolorizer_demo.tscn) and
# their inspector-attached exports keep working unchanged.
#
# New mutators (visibility / transform / ...) live alongside GridColorMutator
# under commons/grid/mutators/ and reuse the same lifecycle.
#
# @identity
# essence: thin alias so the historical GridColorizer name still resolves
# desire: zero behaviour change after the substrate split
# critical_parameter: none — all behaviour delegated to GridColorMutator
# triggers: scene-load (existing tscn references this script path)
# emerges: the original behaviour, byte-for-byte, via the new shared base
# needs: GridColorMutator [present]
# relationships: GridColorMutator (parent); was the original mutator before
#   the substrate refactor
# truth: the name moved, the behaviour didn't

class_name GridColorizer
extends GridColorMutator
