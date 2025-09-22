# Sine Oscillation Algorithm

This folder contains a sine wave visualization and animation system.

## Files

- `sine_oscillation.tscn` - Main scene demonstrating sine wave generation
- `sine_oscillation.gd` - Complete sine wave visualization with unit circle animation

## How it works

The sine oscillation system demonstrates the relationship between circular motion and sine waves:

1. **Unit Circle**: A rotating point moves around a unit circle
2. **Sine Wave**: The vertical position of the rotating point traces out a sine wave
3. **Real-time Animation**: Continuous rotation generates a flowing wave pattern
4. **Visual Feedback**: Both the circle and wave are displayed simultaneously

## Mathematical Foundation

The system visualizes the fundamental relationship:
- **x = cos(θ)** - Horizontal position on unit circle
- **y = sin(θ)** - Vertical position on unit circle
- **y = A·sin(ωt + φ)** - Resulting sine wave equation

## Parameters

- **Radius**: Size of the unit circle
- **Angular Velocity**: Speed of rotation
- **Wave Amplitude**: Height of the sine wave
- **Wave Length**: Distance between wave peaks
- **Wave Speed**: How fast the wave moves horizontally
- **Line Color**: Color of the sine wave
- **Circle Color**: Color of the rotating points

## Features

- Real-time sine wave generation
- Unit circle visualization
- Configurable wave parameters
- Smooth animation at 60 FPS
- Built-in trace drawing system
- Educational visualization of trigonometry

## Educational Value

This demonstration helps understand:
- **Trigonometry**: How sine and cosine relate to circular motion
- **Wave Motion**: How periodic functions create wave patterns
- **Real-time Animation**: How mathematical functions can be visualized dynamically
- **Coordinate Systems**: Relationship between polar and Cartesian coordinates

## Usage

Run the `sine_oscillation.tscn` scene to see the sine wave being generated in real-time. The rotating points on the unit circle will trace out a flowing sine wave, demonstrating the fundamental connection between circular motion and wave functions.
