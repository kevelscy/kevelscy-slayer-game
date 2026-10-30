extends GutTest
## SfxPlayer: plays registered sounds on the SFX bus, skips replays inside a sound's
## minimum interval and caps how many copies of one sound overlap.

var player: SfxPlayer
var clock_msec: int = 1000


func _stream() -> AudioStreamWAV:
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 44100
	stream.data = PackedByteArray()
	stream.data.resize(4410 * 2)
	return stream


func before_each() -> void:
	clock_msec = 1000
	player = SfxPlayer.new()
	player.clock = func() -> int: return clock_msec
	add_child_autofree(player)
	player.register(&"hit", _stream(), 0.05, 3, -6.0)


func after_each() -> void:
	SfxPlayer.set_muted(false)


func test_set_muted_mutes_and_unmutes_the_sfx_bus() -> void:
	var bus: int = AudioServer.get_bus_index(SfxPlayer.BUS)
	SfxPlayer.set_muted(true)
	assert_true(AudioServer.is_bus_mute(bus))
	assert_true(SfxPlayer.is_muted())
	assert_false(AudioServer.is_bus_mute(0), "the master bus stays on")
	SfxPlayer.set_muted(false)
	assert_false(AudioServer.is_bus_mute(bus))
	assert_false(SfxPlayer.is_muted())


func test_sfx_bus_exists_in_the_default_layout() -> void:
	assert_ne(AudioServer.get_bus_index(SfxPlayer.BUS), -1, "the SFX bus is part of default_bus_layout.tres")
	assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(SfxPlayer.BUS)), &"Master")


func test_registered_sound_plays_on_the_sfx_bus_with_its_cap_and_volume() -> void:
	var stream_player: AudioStreamPlayer = player.stream_player(&"hit")
	assert_not_null(stream_player)
	assert_eq(stream_player.bus, SfxPlayer.BUS)
	assert_eq(stream_player.max_polyphony, 3)
	assert_almost_eq(stream_player.volume_db, -6.0, 0.001)
	watch_signals(player)
	assert_true(player.play(&"hit"))
	assert_signal_emitted_with_parameters(player, "played", [&"hit"])


func test_replay_inside_the_minimum_interval_is_skipped() -> void:
	watch_signals(player)
	assert_true(player.play(&"hit"))
	clock_msec += 49
	assert_false(player.play(&"hit"), "49 ms after the last play is inside the 50 ms interval")
	clock_msec += 1
	assert_true(player.play(&"hit"), "50 ms after the last play is allowed")
	assert_signal_emit_count(player, "played", 2)


func test_unknown_sound_is_an_error_and_plays_nothing() -> void:
	watch_signals(player)
	assert_false(player.play(&"nope"))
	assert_push_error("SfxPlayer: unknown sound 'nope'")
	assert_signal_not_emitted(player, "played")


func test_catalog_sounds_all_load_from_the_sfx_folder() -> void:
	var catalog_player: SfxPlayer = SfxPlayer.new()
	add_child_autofree(catalog_player)
	catalog_player.load_catalog()
	assert_eq(catalog_player.get_child_count(), SfxPlayer.SOUNDS.size(), "one stream player per catalog sound")
	for id: StringName in SfxPlayer.SOUNDS:
		var stream_player: AudioStreamPlayer = catalog_player.stream_player(id)
		assert_not_null(stream_player, "%s is registered" % id)
		if stream_player != null:
			assert_not_null(stream_player.stream, "%s has a stream" % id)
