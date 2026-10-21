extends Node
## One-shot SFX player (autoload name: Sfx). Master-bus volume is user-controlled.

const PATH_ARROW := "res://audio/sfx_arrow.wav"
const PATH_HIRE := "res://audio/sfx_hire.wav"
const PATH_HIT := "res://audio/sfx_kingdom_hit.wav"
const PATH_WAVE := "res://audio/sfx_wave.wav"

var _arrow: AudioStream
var _hire: AudioStream
var _kingdom_hit: AudioStream
var _wave: AudioStream
var _players: Array[AudioStreamPlayer] = []
## 0.0 … 1.0 linear volume for Master bus.
var _volume_linear: float = 1.0


func _ready() -> void:
	_arrow = _load_stream(PATH_ARROW)
	_hire = _load_stream(PATH_HIRE)
	_kingdom_hit = _load_stream(PATH_HIT)
	_wave = _load_stream(PATH_WAVE)
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_apply_bus_volume()


func get_volume_linear() -> float:
	return _volume_linear


func get_volume_percent() -> float:
	return _volume_linear * 100.0


func set_volume_percent(percent: float) -> void:
	set_volume_linear(percent / 100.0)


func set_volume_linear(value: float) -> void:
	_volume_linear = clampf(value, 0.0, 1.0)
	_apply_bus_volume()


func _apply_bus_volume() -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		return
	if _volume_linear <= 0.0001:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(_volume_linear))


func play_arrow() -> void:
	_play(_arrow, -4.0)


func play_hire() -> void:
	_play(_hire, -2.0)


func play_kingdom_hit() -> void:
	_play(_kingdom_hit, -1.0)


func play_wave() -> void:
	_play(_wave, -1.5)


func _load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		if stream != null:
			return stream
	if FileAccess.file_exists(path):
		var stream2 := load(path) as AudioStream
		if stream2 != null:
			return stream2
	push_warning("Sfx: missing audio %s" % path)
	return null


func _play(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null or _players.is_empty():
		return
	var player := _free_player()
	player.stream = stream
	player.volume_db = volume_db
	player.play()


func _free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]
