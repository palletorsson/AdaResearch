# Soft Body Physics Variations Test

This scene demonstrates 10 different sphere soft bodies with varying physics properties to showcase different behaviors.

## Soft Body Configurations

### Row 1 (Back Row): Low to Medium Pressure
**Position**: Z = -6

| Body | Precision | Pressure | Expected Behavior |
|------|-----------|----------|-------------------|
| SphereSoftBody01 | 5 | 0.05 | Very soft, low detail physics |
| SphereSoftBody02 | 6 | 0.1 | Soft, slightly better physics |
| SphereSoftBody03 | 7 | 0.15 | Medium-soft, good detail |
| SphereSoftBody04 | 8 | 0.2 | Balanced behavior |
| SphereSoftBody05 | 9 | 0.25 | Slightly firmer |

### Row 2 (Front Row): Medium to High Pressure  
**Position**: Z = -3

| Body | Precision | Pressure | Expected Behavior |
|------|-----------|----------|-------------------|
| SphereSoftBody06 | 10 | 0.3 | Firm, high detail physics |
| SphereSoftBody07 | 12 | 0.4 | Very firm, excellent detail |
| SphereSoftBody08 | 15 | 0.5 | High pressure, very detailed |
| SphereSoftBody09 | 20 | 0.7 | Extremely high pressure |
| SphereSoftBody10 | 25 | 1.0 | Maximum pressure, maximum detail |

## Physics Properties Explained

### Simulation Precision (5-25)
- **Low (5-8)**: Faster performance, less accurate physics
- **Medium (9-15)**: Balanced performance and accuracy
- **High (16-25)**: Slower performance, very accurate physics

### Pressure Coefficient (0.05-1.0)
- **Low (0.05-0.2)**: Soft, squishy behavior, easy deformation
- **Medium (0.3-0.5)**: Balanced firmness, moderate deformation
- **High (0.7-1.0)**: Very firm, maintains shape well, hard to deform

## Expected Visual Differences

1. **Deformation Speed**: Lower pressure bodies deform faster
2. **Shape Retention**: Higher pressure bodies maintain their shape better
3. **Physics Stability**: Higher precision provides smoother, more stable physics
4. **Performance Impact**: Higher precision bodies use more CPU resources

## Interactive Testing

Try applying forces to different bodies to see:
- How quickly they deform
- How well they recover their shape
- How smooth their physics simulation appears
- Performance differences during complex interactions

## State Cycling Behavior

Each body cycles through these states:
- **Idle**: Base behavior with the configured properties
- **Active**: Enhanced pressure (×1.3 multiplier)
- **Deformed**: Maximum deformation (×1.8 multiplier)  
- **Recovering**: Gradual return to base properties

The different base pressure coefficients will make these state transitions more or less dramatic.
