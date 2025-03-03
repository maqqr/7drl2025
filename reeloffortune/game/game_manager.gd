class_name GameManager
extends Node

var player: Character
var player_stats: PlayerStats
var cursor: Node3D
var cursor_tile: Vector2i

var characters: Array[Character] = []
var ground_items: Array[GroundItem] = []
var tilemap: GameTileMap
var actions = []
var item_types: Array[ItemType] = []

signal game_manager_ready

const MOVE_KEYS: Dictionary[String, Vector2i] = {
	"ui_right": Vector2i(1, 0),
	"ui_left": Vector2i(-1, 0),
	"ui_up": Vector2i(0, -1),
	"ui_down": Vector2i(0, 1),
}

func _ready() -> void:
	cursor = $Cursor
	assert(cursor)
	item_types = ItemType.load_all()
	player_stats = PlayerStats.new()

	player_stats.inventory.size = Vector2i(3, 3)

	tilemap = GameTileMap.new()
	add_child(tilemap)
	generate_map()

	var p = tilemap.find_tile(Enum.TileType.FLOOR)
	player = add_character(p, preload("res://characters/player.tscn").instantiate())
	create_ground_item_from_type(p, item_types[0])
	create_ground_item_from_type(p + Vector2i(0, 1), item_types[1])
	create_ground_item_from_type(p + Vector2i(1, 1), item_types[2])
	game_manager_ready.emit()

func _process(delta: float) -> void:
	# Execute character actions
	for i in range(actions.size() - 1, -1, -1):
		if actions[i].execute(delta):
			actions.remove_at(i)

	# Camera
	get_viewport().get_camera_3d().global_position = player.global_position + Vector3(0.0, 7.0, 5.5)

	# Update cursor
	cursor_tile = get_mouse_tile()
	cursor.global_position = GameTileMap.to_scene_pos(cursor_tile)

	# Listen to player input
	if actions.is_empty():
		for key_name in MOVE_KEYS:
			if Input.is_action_pressed(key_name):
				var direction = MOVE_KEYS[key_name]
				var old_position = player.map_position
				var final_position = player.map_position + direction
				if tilemap.is_walkable(final_position):
					player.map_position = final_position
				else:
					final_position = old_position
				actions.append(MoveAction.new(player, old_position, final_position, direction))
				break
			elif Input.is_key_pressed(KEY_G):
				var ground_item = get_item_at(player.map_position)
				if ground_item:
					var slot = player_stats.inventory.get_free_slot_for_item(ground_item.item)
					if slot != Inventory.INVALID_SLOT:
						player_stats.inventory.add_item(slot, ground_item.item)
						ground_items.erase(ground_item)
						ground_item.queue_free()

	# Handle character idle animations
	for character in characters:
		if actions.all(func (a): return a.character != character):
			character.play_idle()

func generate_map() -> void:
	var width = 50
	var height = 40
	var tile_data = CaveGenerator.generate(width, height)
	tilemap.set_tiles(width, height, tile_data)

func add_character(pos: Vector2i, character: Character) -> Character:
	add_child(character)
	characters.append(character)
	character.health = character.stats.max_health
	character.teleport_to(pos)
	return character

func create_ground_item_from_type(pos: Vector2i, item_type: ItemType) -> GroundItem:
	var item = Item.new()
	item.item_type = item_type
	item.quality = Item.Quality.COMMON
	return create_ground_item(pos, item)

func create_ground_item(pos: Vector2i, item: Item) -> GroundItem:
	var ground_item: GroundItem = preload("res://inventory/ground_item.tscn").instantiate()
	ground_item.item = item
	ground_item.map_position = pos

	ground_items.append(ground_item)
	add_child(ground_item)
	return ground_item

func get_mouse_tile() -> Vector2i:
	var camera = get_viewport().get_camera_3d()
	
	var mouse_pos = get_viewport().get_mouse_position()
	var origin = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	if direction.y == 0.0:
		return Vector2i.ZERO
	var distance = -origin.y / direction.y
	var pos = origin + direction * distance
	return GameTileMap.to_tile_pos(pos)

func get_item_at(pos: Vector2i) -> GroundItem:
	for ground_item in ground_items:
		if ground_item.map_position == pos:
			return ground_item
	return null
