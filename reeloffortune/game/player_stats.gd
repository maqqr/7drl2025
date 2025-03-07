class_name PlayerStats
extends Resource

@export var _money: int
@export var _stamina: int
@export var _max_stamina: int
@export var inventory: Inventory = Inventory.new()
@export var equipment: Equipment = Equipment.new()
var breakdown_knowledge = {} # Dictionary[ItemType, Array[ItemType]]
var legendary_caught: bool = false

signal stats_changed

var stamina: int:
	get:
		return _stamina
	set(value):
		var old = _stamina
		_stamina = clamp(value, 0.0, _max_stamina)
		if old != _stamina:
			stats_changed.emit()

var max_stamina: int:
	get:
		return _max_stamina
	set(value):
		var old = _max_stamina
		_max_stamina = value
		if old != _max_stamina:
			stats_changed.emit()

var money: int:
	get:
		return _money
	set(value):
		var old = _money
		_money = max(0, value)
		if old != _money:
			stats_changed.emit()
