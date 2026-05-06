# Riemann Sphere

A visualization of the Riemann sphere, the one-point compactification of the complex plane. Teaches how the entire complex plane plus a point at infinity can be mapped onto the surface of a sphere via stereographic projection.

## How It Works

A translucent sphere is rendered with a highlighted equator circle and a glowing red north pole marked with the infinity symbol. A semi-transparent projection plane sits below the sphere at the south pole, representing the complex plane. The north pole serves as the projection point: every point on the sphere (except the north pole itself) corresponds to a unique point on the plane, and the north pole maps to infinity. This demonstrates how complex analysis compactifies the plane into a closed surface.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `radius` | float | `0.3` |
| `show_projection_lines` | bool | `true` |

## Features

- Translucent sphere with metallic shading
- Yellow equator circle rendered as a torus
- Glowing north pole marker labeled with the infinity symbol
- Semi-transparent projection plane below the sphere
- Descriptive label indicating the compactified complex plane concept

## Files

- `riemann_sphere.gd` -- Main script
- `riemann_sphere.tscn` -- Scene file
