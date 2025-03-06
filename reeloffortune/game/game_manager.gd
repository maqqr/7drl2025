class_name GameManager
extends Node

const PICKUP_DIST_SQ = 2 * 2

var player: Character
var player_stats: PlayerStats
var message_buffer: MessageBuffer
var cursor: Node3D
var cursor_tile: Vector2i
@export var tooltip_label: Label

var characters: Array[Character] = []
var ground_items: Array[GroundItem] = []
var tilemap: GameTileMap
var actions = []
var item_types: Array[ItemType] = []
var fish_entries: Array[FishEntry] = []

var rod_node: Node3D

var stamina_drain_counter: int = 0

var allow_input: bool = true

signal game_manager_ready
signal fishing_started

const MOVE_KEYS: Dictionary[String, Vector2i] = {
	"right": Vector2i(1, 0),
	"left": Vector2i(-1, 0),
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
}

func _ready() -> void:
	cursor = $Cursor
	tooltip_label = $GUI/ToolTipLabel
	message_buffer = $GUI/MessageBuffer
	assert(cursor and tooltip_label and message_buffer)
	item_types = ItemType.load_all()
	fish_entries = FishEntry.load_all()

	player_stats = PlayerStats.new()
	player_stats.equipment.create_empty_slots()

	player_stats.inventory.size = Vector2i(3, 3)
	for item_t in item_types:
		if item_t.name == "Basic Rod":
			var initial_rod := Item.new()
			initial_rod.item_type = item_t
			initial_rod.quality = Item.Quality.TARNISHED
			player_stats.inventory.add_item(Vector2i(0, 0), initial_rod)
			break

	tilemap = GameTileMap.new()
	add_child(tilemap)
	generate_map()

	var p = tilemap.find_tile(Enum.TileType.FLOOR)
	player = add_character(p, preload("res://characters/player.tscn").instantiate())
	for i in 120:
		var random_type = item_types[randi_range(0, item_types.size() - 1)]
		if random_type.attributes.type_flag & ItemAttributes.TypeFlag.MATERIAL and !(random_type.attributes.type_flag & ItemAttributes.TypeFlag.FISH):
			create_ground_item_from_type(tilemap.find_tile(Enum.TileType.FLOOR), random_type)

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
	var item_at_cursor = get_item_at(cursor_tile)
	if item_at_cursor and cursor_tile.distance_squared_to(player.map_position) <= PICKUP_DIST_SQ:
		tooltip_label.visible = true
		tooltip_label.text = item_at_cursor.item.item_type.name
		tooltip_label.position = get_viewport().get_mouse_position()
	else:
		tooltip_label.visible = false

	# Listen to player input
	if actions.is_empty() and allow_input:
		for key_name in MOVE_KEYS:
			if Input.is_action_pressed(key_name):
				var direction = MOVE_KEYS[key_name]
				var old_position = player.map_position
				var final_position = player.map_position + direction
				if tilemap.is_walkable(final_position):
					player.map_position = final_position
					stamina_drain_counter += 1
					if stamina_drain_counter >= 3:
						stamina_drain_counter = 0
						player.set_stamina(player.stamina - 1)
				else:
					final_position = old_position
				actions.append(MoveAction.new(player, old_position, final_position, direction))
				break
			elif Input.is_action_just_pressed("pickup"):
				pick_up_ground_item(get_item_at(player.map_position))

	# Handle character idle animations
	for character in characters:
		if actions.all(func (a): return a.character != character):
			character.play_idle()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1 and allow_input:
			var item_at_cursor = get_item_at(cursor_tile)
			if item_at_cursor and cursor_tile.distance_squared_to(player.map_position) <= PICKUP_DIST_SQ:
				pick_up_ground_item(item_at_cursor)
				return
			if tilemap.get_tile(cursor_tile) == Enum.TileType.WATER:
				start_fishing()

func generate_map() -> void:
	var width = 50
	var height = 40
	var tile_data = CaveGenerator.generate(width, height)
	tilemap.set_tiles(width, height, tile_data)

func add_character(pos: Vector2i, character: Character) -> Character:
	add_child(character)
	characters.append(character)
	character.stamina = character.stats.max_stamina
	character.teleport_to(pos)
	return character

func create_ground_item_from_type(pos: Vector2i, item_type: ItemType, quality = Item.Quality.COMMON) -> GroundItem:
	var item = Item.new()
	item.item_type = item_type
	item.quality = quality
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

# Tries to add a non-inventory item to inventory, otherwise drops it to player's feet
func try_add_item(item: Item) -> void:
	var slot = player_stats.inventory.get_free_slot_for_item(item)
	if slot != Inventory.INVALID_SLOT:
		player_stats.inventory.add_item(slot, item)
	else:
		create_ground_item(player.map_position, item)

func set_player_unarmed(is_unarmed: bool) -> void:
	player.unarmed = is_unarmed
	if is_unarmed and rod_node:
		rod_node.free()
	elif !is_unarmed and !rod_node:
		rod_node = preload("res://models/rod_scene.tscn").instantiate()
		player.find_child("HandContainer").add_child(rod_node)

func pick_up_ground_item(ground_item: GroundItem) -> void:
	if !ground_item:
		return
	var slot = player_stats.inventory.get_free_slot_for_item(ground_item.item)
	if slot != Inventory.INVALID_SLOT:
		message_buffer.add_message(MessageBuffer.MSG_PICKUP.format({ "a": "an" if ground_item.item.item_type.an_article else "a", "item": ground_item.item.item_type.name }))
		player_stats.inventory.add_item(slot, ground_item.item)
		ground_items.erase(ground_item)
		ground_item.queue_free()

func start_fishing() -> void:
	var rod_strength = 1.0

	var current_rod = player_stats.equipment.slot[ItemAttributes.TypeFlag.ROD]
	if !current_rod:
		message_buffer.add_message(MessageBuffer.MSG_NO_ROD)
		return

	var current_bait = player_stats.equipment.slot[ItemAttributes.TypeFlag.BAIT]
	if !current_bait:
		message_buffer.add_message(MessageBuffer.MSG_NO_BAIT)
		return

	var potential_fish: Array[FishEntry] = []
	var weights = PackedFloat32Array()

	for fish_entry in fish_entries:
		var weight = 0.0
		if !fish_entry.attractions.is_empty():
			var w = FishEntry.attraction_match_count(fish_entry.attractions, current_bait.item_type.attributes) / float(fish_entry.attractions.size())
			weight += w * 5.0
		if !fish_entry.minor_attractions.is_empty():
			var count = FishEntry.attraction_match_count(fish_entry.minor_attractions, current_bait.item_type.attributes)
			weight += count

		if weight > 0.0:
			potential_fish.append(fish_entry)
			weights.append(weight)

	if potential_fish.is_empty():
		message_buffer.add_message(MessageBuffer.MSG_NO_BITE)

	# Spend the bait
	player_stats.equipment.set_item_to_slot(ItemAttributes.TypeFlag.BAIT, null)

	var rng = RandomNumberGenerator.new()
	var random_fish_entry = potential_fish[rng.rand_weighted(weights)]

	var minigame = preload("res://ui/fishing_control.tscn").instantiate()
	$GUI.add_child(minigame)
	minigame.setup(rod_strength, random_fish_entry)
	fishing_started.emit()
	allow_input = false
	var success = await minigame.fishing_ended
	allow_input = true
	if success:
		message_buffer.add_message(MessageBuffer.MSG_CATCH.format({ "fish": random_fish_entry.item_type.name }))
		var quality_table = [Item.Quality.COMMON, Item.Quality.FINE, Item.Quality.PREMIUM]
		var quality_weights = [3.0, 2.0, 1.0]
		create_ground_item_from_type(player.map_position, random_fish_entry.item_type, )
	else:
		message_buffer.add_message(MessageBuffer.MSG_CATCH_FAIL)
