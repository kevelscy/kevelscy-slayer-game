#!/usr/bin/env python3
"""Builds the game's sound effects with SoundCraft CLI (soundcraft-cli on PATH).

Every sound is a recipe of instrument tracks (built-in SoundCraft synths) and MIDI notes
timed in milliseconds. For each recipe this writes the SoundCraft command script
`<id>.txt` and session `<id>.scraft` next to this file, then bounces the session and
converts it to `../sfx/<id>.wav` (44.1 kHz, 16-bit, peak-normalized).

Usage: build_sfx.py [id ...]   (no ids builds every sound)
"""

import array
import json
import os
import subprocess
import sys
import tempfile
import wave

HERE = os.path.dirname(os.path.abspath(__file__))
SFX_DIR = os.path.join(HERE, "..", "sfx")
SAMPLE_RATE = 44100
# SoundCraft MIDI runs at 960 ticks per quarter note; at 120 BPM one ms is 1.92 ticks.
TICKS_PER_MS = 1.92
# Linear fade at the end of every WAV so a tail cut by the sound's length never clicks.
FADE_OUT_MS = 10

# Drum Synth keys (General MIDI).
KICK, SNARE, HAT, OPEN_HAT, TOM, CRASH = 36, 38, 42, 46, 45, 49
# Subtractive Synth waveforms (osc1_wave / osc2_wave).
SAW, SQUARE, SINE, TRIANGLE = 0, 1, 2, 3
# EQ 1-Band filter types.
LOW_PASS, BAND_PASS = 4, 6


def track(instrument, notes, params=None, inserts=None, volume_db=0.0):
    """notes: [(pitch, start_ms, length_ms, velocity)]; inserts: [(plugin, {param: value})]."""
    return {
        "instrument": instrument,
        "notes": notes,
        "params": params or {},
        "inserts": inserts or [],
        "volume_db": volume_db,
    }


# Short percussive envelope for the subtractive synth: no sustain, quick release.
def pluck(decay_ms, release_ms=30.0, **extra):
    params = {"amp_attack": 1, "amp_decay": decay_ms, "amp_sustain": 0, "amp_release": release_ms}
    params.update(extra)
    return params


SOUNDS = {
    # Sword hit: bright short snare crack over a small thump and a hat tick.
    "hit": {
        "length_ms": 120,
        "tracks": [
            track(
                "drum_synth",
                [(SNARE, 0, 60, 120), (KICK, 0, 60, 90), (HAT, 0, 40, 100)],
                {"snare_tune": 7, "snare_snappy": 85, "snare_decay": 70, "kick_tune": 12, "kick_decay": 60, "hat_decay": 40},
            ),
        ],
    },
    # Critical hit: heavier kick + snare with a short crash, a high square "ting" on top.
    "crit": {
        "length_ms": 300,
        "tracks": [
            track(
                "drum_synth",
                [(KICK, 0, 120, 127), (SNARE, 0, 120, 127), (CRASH, 0, 200, 80)],
                {"kick_tune": 5, "kick_decay": 150, "snare_tune": 3, "snare_snappy": 90, "snare_decay": 160, "cymbal_decay": 250},
                [("saturator", {"drive": 12, "mix": 60})],
            ),
            track(
                "subtractive_synth",
                [(96, 20, 120, 110)],
                pluck(150, osc1_wave=SQUARE, osc2_wave=SQUARE, osc2_semitones=12, osc2_detune=0, cutoff=8000, resonance=0, filter_env_amount=0),
                [("plate_reverb", {"mix": 15, "decay": 0.6})],
                volume_db=-6,
            ),
        ],
    },
    # Coin: classic two-note square bling (B5 then E6).
    "coin": {
        "length_ms": 250,
        "tracks": [
            track(
                "subtractive_synth",
                [(83, 0, 70, 110), (88, 70, 150, 110)],
                pluck(200, osc1_wave=SQUARE, osc2_wave=SQUARE, osc2_detune=0, cutoff=9000, resonance=0, filter_env_amount=0),
            ),
        ],
    },
    # Spirit attack: soft rising triangle blip with a touch of plate.
    "spirit": {
        "length_ms": 150,
        "tracks": [
            track(
                "subtractive_synth",
                [(76, 0, 40, 100), (88, 30, 90, 100)],
                pluck(110, release_ms=20, osc1_wave=TRIANGLE, osc2_wave=SINE, osc2_semitones=12, osc2_detune=0, glide=50, cutoff=6000, resonance=10, filter_env_amount=0),
                [("plate_reverb", {"mix": 20, "decay": 0.4})],
            ),
        ],
    },
    # Thunder (Trueno): saturated noise crack, then a low-passed rumble of kick, tom and crash.
    "thunder": {
        "length_ms": 600,
        "tracks": [
            track(
                "drum_synth",
                [(SNARE, 0, 150, 127), (HAT, 0, 60, 127)],
                {"snare_tune": -4, "snare_snappy": 100, "snare_decay": 180, "hat_decay": 60},
                [("saturator", {"drive": 20, "mix": 80})],
            ),
            track(
                "drum_synth",
                [(KICK, 30, 500, 127), (TOM, 70, 450, 110), (CRASH, 20, 550, 120)],
                {"kick_tune": -12, "kick_decay": 600, "tom_tune": -12, "tom_decay": 500, "cymbal_decay": 700},
                [("eq_1band", {"type": LOW_PASS, "freq": 450, "q": 0.7}), ("room_reverb", {"mix": 30, "decay": 1.2, "size": 80})],
                volume_db=3,
            ),
        ],
    },
    # Meteor (Meteoro): resonant saw whistle gliding down, then a saturated explosion.
    "meteor": {
        "length_ms": 800,
        "tracks": [
            track(
                "subtractive_synth",
                [(84, 0, 330, 100), (45, 300, 80, 100)],
                {"osc1_wave": SAW, "osc2_wave": SAW, "osc2_detune": 20, "glide": 300, "cutoff": 2500, "resonance": 45,
                 "filter_env_amount": 0, "amp_attack": 20, "amp_decay": 400, "amp_sustain": 70, "amp_release": 40, "level": 6},
                volume_db=2,
            ),
            track(
                "drum_synth",
                [(KICK, 370, 400, 127), (SNARE, 370, 300, 127), (CRASH, 370, 420, 110)],
                {"kick_tune": -10, "kick_decay": 450, "snare_tune": -8, "snare_snappy": 100, "snare_decay": 350, "cymbal_decay": 600},
                [("saturator", {"drive": 22, "mix": 70}), ("room_reverb", {"mix": 25, "decay": 1.0, "size": 70})],
                volume_db=-6,
            ),
        ],
    },
    # Blizzard (Ventisca): band-passed swirling noise wind under falling-ice triangle tinkles.
    "blizzard": {
        "length_ms": 700,
        "tracks": [
            track(
                "drum_synth",
                [(OPEN_HAT, 0, 650, 110), (CRASH, 60, 600, 90)],
                {"open_hat_decay": 700, "cymbal_decay": 700},
                [("eq_1band", {"type": BAND_PASS, "freq": 1800, "q": 0.8}), ("phaser", {"rate": 3, "depth": 80, "feedback": 50, "mix": 60})],
            ),
            track(
                "subtractive_synth",
                [(98, 40, 90, 100), (103, 170, 90, 90), (100, 300, 90, 85), (105, 430, 120, 80)],
                pluck(130, osc1_wave=TRIANGLE, osc2_wave=SINE, osc2_semitones=12, osc2_detune=0, cutoff=10000, resonance=0, filter_env_amount=0),
                [("plate_reverb", {"mix": 35, "decay": 1.0})],
                volume_db=-8,
            ),
        ],
    },
    # Wind (Viento): a short band-passed noise whoosh rising through a phaser, then a bright sword shing.
    "wind": {
        "length_ms": 400,
        "tracks": [
            track(
                "drum_synth",
                [(OPEN_HAT, 0, 260, 120)],
                {"open_hat_decay": 280},
                [("eq_1band", {"type": BAND_PASS, "freq": 2600, "q": 1.2}), ("phaser", {"rate": 6, "depth": 90, "feedback": 40, "mix": 70})],
            ),
            track(
                "subtractive_synth",
                [(100, 150, 60, 110), (107, 170, 140, 90)],
                pluck(160, osc1_wave=TRIANGLE, osc2_wave=SAW, osc2_semitones=12, osc2_detune=8, cutoff=9000, resonance=20, filter_env_amount=0),
                [("plate_reverb", {"mix": 25, "decay": 0.6})],
                volume_db=-10,
            ),
        ],
    },
    # Fury (Furia): detuned saw growl rising a fifth through a resonant filter, with a punch.
    "fury": {
        "length_ms": 500,
        "tracks": [
            track(
                "subtractive_synth",
                [(40, 0, 130, 120), (47, 110, 330, 120)],
                {"osc1_wave": SAW, "osc2_wave": SAW, "osc2_detune": 25, "glide": 150, "cutoff": 900, "resonance": 55,
                 "filter_env_amount": 60, "filter_attack": 120, "filter_decay": 300, "filter_sustain": 30,
                 "amp_attack": 5, "amp_decay": 400, "amp_sustain": 60, "amp_release": 50},
                [("saturator", {"drive": 20, "mix": 70})],
                volume_db=-4,
            ),
            track(
                "drum_synth",
                [(KICK, 0, 250, 127), (SNARE, 0, 150, 90)],
                {"kick_tune": -4, "kick_decay": 250, "snare_snappy": 60, "snare_decay": 150},
            ),
        ],
    },
    # Shield (Escudo): bright rising major arpeggio (C5 E5 G5 C6) shimmering through chorus and plate.
    "shield": {
        "length_ms": 500,
        "tracks": [
            track(
                "subtractive_synth",
                [(72, 0, 380, 100), (76, 50, 330, 100), (79, 100, 280, 100), (84, 150, 230, 110)],
                {"osc1_wave": TRIANGLE, "osc2_wave": SINE, "osc2_semitones": 12, "osc2_detune": 0, "cutoff": 7000,
                 "resonance": 0, "filter_env_amount": 0, "amp_attack": 8, "amp_decay": 350, "amp_sustain": 20, "amp_release": 80},
                [("chorus", {"rate": 1.5, "depth": 40, "mix": 40}), ("plate_reverb", {"mix": 35, "decay": 1.2})],
            ),
        ],
    },
    # Upgrade bought: quick rising square arpeggio (G5 C6 E6 G6), a classic power-up.
    "upgrade": {
        "length_ms": 350,
        "tracks": [
            track(
                "subtractive_synth",
                [(79, 0, 60, 100), (84, 60, 60, 105), (88, 120, 60, 110), (91, 180, 150, 115)],
                pluck(140, osc1_wave=SQUARE, osc2_wave=SQUARE, osc2_semitones=12, osc2_detune=0, osc_mix=30, cutoff=8000, resonance=0, filter_env_amount=0),
                [("plate_reverb", {"mix": 15, "decay": 0.5})],
            ),
        ],
    },
    # UI tap: a dry closed-hat tick over a tiny sine blip.
    "ui_tap": {
        "length_ms": 60,
        "tracks": [
            track("drum_synth", [(HAT, 0, 30, 90)], {"hat_decay": 25}),
            track(
                "subtractive_synth",
                [(84, 0, 25, 90)],
                pluck(30, release_ms=10, osc1_wave=SINE, osc2_wave=SINE, osc2_detune=0, cutoff=8000, resonance=0, filter_env_amount=0),
                volume_db=-4,
            ),
        ],
    },
    # Boss appears: low detuned saw stab (C2 + F#2 tritone) over a rolling low tom.
    "boss_start": {
        "length_ms": 1000,
        "tracks": [
            track(
                "subtractive_synth",
                [(36, 0, 850, 120), (42, 0, 850, 110)],
                {"osc1_wave": SAW, "osc2_wave": SAW, "osc2_detune": 18, "cutoff": 500, "resonance": 40,
                 "filter_env_amount": 50, "filter_attack": 200, "filter_decay": 600, "filter_sustain": 20,
                 "amp_attack": 10, "amp_decay": 900, "amp_sustain": 50, "amp_release": 120},
                [("saturator", {"drive": 14, "mix": 60}), ("room_reverb", {"mix": 25, "decay": 1.5, "size": 85})],
                volume_db=-2,
            ),
            track(
                "drum_synth",
                [(TOM, 0, 120, 120), (TOM, 120, 120, 100), (TOM, 240, 120, 110), (KICK, 360, 500, 127)],
                {"tom_tune": -10, "tom_decay": 250, "kick_tune": -10, "kick_decay": 600},
            ),
        ],
    },
    # Boss defeated: square fanfare G4 C5 E5 then a held G5 over a C major bed, with a crash.
    "boss_defeat": {
        "length_ms": 1200,
        "tracks": [
            track(
                "subtractive_synth",
                [(67, 0, 110, 110), (72, 120, 110, 110), (76, 240, 110, 115), (79, 360, 700, 120)],
                {"osc1_wave": SQUARE, "osc2_wave": SAW, "osc2_detune": 8, "osc_mix": 40, "cutoff": 5000, "resonance": 0,
                 "filter_env_amount": 0, "amp_attack": 5, "amp_decay": 500, "amp_sustain": 60, "amp_release": 150},
                [("plate_reverb", {"mix": 25, "decay": 1.2})],
            ),
            track(
                "subtractive_synth",
                [(48, 360, 700, 90), (55, 360, 700, 85), (64, 360, 700, 85)],
                {"osc1_wave": TRIANGLE, "osc2_wave": SAW, "osc2_detune": 10, "osc_mix": 30, "cutoff": 2500, "resonance": 0,
                 "filter_env_amount": 0, "amp_attack": 20, "amp_decay": 600, "amp_sustain": 60, "amp_release": 150},
                volume_db=-6,
            ),
            track("drum_synth", [(CRASH, 360, 700, 100), (KICK, 360, 200, 110)], {"cymbal_decay": 1200, "kick_decay": 200}, volume_db=-4),
        ],
    },
    # Hero dies: sad descending triangle line (E4 C4 A3) gliding into a low thud.
    "hero_death": {
        "length_ms": 800,
        "tracks": [
            track(
                "subtractive_synth",
                [(64, 0, 180, 110), (60, 170, 180, 105), (57, 340, 380, 100)],
                {"osc1_wave": TRIANGLE, "osc2_wave": SQUARE, "osc2_semitones": -12, "osc2_detune": 0, "osc_mix": 30, "glide": 60,
                 "cutoff": 2500, "resonance": 10, "filter_env_amount": 0, "amp_attack": 5, "amp_decay": 600,
                 "amp_sustain": 50, "amp_release": 80},
                [("plate_reverb", {"mix": 25, "decay": 1.0})],
            ),
            track("drum_synth", [(KICK, 340, 300, 110)], {"kick_tune": -12, "kick_decay": 300}, volume_db=-4),
        ],
    },
    # Ascension: shimmering rising C major arpeggio to a wide held chord, crash and a long plate.
    "ascension": {
        "length_ms": 1500,
        "tracks": [
            track(
                "subtractive_synth",
                [(60, 0, 1200, 90), (64, 90, 1110, 90), (67, 180, 1020, 95), (72, 270, 930, 100), (76, 360, 840, 100), (79, 450, 750, 105), (84, 540, 660, 110)],
                {"osc1_wave": TRIANGLE, "osc2_wave": SINE, "osc2_semitones": 12, "osc2_detune": 0, "cutoff": 9000,
                 "resonance": 0, "filter_env_amount": 0, "amp_attack": 15, "amp_decay": 900, "amp_sustain": 50, "amp_release": 250},
                [("chorus", {"rate": 1.0, "depth": 50, "mix": 40}), ("plate_reverb", {"mix": 40, "decay": 2.5, "size": 90})],
            ),
            track(
                "drum_synth",
                [(CRASH, 540, 900, 90), (KICK, 540, 400, 110)],
                {"cymbal_decay": 2000, "kick_tune": -6, "kick_decay": 500},
                [("plate_reverb", {"mix": 30, "decay": 2.0})],
                volume_db=-8,
            ),
        ],
    },
}


def command_script(sound_id, recipe):
    length_samples = round(recipe["length_ms"] * SAMPLE_RATE / 1000)
    tracks = recipe["tracks"]
    lines = ["# %s: generated by build_sfx.py, do not edit by hand" % sound_id]

    def cmd(command_id, params):
        lines.append("%s %s" % (command_id, json.dumps(params)))

    cmd("session.new", {"name": sound_id, "sample_rate": SAMPLE_RATE})
    names = ["T%d" % (index + 1) for index in range(len(tracks))]
    for name, spec in zip(names, tracks):
        cmd("track.new", {"kind": "instrument", "name": name, "instrument": spec["instrument"]})
    # Tracks take ids 1..N, so the clips made after them take ids N+1..2N.
    for index, (name, spec) in enumerate(zip(names, tracks)):
        clip_id = len(tracks) + index + 1
        cmd("midi.new_clip", {"track": name, "start": 0, "length": length_samples})
        for pitch, start_ms, length_ms, velocity in spec["notes"]:
            cmd("midi.note_add", {
                "clip": clip_id,
                "pitch": pitch,
                "start_ticks": round(start_ms * TICKS_PER_MS),
                "length_ticks": round(length_ms * TICKS_PER_MS),
                "velocity": velocity,
            })
        for param, value in spec["params"].items():
            cmd("mix.instrument_param", {"track": name, "param": param, "value": value})
        for slot, (plugin, params) in enumerate(spec["inserts"]):
            cmd("mix.insert", {"track": name, "slot": slot, "plugin": plugin, "params": params})
        if spec["volume_db"] != 0.0:
            cmd("mix.volume", {"track": name, "db": spec["volume_db"]})
    return "\n".join(lines) + "\n"


def run(args):
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0 or "soundcraft-cli:" in result.stderr:
        sys.exit("build_sfx: %s failed:\n%s%s" % (args[1], result.stdout, result.stderr))


def fade_out(wav_path):
    with wave.open(wav_path, "rb") as source:
        wav_params = source.getparams()
        samples = array.array("h", source.readframes(wav_params.nframes))
    channels = wav_params.nchannels
    fade_frames = min(wav_params.nframes, round(FADE_OUT_MS * wav_params.framerate / 1000))
    first = wav_params.nframes - fade_frames
    for frame in range(first, wav_params.nframes):
        gain = (wav_params.nframes - 1 - frame) / max(fade_frames - 1, 1)
        for channel in range(channels):
            index = frame * channels + channel
            samples[index] = round(samples[index] * gain)
    with wave.open(wav_path, "wb") as target:
        target.setparams(wav_params)
        target.writeframes(samples.tobytes())


def build(sound_id):
    script_path = os.path.join(HERE, sound_id + ".txt")
    with open(script_path, "w") as script:
        script.write(command_script(sound_id, SOUNDS[sound_id]))
    os.makedirs(SFX_DIR, exist_ok=True)
    with tempfile.TemporaryDirectory() as scratch:
        mix_path = os.path.join(scratch, "mix.wav")
        run(["soundcraft-cli", "script", script_path, "--save", os.path.join(HERE, sound_id + ".scraft"), "--bounce", mix_path])
        wav_path = os.path.join(SFX_DIR, sound_id + ".wav")
        run(["soundcraft-cli", "convert", mix_path, wav_path, "--bit-depth", "16", "--normalize"])
        fade_out(wav_path)
    print("built", sound_id)


if __name__ == "__main__":
    ids = sys.argv[1:] or list(SOUNDS)
    unknown = [sound_id for sound_id in ids if sound_id not in SOUNDS]
    if unknown:
        sys.exit("build_sfx: unknown sound(s): %s" % ", ".join(unknown))
    for sound_id in ids:
        build(sound_id)
