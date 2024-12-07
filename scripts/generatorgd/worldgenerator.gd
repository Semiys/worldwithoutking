extends Node2D # Наследуем от Node2D для работы с 2D графикой

# Экспорт текстур шума для настройки через редактор
@export var noise_height_text:NoiseTexture2D # Шум высоты для рельефа - определяет высоту местности
@export var noise_tree_text:NoiseTexture2D # Шум для деревьев - определяет где будут расти деревья  
@export var noise_temp_text:NoiseTexture2D # Шум температуры - влияет на тип биома
@export var noise_moisture_text:NoiseTexture2D # Шум влажности - влияет на тип биома
@export var noise_settlement_text:NoiseTexture2D # Шум для поселений
@export var grave_scene:PackedScene # Сцена надгробия

# Сцена поселения и игрока
@export var village_scene:PackedScene
@export var village_middle_scene:PackedScene # Добавляем экспорт сцены средней деревни
@onready var player = get_tree().get_root().get_node("Game/Player") # Получаем ссылк�� на игрока
@onready var camera = get_tree().get_root().get_node("Game/Player/Camera2D") # Получаем ссылку на камеру

# Настройки размещения поселений
const VILLAGE_MIN_DISTANCE = 100 # Расстояние между деревнями

# Размеры маленькой деревни
const SMALL_VILLAGE_WIDTH = 38 
const SMALL_VILLAGE_HEIGHT = 35 

# Размеры средней деревни
const MIDDLE_VILLAGE_WIDTH = 50  # Увеличенная ширина для средней деревни
const MIDDLE_VILLAGE_HEIGHT = 35 # Увеличенная высота для средней деревни

const VILLAGE_BORDER = 20 # Отступ от края карты
const WATER_SAFE_DISTANCE = 30 # Безопасное расстояние от воды
const TREE_SAFE_DISTANCE = 30 # Безопасное расстояние от деревьев
const MAX_GENERATION_ATTEMPTS = 20 # Максималное количество попыток генерации мира
const WATER_BORDER_WIDTH = 32 # Ширина водной границы в тайлах

# Размеры области надгробия
const GRAVE_AREA_WIDTH = 5
const GRAVE_AREA_HEIGHT = 5

# В начале фала добавим константу для количества надгробий
const GRAVES_PER_AREA = 50  # Количество надгробий на карту

enum Biome {OCEAN, BEACH, TUNDRA, FOREST, PLAINS, DESERT}
enum SettlementType {VILLAGE, GRAVE}

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
# Массив тайлов для пустыни
var desert_atlas_arr=[
	Vector2i(2,6), # Обычный песок
	Vector2i(3,6), # Песок с какт��сом
	Vector2i(0,4)  # Песок с камнями
]

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
		
		# Полная очистка предыдущей генерации
		clear_previous_generation()
		
		# Настройка шумов с новым сидом
		setup_noise()
		
		# Генерируем мир
		generate_world_data()
		generate_water_borders()
		
		# Пытаемся разместить деревни
		if place_settlements():
			world_generated = true
			setup_camera_and_player()
		else:
			print("Начинаем новую попытку генерации...")
			await get_tree().create_timer(0.1).timeout # Небольшая задержка между попытками

func clear_previous_generation() -> void:
	# Очищаем поселения
	for settlement in settlements:
		if is_instance_valid(settlement.scene):
			settlement.scene.queue_free()
	settlements.clear()
	
	# Очищаем карту и тайлмапы
	cell_map.clear()
	cell_map.resize(width)
	for x in width:
		cell_map[x] = []
		cell_map[x].resize(height)
		
	$water.clear()
	$terrain.clear()
	$grass.clear()
	$plants.clear()

func place_settlements() -> bool:
	# Пытаемся разместить маленькую деревню
	var small_locations = find_suitable_locations(village_scene)
	print("Найдено подходящих мест для маленькой деревни: ", small_locations.size())
	
	if small_locations.is_empty():
		print("Не удалось найти место для маленькой деревни")
		return false
		
	var small_pos = small_locations.pick_random()
	spawn_settlement(village_scene, small_pos, SettlementType.VILLAGE, SMALL_VILLAGE_WIDTH, SMALL_VILLAGE_HEIGHT)
	print("Создана маленькая деревня в позиции: ", small_pos)
	
	# Пытаемся разместить среднюю деревню
	var middle_locations = find_suitable_locations(village_middle_scene)
	print("Найдено подходящих мест для средней деревни: ", middle_locations.size())
	
	if middle_locations.is_empty():
		print("Не удалось найти место для средней деревни")
		return false
		
	var middle_pos = middle_locations.pick_random()
	spawn_settlement(village_middle_scene, middle_pos, SettlementType.VILLAGE, MIDDLE_VILLAGE_WIDTH, MIDDLE_VILLAGE_HEIGHT)
	print("Создана средняя деревня в позиции: ", middle_pos)
	
	# Размещаем надгробия
	place_graves()
	
	return true

func find_suitable_locations(scene: PackedScene) -> Array:
	var locations = []
	var village_width = SMALL_VILLAGE_WIDTH
	var village_height = SMALL_VILLAGE_HEIGHT
	
	if scene == village_middle_scene:
		village_width = MIDDLE_VILLAGE_WIDTH
		village_height = MIDDLE_VILLAGE_HEIGHT
	
	# Проверяем только каждую 4-ю позицию для оптимизации
	const STEP = 4
	
	for x in range(VILLAGE_BORDER, width - VILLAGE_BORDER - village_width, STEP):
		for y in range(VILLAGE_BORDER, height - VILLAGE_BORDER - village_height, STEP):
			if is_suitable_for_settlement(Vector2i(x,y), scene):
				locations.append(Vector2i(x,y))
				if locations.size() >= 10: # Достаточно найти 10 подходящих локаций
					return locations
	
	return locations

func is_suitable_for_settlement(pos: Vector2i, scene: PackedScene) -> bool:
	var village_width = SMALL_VILLAGE_WIDTH
	var village_height = SMALL_VILLAGE_HEIGHT
	
	if scene == village_middle_scene:
		village_width = MIDDLE_VILLAGE_WIDTH
		village_height = MIDDLE_VILLAGE_HEIGHT
	
	# Проверяем расстояние до существующих деревень
	for settlement in settlements:
		if settlement.type == SettlementType.VILLAGE:
			var distance = pos.distance_to(settlement.position)
			if distance < VILLAGE_MIN_DISTANCE:
				return false
	
	# Проверяем только углы и центр области
	var check_points = [
		Vector2i(pos.x, pos.y),
		Vector2i(pos.x + village_width, pos.y),
		Vector2i(pos.x, pos.y + village_height),
		Vector2i(pos.x + village_width, pos.y + village_height),
		Vector2i(pos.x + village_width/2, pos.y + village_height/2)
	]
	
	for point in check_points:
		if not is_valid_settlement_point(point):
			return false
			
	# Проверяем безопасное расстояние от воды
	for x in [pos.x - WATER_SAFE_DISTANCE, pos.x + village_width + WATER_SAFE_DISTANCE]:
		for y in range(pos.y - WATER_SAFE_DISTANCE, pos.y + village_height + WATER_SAFE_DISTANCE):
			if not is_valid_settlement_point(Vector2i(x, y)):
				return false
	
	return true

func is_valid_settlement_point(point: Vector2i) -> bool:
	if point.x < 0 or point.x >= width or point.y < 0 or point.y >= height:
		return false
		
	if cell_map[point.x][point.y] == Biome.OCEAN:
		return false
		
	if $plants.get_cell_source_id(point) == 1:
		return false
		
	return true

func generate_world_data() -> void:
	var plains_count = 0
	
	for x in width:
		for y in height:
			var height_val = noise.get_noise_2d(x,y)
			var temp_val = temp_noise.get_noise_2d(x,y)
			var moisture_val = moisture_noise.get_noise_2d(x,y)
			var tree_val = tree_noise.get_noise_2d(x,y)
			
			var biome = get_biome(height_val, temp_val, moisture_val)
			cell_map[x][y] = biome
			
			if biome == Biome.PLAINS:
				plains_count += 1
			
			match biome:
				Biome.OCEAN:
					$water.set_cell(Vector2i(x,y), 0, water_atlas)
				Biome.BEACH:
					$terrain.set_cell(Vector2i(x,y), 3, Vector2i(4,4))
				Biome.TUNDRA:
					$terrain.set_cell(Vector2i(x,y), 8, Vector2i(0,0))
				Biome.FOREST:
					$grass.set_cell(Vector2i(x,y), 0, grass_atlas_arr.pick_random())
					if tree_val > 0.4:
						$plants.set_cell(Vector2i(x,y), 1, Vector2i(0,2))
				Biome.PLAINS:
					$grass.set_cell(Vector2i(x,y), 0, grass_atlas_arr.pick_random())
				Biome.DESERT:
					$terrain.set_cell(Vector2i(x,y), 5, desert_atlas_arr.pick_random())
	
	print("Количество равнин на карте: ", plains_count)

func generate_water_borders() -> void:
	for x in width:
		for y in height:
			# Проверяем, находится ли точка в пределах границы
			if x < WATER_BORDER_WIDTH or x >= width - WATER_BORDER_WIDTH or y < WATER_BORDER_WIDTH or y >= height - WATER_BORDER_WIDTH:
				# Устанавливаем воду
				cell_map[x][y] = Biome.OCEAN
				$terrain.erase_cell(Vector2i(x,y))
				$grass.erase_cell(Vector2i(x,y))
				$plants.erase_cell(Vector2i(x,y))
				$water.set_cell(Vector2i(x,y), 0, water_atlas)

func setup_noise() -> void:
	# Настройка шума высот
	noise = noise_height_text.noise
	noise.seed = randi() # Случайное зерно
	noise.frequency = 0.005 # Уменьшаем частту для более плавного рельефа
	
	# Настройка шума деревьев
	tree_noise = noise_tree_text.noise 
	tree_noise.seed = randi()
	tree_noise.frequency = 0.1
	
	# Настройка шума тмпературы
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
	if elevation < -0.2: # Уве��ичиваем порог для пляжа
		return Biome.BEACH
		
	if temp < -0.2:
		return Biome.TUNDRA
	elif moisture > 0:
		return Biome.FOREST
	elif moisture < -0.5:
		return Biome.DESERT
	else: # Увеличиваем шанс появления равнин
		return Biome.PLAINS

func spawn_settlement(scene: PackedScene, pos: Vector2i, type: int, village_width: int, village_height: int) -> void:
	if scene == null:
		print("ОШИБКА: scene не установлена!")
		return
		
	var settlement_instance = scene.instantiate()
	if settlement_instance == null:
		print("ОШИБКА: Не удалось создать экземпляр деревни!")
		return
		
	# Очищаем тайлы под деревней и в безопасной зоне от деревьев
	for x in range(pos.x - TREE_SAFE_DISTANCE, pos.x + village_width + TREE_SAFE_DISTANCE):
		for y in range(pos.y - TREE_SAFE_DISTANCE, pos.y + village_height + TREE_SAFE_DISTANCE):
			if x >= 0 and x < width and y >= 0 and y < height:
				if $plants.get_cell_source_id(Vector2i(x,y)) == 1:
					$plants.erase_cell(Vector2i(x,y))
				
				if x >= pos.x and x < pos.x + village_width and y >= pos.y and y < pos.y + village_height:
					$terrain.erase_cell(Vector2i(x,y))
					$grass.erase_cell(Vector2i(x,y))
					$water.erase_cell(Vector2i(x,y))
		
	settlement_instance.position = Vector2(pos.x * 32, pos.y * 32)
	if player:
		player.add_to_group("player")
	add_child(settlement_instance)
	
	var settlement = Settlement.new(type, pos, settlement_instance)
	settlements.append(settlement)
	print("Деревня успешно создана в позициии: ", pos)

func find_suitable_locations_for_grave() -> Array:
	var locations = []
	
	for x in range(VILLAGE_BORDER, width - VILLAGE_BORDER - GRAVE_AREA_WIDTH):
		for y in range(VILLAGE_BORDER, height - VILLAGE_BORDER - GRAVE_AREA_HEIGHT):
			if is_suitable_for_grave(Vector2i(x,y)):
				locations.append(Vector2i(x,y))
	return locations

func is_suitable_for_grave(pos: Vector2i) -> bool:
	# Безопасные расстояния для разных объектов
	const VILLAGE_SAFE_DISTANCE = 50  # Большое расстояние от деревень
	const WATER_SAFE_DISTANCE = 5    # Меньшее расстояние от воды
	const TREE_SAFE_DISTANCE = 3      # Минимальное расстояние от деревьев
	
	# Проверяем расстояние до других поселений (деревень)
	for settlement in settlements:
		if settlement.type == SettlementType.VILLAGE:  # Проверяем только для деревень
			if pos.distance_to(settlement.position) < VILLAGE_SAFE_DISTANCE:
				return false
	
	# Проверяем область под надгробие и безопасную зону вокруг
	for x in range(pos.x - WATER_SAFE_DISTANCE, pos.x + GRAVE_AREA_WIDTH + WATER_SAFE_DISTANCE):
		for y in range(pos.y - WATER_SAFE_DISTANCE, pos.y + GRAVE_AREA_HEIGHT + WATER_SAFE_DISTANCE):
			if x < 0 or x >= width or y < 0 or y >= height:
				return false
				
			# Проверяем саму область надгробия
			if x >= pos.x and x < pos.x + GRAVE_AREA_WIDTH and y >= pos.y and y < pos.y + GRAVE_AREA_HEIGHT:
				# Разрешаем спавн на разных биомах, кроме океана
				if cell_map[x][y] == Biome.OCEAN:
					return false
					
			# Проверяем наличие воды в безопасной зоне
			if cell_map[x][y] == Biome.OCEAN:
				return false
				
			# Проверяем наличие деревьев в безопасной зоне
			if $plants.get_cell_source_id(Vector2i(x,y)) == 1:
				var tree_distance = Vector2i(x,y).distance_to(pos)
				if tree_distance < TREE_SAFE_DISTANCE:
					return false
	
	return true

func spawn_grave(scene: PackedScene, pos: Vector2i) -> bool:
	if scene == null:
		print("ОШИБКА: scene надгробия не установлена!")
		return false
		
	var grave_instance = scene.instantiate()
	if grave_instance == null:
		print("ОШИБКА: Не удалось создать экземпляр надгробия!")
		return false
		
	# Очищаем тайлы под надгробием
	for x in range(pos.x, pos.x + GRAVE_AREA_WIDTH):
		for y in range(pos.y, pos.y + GRAVE_AREA_HEIGHT):
			if x >= 0 and x < width and y >= 0 and y < height:
				$plants.erase_cell(Vector2i(x,y))
				$terrain.erase_cell(Vector2i(x,y))
				# Устанавливаем тайл травы
				$grass.set_cell(Vector2i(x,y), 0, grass_atlas_arr.pick_random())
	
	grave_instance.position = Vector2(pos.x * 32, pos.y * 32)
	add_child(grave_instance)
	
	var settlement = Settlement.new(SettlementType.GRAVE, pos, grave_instance)
	settlements.append(settlement)
	return true

func setup_camera_and_player() -> void:
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0 
		camera.limit_right = width * 32
		camera.limit_bottom = height * 32
	
	var safe_settlement = find_safe_settlement()
	if safe_settlement != null and player:
		player.position = Vector2(safe_settlement.position.x * 32, safe_settlement.position.y * 32)
		player.add_to_group("player")
		print("Игрок перемещен в безопасную деревню: ", player.position)

func find_safe_settlement() -> Settlement:
	for settlement in settlements:
		if settlement.type != SettlementType.VILLAGE:
			continue
			
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

func place_graves() -> void:
	var graves_placed = 0
	var grave_locations = find_suitable_locations_for_grave()
	print("Найдено подходящих мест для надгробий: ", grave_locations.size())
	
	# Перемешиваем массив локаций для случайного размещения
	grave_locations.shuffle()
	
	# Пытаемся разместить заданное количество надгробий
	while graves_placed < GRAVES_PER_AREA and !grave_locations.is_empty():
		var grave_pos = grave_locations.pop_back()
		if spawn_grave(grave_scene, grave_pos):
			graves_placed += 1
			print("Создано надгробие ", graves_placed, " из ", GRAVES_PER_AREA, " в позиции: ", grave_pos)
	
	print("Всего размещено надгробий: ", graves_placed)

func _process(_delta:float)->void:
	pass
