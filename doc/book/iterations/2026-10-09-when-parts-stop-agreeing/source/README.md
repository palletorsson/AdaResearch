# When Parts Stop Agreeing

Preview only. No museum map placement. Open `res://commons/artifacts/model_disagreement/preview.tscn` and run F6 in AdaResearch. It uses the existing desktop player, native pointer-compatible dials and buttons, an unchanged reference model and a fixed courtyard floor. The model has no moving collision.

## Exact interventions

- **Precision:** each coordinate is encoded then decoded as float32 at an offset of zero or 2^(18..25), then translated back for local display. The model's small x translation changes with logical time. CONTROL bypasses this roundtrip; the camera/player never leave local coordinates. A quarter metre rounds away at positive 2^24. This exposes storage loss, not a real traversal of a huge museum or a claim about every renderer pipeline.
- **Clocks:** all eight bays sample the same pose function, but their timestamps span 0..4 seconds of age. CONTROL samples one shared timestamp. These are deterministic authored sample times, including pre-zero history, not actual renderer races, networking or changed engine physics ticks. The pose function is defined for every sampled time.
- **Feedback:** a vertex operation changes x by .03*h*h*amount, y by .09*h*amount and z by .18*sin(x*.7)*min(h/2.6,3)*amount, where h=max(y,0). Each complete output becomes the next input. CONTROL reads the original and displays one pass, regardless of requested passes. Coordinates below/on the floor stay fixed. A pass exceeding radius64m is refused before replacing the last complete state. This is deliberately amplified model deformation, not round-off drift or a closed-loop physics controller.

The eight-bay source calls the earlier `model_overflow.make_bay()`, which uses `architecture_spine.build_bay()`. Source arrays and the fixed reference survive all interventions. Every output retains 1,632 triangle records; some become degenerate under severe quantization.

## Controls and tests

SOURCE shows the untouched model. CONDITION adjusts large origin, time skew or deformation amount. STEPS spans0..32. STEP advances one, PLAY / HOLD advances every .2seconds. CONTROL switches the declared comparison while keeping inputs. RESET sets step0, stops play and turns off CONTROL; it does not clear the selected condition. For a baseline use SOURCE or CONTROL. Keys1..4, C, Space, Enter, R; arrows adjust steps/condition.

Run `python tools/test_model_disagreement.py`. Native tests include actual float32 fixtures, lost detail, time-seam mismatch/restoration, feedback/source-reading, retained floor positions, bounds, resets, native dials, real desktop pointer actions, GLB export and F6 lighting. No physical-headset or Quest performance test. Source and models are unchanged by browser inspection of exported states.
