# Atmospheric Monitoring

Laboratory monitoring station with oscillating gauge needles driven by sine waves at different frequencies.

## Behavior

Three independent gauges animate in _process():
- **Pressure** -- slow drift around 1013.25 hPa (0.05 Hz)
- **Temperature** -- subtle variation around 22 C (0.02 Hz)
- **Humidity** -- moderate swing around 45% (0.03 Hz)

Status lights and a display panel complete the station.

## Files

| File | Purpose |
|------|---------|
| atmosphericmonitoring.gd | LabAtmosphericMonitoring -- procedural build + sine animation |
| atmosphericmonitoring.tscn | Scene |
