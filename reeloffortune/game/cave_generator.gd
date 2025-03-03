# Random cave generator using cellular automata
class_name CaveGenerator

class Map:
	var width: int
	var height: int
	var tiles: PackedInt32Array
	var rng: RandomNumberGenerator
	
	func _init(width: int, height: int, rng: RandomNumberGenerator):
		self.width = width
		self.height = height
		self.rng = rng
		tiles.resize(width * height)
		tiles.fill(Enum.TileType.WALL)
	
	func get_tile(pos: Vector2i) -> Enum.TileType:
		if pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height:
			return tiles[pos.x + pos.y * width] as Enum.TileType
		return Enum.TileType.WALL

	func set_tile(pos: Vector2i, tile: Enum.TileType):
		assert(pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < width)
		tiles[pos.x + pos.y * width] = tile as int

	func count_nearby(position: Vector2i, radius: int, tile_type: Enum.TileType) -> int:
		var total = 0
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if dx == 0 and dy == 0:
					continue
				if get_tile(position + Vector2i(dx, dy)) == tile_type:
					total += 1
		return total

	func random_fill(wall_probability: float) -> void:
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				self.set_tile(Vector2i(x, y), Enum.TileType.WALL if rng.randf() < wall_probability else Enum.TileType.FLOOR)

	func iterate(previous_map: Map, wall_rule: Callable) -> void:
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				var tile_position = Vector2i(x, y)
				var make_wall: bool = wall_rule.call(tile_position, previous_map)
				set_tile(tile_position, Enum.TileType.WALL if make_wall else Enum.TileType.FLOOR)

static func _iterate(iterations: int, map: Map, previous_map: Map, rule: Callable):
	for i in iterations:
		map.iterate(previous_map, rule)
		#map.put_walls_at_borders()
		# Re-use previous map by swapping it
		var temp = map
		map = previous_map
		previous_map = temp

static func generate(width: int, height: int) -> PackedInt32Array:
	var rng: = RandomNumberGenerator.new()
	var initial_map: = Map.new(width, height, rng)
	initial_map.random_fill(0.45)

	# Cellular automata rules
	var rule1 = func(pos: Vector2i, old: Map):
		return old.count_nearby(pos, 1, Enum.TileType.WALL) >= 5 or old.count_nearby(pos, 2, Enum.TileType.WALL) <= 2
	var rule2 = func(pos: Vector2i, old: Map):
		return old.count_nearby(pos, 1, Enum.TileType.WALL) >= 5

	var previous_map: Map = initial_map
	var new_map = Map.new(width, height, rng)
	_iterate(4, new_map, previous_map, rule1)
	_iterate(2, new_map, previous_map, rule2)

	# Add water to empty areas
	previous_map.tiles = new_map.tiles.duplicate()
	for y in new_map.height:
		for x in new_map.width:
			var pos = Vector2i(x, y)
			if previous_map.count_nearby(pos, 3, Enum.TileType.WALL) <= 2:
				new_map.set_tile(pos, Enum.TileType.WATER)

	return new_map.tiles
