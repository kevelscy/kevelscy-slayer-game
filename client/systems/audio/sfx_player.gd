class_name SfxPlayer
extends Node
## Plays the game's sound effects on the SFX bus. Each sound owns one AudioStreamPlayer
## whose polyphony caps how many copies overlap, and a replay inside the sound's minimum
## interval is skipped so frequent events never stack into noise.

signal played(id: StringName)

const BUS: StringName = &"SFX"
const SFX_DIR: String = "res://audio/sfx/"
## id -> [minimum interval in seconds, polyphony, volume in dB, random pitch (1.0 = none)].
## Every id has a WAV named after it in SFX_DIR, built by audio/source/build_sfx.py.
const SOUNDS: Dictionary[StringName, Array] = {
	&"hit": [0.06, 4, -13.0, 1.12],
	&"crit": [0.08, 2, -9.0, 1.05],
	&"coin": [0.08, 3, -15.0, 1.0],
	&"spirit": [0.1, 2, -17.0, 1.1],
	&"thunder": [0.2, 1, -11.0, 1.0],
	&"meteor": [0.2, 1, -14.0, 1.0],
	&"blizzard": [0.2, 1, -12.0, 1.0],
	&"fury": [0.2, 1, -15.0, 1.0],
	&"shield": [0.2, 1, -12.0, 1.0],
	&"upgrade": [0.05, 2, -13.0, 1.0],
	&"ui_tap": [0.05, 1, -17.0, 1.0],
	&"boss_start": [0.5, 1, -11.0, 1.0],
	&"boss_defeat": [0.5, 1, -11.0, 1.0],
	&"hero_death": [0.5, 1, -11.0, 1.0],
	&"ascension": [0.5, 1, -12.0, 1.0],
}

## Milliseconds clock, replaceable in tests.
var clock: Callable = Time.get_ticks_msec

var _players: Dictionary[StringName, AudioStreamPlayer] = {}
var _intervals_msec: Dictionary[StringName, int] = {}
var _last_played_msec: Dictionary[StringName, int] = {}


## Registers every sound of SOUNDS from its WAV in SFX_DIR.
func load_catalog() -> void:
	for id: StringName in SOUNDS:
		var spec: Array = SOUNDS[id]
		var stream: AudioStream = load(SFX_DIR + String(id) + ".wav") as AudioStream
		if stream == null:
			push_error("SfxPlayer: missing sound file for '%s'" % id)
			continue
		var random_pitch: float = float(spec[3])
		if random_pitch > 1.0:
			var randomizer: AudioStreamRandomizer = AudioStreamRandomizer.new()
			randomizer.add_stream(-1, stream)
			randomizer.random_pitch = random_pitch
			stream = randomizer
		register(id, stream, float(spec[0]), int(spec[1]), float(spec[2]))


func register(id: StringName, stream: AudioStream, min_interval: float, polyphony: int, volume_db: float) -> void:
	var stream_player: AudioStreamPlayer = _players.get(id) as AudioStreamPlayer
	if stream_player == null:
		stream_player = AudioStreamPlayer.new()
		stream_player.name = String(id)
		add_child(stream_player)
		_players[id] = stream_player
	stream_player.stream = stream
	stream_player.bus = BUS
	stream_player.max_polyphony = polyphony
	stream_player.volume_db = volume_db
	_intervals_msec[id] = roundi(min_interval * 1000.0)
	_last_played_msec.erase(id)


## Mutes or unmutes the whole SFX bus (the master bus is untouched).
static func set_muted(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS), muted)


static func is_muted() -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(BUS))


func stream_player(id: StringName) -> AudioStreamPlayer:
	return _players.get(id) as AudioStreamPlayer


## Plays the sound unless it played less than its minimum interval ago. Returns whether it played.
func play(id: StringName) -> bool:
	var stream_player: AudioStreamPlayer = _players.get(id) as AudioStreamPlayer
	if stream_player == null:
		push_error("SfxPlayer: unknown sound '%s'" % id)
		return false
	var now: int = clock.call()
	if _last_played_msec.has(id) and now - _last_played_msec[id] < _intervals_msec[id]:
		return false
	_last_played_msec[id] = now
	stream_player.play()
	played.emit(id)
	return true
