extends Control

@onready var music_control: VSlider = $Background/MusicControl
@onready var sfx_control: VSlider = $Background/SFXControl

func _ready():
	var music_bus = ensure_bus("Music")
	var sfx_bus = ensure_bus("SFX")
	music_control.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	sfx_control.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))
 
func ensure_bus(bus_name: String) -> int:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, bus_name)
		AudioServer.set_bus_volume_db(bus_idx, 0.0)  # Set to 0 dB (full volume)
		print("Created bus: ", bus_name, " at index: ", bus_idx)
	return bus_idx

func _on_sfx_control_value_changed(value: float) -> void:
	var sfx_bus = AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		var db_value = linear_to_db(value)
		AudioServer.set_bus_volume_db(sfx_bus, db_value)
		AudioServer.set_bus_mute(sfx_bus, value <= 0.01)


func _on_music_control_value_changed(value: float) -> void:
	var music_bus = AudioServer.get_bus_index("Music")
	if music_bus != -1:
		var db_value = linear_to_db(value)
		AudioServer.set_bus_volume_db(music_bus, db_value)
		AudioServer.set_bus_mute(music_bus, value <= 0.01)
