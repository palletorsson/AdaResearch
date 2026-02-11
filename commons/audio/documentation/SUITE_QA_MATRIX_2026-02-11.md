# Audio QA Matrix (Song + Suite Parity)

Date: 2026-02-11

This matrix is generated from source code wiring (static audit):
- `commons/audio/catalog/SongDevTools.gd`
- `commons/audio/catalog/SongPreviewDesktop.gd`
- `commons/audio/catalog/GenreSynthBrowser.gd`
- `commons/audio/soundbanks/SuitToSoundbankMapper.gd`
- `commons/audio/soundbanks/*/brief.json`

## 3) Playback QA Matrix (SongDevTools + SongPreviewDesktop)

Legend: `OK`, `NO_AUDIO_PATH`, `LISTED_BUT_NO_ROUTE`, `N/A`.

Snapshot totals:
- songs in `commons/audio/parameters/songs/*.json`: `42`
- songs listed in `SongPreviewDesktop`: `20`
- JSON songs with no direct audio route in `SongDevTools`: `1` (`dark_wave_cathedral`)

| song_id | in songs/*.json | SongDevTools route | Ref mix route | Dev status | SongPreview listed | SongPreview route | Preview status |
|---|---|---|---|---|---|---|---|
| acid_house | True | `AudioSynthesizer.generate_acid_house_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| acid_techno_303 | True | `AudioSynthesizer.generate_acid_house_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| ada_theme | True | `SoundbankGenerator.generate_song("ada_theme", generation_params)` | `SoundbankGenerator.generate_song("ada_theme", {"bpm": 100})` | OK | True | `SoundbankGenerator.generate_song("ada_theme", {"bpm": 100})` | OK |
| ambient_techno | True | `AudioSynthesizer.generate_ambient_techno_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| ambient_works | True | `AudioSynthesizer.generate_ambient_works_song(generation_params)` | `AudioSynthesizer.generate_ambient_works_song({})` | OK | True | `AudioSynthesizer.generate_ambient_works_song({})` | OK |
| aphex_twin_digital_amber | True | `SoundbankGenerator.generate_song("aphex_twin", generation_params)` | `SoundbankGenerator.generate_song("aphex_twin", {"bpm": 108})` | OK | True | `SoundbankGenerator.generate_song("aphex_twin", {"bpm": 108})` | OK |
| blade_runner | True | `AudioSynthesizer.generate_blade_runner_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| boards_of_canada | True | `AudioSynthesizer.generate_boards_of_canada_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| boards_of_canada_v2 | True | `AudioSynthesizer.generate_boards_of_canada_v2_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| boc_sb | True | `SoundbankGenerator.generate_song("boards_of_canada", generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| burial | True | `AudioSynthesizer.generate_burial_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| burial_sb | True | `SoundbankGenerator.generate_song("burial", generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| burial_v2 | True | `AudioSynthesizer.generate_burial_v2_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| chicago_dusseldorf | False | `SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf", generation_params)` | `SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf", {})` | OK | True | `SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf", {})` | OK |
| chromatic_story | True | `SoundbankGenerator.generate_song("chromatic_story", generation_params)` | `SoundbankGenerator.generate_song("chromatic_story", {"bpm": 100})` | OK | True | `SoundbankGenerator.generate_song("chromatic_story", {"bpm": 100})` | OK |
| computer_love | False | `(no direct route)` | `SoundbankGenerator.generate_song("kraftwerk", {"bpm": 129})` | NO_AUDIO_PATH | True | `SoundbankGenerator.generate_song("kraftwerk", {"bpm": 129})` | OK |
| dark_wave_cathedral | True | `(no direct route)` | `(none)` | NO_AUDIO_PATH | False | `(not in SongPreviewDesktop)` | N/A |
| detroit_sb | True | `SoundbankGenerator.generate_song("detroit_techno", generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| detroit_techno | True | `AudioSynthesizer.generate_detroit_techno_song(generation_params)` | `AudioSynthesizer.generate_detroit_techno_song({})` | OK | True | `AudioSynthesizer.generate_detroit_techno_song({})` | OK |
| dub_house_sb | True | `SoundbankGenerator.generate_song("dub_house", generation_params)` | `SoundbankGenerator.generate_song("dub_house", {"bpm": 122})` | OK | True | `SoundbankGenerator.generate_song("dub_house", {"bpm": 122})` | OK |
| foggy_frequencies | False | `SoundbankGenerator.generate_hybrid_song("foggy_frequencies", generation_params)` | `SoundbankGenerator.generate_hybrid_song("foggy_frequencies", {})` | OK | True | `SoundbankGenerator.generate_hybrid_song("foggy_frequencies", {})` | OK |
| french_touch | True | `AudioSynthesizer.generate_french_touch_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| gypsy_sb | True | `SoundbankGenerator.generate_song("gypsy_woman_house", generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| gypsy_woman_house | True | `AudioSynthesizer.generate_gypsy_woman_house_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| i_feel_love | False | `(no direct route)` | `SoundbankGenerator.generate_song("moroder_disco", {"bpm": 126})` | NO_AUDIO_PATH | True | `SoundbankGenerator.generate_song("moroder_disco", {"bpm": 126})` | OK |
| k_bass | True | `SoundbankGenerator.generate_song("k_bass", generation_params)` | `SoundbankGenerator.generate_song("k_bass", {"bpm": 170})` | OK | True | `SoundbankGenerator.generate_song("k_bass", {"bpm": 170})` | OK |
| kpop_prog | False | `(no direct route)` | `AudioSynthesizer.generate_kpop_prog_song({})` | NO_AUDIO_PATH | True | `AudioSynthesizer.generate_kpop_prog_song({})` | OK |
| kpop_prog_remix | True | `AudioSynthesizer.generate_kpop_prog_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| kraftwerk | True | `AudioSynthesizer.generate_kraftwerk_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| kraftwerk_sb | True | `SoundbankGenerator.generate_song("kraftwerk", generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| kraftwerk_v2 | True | `AudioSynthesizer.generate_kraftwerk_v2_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| lofi_house | True | `AudioSynthesizer.generate_lofi_house_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| madonna_sb | True | `SoundbankGenerator.generate_song("madonna_80s", generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| midnight_metroplex | True | `SoundbankGenerator.generate_song("detroit_techno", generation_params)` | `SoundbankGenerator.generate_song("detroit_techno", {})` | OK | True | `SoundbankGenerator.generate_song("detroit_techno", {})` | OK |
| moroder_disco | True | `AudioSynthesizer.generate_moroder_disco_song(generation_params)` | `SoundbankGenerator.generate_song("moroder_disco", {"bpm": 126})` | OK | True | `SoundbankGenerator.generate_song("moroder_disco", {"bpm": 126})` | OK |
| nineties_rnb | True | `SoundbankGenerator.generate_song("nineties_rnb", generation_params)` | `SoundbankGenerator.generate_song("nineties_rnb", {"bpm": 92})` | OK | True | `SoundbankGenerator.generate_song("nineties_rnb", {"bpm": 92})` | OK |
| pop_generative | True | `AudioSynthesizer.generate_pop_interactive_song(generation_params)` | `AudioSynthesizer.generate_pop_interactive_song({})` | OK | True | `AudioSynthesizer.generate_pop_interactive_song({})` | OK |
| pop_madonna | True | `AudioSynthesizer.generate_pop_madonna_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| pop_v2 | True | `AudioSynthesizer.generate_pop_v2_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| prog_synth_70s | True | `AudioSynthesizer.generate_prog_synth_song(generation_params)` | `AudioSynthesizer.generate_prog_synth_song({})` | OK | True | `AudioSynthesizer.generate_prog_synth_song({})` | OK |
| prog_synth_v2 | True | `AudioSynthesizer.generate_prog_synth_v2_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| rave | True | `AudioSynthesizer.generate_rave_song(generation_params)` | `AudioSynthesizer.generate_rave_song({})` | OK | True | `AudioSynthesizer.generate_rave_song({})` | OK |
| rave_sb | True | `SoundbankGenerator.generate_song("rave", generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| reese_jungle | True | `AudioSynthesizer.generate_reese_jungle_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| replicants_dawn | False | `SoundbankGenerator.generate_hybrid_song("replicants_dawn", generation_params)` | `SoundbankGenerator.generate_hybrid_song("replicants_dawn", {})` | OK | True | `SoundbankGenerator.generate_hybrid_song("replicants_dawn", {})` | OK |
| supersaw_trance | True | `AudioSynthesizer.generate_supersaw_trance_song(generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |
| synthwave | True | `AudioSynthesizer.generate_synthwave_song(generation_params)` | `AudioSynthesizer.generate_synthwave_song({})` | OK | True | `AudioSynthesizer.generate_synthwave_song({})` | OK |
| synthwave_sb | True | `SoundbankGenerator.generate_song("synthwave", generation_params)` | `(none)` | OK | False | `(not in SongPreviewDesktop)` | N/A |

## 4) Suit->Soundbank Parity (per genre)

Checks:
- every suite element maps to a sound name (`ELEMENT_TO_SOUND` + fallback rules)
- mapped sound exists in the genre soundbank `brief.json`
- runtime `main` pattern can be complete (all mapped sounds included)

| genre | soundbank exists | mapped sounds | missing element->sound map | missing in soundbank | main pattern complete | status |
|---|---:|---:|---:|---:|---|---|
| acid_house | no | 7 | 2 | 0 | no | NO_SOUNDBANK |
| detroit_techno | yes | 10 | 0 | 4 | yes | FAIL_BANK_COVERAGE |
| chicago_house | no | 7 | 3 | 0 | no | NO_SOUNDBANK |
| rave_hardcore | no | 6 | 4 | 0 | no | NO_SOUNDBANK |
| jungle_dnb | no | 7 | 1 | 0 | no | NO_SOUNDBANK |
| synthwave | yes | 8 | 2 | 3 | no | FAIL_MAPPING |
| ambient_idm | no | 4 | 5 | 0 | no | NO_SOUNDBANK |
| disco_funk | no | 8 | 1 | 0 | no | NO_SOUNDBANK |
| hip_hop | no | 7 | 2 | 0 | no | NO_SOUNDBANK |
| prog_rock | no | 7 | 3 | 0 | no | NO_SOUNDBANK |
| dub_techno | no | 8 | 2 | 0 | no | NO_SOUNDBANK |
| uk_garage | no | 8 | 2 | 0 | no | NO_SOUNDBANK |
| neurofunk | no | 9 | 1 | 0 | no | NO_SOUNDBANK |

Status totals:
- `PASS`: `0`
- `FAIL_MAPPING`: `1` (`synthwave`)
- `FAIL_BANK_COVERAGE`: `1` (`detroit_techno`)
- `NO_SOUNDBANK`: `11`

### Details: Missing map entries
- `acid_house`: bass:tb303_acid, hook:arp_synth
- `chicago_house`: harmony:house_organ, harmony:house_piano, hook:house_piano
- `rave_hardcore`: rhythm:amen_break, bass:mentasm, harmony:rave_piano, hook:trancer
- `jungle_dnb`: rhythm:amen_break
- `synthwave`: harmony:supersaw, hook:arp_synth
- `ambient_idm`: rhythm:lofi_break, rhythm:bitcrush_drums, bass:ambient_drone, hook:trap_bell, fx:tape_delay
- `disco_funk`: bass:moroder_seq
- `hip_hop`: hook:trap_bell, fx:sp1200_crunch
- `prog_rock`: rhythm:motorik_beat, harmony:cs80_brass, fx:tape_delay
- `dub_techno`: harmony:dub_chord, fx:tape_delay
- `uk_garage`: hook:ukg_pluck, hook:ukg_vocal_chop
- `neurofunk`: hook:neuro_laser

### Details: Missing soundbank entries
- `detroit_techno`: hook:arp_sequence->sequence, fx:noise_riser->sweep_up, fx:noise_fall->sweep_down, fx:impact_hit->impact
- `synthwave`: hook:synthwave_lead->lead, fx:noise_riser->sweep_up, fx:impact_hit->impact

## Notes
- `SoundSuiteSequencer` currently registers one mapper runtime suite at startup: `detroit_techno`.
- Genres without a matching soundbank folder are expected to fail parity until that bank is authored.
- This report is static and does not replace listening QA for balance, clipping, or musicality.
