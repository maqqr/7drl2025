class_name Breakable
extends Node3D

@export var breakable_name: String
@export var drop_chance: float = 1.0
@export var drop_table: Array[ItemType]

var map_position: Vector2i
