# Transformation Introduction

**Learning elements**

- Signals and event handlers
- One function for shared behaviour
- Target and current state
- Gradual reset
- Readout feedback

Trans_Pre used elapsed time to change a cube's pose. Here, an action chooses where a surface should go. Work with the existing MOVE THE BANK panel beside the rotation crossing. Its BANK slider and RESET button control the far landing.

First watch the three supplied crossings: a transport cube moves, a growing cube reaches floor height, and a plank turns to meet the banks. Their automatic motion supplies the encounter. This lesson follows the landing's controls, from an event to a visible change.

Move BANK toward its maximum, then release it. Watch the landing continue toward the requested position. Press RESET before it arrives. The slider returns immediately; the landing changes direction and travels home. Use the fixed side aisle to compare the bank edge and readout while the plank keeps turning.

The excerpts below come from `commons/artifacts/adjustable_landing/adjustable_landing.gd`. They explain the installed artifact; its geometry, controls and object references are already supplied.

## The panel announces an event

In `_ready()`, `RackTemplates.gd` creates the panel. The script finds its slider as `Param_0` and the RESET button's `InteractableAreaButton` as `reset`, then connects their signals:

```gdscript
slider.slider_moved.connect(_on_slider)
reset.button_pressed.connect(func(_button): reset_landing())
```

A signal announces that something happened. Connecting it names the code to run when that event occurs. Moving the slider calls `_on_slider`; pressing the panel button calls `reset_landing` through the short anonymous function. The button signal includes a button argument, which this function accepts but does not use.

## Both paths reach one function

```gdscript
func _on_slider(_value: Variant) -> void:
    if not _syncing:
        set_bank_fraction(float(slider.get_normalized_value()))

func reset_landing() -> void:
    set_bank_fraction(0.0)
```

The slider wrapper converts its physical position to a fraction from zero to one. `_on_slider` reads that fraction rather than using the signal's raw value. RESET requests the same operation with zero as its argument. Both events therefore share the named function `set_bank_fraction`:

```gdscript
func set_bank_fraction(fraction: float) -> void:
    target_displacement = clampf(fraction,0.0,1.0) * TRAVEL
    if is_instance_valid(slider) and not _syncing:
        _syncing = true
        slider.set_normalized_value(target_displacement/TRAVEL)
        _syncing = false
```

`TRAVEL` is one metre. Clamping bounds the request, so a fraction of `0.5` requests half a metre. The function also puts the slider at the requested fraction, which matters when RESET calls it. `_syncing` prevents a slider event during that update from repeating the request.

## Separate the request from the motion

`target_displacement` stores the requested offset. `displacement` stores the current offset. The physics callback brings the current value toward the target:

```gdscript
func _physics_process(delta: float) -> void:
    displacement = move_toward(displacement,target_displacement,SPEED * delta)
    landing.position = HOME + Vector3.BACK * displacement
    _update_readout()
```

`SPEED` is `0.25` metres per second; `delta` is the time since the previous physics tick. Multiplying them gives this tick's maximum movement. `Vector3.BACK` means local positive Z. Adding that offset to `HOME` moves the landing along its existing route.

RESET changes the target to zero. It never assigns zero directly to the current displacement, so returning home remains gradual. Once the target is reached, `move_toward` leaves the bank there.

## Read what has happened

`_update_readout()` formats the current `displacement` as `BANK +… m`. It reports “edges meet” at zero and otherwise gives the gap for the plank's aligned pose. Immediately after RESET, the slider can show zero while this readout still shows a positive distance. Those displays describe the request and the moving bank respectively. The gap label describes the surfaces; crossing also depends on the player's body and movement.

## Try one source parameter

For a local experiment, change only `const SPEED := 0.25` to `const SPEED := 0.50` in the landing script, then rerun the existing scene. Predict the result before moving BANK fully from home: one metre should take about two seconds instead of four. RESET from the far endpoint should take the same reduced time. The endpoints and final gap stay the same. Compare the readout during travel, then restore `0.25`.

Trans_Translation extends this distinction between a destination and the journey to it through carrier routes. Carry forward the question established here: which function changes the request, and which callback performs the movement?
