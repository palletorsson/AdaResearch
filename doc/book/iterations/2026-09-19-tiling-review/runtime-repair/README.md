# A local was read before it was declared

During the Tiling pass, concurrently edited `commons/scenes/em/em_detail.gd` recorded card-fit metadata before declaring its local `fit_card` dictionary. Godot reported `Identifier "fit_card" not declared in the current scope`, followed by dependency compile errors from the museum.

The repair moves the existing font and fit calculation immediately before its first use. No card metadata, layout rule or intended feature is removed. The original file is saved as `em_detail-before.gd`; `declaration-order.diff` contains the exact change. Other shared museum work is preserved.

Some initial artifact probes passed their assertions despite these dependency errors. Those runs remain diagnostic evidence and are not reported as clean full-hall verification. The opening and relation audits distinguish them from fresh runs after the repair.
