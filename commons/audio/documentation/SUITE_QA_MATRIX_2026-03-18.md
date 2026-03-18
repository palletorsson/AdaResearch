# Audio QA Matrix (Song + Suite Parity)

Date: 2026-03-18

This matrix is generated from source code wiring (static audit):
- `commons/audio/catalog/SongDevTools.gd`
- `commons/audio/catalog/SongPreviewDesktop.gd`
- `commons/audio/catalog/GenreSynthBrowser.gd`
- `commons/audio/soundbanks/SuitToSoundbankMapper.gd`
- `commons/audio/soundbanks/*/brief.json`
- `commons/audio/sequencer/SoundSuiteSequencer.gd`

## Summary

| Metric | Feb 11 | Mar 18 | Change |
|---|---|---|---|
| Total songs (JSON) | 42 | 47 | +5 |
| Songs in SongPreviewDesktop | 20 | 44 | +24 |
| Soundbank folders | 20 | 20 | 0 |
| Registered suites | 1 | 20 (auto) | +19 |
| Genre suites with PASS | 0 | 2 | +2 |
| Songs with NO_AUDIO_PATH | 1 | 0 | -1 |

## 1) Soundbank Inventory (20 banks)

| Soundbank | Sounds in brief.json | Scripts (.gd) | Status |
|---|---|---|---|
| ada_theme | kick, snare, hihat, bass, pad, sequence | 6 | OK |
| aphex_twin | kick, snare, hihat, bass, pad, sequence, texture | 7 | OK |
| boards_of_canada | kick, snare, hihat, bass, pad, sequence, texture | 7 | OK |
| burial | kick, snare, hihat, sub, atmosphere, crackle, vocal | 7 | OK |
| chromatic_story | kick, snare, hihat, rimshot, bass, piano, pad, sequence | 8 | OK |
| dark_wave | kick, snare, hihat, bass, pad, arp, lead, atmosphere, tom_low, tom_high, clap | 11 | OK |
| detroit_techno | kick, snare, hihat, clap, bass, pad, stab, sequence, sweep_up, sweep_down, impact | 11 | OK |
| dub_house | kick, snare, clap, hihat, rimshot, bass, stab, pad, siren | 9 | OK |
| emd_house | sine_arp, wub_synth, vowel_wub, gritty_lead, + 4 bass variants | 8 | OK |
| gypsy_woman_house | kick, snare, hihat, clap, bass, piano, organ, pad | 8 | OK |
| k_bass | kick, snare, hihat, sub, stab, atmosphere, break | 7 | OK |
| kpop_prog | kick, snare, clap, hihat, hihat_open, 808_sub, neomoog_lead, kraftwerk_seq, supersaw_pad, mellotron_pad | 10 | OK |
| kraftwerk | kick, snare, hihat, bass, pad, sequence, vocoder, electronic_perc | 12 | OK |
| madonna_80s | kick, snare, hihat, clap, bass, stab, pad, arp | 8 | OK |
| moroder_disco | kick, hihat, snare, sequencer, bass, pad, singing_voice | 7 | OK |
| nineties_rnb | kick, snare, clap, hihat, shaker, fingersnap, rhodes, bass, pad, strings, organ, lead, choir | 13 | OK |
| rave | kick, snare, hihat, hoover, stab, pad | 6 | OK |
| roland_emulation | juno_pad, juno_bass, d50_fantasia, tr808_*, tr909_* | 9 | OK |
| synthwave | kick, snare, hihat, bass, supersaw, arp, pad, lead, sweep_up, impact | 10 | OK |
| vangelis_cs80 | cr5000_*, cs80_*, jupiter_arp, prophet_pad, vp330_*, singing_voice | 11 | OK |

## 2) SoundSuiteSequencer Registration

**Major change since Feb 11**: SoundSuiteSequencer now auto-registers ALL soundbanks at startup via `_auto_register_soundbanks()`.

- Feb 11: Only `detroit_techno` manually registered
- Mar 18: All 20 soundbanks auto-registered from `SOUNDBANKS_BASE_PATH`

This means every soundbank with a `brief.json` is now available as a runtime suite.

## 3) Playback QA Matrix (SongDevTools + SongPreviewDesktop)

Legend: `OK`, `NO_AUDIO_PATH`, `N/A` (not in preview).

| song_id | in songs/*.json | SongDevTools route | SongPreview listed | Status |
|---|---|---|---|---|
| acid_house | True | `AudioSynthesizer.generate_acid_house_song()` | True | OK |
| acid_techno_303 | True | `AudioSynthesizer.generate_acid_house_song()` | True | OK |
| ada_theme | True | `SoundbankGenerator.generate_song("ada_theme")` | True | OK |
| ambient_techno | True | `AudioSynthesizer.generate_ambient_techno_song()` | True | OK |
| ambient_works | True | `AudioSynthesizer.generate_ambient_works_song()` | True | OK |
| aphex_twin_digital_amber | True | `SoundbankGenerator.generate_song("aphex_twin")` | True | OK |
| blade_runner | True | `AudioSynthesizer.generate_blade_runner_song()` | True | OK |
| boards_of_canada | True | `AudioSynthesizer.generate_boards_of_canada_song()` | True | OK |
| boards_of_canada_v2 | True | `AudioSynthesizer.generate_boards_of_canada_v2_song()` | True | OK |
| boc_sb | True | `SoundbankGenerator.generate_song("boards_of_canada")` | True | OK |
| burial | True | `AudioSynthesizer.generate_burial_song()` | True | OK |
| burial_sb | True | `SoundbankGenerator.generate_song("burial")` | False | N/A |
| burial_v2 | True | `AudioSynthesizer.generate_burial_v2_song()` | True | OK |
| chicago_dusseldorf | True | `SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf")` | True | OK |
| chromatic_story | True | `SoundbankGenerator.generate_song("chromatic_story")` | True | OK |
| computer_love | False | `SoundbankGenerator.generate_song("kraftwerk")` | True | OK |
| dark_kraftwerk_ambience | True | `(inferred)` | True | OK |
| dark_wave_cathedral | True | `SoundbankGenerator.generate_song("dark_wave")` | True | OK |
| detroit_sb | True | `SoundbankGenerator.generate_song("detroit_techno")` | False | N/A |
| detroit_techno | True | `AudioSynthesizer.generate_detroit_techno_song()` | True | OK |
| dub_house_sb | True | `SoundbankGenerator.generate_song("dub_house")` | True | OK |
| foggy_frequencies | True | `SoundbankGenerator.generate_hybrid_song("foggy_frequencies")` | True | OK |
| french_touch | True | `AudioSynthesizer.generate_french_touch_song()` | True | OK |
| gypsy_sb | True | `SoundbankGenerator.generate_song("gypsy_woman_house")` | False | N/A |
| gypsy_woman_house | True | `AudioSynthesizer.generate_gypsy_woman_house_song()` | True | OK |
| i_feel_love | False | `SoundbankGenerator.generate_song("moroder_disco")` | True | OK |
| k_bass | True | `SoundbankGenerator.generate_song("k_bass")` | True | OK |
| kpop_prog | False | `AudioSynthesizer.generate_kpop_prog_song()` | True | OK |
| kpop_prog_remix | True | `AudioSynthesizer.generate_kpop_prog_song()` | False | N/A |
| kraftwerk | True | `AudioSynthesizer.generate_kraftwerk_song()` | True | OK |
| kraftwerk_sb | True | `SoundbankGenerator.generate_song("kraftwerk")` | False | N/A |
| kraftwerk_v2 | True | `AudioSynthesizer.generate_kraftwerk_v2_song()` | True | OK |
| lofi_house | True | `AudioSynthesizer.generate_lofi_house_song()` | True | OK |
| madonna_sb | True | `SoundbankGenerator.generate_song("madonna_80s")` | False | N/A |
| midnight_metroplex | True | `SoundbankGenerator.generate_song("detroit_techno")` | True | OK |
| moroder_disco | True | `AudioSynthesizer.generate_moroder_disco_song()` | True | OK |
| nineties_rnb | True | `SoundbankGenerator.generate_song("nineties_rnb")` | True | OK |
| pop_generative | True | `AudioSynthesizer.generate_pop_interactive_song()` | True | OK |
| pop_madonna | True | `AudioSynthesizer.generate_pop_madonna_song()` | True | OK |
| pop_v2 | True | `AudioSynthesizer.generate_pop_v2_song()` | True | OK |
| prog_odyssey | True | `AudioSynthesizer.generate_prog_odyssey_song()` | True | OK |
| prog_synth_70s | True | `AudioSynthesizer.generate_prog_synth_song()` | True | OK |
| prog_synth_v2 | True | `AudioSynthesizer.generate_prog_synth_v2_song()` | True | OK |
| rave | True | `AudioSynthesizer.generate_rave_song()` | True | OK |
| rave_sb | True | `SoundbankGenerator.generate_song("rave")` | True | OK |
| reese_jungle | True | `AudioSynthesizer.generate_reese_jungle_song()` | True | OK |
| replicants_dawn | True | `SoundbankGenerator.generate_hybrid_song("replicants_dawn")` | True | OK |
| supersaw_trance | True | `AudioSynthesizer.generate_supersaw_trance_song()` | True | OK |
| synthwave | True | `AudioSynthesizer.generate_synthwave_song()` | True | OK |
| synthwave_sb | True | `SoundbankGenerator.generate_song("synthwave")` | True | OK |

**Totals:**
- Songs in `parameters/songs/*.json`: 47
- Songs listed in SongPreviewDesktop: 44
- Songs with valid routes: 47 (all)
- Songs with NO_AUDIO_PATH: 0 (fixed since Feb 11)

## 4) Suite->Soundbank Parity (per GenreSynthBrowser genre)

Checks per GENRE_SUITES definition:
- Every suite element maps to a sound name via `ELEMENT_TO_SOUND` + fallback rules
- Mapped sound exists in the genre soundbank `brief.json`
- Runtime `main` pattern can be complete (all mapped sounds present)

| genre | soundbank exists | mapped sounds | missing element->sound | missing in soundbank | status |
|---|---|---|---|---|---|
| detroit_techno | yes | 10 | 0 | 0 | **PASS** |
| synthwave | yes | 10 | 0 | 0 | **PASS** |
| acid_house | no | 7 | 2 | 0 | NO_SOUNDBANK |
| chicago_house | no | 7 | 3 | 0 | NO_SOUNDBANK |
| rave_hardcore | no | 6 | 4 | 0 | NO_SOUNDBANK |
| jungle_dnb | no | 7 | 1 | 0 | NO_SOUNDBANK |
| ambient_idm | no | 4 | 5 | 0 | NO_SOUNDBANK |
| disco_funk | no | 8 | 1 | 0 | NO_SOUNDBANK |
| hip_hop | no | 7 | 2 | 0 | NO_SOUNDBANK |
| prog_rock | no | 7 | 3 | 0 | NO_SOUNDBANK |
| dub_techno | no | 8 | 2 | 0 | NO_SOUNDBANK |
| uk_garage | no | 8 | 2 | 0 | NO_SOUNDBANK |
| neurofunk | no | 9 | 1 | 0 | NO_SOUNDBANK |

**Status totals:**
- `PASS`: 2 (detroit_techno, synthwave) - up from 0
- `FAIL_MAPPING`: 0 - down from 1
- `FAIL_BANK_COVERAGE`: 0 - down from 1
- `NO_SOUNDBANK`: 11 - unchanged

### Details: Fixed since Feb 11

**detroit_techno** (was FAIL_BANK_COVERAGE):
- Added: `sequence.gd`, `sweep_up.gd`, `sweep_down.gd`, `impact.gd`
- Now fully mapped: kick, snare, hihat, clap, bass, pad, stab, sequence, sweep_up, sweep_down, impact

**synthwave** (was FAIL_MAPPING):
- Added: `lead.gd`, `sweep_up.gd`, `impact.gd`
- Now fully mapped: kick, snare, hihat, bass, supersaw, arp, pad, lead, sweep_up, impact

### Details: Still missing (NO_SOUNDBANK genres)

These genres are defined in `GENRE_SUITES` but no matching soundbank folder exists:

| genre | missing element->sound mappings |
|---|---|
| acid_house | bass:tb303_acid, hook:arp_synth |
| chicago_house | harmony:house_organ, harmony:house_piano, hook:house_piano |
| rave_hardcore | rhythm:amen_break, bass:mentasm, harmony:rave_piano, hook:trancer |
| jungle_dnb | rhythm:amen_break |
| ambient_idm | rhythm:lofi_break, rhythm:bitcrush_drums, bass:ambient_drone, hook:trap_bell, fx:tape_delay |
| disco_funk | bass:moroder_seq |
| hip_hop | hook:trap_bell, fx:sp1200_crunch |
| prog_rock | rhythm:motorik_beat, harmony:cs80_brass, fx:tape_delay |
| dub_techno | harmony:dub_chord, fx:tape_delay |
| uk_garage | hook:ukg_pluck, hook:ukg_vocal_chop |
| neurofunk | hook:neuro_laser |

## 5) Additional Soundbanks (not in GENRE_SUITES)

These soundbanks exist and work but are not defined as GENRE_SUITES in GenreSynthBrowser:

| Soundbank | Songs using it | Status |
|---|---|---|
| ada_theme | ada_theme | OK |
| aphex_twin | aphex_twin_digital_amber | OK |
| boards_of_canada | boc_sb | OK |
| burial | burial_sb | OK |
| chromatic_story | chromatic_story | OK |
| dark_wave | dark_wave_cathedral | OK |
| dub_house | dub_house_sb | OK |
| emd_house | (standalone) | OK |
| gypsy_woman_house | gypsy_sb | OK |
| k_bass | k_bass | OK |
| kpop_prog | kpop_prog | OK |
| kraftwerk | kraftwerk_sb, computer_love | OK |
| madonna_80s | madonna_sb | OK |
| moroder_disco | moroder_disco, i_feel_love | OK |
| nineties_rnb | nineties_rnb | OK |
| rave | rave_sb | OK |
| roland_emulation | (reference bank) | OK |
| vangelis_cs80 | blade_runner | OK |

## Notes

- `SoundSuiteSequencer` now auto-registers all 20 soundbanks at startup (major improvement).
- `dark_wave_cathedral` route was already fixed in commit 0cf771cb (Feb 11) - no action needed.
- All 47 songs have valid audio routes - no more NO_AUDIO_PATH status.
- SongPreviewDesktop expanded from 20 to 44 songs.
- detroit_techno and synthwave are now PASS status after adding missing scripts.
- 11 genres still need dedicated soundbank folders to achieve full parity.
- This report is static and does not replace listening QA for balance, clipping, or musicality.
