# Joint Mechanics Playground

A collection of ten 3D physics vignettes that demonstrate Godot joint setups for machines, swings, and contraptions. Each scene extends `JointDemoBase` (res://algorithms/joint/_shared/joint_demo_base.gd) for consistent lighting, floor, and camera framing.

## Scenes
1. **Pin Pendulum** — Classic pendulum on a pin joint. `res://algorithms/joint/01_pendulum_pin/PendulumPin.tscn`
2. **Double Pendulum** — Chaotic two-link motion using stacked pin joints. `res://algorithms/joint/02_double_pendulum/DoublePendulum.tscn`
3. **Powered Hinge Crank** — A hinge joint with motor driving a crank-slider linkage. `res://algorithms/joint/03_hinge_crank/HingeCrank.tscn`
4. **Slider Piston Press** — Slider joint with oscillating linear motor. `res://algorithms/joint/04_slider_press/SliderPress.tscn`
5. **Spring Suspension** — Damped spring joint acting as a car suspension strut. `res://algorithms/joint/05_spring_suspension/SpringSuspension.tscn`
6. **Cone Twist Bag** — Punching bag tethered by a cone twist joint. `res://algorithms/joint/06_cone_twist_bag/ConeTwistBag.tscn`
7. **Chain Swing** — Multi-link swing seat using pin joints. `res://algorithms/joint/07_chain_swing/ChainSwing.tscn`
8. **Character Hip Joint** — Ragdoll leg attached with a character joint. `res://algorithms/joint/08_character_ragdoll/CharacterRagdoll.tscn`
9. **Motorised Drawbridge** — Hinge motor lifting a deck within set limits. `res://algorithms/joint/09_drawbridge_hinge/DrawbridgeHinge.tscn`
10. **Dual Hinge Gimbal** — Two hinge joints gimbal a payload with user control. `res://algorithms/joint/10_gimbal_stabilizer/GimbalStabilizer.tscn`

## Interaction Cheatsheet
- `Enter` / `Space` (`ui_accept`): Trigger impulses where noted.
- Arrow keys (`ui_left`, `ui_right`, `ui_up`, `ui_down`): Drive motors or apply forces in select demos.

Drop any scene into the editor or run it directly to explore how each joint behaves.
