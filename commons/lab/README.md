# Lab Equipment

Procedural and scene-based laboratory equipment used to furnish lab environments throughout Ada Research. Each subfolder contains a self-contained lab prop -- either a .tscn scene asset or a scripted Node3D with procedural geometry and animated behavior.

## Categories

### Animated Instruments (scripted)
Modules with dedicated .gd scripts that generate geometry procedurally and animate in _process():

| Module | Description |
|--------|-------------|
| atmosphericmonitoring | Pressure/temperature/humidity gauges with sine-wave needle drift |
| biomagneticresonator | Pulsing field rings demonstrating standing waves and resonance |
| chemicalapparatus | Bubbling flasks and test tubes with phase-offset sine animation |
| electronicscales | Damped harmonic oscillation settling display |
| holographicdisplay | Rotating hologram with scan lines and flicker |
| microscope | Pulsing stage illumination with auto-focus |
| multimeter | AC/DC voltage readout with oscillating needle |
| samplevialrack | Phased glow propagation across vial array |

### Historical Studies (scripted)
Procedural recreations of historical scientific illustrations:

| Module | Description |
|--------|-------------|
| elizabethpeabodychronologicalchart | Color-coded historical timeline grid (1859) |
| geometricstudiescollection | Bruckner polyhedra and Renaissance geometric studies |
| hirschvogelgeometry | Augustin Hirschvogel 1543 geometric constructions |
| worthingtonsplashstudy | Worthington 1895 mercury drop splash photography |

### Furniture (scripted, SurfaceTool)
Procedural furniture built with SurfaceTool:

| Module | Description |
|--------|-------------|
| chair | Office chairs (procedural and scene variants) |
| drawer | Drawer/cabinet with open/close state |
| table | Wooden lab table |

### Interactive Props (scripted)
Props with interaction logic:

| Module | Description |
|--------|-------------|
| clipboard | Grabbable clipboard showing code snippets with page navigation |
| scifishelf | Holographic shelf populated with sci-fi equipment |
| smallcontainment | Desktop containment cube with energy field and breach monitoring |

### Scene-Only Props
Static or lightly scripted .tscn assets -- lab dressing with no dedicated script file:

backpack, cardreader, circularradarmonitor, containment, cryogenicpreservation, datatablet, electromagneticfieldgenerator, fluxdetector, holographicprojector, interfacepod, pipettedispenser, quantumentanglementmeter, resonancechamber, robotarm, seismograph, temporalfluxdetector, terminal, ultrawidemonitor, verticalstatusmonitor, vintagesciencelab
