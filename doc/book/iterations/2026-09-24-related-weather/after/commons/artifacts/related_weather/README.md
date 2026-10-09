# Related weather

Three full-size glazed viewing walls for `Random_Noise_Types`. Fresh samples, accumulated steps and an approximate pink filter share uniform innovations. Only sight apertures move; glass and floor collision stay fixed.

- `weather_signals.gd`: raw model, explicit filter preparation, no display clamp.
- `related_weather.gd`: eight visible moments, fixed display gain and bounds, identical travel, 128-sample record budget, production pointer/VR-area buttons.
- `related_weather.tscn`: registered artifact scene.

RUN / HOLD shares one clock. NEXT starts one sample or completes the paused stroke. REPLAY clears and reseeds, including 4096 preparation samples for the pink filter. NEW SEED selects a different seed; no promise that a short run must look different. Orange markers identify clipped target values. The gold sight target and all glass collision remain fixed.

The filter coefficients come from [Julius O. Smith, Spectral Audio Signal Processing: Example, Synthesis of 1/F Noise](https://www.dsprelated.com/freebooks/sasp/Example_Synthesis_1_F_Noise.html). The production model uses uniform innovations, while the reference example uses Gaussian innovations. The linear filter response is unchanged; marginal distributions differ. The filter is finite and approximately pink only over a verified band.

`doc/book/iterations/2026-09-24-related-weather/` contains native controls/collision checks, actual museum captures and routes, raw production-model samples, independent recurrence and spectral checks, source snapshots and exact book differences. The measured band is 0.01–0.20 cycles per sample, before display gain, clamp and easing. Eight apertures are not enough evidence to certify a spectrum. The other hall's audio filters and illustrated spectral curves remain separate constructions.

Headset reach, comfort, group interpretation and Quest performance remain open. This scene makes no audio, natural weather, geology or physical entropy claim.
