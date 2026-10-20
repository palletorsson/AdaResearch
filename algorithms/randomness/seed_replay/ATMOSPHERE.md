# An atmospheric seed in the museum

Random Definition opts into `atmosphere:true`. Its ATMOSPHERE hand button asks
RANDOM.ORG for one integer in **0–999**, the same range as the existing seed slider.
The source and number appear above the grids. Godot then uses that seed to draw
the colours; the colour stream remains pseudorandom and reproducible. REPLAY
does not contact the service.

Random Definition opens with the actual recorded response **435**, received at
2026-10-13T14:29:02Z and retained in `opening_seed.json`. Its map and museum plan
opt into `seed:435#recorded_atmosphere:true`. A large display above the grids
names the source, date and saved status. It follows seed edits and new responses;
the date is a receipt, not a claim that the museum contacted the service on arrival.

No request occurs on arrival or when a saved room state is restored. The receipt
retains the provider, range, endpoint and UTC receipt time alongside the seed in
the existing museum visit state. A local seed edit clears that attribution. If
the visitor edits while a request is pending, the later response cannot overwrite
the edit. Unavailable service, malformed replies and out-of-range values retain
the current picture; there is no local substitute labelled as atmospheric noise.

The existing Android preset already enables INTERNET permission. The request
uses HTTPS with normal certificate verification, asynchronously, with a two-minute
timeout. The app permits one request at a time, checks quota before each seed,
backs off ten minutes for exhausted quota, one minute after other failures, and
five seconds after success. Other placements stay offline unless explicitly opted in.

Service documentation: [HTTP API](https://www.random.org/clients/http/api/) and
[client guidelines](https://www.random.org/clients/). The latter request a contact
email in User-Agent. A maintainer can set the project setting
`ada/random_org/contact` to a public maintenance address; the client does not read
or transmit a user's account email.

Verification probe:

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-atmosphere-in-the-headset/museum_probe.gd --output-tag atmosphere
```

The probe includes one real service request and deterministic failure responses.
On 13 October 2026, all 48 checks passed. Godot on desktop received seed 435 and
replayed its exact colour stream. The production client also ran in an isolated
Android test app on a connected Quest 3; that headset reported no active network
and disconnected Wi-Fi, so its request failed. The test app was removed afterward.
An online Quest request and VR hand reach remain unverified. These source changes
will be included in the next museum APK build; the installed museum was not replaced.

Evidence: `doc/book/iterations/2026-10-13-atmosphere-in-the-headset/` contains the
desktop report, museum captures, Android probe script and headset result.

The opening-display pass added checks for the recorded arrival, visible source,
display updates and the physical +1 DRAW button: 64/64 passed on desktop Godot.
A separate photograph pass passed 7/7 and made matching views before and after
the discarded draw without a network request. The reports and reading edition
are in `doc/book/iterations/2026-10-13-a-number-in-the-room/`.

Random Definition now also opts into a movement sampler beside the same grids.
Holding and moving a PointBody sphere records poses and timing; release derives
a seed, with its source visibly distinguished from the atmospheric receipt.
See [Movement becomes a seed](MOVEMENT.md) for the measurement, replay contract
and limitations. The atmospheric arrival and HTTP button keep their existing jobs.
