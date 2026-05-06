# QFEP Sandbox - Summary

## Overview
The seventh QFEP Laboratory map removes all guardrails. Both lambda and phi sliders are unlocked at their defaults (0.5 each). The qfep_reactor at center responds to parameter changes in real time, producing visible behavior that shifts continuously between crystal, edge, and chaos regimes. The learner must find their own edge of chaos — no targets, no scores, no locked parameters.

## Spatial Layout
- **Dimensions**: 14x16 grid with elevated central platform
- **Architecture**: Height 2 perimeter walls, height 1 walkway, height 3 central platform (rows 3-9, columns 3-10) housing the reactor and reactive particles
- **Console layout**: lambda_slider at (2,2) and phi_slider at (10,2) flanking the entrance; qfep_formula_3d at (5,12) near exit

## Key Elements

### Interactables
- **lambda_slider** (0-1, default 0.5) — Controls order-chaos balance; fully unlocked
- **phi_slider** (-1 to +1, default 0.5) — Controls disposition toward change; fully unlocked
- **qfep_reactor** — Central simulation engine computing QFE = F - lambda*E(S) + phi*delta_E in real time from live particle entropy
- **reactive_particles** (2 instances) — Visual field modulated by both sliders: spread, gravity, speed, count, and color all respond to parameters
- **qfep_formula_3d** — Live equation display with term scaling, pulsing, and QFE readout

### Utilities
- **Spawn** at (1,1), **elevator** at (6,5), two teleporters: "qfep_mastery" and "qfep_queer"

## Learning Sequence
1. Enter and reach both sliders within seconds of spawn
2. Adjust lambda — watch particles shift from tight beams to omnidirectional scatter
3. Adjust phi — watch particles accelerate (positive) or decelerate (negative) without changing distribution
4. Explore the two-dimensional parameter space: low-lambda/low-phi (frozen), low-lambda/high-phi (spring-loaded), high-lambda/low-phi (stagnant chaos), high-lambda/high-phi (runaway dissolution)
5. Find the zone where the reactive_particles produce emergent structure — approximately lambda 0.3-0.5, phi slightly positive
6. Check the formula display near the exit: does the QFE number match the felt experience?
7. Exit toward mastery or queer application

## Design Intent
The Sandbox tests operational understanding. The learner knows QFEP not when they can recite the terms but when they can tune the parameters to produce desired behaviors. The open-ended format — no correct answer, no grade — embodies the curriculum's thesis that understanding is capacity, not declaration. Two exit paths honor both technical and critical engagement with the formula.

## Connection to Sequence
- **Position**: 7/8 in qfeplaboratory
- **Follows**: QFEP_Edge_Of_Chaos (witnessed emergence at locked parameters)
- **Leads to**: QFEP_Synthesis (integration and return)
