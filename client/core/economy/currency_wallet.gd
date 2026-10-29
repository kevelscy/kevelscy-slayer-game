class_name CurrencyWallet
extends RefCounted
## Balances per currency (gold, gems, ...). Spending never leaves a negative balance.

signal changed(currency: StringName, total: BigNumber)

var _amounts: Dictionary[StringName, BigNumber] = {}


func get_amount(currency: StringName) -> BigNumber:
	return _amounts.get(currency, BigNumber.zero())


func add(currency: StringName, amount: BigNumber) -> void:
	if amount.is_negative():
		push_error("CurrencyWallet.add: negative amount %s for %s" % [amount.serialize(), currency])
		return
	_set_amount(currency, get_amount(currency).add(amount))


## Sets a balance directly, e.g. when loading a save; negative amounts are refused.
func restore(currency: StringName, amount: BigNumber) -> void:
	if amount.is_negative():
		push_error("CurrencyWallet.restore: negative amount %s for %s" % [amount.serialize(), currency])
		return
	_set_amount(currency, amount)


func can_afford(currency: StringName, amount: BigNumber) -> bool:
	return get_amount(currency).gte(amount)


## Spends only when affordable; returns whether the balance changed.
func try_spend(currency: StringName, amount: BigNumber) -> bool:
	if not can_afford(currency, amount):
		return false
	_set_amount(currency, get_amount(currency).sub(amount))
	return true


func to_dict() -> Dictionary[String, String]:
	var data: Dictionary[String, String] = {}
	for currency: StringName in _amounts:
		data[String(currency)] = _amounts[currency].serialize()
	return data


static func from_dict(data: Dictionary) -> CurrencyWallet:
	var wallet: CurrencyWallet = CurrencyWallet.new()
	for key: Variant in data:
		wallet._amounts[StringName(str(key))] = BigNumber.parse(str(data[key]))
	return wallet


func _set_amount(currency: StringName, total: BigNumber) -> void:
	_amounts[currency] = total
	changed.emit(currency, total)
