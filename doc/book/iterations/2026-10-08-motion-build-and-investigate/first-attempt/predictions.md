# Predictions recorded before running

No Godot execution has been performed. These are predictions from the packet, for a fresh start at rest, one press, no grabbing, no contact, unit study scale, and a stationary study frame. The force is 1 N along local +Z. A is 1 kg and receives it for 1 second; B is 2 kg and receives it for 2 seconds.

I infer acceleration = force / mass from the lesson's mass and speed-change examples. A accelerates at 1 m/s² while pushed; B at 0.5 m/s².

| Time after press | A speed | B speed | A distance from start | B distance from start |
| --- | --- | --- | --- | --- |
| 1 s | 1 m/s | 0.5 m/s | 0.5 m | 0.25 m |
| 2 s | 1 m/s | 1 m/s | 1.5 m | 1 m |

At 2 seconds, A has travelled 0.5 m during its push and then 1 m during one second of coasting. B has travelled 0.5 × 0.5 × 2² = 1 m while accelerating throughout. I used Launch's displacement rule for each interval. Equal final speeds do not imply equal distances: A was faster throughout the interior of the two-second interval. Its forward lead is 0.5 m at 2 seconds.

For t >= 2 seconds, predicted distances are A = 1.5 + (t - 2) metres and B = 1 + (t - 2) metres. Both retain a speed of 1 m/s; the 0.5 m forward lead remains. Their paths are separated by 2 m across X as well, so neither touches the other in this trial.

Each remaining-time entry reaches zero. Then minf(remaining[i], delta) returns zero and the force branch is skipped for that point. Nothing assigns zero velocity. The supplied free_point.gd sets gravity_scale to zero, replaces linear and angular damping with zero, unfreezes the point, and disables sleeping. The continuing motion assumes no collision or hand interaction.

A new choice: use a 3 kg point with the same 1 N force for 3 seconds. Starting at rest, (1 N / 3 kg) × 3 s = 1 m/s. Its distance when its own push ends would be 0.5 × (1/3) × 3² = 1.5 m. The general duration for a target 1 m/s at force 1 N is numerically equal to the chosen mass in kilograms, expressed in seconds.

These distances are continuous-motion predictions. The lesson delegates integration to the engine, so displayed or measured positions at finite physics steps may differ slightly. I have not observed or fitted any measured result.
