# VR Rack Control Wrappers

3D wrappers that make 2D rack controls interactive in VR.

## Files

- `VRRackControl.gd` — Base wrapper that hosts a 2D `RackControlBase` on a 3D surface and translates VR hand interactions (grab, slide, rotate) into control value changes.
- `VRFacePlate.gd` — 3D face plate mesh for mounting rack controls, providing the physical surface and visual frame.

## Usage

`UniversalVRAudioController` uses these wrappers when building the VR modular synth rack. Each 2D control from `../` is wrapped in a `VRRackControl` mounted on a `VRFacePlate`, enabling hand interaction via XR controller input.
