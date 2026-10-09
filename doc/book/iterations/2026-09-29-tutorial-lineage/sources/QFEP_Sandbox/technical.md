# A value needs a receiver

Edge of Chaos compared numerical steps while keeping a model and its start fixed. Sandbox compares the presence of a connection. Two existing controls and one existing qfep_reactor make the experiment; the separate particle field and formula retain their independent behaviour.

The historical reactor and particle field searched the group qfep_slider. The handles register elsewhere. A matching parameter name therefore supplied no working route. The opt-in wiring_study mode uses the actual LambdaSlider and PhiSlider instances beside the reactor, under the same parent hall. It requires exactly one of each and fails closed if either is missing or ambiguous. It never searches another hall. The study reactor leaves global reactive aggregation and bypasses the historical group lookup. Other reactor placements retain their earlier mode.

The console receives handle signals in both states so it can show the offered values. Delivery is conditional:

```gdscript
func _lambda_changed(value: float) -> void:
    if connected:
        receiver.set_lambda(value)
        receiver._update_visuals()
    _refresh()
```

CONNECT immediately sends both current handle values. CUT stops subsequent delivery and retains the last receiver values. The readout reads current_lambda and current_phi from the receiver, not copies of the handle labels. It also reads the actual particle material's initial_velocity_max. Both illuminated paths terminate at this receiver; the independent field is not wired as a side effect.

In this existing reactor, lambda selects a colour gradient, particle maximum launch speed 0.1 + 0.4*lambda, spread, an authored population band and pulse/jitter branches. Phi lightens the colour by phi*0.3 for positive values and darkens it for negative values. It does not change the reactor's temporal sensitivity. These are authored mappings, not measurements of entropy or universal biological regimes. The internal toy score (1-lambda)-0.8*lambda+0.2*phi supplies no entropy estimate and is not displayed as scientific evidence.

REPEAT resets time, pulse phase and the reactor's seeded random generator, retaining connection and inputs. It restarts its GPU particle emission; histories of individual GPU particles are not asserted bit-identical. Identical CPU update steps from this start are checked separately from rendered screenshots. It does not reset the whole hall, visitor, or independent particle field.

The restored map has three rectangular 14 by 16 layers, a clear entrance and exit, full-size handles, and separate support cells for Phi, reactor and formula. Its former inconsistent layers and large central block are retained in the review snapshot. All six artifact families remain. Reactor becomes a third primary because its received values and response now provide essential evidence. The old tt entry remains secondary but has no living scene in the current registry.

The remaining chapter asks what can change the response law itself. This panel can connect, cut and replay a particular mapping. It cannot edit that mapping. Synthesis applies local controls to a deformable body next.
