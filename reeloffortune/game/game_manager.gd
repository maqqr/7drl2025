class_name GameManager
extends Node

const INITIAL_STAMINA = 50
const PICKUP_DIST_SQ = 2 * 2
const FISH_DIST_SQ = 1.5 * 1.5

var player: Character
var player_stats: PlayerStats
var depth: int
var message_buffer: MessageBuffer
var shop_control: ShopControl
var cursor: Node3D
var cursor_tile: Vector2i
@export var tooltip_label: Label

@export var cursor_material: StandardMaterial3D
@export var cursor_highlight_material: StandardMaterial3D

var characters: Array[Character] = []
var ground_items: Array[GroundItem] = []
var breakables: Array[Breakable] = []
var tilemap: GameTileMap
var actions = []
var item_types: Array[ItemType] = []
var fish_entries: Array[FishEntry] = []

var rod_node: Node3D

var stamina_drain_counter: int = 0

enum InputMode {
	NONE,
	ONLY_DRAG,
	ALLOWED,
}

var allow_input_mode: InputMode = InputMode.ALLOWED

signal game_manager_ready
signal fishing_started

const MOVE_KEYS: Dictionary[String, Vector2i] = {
	"right": Vector2i(1, 0),
	"left": Vector2i(-1, 0),
	"up": Vector2i(0, -1),
	"down": Vector2i(0, 1),
}

const BREAKABLE_PREFABS = [
	preload("res://breakable/glowing_mushroom.tscn"),
	preload("res://breakable/stalagmite.tscn"),
]

const RANDOM_ITEMS_PER_FLOOR = [
	20,
	10,
	8,
	5,
]

func _ready() -> void:
	cursor = $Cursor
	tooltip_label = $GUI/ToolTipLabel
	message_buffer = $GUI/MessageBuffer
	shop_control = $GUI/ShopControl
	assert(cursor and tooltip_label and message_buffer and shop_control)
	item_types = ItemType.load_all()
	fish_entries = FishEntry.load_all()

	# Legendary fish is always known at start
	for fish_entry in fish_entries:
		if fish_entry.item_type.is_legendary_fish:
			fish_entry.is_known = true

	player_stats = PlayerStats.new()
	player_stats.equipment.create_empty_slots()
	player_stats._max_stamina = 50
	player_stats._stamina = player_stats._max_stamina
	depth = 1

	shop_control.set_shop_visible(false)

	player_stats.inventory.size = Vector2i(3, 3)

	tilemap = GameTileMap.new()
	add_child(tilemap)
	generate_map()

	var p = tilemap.find_tile(Enum.TileType.FLOOR)
	player = add_character(p, preload("res://characters/player.tscn").instantiate())

	# TODO: remove
	#var d = tilemap.find_tile(Enum.TileType.DOWNSTAIRS)
	#player.teleport_to(d + Vector2i(1, 0))

	#for i in item_types:
		#if i.is_legendary_fish:
			#create_ground_item_from_type(player.map_position + Vector2i(1, 1), i, Item.Quality.LEGENDARY)
#
	#create_ground_item_from_type(player.map_position + Vector2i(0, 1), get_item_type_by_name("Common Rod"), Item.Quality.COMMON)
	#create_ground_item_from_type(player.map_position + Vector2i(0, -1), get_item_type_by_name("Fine Rod"), Item.Quality.FINE)
	#create_ground_item_from_type(player.map_position + Vector2i(-1, -1), get_item_type_by_name("Premium Rod"), Item.Quality.PREMIUM)

	#for f in fish_entries:
		#f.is_known = true

	#player_stats._money = 1000

	MusicManager.play_music(MusicManager.Music.GAME)

	player_stats.stats_changed.connect(on_stats_changed)
	game_manager_ready.emit()

	var initial_rod := Item.new()
	initial_rod.item_type = get_item_type_by_name("Basic Rod")
	initial_rod.quality = Item.Quality.TARNISHED
	player_stats.inventory.add_item(Vector2i(0, 0), initial_rod)
	
	var initial_boots := Item.new()
	initial_boots.item_type = get_item_type_by_name("Soggy Boots")
	initial_boots.quality = Item.Quality.TARNISHED
	player_stats.equipment.set_item_to_slot(ItemAttributes.TypeFlag.BOOTS, initial_boots)

func enter_next_floor():
	# Remove all characters except player
	characters.erase(player)
	for c in characters:
		c.queue_free()
	characters.clear()
	characters.append(player)

	# Remove ground items
	for ground_item in ground_items:
		ground_item.queue_free()
	ground_items.clear()

	# Remove breakables
	for breakable in breakables:
		breakable.queue_free()
	breakables.clear()

	depth += 1

	tilemap.free()
	tilemap = GameTileMap.new()
	add_child(tilemap)
	generate_map()
	player.teleport_to(find_free_tile(Enum.TileType.FLOOR))

	$GUI/StatusPanelContainer.update_labels()
	MusicManager.play_music(MusicManager.Music.GAME)

func _process(delta: float) -> void:
	# Execute character actions
	for i in range(actions.size() - 1, -1, -1):
		if actions[i].execute(self, delta):
			actions.remove_at(i)

			if tilemap.get_tile(player.map_position) == Enum.TileType.DOWNSTAIRS:
				$GUI/CraftingControl.set_open(false)
				$GUI/InventoryControl.set_inventory_open(true)
				shop_control.set_shop_visible(true)
				allow_input_mode = InputMode.ONLY_DRAG
				await shop_control.continue_pressed
				allow_input_mode = InputMode.ALLOWED
				shop_control.set_shop_visible(false)
				$GUI/InventoryControl.set_inventory_open(false)
				enter_next_floor()

	# Camera
	get_viewport().get_camera_3d().global_position = player.global_position + Vector3(0.0, 7.0, 5.5)

	# Update cursor
	var highlight = false
	if allow_input_mode != InputMode.NONE:
		cursor_tile = get_mouse_tile()
		cursor.global_position = GameTileMap.to_scene_pos(cursor_tile)
		var item_at_cursor = get_item_at(cursor_tile)
		if item_at_cursor and cursor_tile.distance_squared_to(player.map_position) <= PICKUP_DIST_SQ:
			tooltip_label.visible = true
			tooltip_label.text = item_at_cursor.item.item_type.name
			tooltip_label.set("theme_override_colors/font_color", Item.quality_color(item_at_cursor.item.quality))
			tooltip_label.position = get_viewport().get_mouse_position()
			highlight = true
		else:
			tooltip_label.visible = false
	else:
		cursor.global_position = Vector3(1000, 0, 0)

	if cursor_tile.distance_squared_to(player.map_position) <= FISH_DIST_SQ:
		if tilemap.get_tile(cursor_tile) == Enum.TileType.WATER:
			highlight = true

	set_cursor_material(cursor_highlight_material if highlight else cursor_material)

	# Listen to player input
	if actions.is_empty() and allow_input_mode == InputMode.ALLOWED:
		for key_name in MOVE_KEYS:
			if Input.is_action_pressed(key_name):
				var direction = MOVE_KEYS[key_name]
				var old_position = player.map_position
				var final_position = player.map_position + direction
				var breakable = get_breakable_at(final_position)
				if breakable:
					var cost = 1
					if player_stats.stamina > cost:
						var break_action = BreakAction.new(player, old_position, final_position, direction, breakable)
						break_action.break_signal.connect(func (): player_stats.stamina -= cost; destroy_breakable(breakable))
						actions.append(break_action)
					else:
						if Input.is_action_just_pressed(key_name):
							message_buffer.add_message(MessageBuffer.MSG_NO_STAMINA)
				else:
					if tilemap.is_walkable(final_position):
						player.map_position = final_position
						stamina_drain_counter += 1
						if stamina_drain_counter >= player_stats.get_steps_per_stamina_drain():
							stamina_drain_counter = 0
							if !player_stats.equipment.slot[ItemAttributes.TypeFlag.BOOTS]:
								message_buffer.add_message(MessageBuffer.MSG_FLOOR_HURT)
							player_stats.stamina -= 1
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
		if event.pressed and event.button_index == 1 and allow_input_mode == InputMode.ALLOWED:
			var item_at_cursor = get_item_at(cursor_tile)
			if item_at_cursor and cursor_tile.distance_squared_to(player.map_position) <= PICKUP_DIST_SQ:
				pick_up_ground_item(item_at_cursor)
				return
			if tilemap.get_tile(cursor_tile) == Enum.TileType.WATER:
				if cursor_tile.distance_squared_to(player.map_position) <= FISH_DIST_SQ:
					if player_stats.stamina > 1:
						start_fishing()
					else:
						message_buffer.add_message(MessageBuffer.MSG_NO_STAMINA)

func generate_map() -> void:
	var width = 40
	var height = 30
	var tile_data = CaveGenerator.generate(width, height)
	tilemap.set_tiles(width, height, tile_data)

	var random_item_types = [get_item_type_by_name("Cave Slug"), get_item_type_by_name("Cave Moss")]
	for i in RANDOM_ITEMS_PER_FLOOR[min(RANDOM_ITEMS_PER_FLOOR.size() - 1, depth - 1)]:
		var pos = find_free_tile(Enum.TileType.FLOOR)
		create_ground_item_from_type(pos, random_item_types[randi_range(0, random_item_types.size() - 1)])

	# Generate breakables
	for i in 20:
		var potential = []
		for b in BREAKABLE_PREFABS:
			potential.append(b)

		if depth >= 3:
			potential.append(preload("res://breakable/crystal.tscn"))

		var node = potential[randi_range(0, potential.size() - 1)].instantiate()
		var pos = find_free_tile(Enum.TileType.FLOOR)
		add_child(node)
		node.map_position = pos
		node.global_position = tilemap.to_scene_pos(pos)
		breakables.append(node)

func add_character(pos: Vector2i, character: Character) -> Character:
	add_child(character)
	characters.append(character)
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

func get_breakable_at(pos: Vector2i) -> Breakable:
	for breakable in breakables:
		if breakable.map_position == pos:
			return breakable
	return null

func get_item_at(pos: Vector2i) -> GroundItem:
	for ground_item in ground_items:
		if ground_item.map_position == pos:
			return ground_item
	return null

func get_item_type_by_name(name: String) -> ItemType:
	for item_type in item_types:
		if item_type.name == name:
			return item_type
	assert(false)
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
	else:
		message_buffer.add_message(MessageBuffer.MSG_NO_INV_SPACE)

func destroy_breakable(breakable: Breakable):
	if randf() <= breakable.drop_chance:
		create_ground_item_from_type(breakable.map_position, breakable.drop_table[randi_range(0, breakable.drop_table.size() - 1)])
	breakables.erase(breakable)
	breakable.queue_free()

func start_fishing() -> void:
	var current_rod = player_stats.equipment.slot[ItemAttributes.TypeFlag.ROD]
	if !current_rod:
		message_buffer.add_message(MessageBuffer.MSG_NO_ROD)
		return

	var rod_strength = Item.quality_multiplier(current_rod.quality)

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

		# Check depth
		if depth < fish_entry.min_depth:
			continue

		# Check bait size
		if current_bait.item_type.attributes.size > fish_entry.get_max_bait_size():
			continue

		# Prevent catching another legendary
		if player_stats.legendary_caught and fish_entry.item_type.is_legendary_fish:
			continue

		# Legendary must have at least two matching attractions
		if fish_entry.item_type.is_legendary_fish and FishEntry.attraction_match_count(fish_entry.attractions, current_bait.item_type.attributes) < 2:
			continue

		if weight > 0.0:
			potential_fish.append(fish_entry)
			weights.append(weight)

	if potential_fish.is_empty():
		message_buffer.add_message(MessageBuffer.MSG_NO_BITE)
		return

	player_stats.stamina -= 1

	print("Potential fish: " + ", ".join(PackedStringArray(potential_fish.map(func (f): return f.item_type.name))))

	var rng = RandomNumberGenerator.new()
	var random_fish_entry = potential_fish[rng.rand_weighted(weights)]

	allow_input_mode = InputMode.NONE
	await get_tree().create_timer(1).timeout

	var minigame = preload("res://ui/fishing_control.tscn").instantiate()
	$GUI.add_child(minigame)
	minigame.setup(rod_strength, random_fish_entry)
	fishing_started.emit()

	var success = await minigame.fishing_ended

	# Spend the bait
	var bait_gone = false
	if randf() < current_bait.get_bait_spend_chance():
		player_stats.equipment.set_item_to_slot(ItemAttributes.TypeFlag.BAIT, null)
		bait_gone = true
	else:
		current_bait.bait_uses_left -= 1

	await get_tree().create_timer(0.5).timeout

	allow_input_mode = InputMode.ALLOWED
	if success:
		message_buffer.add_message(MessageBuffer.MSG_CATCH.format({ "fish": random_fish_entry.item_type.name }))
		var was_not_known = random_fish_entry.is_known
		random_fish_entry.is_known = true
		if was_not_known != random_fish_entry.is_known:
			message_buffer.add_message(MessageBuffer.MSG_NEW_JOURNAL.format({ "fish": random_fish_entry.item_type.name }))
		if bait_gone:
			message_buffer.add_message(MessageBuffer.MSG_BAIT_GONE)
		var quality_table = [Item.Quality.COMMON, Item.Quality.FINE, Item.Quality.PREMIUM]
		var quality_weights = [3.0, 2.0, 1.0]
		var random_quality = quality_table[rng.rand_weighted(quality_weights)]
		# Force quality to legendary for legendary fish
		if random_fish_entry.item_type.is_legendary_fish:
			random_quality = Item.Quality.LEGENDARY
			player_stats.legendary_caught = true
		create_ground_item_from_type(player.map_position, random_fish_entry.item_type, random_quality)
	else:
		message_buffer.add_message(MessageBuffer.MSG_CATCH_FAIL)

func on_stats_changed() -> void:
	if player_stats.stamina == 0:
		get_tree().change_scene_to_file("res://menu/losemenu.tscn")

func set_cursor_material(mat: StandardMaterial3D) -> void:
	for child in cursor.get_children():
		if child is MeshInstance3D:
			child.material_override = mat

func find_free_tile(tile_type: Enum.TileType) -> Vector2i:
	var p: Vector2i
	while true:
		p = tilemap.find_tile(tile_type)
		var found_character = false
		for c in characters:
			if c.map_position == p:
				found_character = true
				break
		if found_character:
			continue
		var found_item = false
		for ground_item in ground_items:
			if ground_item.map_position == p:
				found_item = true
				break
		if found_item:
			continue
		var found_breakable = false
		for b in breakables:
			if b.map_position == p:
				found_breakable = true
				break
		if found_breakable:
			continue
		break
	return p
