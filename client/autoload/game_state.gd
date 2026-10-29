extends Node
## Owns the running GameSession. Phase 2 adds save/load and server-validated
## offline income here.

const STAGE_BALANCE: StageBalance = preload("res://data/content/balance/stage_balance.tres")

var session: GameSession = GameSession.new(STAGE_BALANCE)
