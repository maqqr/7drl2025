class_name InventoryControl
extends Control

@export var open: bool
var x_position: float
var y_open: float
var y_close: float

@onready var game_manager: GameManager = $"/root/Game"
@onready var panel_container: PanelContainer = $InventoryPanelContainer
@onready var crafting_control: CraftingControl = $"../CraftingControl"

func _ready() -> void:
	$Button.pressed.connect(toggle_inventory)
	x_position = position.x
	y_close = position.y
	assert(game_manager && crafting_control)
	game_manager.game_manager_ready.connect(on_game_manager_ready)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()

func on_game_manager_ready() -> void:
	panel_container.set_inventory(game_manager.player_stats.inventory)
	y_open = y_close - panel_container.custom_minimum_size.y

func toggle_inventory() -> void:
	open = !open
	var target_pos = Vector2(x_position, y_open) if open else Vector2(x_position, y_close)
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "position", target_pos, 0.3).set_ease(Tween.EASE_OUT)
	crafting_control.set_open(open)
