class_name SaveData
extends RefCounted
## Everything a local save keeps. Progress inside a stage (kills, boss timer) is
## intentionally not saved: loading restarts the saved stage.

var stage: int = 1
var gold: BigNumber = BigNumber.zero()
var attack_level: int = 0
var health_level: int = 0
var last_seen_unix: int = 0
