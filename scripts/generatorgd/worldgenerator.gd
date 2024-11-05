extends Node2D # Наследуем от Node2D для работы с 2D графикой

# Экспорт текстур шума для настройки через редактор
@export var noise_height_text:NoiseTexture2D # Шум высоты для рельефа - определяет высоту местности
@export var noise_tree_text:NoiseTexture2D # Шум для деревьев - определяет где будут расти деревья
@export var noise_temp_text:NoiseTexture2D # Шум температуры - влияет на тип биома
@export var noise_moisture_text:NoiseTexture2D # Шум влажности - влияет на тип биома

# Определение типов биомов - перечисление всех возможных типов местности
enum Biome {OCEAN, BEACH, TUNDRA, FOREST, PLAINS, DESERT}

# Переменные для генерации
var noise:Noise # Шум для генерации высоты
var tree_noise:Noise # Шум для генерации деревьев
var temp_noise:Noise # Шум для температуры
var moisture_noise:Noise # Шум для влажности
var width:int=256 # Ширина карты в тайлах
var height:int=256 # Высота карты в тайлах

# Атласы тайлов - определяют координаты текстур в тайлсете
var water_atlas=Vector2i(0,2) # Координаты тайла воды
var grass_tiles_arr=[] # Массив для тайлов травы
var terrain_grass_int=0 # Индекс текущего тайла травы
var grass_atlas_arr=[Vector2i(1,1),Vector2i(5,1),Vector2i(5,0),Vector2i(5,3),Vector2i(5,4),Vector2i(5,2)] # Координаты разных тайлов травы
var thread: Thread

# Массив для хранения биомов - двумерный массив размером width x height
var cell_map:Array = []

func _ready() -> void:
	thread=Thread.new()
	
	# Инициализация шумов - получаем шумы из текстур
	noise = noise_height_text.noise
	tree_noise = noise_tree_text.noise
	temp_noise = noise_temp_text.noise
	moisture_noise = noise_moisture_text.noise
	
	# Инициализация карты биомов - создаем двумерный массив
	cell_map.resize(width)
	for x in width:
		cell_map[x] = []
		cell_map[x].resize(height)
	
	generate_world() # Генерируем мир
	generate_rivers() # Генерируем реки

func get_biome(height:float, temp:float, moisture:float) -> int:
	if height < 0.0: # Если высота меньше 0 - это океан
		return Biome.OCEAN
	if height < 0.1: # Если высота меньше 0.1 - это пляж
		return Biome.BEACH
		
	if temp < -0.2: # Если холодно - это тундра
		return Biome.TUNDRA
	elif moisture > 0.3: # Если влажно - это лес
		return Biome.FOREST
	elif moisture < -0.2: # Если сухо - это пустыня
		return Biome.DESERT
	else: # В остальных случаях - равнины
		return Biome.PLAINS

func generate_rivers():
	var start_points = [] # Массив начальных точек для рек
	for x in width:
		for y in height:
			if cell_map[x][y] == Biome.TUNDRA: # Ищем точки в тундре для начала рек
				start_points.append(Vector2i(x,y))
	
	for point in start_points:
		if randf() < 0.1: # 10% шанс создать реку в каждой точке
			create_river(point)

func create_river(start:Vector2i):
	var current = start # Текущая позиция
	var river = [current] # Массив точек реки
	
	while !is_ocean(current): # Пока не достигнем океана
		var next = find_lowest_neighbor(current) # Ищем самую низкую соседнюю точку
		if next == current: # Если застряли, прерываем
			break
		river.append(next) # Добавляем точку к реке
		current = next # Переходим к следующей точке
		
	for point in river: # Размещаем тайлы воды вдоль реки
		# Очищаем все тайлы над водой
		$terrain.erase_cell(point)
		$grass.erase_cell(point)
		$plants.erase_cell(point)
		# Ставим тайл воды
		$water.set_cell(point, 0, water_atlas)

func is_ocean(pos:Vector2i) -> bool:
	return cell_map[pos.x][pos.y] == Biome.OCEAN # Проверяем, является ли точка океаном

func find_lowest_neighbor(pos:Vector2i) -> Vector2i:
	var lowest = pos # Самая низкая точка
	var lowest_height = noise.get_noise_2d(pos.x, pos.y) # Высота текущей точки
	
	# Массив соседних точек
	var neighbors = [
		Vector2i(pos.x-1, pos.y), # Слева
		Vector2i(pos.x+1, pos.y), # Справа
		Vector2i(pos.x, pos.y-1), # Сверху
		Vector2i(pos.x, pos.y+1)  # Снизу
	]
	
	for n in neighbors: # Проверяем каждого соседа
		if n.x >= 0 and n.x < width and n.y >= 0 and n.y < height: # Если сосед в пределах карты
			var height = noise.get_noise_2d(n.x, n.y) # Получаем высоту соседа
			if height < lowest_height: # Если сосед ниже текущей низшей точки
				lowest = n # Обновляем низшую точку
				lowest_height = height # Обновляем низшую высоту
				
	return lowest # Возвращаем самую низкую соседнюю точку

func generate_world():
	for x in width:
		for y in height:
			# Получаем значения шума для каждой координаты
			var height_val:float = noise.get_noise_2d(x,y) # Значение высоты
			var temp_val:float = temp_noise.get_noise_2d(x,y) # Значение температуры
			var moisture_val:float = moisture_noise.get_noise_2d(x,y) # Значение влажности
			var tree_val:float = tree_noise.get_noise_2d(x,y) # Значение для деревьев
			
			# Определяем биом на основе значений шума
			var biome = get_biome(height_val, temp_val, moisture_val)
			cell_map[x][y] = biome
			
			# Размещаем тайлы в зависимости от биома
			if biome == Biome.OCEAN: # Для океана ставим только тайл воды
				$water.set_cell(Vector2i(x,y), 0, water_atlas)
			else: # Для остальных биомов размещаем соответствующие тайлы
				match biome:
					Biome.BEACH: # Для пляжа ставим песок
						$terrain.set_cell(Vector2i(x,y), 0, Vector2i(0,4))
					Biome.TUNDRA: # Для тундры ставим снег
						$terrain.set_cell(Vector2i(x,y), 0, Vector2i(3,4))
					Biome.FOREST: # Для леса ставим траву и деревья
						$grass.set_cell(Vector2i(x,y), 0, grass_atlas_arr.pick_random())
						if tree_val > 0.4: # Если значение шума больше 0.4, ставим дерево
							$plants.set_cell(Vector2i(x,y), 1, Vector2i(0,2))
					Biome.PLAINS: # Для равнин ставим траву
						$grass.set_cell(Vector2i(x,y), 0, grass_atlas_arr.pick_random())
					Biome.DESERT: # Для пустыни ставим песок
						$terrain.set_cell(Vector2i(x,y), 0, Vector2i(1,3))

func _process(delta:float)->void:
	pass
