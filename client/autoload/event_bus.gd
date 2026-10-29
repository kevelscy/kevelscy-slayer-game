extends Node
## Cross-system signals only. Events local to one entity stay as that entity's signals.

@warning_ignore("unused_signal")
signal enemy_killed(was_boss: bool)
@warning_ignore("unused_signal")
signal hero_died
