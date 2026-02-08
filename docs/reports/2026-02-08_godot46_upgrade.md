# Godot 4.6 Upgrade Report
**Date:** 2026-02-08

## Summary

Upgraded AdaResearch project to Godot 4.6 with Android build template reinstallation.

## Android Build Fix

**Problem:** JVM crash during Android export
```
Internal Error (relocInfo_x86.cpp:106)
Error: ShouldNotReachHere()
JRE: OpenJDK Temurin-17.0.14+7
```

**Cause:** JIT compiler bug in Temurin 17.0.14 when compiling `java.util.zip.ZipUtils::CENCOM`

**Solution:** Switched JAVA_HOME to Microsoft JDK 17.0.11
```
C:\Program Files\Microsoft\jdk-17.0.11.9-hotspot
```

## Build Configuration

| Component | Version |
|-----------|---------|
| Godot | 4.6 |
| Gradle | 8.11.1 |
| Android Gradle Plugin | 8.6.1 |
| JDK | Microsoft OpenJDK 17.0.11 |
| Target SDK | 35 |
| Min SDK | 24 |

## New Enemy: Sphere Droideka

Added Armadillidiidae/Star Wars-inspired spherical droideka enemy.

### Behavior Cycle
```
BALL → UNROLL → DEPLOY → AIM → FIRE → RETRACT → ROLL_UP → BALL
```

### Features
- 8 latitudinal bands of curved overlapping shell plates
- 12 longitudinal slices per band
- Plates hinge outward from equator when deploying
- 3 tripod legs unfold from inside
- Twin barrel turret on rising core
- Transparent shield dome when deployed
- Shield absorbs damage before health

### Files
- `commons/hazards/sphere_droideka/sphere_droideka.gd`
- `commons/hazards/sphere_droideka/sphere_droideka.tscn`

### Usage
```json
"sphere_droideka"
```

## Existing Folding Enemies (Verified)

| Enemy | Mechanism | Status |
|-------|-----------|--------|
| miura_crawler | Miura-ori corrugated sheet | ✅ |
| kresling_spire | Twisting cylinder tower | ✅ |
| scissor_stalker | Hoberman scissor linkage legs | ✅ |
| kaleidocycle_enemy | Tumbling tetrahedra ring | ✅ |
| origami_droideka | Magic-ball accordion pleats | ✅ |
| sphere_droideka | Segmented shell ball→tripod | ✅ NEW |

## Utility Added

**ProximitySpawner** - Spawns enemies when player enters radius, respawns after death.

```json
"proximity_spawner#type:sphere_droideka#spawn_radius:15#respawn_delay:2"
```
