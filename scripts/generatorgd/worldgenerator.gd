extends Node2D # Наследуем от Node2D для работы с 2D графикой

# Экспорт текстур шума для настройки через редактор
@export var noise_height_text:NoiseTexture2D # Шум высоты для рельефа - определяет высоту местности
@export var noise_tree_text:NoiseTexture2D # Шум для деревьев - определяет где будут расти деревья  
@export var noise_temp_text:NoiseTexture2D # Шум температуры - влияет на тип биома
@export var noise_moisture_text:NoiseTexture2D # Шум влажности - влияет на тип биома
@export var noise_settlement_text:NoiseTexture2D # Шум для поселений

# Сцена поселения и игрока
@export var village_scene:PackedScene
@onready var player = get_tree().get_root().get_node("Game/Player") # Получаем ссылку на игрока

# Настройки размещения поселений
const VILLAGE_MIN_DISTANCE = 50 # Уменьшаем минимальное расстояние между деревнями
const VILLAGE_SIZE = 80 # Уменьшаем размер деревни
const VILLAGE_BORDER = 20 # Уменьшаем отступ от края карты
const WATER_SAFE_DISTANCE = 5 # Уменьшаем безопасное расстояние от воды
const MAX_GENERATION_ATTEMPTS = 5 # Максимальное количество попыток генерации мира

enum Biome {OCEAN, BEACH, TUNDRA, FOREST, PLAINS, DESERT}
enum SettlementType {VILLAGE}

# Настройки шумов
var noise:Noise # Шум для генерации высоты
var tree_noise:Noise # Шум для генерации деревьев
var temp_noise:Noise # Шум для температуры
var moisture_noise:Noise # Шум для влажности
var settlement_noise:Noise # Шум для поселений

# Размеры карты
var width:int=512 # Увеличиваем размер карты для больших деревень
var height:int=512 # Увеличиваем размер карты для больших деревень

# Тайлы
var water_atlas=Vector2i(0,2) # Координаты тайла воды
var grass_tiles_arr=[] # Массив для тайлов травы
var terrain_grass_int=0 # Индекс текущего тайла травы
var grass_atlas_arr=[Vector2i(1,1),Vector2i(5,1),Vector2i(5,0),Vector2i(5,2)]

var thread: Thread

var cell_map:Array = []
var settlements:Array = []

# Структура для хранения информации о поселении
class Settlement:
	var type: int
	var position: Vector2i
	var scene: Node2D
	
	func _init(t: int, pos: Vector2i, s: Node2D):
		type = t
		position = pos
		scene = s

func _ready() -> void:
	var world_generated = false
	var attempts = 0
	
	while !world_generated:
		attempts += 1
		print("Попытка генерации мира #", attempts)
		
		# Очистка предыдущей генерации
		for settlement in settlements:
			if is_instance_valid(settlement.scene):
				settlement.scene.queue_free()
		settlements.clear()
		cell_map.clear()
		
		# Настройка шумов с новым сидом
		setup_noise()
		
		# Инициализация карты биомов
		cell_map.resize(width)
		for x in width:
			cell_map[x] = []
			cell_map[x].resize(height)
		
		# Генерируем мир
		generate_world_data()
		generate_river_data()
		place_settlements()
		
		# Проверяем успешность генерации
		if settlements.size() > 0:
			world_generated = true
			print("Мир успешно сгенерирован с", settlements.size(), "деревней")
			
			# Перемещаем игрока в первую безопасную деревню
			var safe_settlement = find_safe_settlement()
			if safe_settlement != null:
				if player:
					player.position = Vector2(safe_settlement.position.x * 32, safe_settlement.position.y * 32)
					player.add_to_group("player")
					print("Игрок перемещен в безопасную деревню: ", player.position)
				else:
					print("ВНИМАНИЕ: Игрок не найден в сцене!")
		else:
			print("Попытка генерации не удалась - нет деревень. Пробуем снова...")
			# Очищаем тайлмапы
			$water.clear()
			$terrain.clear()
			$grass.clear()
			$plants.clear()
			
			# Если превысили лимит попыток, создаем принудительно безопасную зону для деревни
			if attempts >= MAX_GENERATION_ATTEMPTS:
				print("Превышен лимит попыток, создаем принудительно безопасную зону...")
				force_create_safe_zone()
				place_settlements()
				if settlements.size() > 0:
					world_generated = true
					print("Мир успешно сгенерирован с принудительной деревней")
					if player:
						player.position = Vector2(settlements[0].position.x * 32, settlements[0].position.y * 32)
						player.add_to_group("player")
				else:
					# Сбрасываем счетчик попыток и пробуем заново
					attempts = 0
					print("Не удалось создать деревню даже в безопасной зоне. Начинаем новый цикл генерации...")

# Функция принудительного создания безопасной зоны для деревни
func force_create_safe_zone() -> void:
	# Выбираем центр карты для гарантированной деревни
	var center_x = width / 2
	var center_y = height / 2
	
	# Создаем безопасную зону для деревни
	for x in range(center_x - VILLAGE_SIZE - WATER_SAFE_DISTANCE, center_x + VILLAGE_SIZE + WATER_SAFE_DISTANCE):
		for y in range(center_y - VILLAGE_SIZE - WATER_SAFE_DISTANCE, center_y + VILLAGE_SIZE + WATER_SAFE_DISTANCE):
			if x >= 0 and x < width and y >= 0 and y < height:
				# Устанавливаем равнину в области деревни
				cell_map[x][y] = Biome.PLAINS
				# Очищаем старые тайлы
				$water.erase_cell(Vector2i(x,y))
				$terrain.erase_cell(Vector2i(x,y))
				$plants.erase_cell(Vector2i(x,y))
				# Устанавливаем тайл травы
				$grass.set_cell(Vector2i(x,y), 0, grass_atlas_arr.pick_random())

# Функция поиска безопасной деревни для спавна
func find_safe_settlement() -> Settlement:
	for settlement in settlements:
		var pos = settlement.position
		# Проверяем область вокруг деревни на наличие воды
		var is_safe = true
		for x in range(pos.x - 1, pos.x + 2):
			for y in range(pos.y - 1, pos.y + 2):
				if x >= 0 and x < width and y >= 0 and y < height:
					if cell_map[x][y] == Biome.OCEAN:
						is_safe = false
						break
			if not is_safe:
				break
		if is_safe:
			return settlement
	return null

func setup_noise() -> void:
	# Настройка шума высот
	noise = noise_height_text.noise
	noise.seed = randi() # Случайное зерно
	noise.frequency = 0.005 # Уменьшаем частоту для более плавного рельефа
	
	# Настройка шума деревьев
	tree_noise = noise_tree_text.noise 
	tree_noise.seed = randi()
	tree_noise.frequency = 0.1
	
	# Настройка шума температуры
	temp_noise = noise_temp_text.noise
	temp_noise.seed = randi()
	temp_noise.frequency = 0.005
	
	# Настройка шума влажности
	moisture_noise = noise_moisture_text.noise
	moisture_noise.seed = randi()
	moisture_noise.frequency = 0.005
	
	# Настройка шума поселений
	settlement_noise = noise_settlement_text.noise
	settlement_noise.seed = randi()
	settlement_noise.frequency = 0.01

func get_biome(elevation:float, temp:float, moisture:float) -> int:
	if elevation < -0.3: # Увеличиваем порог для океана
		return Biome.OCEAN
	if elevation < -0.2: # Увеличиваем порог для пляжа
		return Biome.BEACH
		
	if temp < -0.2:
		return Biome.TUNDRA
	elif moisture > 0:
		return Biome.FOREST
	elif moisture < -0.5:
		return Biome.DESERT
	else: # Увеличиваем шанс появления равнин
		return Biome.PLAINS

func generate_world_data() -> void:
	var plains_count = 0 # Счетчик равнин для отладки
	
	for x in width:
		for y in height:
			# Получаем значения шума для каждой координаты
			var height_val:float = noise.get_noise_2d(x,y)
			var temp_val:float = temp_noise.get_noise_2d(x,y)
			var moisture_val:float = moisture_noise.get_noise_2d(x,y)
			var tree_val:float = tree_noise.get_noise_2d(x,y)
			
			# Определяем биом
			var biome = get_biome(height_val, temp_val, moisture_val)
			cell_map[x][y] = biome
			
			if biome == Biome.PLAINS:
				plains_count += 1
			
			# Сразу отрисовываем тайлы
			if biome == Biome.OCEAN:
				$water.set_cell(Vector2i(x,y), 0, water_atlas)
			else:
				match biome:
					Biome.BEACH:
						$terrain.set_cell(Vector2i(x,y), 0, Vector2i(0,4))
					Biome.TUNDRA:
						$terrain.set_cell(Vector2i(x,y), 0, Vector2i(3,4))
					Biome.FOREST:
						$grass.set_cell(Vector2i(x,y), 0, grass_atlas_arr.pick_random())
						if tree_val > 0.4:
							$plants.set_cell(Vector2i(x,y), 1, Vector2i(0,2))
					Biome.PLAINS:
						$grass.set_cell(Vector2i(x,y), 0, grass_atlas_arr.pick_random())
					Biome.DESERT:
						$terrain.set_cell(Vector2i(x,y), 0, Vector2i(1,3))
	
	print("Количество равнин на карте: ", plains_count)

func generate_river_data() -> void:
	var start_points = []
	
	# Находим начальные точки рек
	for x in width:
		for y in height:
			if cell_map[x][y] == Biome.TUNDRA:
				start_points.append(Vector2i(x,y))
	
	# Генерируем реки (уменьшаем их количество)
	for start_point in start_points:
		if randf() < 0.01: # Еще сильнее уменьшаем количество рек
			var river_points = create_river_path(start_point)
			for river_point in river_points:
				$terrain.erase_cell(river_point)
				$grass.erase_cell(river_point)
				$plants.erase_cell(river_point)
				$water.set_cell(river_point, 0, water_atlas)
				cell_map[river_point.x][river_point.y] = Biome.OCEAN

func create_river_path(start: Vector2i) -> Array:
	var current = start
	var river = [current]
	
	while !is_ocean(current):
		var next = find_lowest_neighbor(current)
		if next == current:
			break
		river.append(next)
		current = next
		
	return river

func is_ocean(pos:Vector2i) -> bool:
	return cell_map[pos.x][pos.y] == Biome.OCEAN

func find_lowest_neighbor(pos:Vector2i) -> Vector2i:
	var lowest = pos
	var lowest_elevation = noise.get_noise_2d(pos.x, pos.y)
	
	var neighbors = [
		Vector2i(pos.x-1, pos.y),
		Vector2i(pos.x+1, pos.y), 
		Vector2i(pos.x, pos.y-1),
		Vector2i(pos.x, pos.y+1)
	]
	
	for n in neighbors:
		if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height:
			var elevation = noise.get_noise_2d(n.x, n.y)
			if elevation < lowest_elevation:
				lowest = n
				lowest_elevation = elevation
				
	return lowest

func place_settlements():
	var suitable_locations = find_suitable_locations()
	print("Найдено подходящих мест для деревень: ", suitable_locations.size())
	
	# Размещаем деревни (уменьшаем до 1)
	var village_count = 1 # Ограничиваем количество деревень
	for i in village_count:
		var pos = find_best_location(suitable_locations, SettlementType.VILLAGE)
		if pos != Vector2i.ZERO:
			spawn_settlement(village_scene, pos, SettlementType.VILLAGE)
			print("Создана деревня #", i+1, " в позиции: ", pos)
		else:
			print("Не удалось найти место для деревни #", i+1)

func find_suitable_locations() -> Array:
	var locations = []
	# Учитываем размер деревни и отступы от края
	for x in range(VILLAGE_BORDER, width - VILLAGE_BORDER - VILLAGE_SIZE):
		for y in range(VILLAGE_BORDER, height - VILLAGE_BORDER - VILLAGE_SIZE):
			if is_suitable_for_settlement(Vector2i(x,y)):
				locations.append(Vector2i(x,y))
	return locations

func is_suitable_for_settlement(pos: Vector2i) -> bool:
	# Проверяем область под деревню и безопасную зону вокруг
	for x in range(pos.x - WATER_SAFE_DISTANCE, pos.x + VILLAGE_SIZE + WATER_SAFE_DISTANCE):
		for y in range(pos.y - WATER_SAFE_DISTANCE, pos.y + VILLAGE_SIZE + WATER_SAFE_DISTANCE):
			if x < 0 or x >= width or y < 0 or y >= height:
				return false
			# Проверяем саму область деревни
			if x >= pos.x and x < pos.x + VILLAGE_SIZE and y >= pos.y and y < pos.y + VILLAGE_SIZE:
				if cell_map[x][y] != Biome.PLAINS and cell_map[x][y] != Biome.FOREST: # Разрешаем строить в лесу
					return false
			# Проверяем наличие воды в безопасной зоне
			elif cell_map[x][y] == Biome.OCEAN:
				return false
	
	return true

func find_best_location(locations: Array, settlement_type: int) -> Vector2i:
	var min_distance = VILLAGE_MIN_DISTANCE
	var best_pos = Vector2i.ZERO
	var best_score = -1
	
	for pos in locations:
		var score = calculate_location_score(pos)
		if score > best_score:
			var suitable = true
			for settlement in settlements:
				if pos.distance_to(settlement.position) < min_distance:
					suitable = false
					break
			if suitable:
				best_pos = pos
				best_score = score
				
	return best_pos

func calculate_location_score(pos: Vector2i) -> float:
	var score = 0.0
	
	# Учитываем расстояние до центра карты
	var center_dist = pos.distance_to(Vector2i(width/2.0, height/2.0))
	score -= center_dist * 0.1
	
	# Учитываем близость к воде (но не слишком близко)
	var water_dist = find_distance_to_water(pos)
	if water_dist < WATER_SAFE_DISTANCE:
		score -= 1000 # Сильный штраф за близость к воде
	elif water_dist < 20:
		score += (20 - water_dist)
		
	# Учитываем тип местности
	if cell_map[pos.x][pos.y] == Biome.PLAINS:
		score += 20 # Увеличиваем бонус за равнины
	elif cell_map[pos.x][pos.y] == Biome.FOREST:
		score += 10 # Добавляем бонус за лес
		
	return score

func find_distance_to_water(pos: Vector2i) -> int:
	var distance = 999
	for x in range(max(0, pos.x - 20), min(width, pos.x + 21)):
		for y in range(max(0, pos.y - 20), min(height, pos.y + 21)):
			if cell_map[x][y] == Biome.OCEAN:
				distance = min(distance, pos.distance_to(Vector2i(x,y)))
	return distance

func spawn_settlement(scene: PackedScene, pos: Vector2i, type: int) -> void:
	if scene == null:
		print("ОШИБКА: village_scene не установлена!")
		return
		
	var settlement_instance = scene.instantiate()
	if settlement_instance == null:
		print("ОШИБКА: Не удалось создать экземпляр деревни!")
		return
		
	settlement_instance.position = Vector2(pos.x * 32, pos.y * 32)
	# Добавляем игрока в группу для доступа врагам
	if player:
		player.add_to_group("player")
	add_child(settlement_instance)
	
	var settlement = Settlement.new(type, pos, settlement_instance)
	settlements.append(settlement)
	print("Деревня успешно создана в позиции: ", pos)

func _process(_delta:float)->void:
	pass
