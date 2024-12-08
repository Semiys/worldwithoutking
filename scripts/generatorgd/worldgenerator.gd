extends Node2D # Наследуем от Node2D для работы с 2D графикой

# Переносим эти константы в начало файла, сразу после других констант
const SAFETY_WATER_WEIGHT = 2.0
const SAFETY_WALKABLE_WEIGHT = 1.0
const SAFETY_CENTER_PENALTY = 0.5
const CHECK_RADIUS = 5

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
@onready var player = get_tree().get_root().get_node("Game/Player") # Получаем ссылку на игрока
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
const WATER_SAFE_DISTANCE = 80 # Безопасное расстояние от воды
const TREE_SAFE_DISTANCE = 80 # Безопасное расстояние от деревьев
const MAX_GENERATION_ATTEMPTS = 20 # Максималное количество попыток генерации мира
const WATER_BORDER_WIDTH = 32 # Ширина в��дной границы в тайлах

# Размеры области надгробия
const GRAVE_AREA_WIDTH = 5
const GRAVE_AREA_HEIGHT = 5

# В начале фала доавим константы для количества надгробий
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
# Ма��сив тайлов для пустыни
var desert_atlas_arr=[
	Vector2i(2,6), # Обычный песок
	Vector2i(3,6), # Песок с кактсом
	Vector2i(0,4)  # Псок с камнями
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

# В начале файла добавим новые константы
const MAX_ATTEMPTS_PER_GENERATION = 20  # Максимальное число попыток для одной генерации
const GENERATION_TIMEOUT = 30.0  # Таймаут в секундах для всего процесса генерации

# Добавляем новые константы для контроля генерации
const MAX_TOTAL_ATTEMPTS = 100  # Максимальное общее количество попыток
const RETRY_DELAY = 0.05  # Задержка между попытками в секундах
const MIN_REQUIRED_GRAVES = 10  # Минимальное количество надгробий для успешной генерации

# Добавляем новые константы для безопасных расстояний
const SMALL_VILLAGE_WATER_SAFE_DISTANCE = 80  # Для маленькой деревни
const MIDDLE_VILLAGE_WATER_SAFE_DISTANCE = 120  # Увеличенное расстояние для средней деревни

func _ready() -> void:
	if !validate_requirements():
		return
		
	await generate_valid_world()

func validate_requirements() -> bool:
	if !player or !camera:
		push_error("КРИТИЧЕСКАЯ ОШИБКА: Не удалось найти игрока или камеру!")
		return false
	if !village_scene or !village_middle_scene or !grave_scene:
		push_error("КРИТИЧЕСКАЯ ОШИБКА: Отсутствуют необходимые сцены!")
		return false
	if !$water or !$terrain or !$grass or !$plants:
		push_error("КРИТИЧЕСКАЯ ОШИБКА: Отсутствуют необходимые тайлмапы!")
		return false
	return true

func generate_valid_world() -> void:
	var total_attempts = 0
	var world_generated = false
	
	while !world_generated and total_attempts < MAX_TOTAL_ATTEMPTS:
		total_attempts += 1
		print("Попытка полной генерации мира #", total_attempts)
		
		if await try_generate_world():
			if validate_world_state():
				world_generated = true
				print("Мир успешно сгенерирован на попытке ", total_attempts)
				break
		
		await get_tree().create_timer(RETRY_DELAY).timeout
	
	if !world_generated:
		push_error("Не удалось сгенерировать валидный мир после " + str(total_attempts) + " попыток")

func try_generate_world() -> bool:
	await clear_previous_generation()
	
	var current_seed = randi()
	setup_noise(current_seed)
	print("Используется сид: ", current_seed)
	
	generate_world_data()
	generate_water_borders()
	
	if !place_settlements():
		return false
		
	setup_camera_and_player()
	return true

func validate_world_state() -> bool:
	# Проверяем наличие маленькой деревни
	var small_village = find_small_village()
	if !small_village:
		print("Валидация: отсутствует маленькая деревня")
		return false
		
	# Проверяем наличие средней деревни
	var has_middle_village = false
	for settlement in settlements:
		if settlement.type == SettlementType.VILLAGE and settlement.scene.scene_file_path == village_middle_scene.resource_path:
			has_middle_village = true
			break
	
	if !has_middle_village:
		print("Валидация: отсутствует средняя деревня")
		return false
		
	# Проверяем количество надгробий
	var grave_count = 0
	for settlement in settlements:
		if settlement.type == SettlementType.GRAVE:
			grave_count += 1
	
	if grave_count < MIN_REQUIRED_GRAVES:
		print("Валидация: недостаточно надгробий (", grave_count, "/", MIN_REQUIRED_GRAVES, ")")
		return false
		
	# Проверяем доступность всех деревень (нет окружения водой)
	if !validate_settlements_accessibility():
		print("Валидация: проблемы с доступностью деревень")
		return false
		
	return true

func validate_settlements_accessibility() -> bool:
	for settlement in settlements:
		if settlement.type != SettlementType.VILLAGE:
			continue
			
		var pos = settlement.position
		var width = SMALL_VILLAGE_WIDTH
		var height = SMALL_VILLAGE_HEIGHT
		
		if settlement.scene.scene_file_path == village_middle_scene.resource_path:
			width = MIDDLE_VILLAGE_WIDTH
			height = MIDDLE_VILLAGE_HEIGHT
			
		# Проверяем наличие прохода к деревне
		var has_access = false
		for check_dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var check_pos = pos + check_dir * (width/2)
			if is_valid_settlement_point(check_pos):
				has_access = true
				break
				
		if !has_access:
			return false
			
	return true

func clear_previous_generation() -> void:
	for settlement in settlements:
		if is_instance_valid(settlement.scene):
			settlement.scene.queue_free()
	
	# Ждем один кад для удаления объектов
	await get_tree().process_frame
	
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
	# Сначала пытаемся разместить маленькую деревню
	var small_locations = find_suitable_locations(village_scene)
	print("Найдено подходящих мест для маленькой деревни: ", small_locations.size())
	
	# Если не нашли места для маленькой деревни - сразу возвращаем false
	if small_locations.is_empty():
		print("Не удалось найти место для маленькой деревни")
		return false
		
	# Выбираем наиболее безопасное место для маленькой деревни
	var best_small_pos = find_safest_location(small_locations)
	if !spawn_settlement(village_scene, best_small_pos, SettlementType.VILLAGE, SMALL_VILLAGE_WIDTH, SMALL_VILLAGE_HEIGHT):
		return false
	print("Создана маленькая дервня в позиции: ", best_small_pos)
	
	# Теперь пытаемся разместить среднюю деревню
	var middle_locations = find_suitable_locations(village_middle_scene)
	print("Найдено подходящих мест для средней деревни: ", middle_locations.size())
	
	if middle_locations.is_empty():
		print("Не удалось найти место для средней деревни")
		return false
		
	var middle_pos = middle_locations.pick_random()
	if !spawn_settlement(village_middle_scene, middle_pos, SettlementType.VILLAGE, MIDDLE_VILLAGE_WIDTH, MIDDLE_VILLAGE_HEIGHT):
		return false
	print("Создана средняя деревня в позиции: ", middle_pos)
	
	# Размещаем надгробия
	place_graves()
	
	return true

func find_safest_location(locations: Array) -> Vector2i:
	var best_location = locations[0]
	var max_safety_score = -1
	
	for pos in locations:
		var safety_score = calculate_safety_score(pos)
		if safety_score > max_safety_score:
			max_safety_score = safety_score
			best_location = pos
			
	return best_location

func calculate_safety_score(pos: Vector2i) -> float:
	var score = 0.0
	
	# Проверяем расстояние до воды
	var water_distance = get_min_water_distance(pos)
	score += water_distance * 2  # Больши вес для расстояния до воды
	
	# Проверяем количество проходимой территории вокруг
	var walkable_tiles = count_walkable_tiles(pos)
	score += walkable_tiles
	
	# Проверяем центральность позиции
	var center_distance = pos.distance_to(Vector2i(width/2, height/2))
	score -= center_distance * 0.5  # Штраф за удаленность от центра
	
	return score

func get_min_water_distance(pos: Vector2i) -> float:
	var min_distance = 999999.0
	
	for x in range(max(0, pos.x - WATER_SAFE_DISTANCE), min(width, pos.x + SMALL_VILLAGE_WIDTH + WATER_SAFE_DISTANCE)):
		for y in range(max(0, pos.y - WATER_SAFE_DISTANCE), min(height, pos.y + SMALL_VILLAGE_HEIGHT + WATER_SAFE_DISTANCE)):
			if cell_map[x][y] == Biome.OCEAN:
				var dist = pos.distance_to(Vector2i(x, y))
				min_distance = min(min_distance, dist)
				
	return min_distance

func count_walkable_tiles(pos: Vector2i) -> int:
	var count = 0
	var check_radius = CHECK_RADIUS
	
	for x in range(max(0, pos.x - check_radius), min(width, pos.x + SMALL_VILLAGE_WIDTH + check_radius)):
		for y in range(max(0, pos.y - check_radius), min(height, pos.y + SMALL_VILLAGE_HEIGHT + check_radius)):
			if x >= width or y >= height:
				continue
			if cell_map[x][y] != Biome.OCEAN:
				count += 1
	return count

func find_suitable_locations(scene: PackedScene) -> Array:
	var locations = []
	var village_width = SMALL_VILLAGE_WIDTH
	var village_height = SMALL_VILLAGE_HEIGHT
	
	if scene == village_middle_scene:
		village_width = MIDDLE_VILLAGE_WIDTH
		village_height = MIDDLE_VILLAGE_HEIGHT
	
	# Адаптивный шаг в зависимости от размера карты
	var step = max(4, min(village_width, village_height) / 4)
	
	# Используем пул точек для оптимизации
	var check_points = []
	for x in range(VILLAGE_BORDER, width - VILLAGE_BORDER - village_width, step):
		for y in range(VILLAGE_BORDER, height - VILLAGE_BORDER - village_height, step):
			check_points.append(Vector2i(x,y))
	
	# Перемешиваем точки для более равномерного распределения
	check_points.shuffle()
	
	# Проверяем только необходимое количество точек
	for point in check_points:
		if is_suitable_for_settlement(point, scene):
			locations.append(point)
			if locations.size() >= 10:
				break
	
	return locations

func is_suitable_for_settlement(pos: Vector2i, scene: PackedScene) -> bool:
	var village_width = SMALL_VILLAGE_WIDTH
	var village_height = SMALL_VILLAGE_HEIGHT
	var water_safe_distance = SMALL_VILLAGE_WATER_SAFE_DISTANCE
	
	if scene == village_middle_scene:
		village_width = MIDDLE_VILLAGE_WIDTH
		village_height = MIDDLE_VILLAGE_HEIGHT
		water_safe_distance = MIDDLE_VILLAGE_WATER_SAFE_DISTANCE
	
	# Проверяем базовые границы
	if pos.x < VILLAGE_BORDER or pos.x + village_width >= width - VILLAGE_BORDER:
		return false
	if pos.y < VILLAGE_BORDER or pos.y + village_height >= height - VILLAGE_BORDER:
		return false
	
	# Проверяем расстояние до существующих деревень
	for settlement in settlements:
		if settlement.type == SettlementType.VILLAGE:
			var distance = pos.distance_to(settlement.position)
			if distance < VILLAGE_MIN_DISTANCE:
				return false
	
	# Проверяем только критические точки для оптимизации
	var check_points = [
		Vector2i(pos.x, pos.y), # Левый верхний угол
		Vector2i(pos.x + village_width, pos.y), # Правый верхний угол
		Vector2i(pos.x, pos.y + village_height), # Левый нижний угол
		Vector2i(pos.x + village_width, pos.y + village_height), # Правый нижний угол
		Vector2i(pos.x + village_width/2, pos.y + village_height/2) # Центр
	]
	
	# Проверяем наличие воды в критических точках
	for point in check_points:
		if point.x < 0 or point.x >= width or point.y < 0 or point.y >= height:
			return false
		if cell_map[point.x][point.y] == Biome.OCEAN:
			return false
	
	# Проверяем наличие достаточного количества проходимой территории
	var walkable_tiles = 0
	var required_walkable = (village_width * village_height) * 0.9 # 90% территории должно быть проходимым
	
	for x in range(pos.x, pos.x + village_width):
		for y in range(pos.y, pos.y + village_height):
			if cell_map[x][y] != Biome.OCEAN:
				walkable_tiles += 1
	
	if walkable_tiles < required_walkable:
		return false
	
	# Проверяем безопасную зону вокруг деревни
	var border_check_points = []
	for i in range(water_safe_distance):
		border_check_points.append(Vector2i(pos.x - i, pos.y)) # Левая граница
		border_check_points.append(Vector2i(pos.x + village_width + i, pos.y)) # Правая граница
		border_check_points.append(Vector2i(pos.x, pos.y - i)) # Верхняя граница
		border_check_points.append(Vector2i(pos.x, pos.y + village_height + i)) # Нижняя граница
	
	var water_count = 0
	for point in border_check_points:
		if point.x >= 0 and point.x < width and point.y >= 0 and point.y < height:
			if cell_map[point.x][point.y] == Biome.OCEAN:
				water_count += 1
	
	# Допускаем небольшое количество воды в безопасной зоне
	if water_count > border_check_points.size() * 0.1: # Допускаем до 10% воды
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

func setup_noise(generation_seed: int) -> void:
	# Настройка шума высот
	noise = noise_height_text.noise
	noise.seed = generation_seed
	noise.frequency = 0.005
	
	# Настройка шума деревьев
	tree_noise = noise_tree_text.noise 
	tree_noise.seed = generation_seed + 1  # Разные сид для разных шумов
	tree_noise.frequency = 0.1
	
	# Настройка шума температуры
	temp_noise = noise_temp_text.noise
	temp_noise.seed = generation_seed + 2
	temp_noise.frequency = 0.005
	
	# Настройка шума влажности
	moisture_noise = noise_moisture_text.noise
	moisture_noise.seed = generation_seed + 3
	moisture_noise.frequency = 0.005
	
	# Настройка шума поселений
	settlement_noise = noise_settlement_text.noise
	settlement_noise.seed = generation_seed + 4
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

func spawn_settlement(scene: PackedScene, pos: Vector2i, type: int, village_width: int, village_height: int) -> bool:
	if scene == null:
		push_error("ОШИБКА: scene не установлена!")
		return false
		
	var settlement_instance: Node2D
	
	# Безопасное инстанцирование
	if !is_instance_valid(scene):
		push_error("Ошибка: некорректная сцена")
		return false
		
	settlement_instance = scene.instantiate()
	if !is_instance_valid(settlement_instance):
		push_error("Ошибка при создании экземпляра сцены")
		return false
		
	if settlement_instance == null:
		push_error("ОШИБКА: Не удалось создать экземпляр деревни!")
		return false
	
	# Проверяем пересечение с другими деревнями
	if check_settlement_overlap(pos, village_width, village_height):
		push_error("ОШИБКА: Обнаружено пересечение с существующей деревней!")
		settlement_instance.queue_free()
		return false
		
	# Очищаем тайлы под деревней и в безопасной зоне от деревьев
	if !clear_settlement_area(pos, village_width, village_height):
		settlement_instance.queue_free()
		return false
	
	settlement_instance.position = Vector2(pos.x * 32, pos.y * 32)
	if player:
		player.add_to_group("player")
	add_child(settlement_instance)
	
	var settlement = Settlement.new(type, pos, settlement_instance)
	settlements.append(settlement)
	print("Деревня успешно создана в позиции: ", pos)
	
	return true

# Новая функция для проверки пересечений
func check_settlement_overlap(pos: Vector2i, width: int, height: int) -> bool:
	const MINIMUM_GAP = 5  # Минимальный промежуток между деревнями
	
	for settlement in settlements:
		if settlement.type != SettlementType.VILLAGE:
			continue
			
		# Проверяем пересечение прямоугольников с учетом промежутка
		var other_pos = settlement.position
		var other_width = SMALL_VILLAGE_WIDTH
		var other_height = SMALL_VILLAGE_HEIGHT
		
		if settlement.scene.scene_file_path == village_middle_scene.resource_path:
			other_width = MIDDLE_VILLAGE_WIDTH
			other_height = MIDDLE_VILLAGE_HEIGHT
			
		if (pos.x - MINIMUM_GAP < other_pos.x + other_width + MINIMUM_GAP and
			pos.x + width + MINIMUM_GAP > other_pos.x - MINIMUM_GAP and
			pos.y - MINIMUM_GAP < other_pos.y + other_height + MINIMUM_GAP and
			pos.y + height + MINIMUM_GAP > other_pos.y - MINIMUM_GAP):
			return true
			
	return false

# Новая функция для очистки области под деревню
func clear_settlement_area(pos: Vector2i, village_width: int, village_height: int) -> bool:
	for x in range(pos.x - TREE_SAFE_DISTANCE, pos.x + village_width + TREE_SAFE_DISTANCE):
		for y in range(pos.y - TREE_SAFE_DISTANCE, pos.y + village_height + TREE_SAFE_DISTANCE):
			if x < 0 or x >= width or y < 0 or y >= height:
				continue
				
			if $plants.get_cell_source_id(Vector2i(x,y)) == 1:
				$plants.erase_cell(Vector2i(x,y))
			
			if x >= pos.x and x < pos.x + village_width and y >= pos.y and y < pos.y + village_height:
				if cell_map[x][y] == Biome.OCEAN:
					return false
				$terrain.erase_cell(Vector2i(x,y))
				$grass.erase_cell(Vector2i(x,y))
				$water.erase_cell(Vector2i(x,y))
	
	return true

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
	const TREE_SAFE_DISTANCE = 3      # Минимальное расстоя��ие от деревьев
	
	# Проверяем расстояние до других пселений (деревень)
	for settlement in settlements:
		if settlement.type == SettlementType.VILLAGE:  # Проверяем только для деревень
			if pos.distance_to(settlement.position) < VILLAGE_SAFE_DISTANCE:
				return false
	
	# Проверяем область под надгробие и безопасную зону вокруг
	for x in range(pos.x - WATER_SAFE_DISTANCE, pos.x + GRAVE_AREA_WIDTH + WATER_SAFE_DISTANCE):
		for y in range(pos.y - WATER_SAFE_DISTANCE, pos.y + GRAVE_AREA_HEIGHT + WATER_SAFE_DISTANCE):
			if x < 0 or x >= width or y < 0 or y >= height:
				return false
				
			# Проверяем саму область надгробя
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
	
	# Ищем маленькую деревню для спавна игрока
	var small_village = find_small_village()
	if small_village != null and player:
		# Добавляем небольшой отступ от края деревни для безопасного спавна
		var spawn_offset = Vector2(SMALL_VILLAGE_WIDTH/2, SMALL_VILLAGE_HEIGHT/2) * 32
		player.position = Vector2(small_village.position.x * 32, small_village.position.y * 32) + spawn_offset
		player.add_to_group("player")
		print("Игрок перемещен в маленькую деревню: ", player.position)
	else:
		# Если маленькая деревня не найдена - это критическая ошибка
		push_error("КРИТИЧЕСКАЯ ОШИБКА: Маленькая деревня не найдена!")
		# Перезапускаем генерацию мира
		clear_previous_generation()
		var new_seed = randi()  # Генерируем новый сид
		setup_noise(new_seed)   # Передаем сид в функцию
		generate_world_data()
		generate_water_borders()
		if !place_settlements():
			push_error("Не удалось сгенерировать мир с маленькой деревней!")

func find_small_village() -> Settlement:
	# Ищем именно маленькую деревню (проверяем и тип, и сцену)
	for settlement in settlements:
		if settlement.type == SettlementType.VILLAGE and settlement.scene.scene_file_path == village_scene.resource_path:
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
