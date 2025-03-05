class_name PlayerStats
extends Resource

@export var money: int
@export var stamina: int
@export var max_stamina: int
@export var inventory: Inventory = Inventory.new()
@export var equipment: Equipment = Equipment.new()
var breakdown_knowledge = {} # Dictionary[ItemType, Array[ItemType]]
