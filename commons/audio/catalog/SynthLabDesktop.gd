# SynthLabDesktop.gd
# Main desktop application for AdaResearch synthesis tools
# Combines: Element Browser, Song Dev Tools, Audio Catalog

extends Control

const SynthElementBrowser = preload("res://commons/audio/catalog/SynthElementBrowser.gd")

var _tab_container: TabContainer
var _element_browser: SynthElementBrowser
var _status_label: Label

func _ready():
	get_tree().root.title = "AdaResearch Synth Lab"
	_build_ui()
	print("Synth Lab Desktop ready")


func _build_ui():
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)
	
	# Header
	var header = _create_header()
	main_vbox.add_child(header)
	
	# Tab container
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_tab_container)
	
	# Tab 1: Synth Element Browser
	_element_browser = SynthElementBrowser.new()
	_element_browser.name = "🎛️ Elements"
	_tab_container.add_child(_element_browser)
	
	# Tab 2: Quick Reference
	var reference_panel = _create_reference_panel()
	reference_panel.name = "📚 Reference"
	_tab_container.add_child(reference_panel)
	
	# Tab 3: About
	var about_panel = _create_about_panel()
	about_panel.name = "ℹ️ About"
	_tab_container.add_child(about_panel)
	
	# Status bar
	var status_bar = PanelContainer.new()
	status_bar.custom_minimum_size.y = 30
	main_vbox.add_child(status_bar)
	
	_status_label = Label.new()
	_status_label.text = "Ready. Select an element to begin."
	status_bar.add_child(_status_label)


func _create_header() -> Control:
	var header = PanelContainer.new()
	header.custom_minimum_size.y = 60
	
	var hbox = HBoxContainer.new()
	header.add_child(hbox)
	
	var title = Label.new()
	title.text = "🔊 SYNTH LAB"
	title.add_theme_font_size_override("font_size", 28)
	hbox.add_child(title)
	
	hbox.add_child(HSeparator.new())
	
	var subtitle = Label.new()
	subtitle.text = "Deep synthesis research for AdaResearch"
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	hbox.add_child(subtitle)
	
	return header


func _create_reference_panel() -> Control:
	var scroll = ScrollContainer.new()
	
	var content = RichTextLabel.new()
	content.bbcode_enabled = true
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.text = _get_reference_text()
	scroll.add_child(content)
	
	return scroll


func _get_reference_text() -> String:
	return """[font_size=24][b]🎛️ SYNTH ELEMENT QUICK REFERENCE[/b][/font_size]

[font_size=18][b]🎸 BASS SYNTHESIZERS[/b][/font_size]

[b]TB-303 Acid Bass[/b]
The sound of acid house. Roland TB-303 (1982).
[color=#888888]Key params: cutoff, resonance, env_mod, decay, accent
18dB diode ladder filter. Accent boosts res + env. Slides create the "squelch".[/color]

[b]Minimoog Fat Bass[/b]
The fattest bass ever. Moog Minimoog (1970).
[color=#888888]Key params: osc detune, cutoff, resonance, saturation
3 oscillators, 24dB ladder filter, warm transistor saturation.[/color]

[b]Sub Bass (808)[/b]
Foundation of hip-hop. TR-808 extended kick.
[color=#888888]Key params: frequency, decay, saturation
Pure sine with pitch envelope. Long decay for boom.[/color]

[font_size=18][b]🥁 DRUM MACHINES[/b][/font_size]

[b]TR-909 Kick[/b]
The heartbeat of techno. Roland TR-909 (1984).
[color=#888888]Key params: tune, pitch_start, pitch_decay, attack_level, decay
Analog body + click transient. Pitch drops from ~150Hz to ~55Hz.[/color]

[b]TR-808 Kick[/b]
Deep boom of hip-hop. Roland TR-808 (1980).
[color=#888888]Key params: tune, decay, tone
Longer decay than 909. Less click, more sub.[/color]

[b]TR-909 Snare[/b]
Punchy hybrid snare.
[color=#888888]Key params: tune, tone, snappy
Two tone oscillators + sampled noise.[/color]

[b]TR-909 Hi-Hat[/b]
Metallic shimmer.
[color=#888888]Key params: decay, tone, metallic
6 square waves at non-harmonic ratios.[/color]

[font_size=18][b]🎹 PADS & STRINGS[/b][/font_size]

[b]Juno-106 Chorus Pad[/b]
Lush analog warmth. Roland Juno-106 (1984).
[color=#888888]Key params: waveform, pwm, chorus_mode
BBD (bucket brigade) chorus. Modes: I, II, I+II.[/color]

[b]JP-8000 Supersaw[/b]
The sound of trance. Roland JP-8000 (1996).
[color=#888888]Key params: voices, detune, mix
7 detuned sawtooths. Adjust center vs sides.[/color]

[font_size=18][b]🎺 LEADS[/b][/font_size]

[b]Hoover / Rave Stab[/b]
Vacuum cleaner of rave. Alpha Juno "What The" patch.
[color=#888888]Key params: detune, pwm, portamento, filter_env
Detuned oscillators + PWM + filter sweep.[/color]

[b]DX7 Electric Piano[/b]
The 80s sound. Yamaha DX7 (1983).
[color=#888888]Key params: mod_ratio, mod_index, brightness
FM synthesis. Modulator controls brightness.[/color]

[font_size=18][b]🔧 EFFECTS[/b][/font_size]

[b]Filter Types[/b]
[color=#888888]- 12dB (2-pole): Subtle, musical
- 18dB (3-pole): TB-303 character  
- 24dB (4-pole): Moog ladder, fat[/color]

[b]Distortion Types[/b]
[color=#888888]- Tube: Warm, even harmonics
- Transistor: Harder clipping
- Diode: 303-style asymmetric
- Bitcrush: Digital grit[/color]

[font_size=18][b]🎯 PRO TIPS[/b][/font_size]

[b]Acid Lines[/b]
• Accent + Slide + Octave Jump = Maximum Squelch
• Slides INTO accented notes for hypnotic pull
• Filter envelope depth > cutoff for screaming leads

[b]Fat Bass[/b]
• Detune oscillators 2-5 cents for width
• Sub oscillator (one octave down) for weight
• Light saturation glues oscillators together

[b]Drums[/b]
• 909 punch comes from fast pitch envelope
• 808 boom needs long decay + low tune
• Hi-hat metallic comes from non-harmonic ratios

[b]Pads[/b]
• Chorus adds width without mud
• Slow attack (500ms+) for evolving texture
• PWM adds movement without modulation

"""


func _create_about_panel() -> Control:
	var scroll = ScrollContainer.new()
	
	var content = RichTextLabel.new()
	content.bbcode_enabled = true
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.text = """[font_size=24][b]🔊 AdaResearch Synth Lab[/b][/font_size]

Deep synthesis research and sound design tools for AdaResearch.

[font_size=18][b]Purpose[/b][/font_size]
This tool focuses on [b]authentic recreation[/b] of classic synthesizer circuits and drum machines. Each element is researched from original circuit schematics and documented behavior.

[font_size=18][b]Elements Included[/b][/font_size]
[b]Bass:[/b] TB-303, Minimoog, 808 Sub Bass
[b]Drums:[/b] TR-909 Kick/Snare/HiHat, TR-808 Kick/Clap
[b]Pads:[/b] Juno-106 Chorus, JP-8000 Supersaw
[b]Leads:[/b] Hoover/Rave Stab, DX7 FM Piano
[b]FX:[/b] Filters, Chorus, Distortion

[font_size=18][b]Technical Notes[/b][/font_size]
• All synthesis is procedural (no samples)
• Filters accurately model original topologies
• Parameters map to real circuit behavior
• See [code]SYNTH_ELEMENTS.md[/code] for deep technical reference

[font_size=18][b]Related Files[/b][/font_size]
• [code]commons/audio/documentation/SYNTH_ELEMENTS.md[/code] - Technical reference
• [code]commons/audio/catalog/SynthElementBrowser.gd[/code] - This tool
• [code]commons/audio/generators/AudioSynthesizer.gd[/code] - Full generator

[font_size=18][b]Credits[/b][/font_size]
Built for AdaResearch educational platform.
Research based on Sound On Sound "Synth Secrets" series and original manufacturer documentation.

"""
	scroll.add_child(content)
	
	return scroll
