extends Node

var text = '''
[center][b]Time Series Analysis[/b][/center]
[center][i]Trend, seasonality, and forecasting in 3D[/i][/center]

[hr]
[b]What You Are Seeing[/b]
- Blue data particles trace a temporal waveform — sin(4π·t) with cosine depth, representing historical observations.
- Green forecast particles trace a predicted future — sin(3π·t) at slightly lower amplitude, showing model output.
- Three analysis method cores rotate inside the engine:
  [color=red]Trend Analysis[/color] — detects long-term direction.
  [color=red]Seasonality[/color] — identifies repeating cycles.
  [color=red]Forecasting[/color] — projects future values.
- A time axis core anchors the temporal reference frame.
- Gold flow particles move through the pipeline from input data → engine → forecast output.
- Accuracy and forecast horizon meters show model confidence.

[hr]
[b]Key Controls[/b]
[color=yellow]Inspector[/color]
[code]
analysis_progress : 0–1 manual progress override
accuracy_score    : manual accuracy (0–1)
forecast_horizon  : manual horizon reach (0–1)
particle_count    : data density (10–50)
animation_speed   : global animation multiplier
auto_progress     : enable auto-advance mode
[/code]

[hr]
[b]How It Works[/b]
- `create_time_series_particles()` distributes particles along a sine wave with 4 full periods, creating a visible seasonal pattern.
- `animate_time_series_data()` drifts each particle's position using `sin(progress * 4π + time * 1.2)` — the wave continuously flows forward in time.
- The forecast particles use 3 periods at 80% amplitude — the model captures the main pattern but slightly underestimates peaks, a realistic forecasting behavior.
- `_on_progress_changed()` fires a gold→green tween on the engine core to signal processing activity.
- `reset_analysis()` zeros all metrics and pulses the engine to 1.5× scale.
- Stats label: "Progress: X% | Accuracy: Y% | Horizon: Z%".

[hr]
[b]Try This[/b]
1. Disable `auto_progress` and slowly increase `analysis_progress` — watch data particles stabilize as the model learns the pattern.
2. Set accuracy high but horizon low to see a model that's accurate near-term but fades.
3. Increase `particle_count` to 50 for a denser waveform that shows the sine pattern more clearly.
4. Compare the blue input wave with the green forecast wave — notice the amplitude difference.

[hr]
[i]VR Tip[/i]
Walk along the time axis from left to right to travel forward in time — blue historical data behind you, green forecasts ahead.
'''
