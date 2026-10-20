# Offline is still physical

13 October 2026. Research following Palle's question about randomness from within
the Quest. This note does not change the museum or canonical chapter.

## Direct observations

The connected Quest 3 reported Android 14. A read-only USB-shell check of
`dumpsys connectivity` reported `Active default network: none`. Reading two bytes
with `od -An -tu2 -N2 /dev/urandom` returned **16137**. This is an operating-system
random output, not a raw physical sensor sample or evidence proving fundamental
indeterminism. The USB shell read worked; this turn did not run a Godot APK probe.

The Android sensor-service inventory listed three custom Oculus sensor types:
double tap, HMD IMU and IAD. The HMD IMU identifies an ICM45688 and custom type
`oculus.sensor.hmd_imu.2` (65537). Standard Android accelerometer and gyroscope
types were not listed. Inventory visibility does not establish supported access
from an ordinary application. No live motion, microphone or camera capture was
performed, and no full device calibration dump is retained here.

## API and source checks

- Godot's [Crypto API](https://docs.godotengine.org/en/stable/classes/class_crypto.html)
  offers `generate_random_bytes()`. In the project's Godot 4.6 release,
  [CryptoMbedTLS](https://github.com/godotengine/godot/blob/4.6-stable/modules/mbedtls/crypto_mbedtls.cpp)
  uses CTR-DRBG, initialised through the mbedTLS entropy collector. The bundled
  [platform entropy source](https://github.com/godotengine/godot/blob/4.6-stable/thirdparty/mbedtls/library/entropy_poll.c)
  reads the operating-system source. This route is local; it is not a network
  service and does not give the application raw thermal-noise samples. The exact
  hardware contributions to this Quest's operating-system pool remain unverified.
- [XRPose](https://docs.godotengine.org/en/stable/classes/class_xrpose.html)
  supplies position, orientation, linear/angular velocity and tracking validity.
  [OpenXR](https://registry.khronos.org/OpenXR/specs/1.0-khr/html/xrspec.html)
  permits locations at historical or predicted times. These are runtime estimates,
  not a documented raw electrical-noise stream. Small changes can combine bodily
  movement, sensor uncertainty and tracking computations.
- Godot's ordinary Android gyro API needs an enabled sensor and can return zero
  if unavailable. The custom sensor list means we should test access, rather
  than infer support from the presence of an IMU.
- [Microphone input](https://docs.godotengine.org/en/stable/tutorials/audio/recording_with_microphone.html)
  is another potential physical input, subject to audio permission and the
  device's processing. Microphone noise quality has not been measured here.
- Meta documents [camera access](https://developers.meta.com/vr/documentation/spatial-sdk/spatial-sdk-pca-overview/)
  on Quest 3/3S with camera permission. Accessible images are not a promise of
  unprocessed sensor noise; using them requires additional integration and testing.

## Proposed encounter

Keep one colour bench and distinguish three source choices: remote atmospheric
draw, device cryptographic source, and measured hand movement. Preserve source,
sample procedure and seed so a visitor can replay the resulting picture.

For the bodily version, a person holds the carried sphere as still as possible.
An enlarged trace shows the fluctuations still reported by tracking. A brief
sample becomes a seed; replay preserves its consequence. Label this **tracking
sample**, never certified true randomness. Reject missing or stale tracking;
report a constant sample honestly. Do not invent fluctuations to keep the display
busy. Hashing can mix samples but cannot create entropy absent from the source.

The critical distinction is between a system disconnected from the internet and
a system closed to physical events. A bodily sample also makes the choices of
measurement, filtering, range and assignment available for the student to inspect.

## Historical connection: input becomes seed material

Palle supplied the PGP / TrueCrypt / VeraCrypt precedent. The PGP 6.0
[Introduction to Cryptography](https://pgpkeys.org/docs/6.0/IntroToCrypto.pdf),
in Zimmermann's discussion of session keys, describes seed material derived
from the timing of keystrokes and mouse movements. VeraCrypt's current
[RNG documentation](https://veracrypt.io/en/Random%20Number%20Generator.html)
lists mouse events alongside other sources, including operating-system random
output, and describes hashing its pool. This is a precedent for mixing physical
input with algorithmic generation, not evidence that all reported motion is
uniformly random or that hashing adds entropy of its own.

X41's [25 September 2025 mouse study](https://x41-dsec.de/security/research/news/2025/09/25/mouse-entropy/)
provides evidence about mouse-event collection under its tested conditions.
It does not measure the entropy of Quest's filtered and predicted poses.

Candidate paragraph route for a later writing trial: saved atmospheric arrival
435 -> present visitor's sampled movement -> historical input collection for
cryptography -> the distinction between sample, seed and generated sequence ->
replay of the resulting picture. This is a candidate, not a canonical rewrite.
Within the chapter's size budget, the historical detour must be chosen or
compressed alongside RAND, rather than automatically adding a second long history.

For the first encounter, retain the carried sphere and paired 4 x 4 colour grids:
hold and move to collect a short valid tracking sample, release to derive and keep
a seed, regenerate the grids, and replay. An enlarged trace makes collection
visible; label its length as a sample count or duration, not an entropy score.
Reject missing or stale tracking. A larger multi-sensor laboratory is a separate
scope decision. Reproduction here means the same initial colour arrangement with
the same generator and procedure, not a promise that an entire physics simulation
will play out identically.
