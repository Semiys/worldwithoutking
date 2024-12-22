extends CanvasLayer

signal move_made(start_pos, end_pos)

var selected_piece = null
var board_buttons = []
var current_board = []
var current_game = null
var rules_window = null

class Move:
	var x1: int
	var y1: int
	var x2: int
	var y2: int
	var jump: bool = false
	var x3: int = 0
	var y3: int = 0
	
	func _init(p_x1: int, p_y1: int, p_x2: int, p_y2: int, p_x3: int = 0, p_y3: int = 0, p_jump: bool = false):
		x1 = p_x1
		y1 = p_y1
		x2 = p_x2
		y2 = p_y2
		x3 = p_x3
		y3 = p_y3
		jump = p_jump

func setup(game):
	current_game = game

func _ready():
	layer = 100
	
	# Возвращаем исходный размер панели
	var panel = $CenterContainer/Panel
	panel.custom_minimum_size = Vector2(400, 450)
	
	create_board()
	create_rules_button()
	await get_tree().create_timer(0.1).timeout
	if has_node("CenterContainer/Panel/VBoxContainer/CloseButton"):
		$CenterContainer/Panel/VBoxContainer/CloseButton.grab_focus()
	get_tree().paused = true
	print("UI создан")

func _exit_tree():
	get_tree().paused = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_close_button_pressed()

func create_board():
	var grid = $CenterContainer/Panel/VBoxContainer/MarginContainer/GridContainer
	
	var button_style = StyleBoxFlat.new()
	button_style.set_border_width_all(1)
	button_style.border_color = Color(0.3, 0.3, 0.3)
	
	for row in range(8):
		var button_row = []
		for col in range(8):
			var button = Button.new()
			button.custom_minimum_size = Vector2(40, 40)
			button.mouse_filter = Control.MOUSE_FILTER_STOP  # Изменено
			button.focus_mode = Control.FOCUS_ALL
			
			var cell_style = button_style.duplicate()
			button.add_theme_stylebox_override("normal", cell_style)
			button.add_theme_stylebox_override("hover", cell_style)
			button.add_theme_stylebox_override("pressed", cell_style)
			
			if (row + col) % 2 == 0:
				cell_style.bg_color = Color(0.8, 0.8, 0.8, 0.9)
			else:
				cell_style.bg_color = Color(0.3, 0.3, 0.3, 0.9)
			
			# Изменяем способ подключения сигнала
			button.pressed.connect(_on_cell_pressed.bind(row, col))
			
			grid.add_child(button)
			button_row.append(button)
		board_buttons.append(button_row)
	
	print("Доска создана")  # Отладка

func update_board(board):
	current_board = board.duplicate(true)
	for row in range(8):
		for col in range(8):
			var button = board_buttons[row][col]
			match board[row][col]:
				'b':
					if current_game.is_king([row, col]):
						button.text = "♔"  # Символ черной дамки
					else:
						button.text = "⚫"
					button.add_theme_font_size_override("font_size", 24)
				'w':
					if current_game.is_king([row, col]):
						button.text = "♕"  # Символ белой дамки
					else:
						button.text = "⚪"
					button.add_theme_font_size_override("font_size", 24)
				' ':
					button.text = ""
	print("Доска обновлена")  # Отладка

func _on_cell_pressed(row: int, col: int):
	if selected_piece == null:
		# Проверяем, является ли выбранная фигура белой (игрока)
		if current_board[row][col] == 'w':
			selected_piece = [row, col]
			var button = board_buttons[row][col]
			var style = button.get_theme_stylebox("normal").duplicate()
			
			style.bg_color = Color(1, 1, 0, 0.7)
			button.add_theme_stylebox_override("normal", style)
			
			# Подсвечиваем возможные ходы
			var possible_moves = current_game.get_possible_moves(current_game.player_color)
			for move in possible_moves:
				if move[0] == [row, col]:
					var end_button = board_buttons[move[1][0]][move[1][1]]
					var end_style = end_button.get_theme_stylebox("normal").duplicate()
					end_style.bg_color = Color(0, 1, 0, 0.3)
					end_button.add_theme_stylebox_override("normal", end_style)
	else:
		var start_pos = selected_piece
		var end_pos = [row, col]
		
		# Проверяем, является ли этот ход допустимым
		var possible_moves = current_game.get_possible_moves(current_game.player_color)
		var is_valid = false
		for move in possible_moves:
			if move[0] == start_pos and move[1] == end_pos:
				is_valid = true
				break
		
		if is_valid:
			emit_signal("move_made", start_pos, end_pos)
		
		# Убираем подсветку в любом случае
		for r in range(8):
			for c in range(8):
				var button = board_buttons[r][c]
				var style = button.get_theme_stylebox("normal").duplicate()
				style.bg_color = Color(0.8, 0.8, 0.8, 0.9) if (r + c) % 2 == 0 else Color(0.3, 0.3, 0.3, 0.9)
				button.add_theme_stylebox_override("normal", style)
		
		selected_piece = null

func find_capture_sequence(start_pos: Array, end_pos: Array) -> Array:
	var possible_moves = current_game.get_possible_moves(current_game.player_color)
	for move in possible_moves:
		if move[0] == start_pos and end_pos in move:
			var start_idx = move.find(start_pos)
			var end_idx = move.find(end_pos)
			return move.slice(start_idx, end_idx + 1)
	return []

func is_valid_move(start_pos: Array, end_pos: Array) -> bool:
	var all_moves = current_game.get_possible_moves(current_game.player_color)
	var is_king = current_game.is_king(start_pos)
	var current_piece = current_board[start_pos[0]][start_pos[1]]
	
	# Проверяем ходы с взятием
	var capture_moves = []
	for move in all_moves:
		if move.size() > 2 or (move.size() == 2 and is_capture_move(move[0], move[1])):
			capture_moves.append(move)
	
	if capture_moves.size() > 0:
		for move in capture_moves:
			if move[0] == start_pos and end_pos in move:
				return true
		return false
	
	if current_board[end_pos[0]][end_pos[1]] != ' ':
		return false
	
	if is_king:
		var dx = abs(end_pos[1] - start_pos[1])
		var dy = abs(end_pos[0] - start_pos[0])
		
		# Проверяем диагональность хода
		if dx != dy:
			return false
		
		return is_valid_king_path(start_pos, end_pos, current_piece)
	else:
		# Логика для обычной шашки
		var dx = abs(end_pos[1] - start_pos[1])
		var dy = abs(end_pos[0] - start_pos[0])
		
		# Проверяем направление движения
		var valid_direction = end_pos[0] < start_pos[0] if current_piece == 'w' else end_pos[0] > start_pos[0]
		
		# Обычный ход
		if dx == 1 and dy == 1:
			return valid_direction
		
		# Ход с взятием
		elif dx == 2 and dy == 2:
			var middle_row = (start_pos[0] + end_pos[0]) / 2
			var middle_col = (start_pos[1] + end_pos[1]) / 2
			var enemy_piece = 'b' if current_piece == 'w' else 'w'
			return current_board[middle_row][middle_col] == enemy_piece
	
	return false

func is_capture_move(start_pos: Array, end_pos: Array) -> bool:
	return abs(start_pos[0] - end_pos[0]) == 2 and abs(start_pos[1] - end_pos[1]) == 2

func is_valid_king_path(start_pos: Array, end_pos: Array, current_piece: String) -> bool:
	var dir_x = sign(float(end_pos[1] - start_pos[1]))
	var dir_y = sign(float(end_pos[0] - start_pos[0]))
	var x = start_pos[1]
	var y = start_pos[0]
	var enemy_found = false
	var max_steps = 8  # Максимальное количество шагов на доске
	var steps = 0
	
	# Проверяем конечную точку
	if not (0 <= end_pos[1] < 8 and 0 <= end_pos[0] < 8):
		return false
		
	# Проверяем диагональность хода
	if abs(end_pos[1] - start_pos[1]) != abs(end_pos[0] - start_pos[0]):
		return false
	
	while steps < max_steps:
		x += dir_x
		y += dir_y
		steps += 1
		
		# Достигли конечной позиции
		if x == end_pos[1] and y == end_pos[0]:
			return not enemy_found  # Разрешаем ход только если не было вражеских фигур
		
		# Проверка выхода за пределы доски
		if not (0 <= x < 8 and 0 <= y < 8):
			return false
		
		if current_board[y][x] != ' ':
			if enemy_found:
				return false  # Уже нашли одну фигуру противника
			
			var piece_on_path = current_board[y][x]
			if piece_on_path == current_piece:
				return false  # Своя фигура на пути
			
			if not is_enemy_piece(current_piece, piece_on_path):
				return false
			
			enemy_found = true
			
			# Проверяем следующую клетку после вражеской фигуры
			var next_x = x + dir_x
			var next_y = y + dir_y
			
			# Если следующая клетка - конечная позиция
			if next_x == end_pos[1] and next_y == end_pos[0]:
				return true  # Разрешаем взятие
			
			# Если следующая клетка за пределами доски или занята
			if not (0 <= next_x < 8 and 0 <= next_y < 8) or current_board[next_y][next_x] != ' ':
				return false
			
			# Продолжаем проверку пути
			x = next_x - dir_x
			y = next_y - dir_y
	
	# Если вышли из цикла, значит не достигли цели
	return false

func _on_close_button_pressed():
	print("Кнопка закрытия нажата")  # Отладка
	queue_free()

func create_rules_button():
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var rules_button = Button.new()
	rules_button.text = "Правила"
	rules_button.custom_minimum_size = Vector2(100, 40)
	rules_button.pressed.connect(_on_rules_button_pressed)
	
	var close_button = $CenterContainer/Panel/VBoxContainer/CloseButton
	var parent = close_button.get_parent()
	parent.remove_child(close_button)
	
	hbox.add_child(rules_button)
	hbox.add_child(close_button)
	
	$CenterContainer/Panel/VBoxContainer.add_child(hbox)

func _on_rules_button_pressed():
	if rules_window != null:
		rules_window.queue_free()
		rules_window = null
		return
		
	rules_window = Window.new()
	rules_window.title = "Правила игры"
	rules_window.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	rules_window.size = Vector2(400, 500)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 500)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var rules_text = RichTextLabel.new()
	rules_text.bbcode_enabled = true
	rules_text.custom_minimum_size = Vector2(380, 500)
	rules_text.text = """[center][b]Правила игры[/b][/center]

1. [b]Ходы:[/b]
- Простые шашки ходят по диагонали вперёд на одну клетку
- Дамка ходит на любое количество клеток по диагонали

2. [b]Взятие:[/b]
- Взятие обязательно
- Простая шашка бьёт вперед и назад
- Дамка бьёт на любое расстояние
- За один ход можно взять только одну шашку

3. [b]Дамка:[/b]
- Шашка становится дамкой, достигнув последней горизонтали
- Дамка обозначается короной (♔/♕)
- Дамка может ходить на любое количество полей по диагонали
- При взятии дамка может остановиться на любом свободном поле за взятой шашкой

4. [b]Победа:[/b]
- Побеждает игрок, который съел все шашки противника
- Побеждает игрок, если у противника не осталось возможных ходов"""
	
	scroll.add_child(rules_text)
	rules_window.add_child(scroll)
	
	rules_window.close_requested.connect(func(): 
		rules_window.queue_free()
		rules_window = null
	)
	
	add_child(rules_window)

func is_king(pos: Array) -> bool:
	if not (0 <= pos[0] < 8 and 0 <= pos[1] < 8):
		return false
		
	var piece = current_board[pos[0]][pos[1]]
	# Проверяем, является ли шашка дамкой (W для белых, B для черных)
	if piece == 'W' or piece == 'B':
		return true
		
	# Проверяем, достигла ли обычная шашка последней линии
	if piece == 'w' and pos[0] == 0:  # Белая шашка достигла верхнего края
		current_board[pos[0]][pos[1]] = 'W'  # Превращаем в дамку
		return true
	elif piece == 'b' and pos[0] == 7:  # Черная шашка достигла нижнего края
		current_board[pos[0]][pos[1]] = 'B'  # Превращаем в дамку
		return true
		
	return false

func get_possible_moves(color: String) -> Array:
	var moves = []
	var has_captures = false
	
	# Сначала ищем все возможные взятия
	for i in range(8):
		for j in range(8):
			if (color == 'w' and (current_board[i][j] == 'w' or current_board[i][j] == 'W')) or \
			   (color == 'b' and (current_board[i][j] == 'b' or current_board[i][j] == 'B')):
				var capture_moves = get_capture_moves(Vector2i(i, j))
				if capture_moves.size() > 0:
					moves.append_array(capture_moves)
					has_captures = true
	
	# Если нет взятий, добавляем обычные ходы
	if not has_captures:
		for i in range(8):
			for j in range(8):
				if color == 'w':
					if current_board[i][j] == 'w':
						# Обычные ходы для белых шашек
						for dx in [-1, 1]:
							if i > 0 and 0 <= j + dx < 8:
								if current_board[i-1][j+dx] == ' ':
									moves.append([Vector2i(i, j), Vector2i(i-1, j+dx)])
					elif current_board[i][j] == 'W':
						# Ходы для белых дамок
						var king_moves = get_king_moves(Vector2i(i, j))
						moves.append_array(king_moves)
				else:  # color == 'b'
					if current_board[i][j] == 'b':
						# Обычные ходы для черных шашек
						for dx in [-1, 1]:
							if i < 7 and 0 <= j + dx < 8:
								if current_board[i+1][j+dx] == ' ':
									moves.append([Vector2i(i, j), Vector2i(i+1, j+dx)])
					elif current_board[i][j] == 'B':
						# Ходы для черных дамок
						var king_moves = get_king_moves(Vector2i(i, j))
						moves.append_array(king_moves)
	
	return moves

func get_capture_moves(pos: Vector2i) -> Array:
	var moves = []
	var piece = current_board[pos.x][pos.y]
	var is_king = piece == 'W' or piece == 'B'
	var king_directions = [[1,1], [1,-1], [-1,1], [-1,-1]]
	
	if is_king:
		# Логика взятия для дамки
		for dir in king_directions:
			var k = 1
			while pos.x + k * dir[0] < 7 and pos.y + k * dir[1] < 7 and \
				  pos.x + k * dir[0] >= 0 and pos.y + k * dir[1] >= 0:
				var curr_pos = Vector2i(pos.x + k * dir[0], pos.y + k * dir[1])
				var next_pos = Vector2i(pos.x + (k + 1) * dir[0], pos.y + (k + 1) * dir[1])
				
				if not is_valid_position(next_pos):
					break
					
				var curr_piece = current_board[curr_pos.x][curr_pos.y]
				if curr_piece != ' ':
					if is_enemy_piece(piece, curr_piece) and current_board[next_pos.x][next_pos.y] == ' ':
						# Создаем временную доску для проверки следующих взятий
						var temp_board = current_board.duplicate(true)
						temp_board[pos.x][pos.y] = ' '
						temp_board[curr_pos.x][curr_pos.y] = ' '
						temp_board[next_pos.x][next_pos.y] = piece
						
						var next_captures = get_next_captures(next_pos, temp_board)
						if next_captures.empty():
							moves.append([pos, next_pos, curr_pos])
						else:
							for capture in next_captures:
								var full_capture = [pos]
								full_capture.append_array(capture)
								moves.append(full_capture)
					break
				k += 1
	else:
		# Логика взятия для обычной шашки
		var pawn_directions = [[2,2], [2,-2], [-2,2], [-2,-2]]
		for dir in pawn_directions:
			var new_pos = Vector2i(pos.x + dir[0], pos.y + dir[1])
			var jumped_pos = Vector2i(pos.x + dir[0]/2, pos.y + dir[1]/2)
			
			if is_valid_position(new_pos) and current_board[new_pos.x][new_pos.y] == ' ':
				var jumped_piece = current_board[jumped_pos.x][jumped_pos.y]
				if is_enemy_piece(piece, jumped_piece):
					# Создаем временную доску для проверки следующих взятий
					var temp_board = current_board.duplicate(true)
					temp_board[pos.x][pos.y] = ' '
					temp_board[jumped_pos.x][jumped_pos.y] = ' '
					temp_board[new_pos.x][new_pos.y] = piece
					
					var next_captures = get_next_captures(new_pos, temp_board)
					if next_captures.empty():
						moves.append([pos, new_pos, jumped_pos])
					else:
						for capture in next_captures:
							var full_capture = [pos]
							full_capture.append_array(capture)
							moves.append(full_capture)
	
	return moves

func get_next_captures(pos: Vector2i, temp_board: Array) -> Array:
	var moves = []
	var piece = temp_board[pos.x][pos.y]
	var is_king = piece == 'W' or piece == 'B'
	
	if is_king:
		# Рекурсивный поиск взятий для дамки
		var king_directions = [[1,1], [1,-1], [-1,1], [-1,-1]]
		for dir in king_directions:
			var k = 1
			while pos.x + k * dir[0] < 7 and pos.y + k * dir[1] < 7 and \
				  pos.x + k * dir[0] >= 0 and pos.y + k * dir[1] >= 0:
				var curr_pos = Vector2i(pos.x + k * dir[0], pos.y + k * dir[1])
				var next_pos = Vector2i(pos.x + (k + 1) * dir[0], pos.y + (k + 1) * dir[1])
				
				if not is_valid_position(next_pos):
					break
					
				var curr_piece = temp_board[curr_pos.x][curr_pos.y]
				if curr_piece != ' ':
					if is_enemy_piece(piece, curr_piece) and temp_board[next_pos.x][next_pos.y] == ' ':
						var new_temp_board = temp_board.duplicate(true)
						new_temp_board[pos.x][pos.y] = ' '
						new_temp_board[curr_pos.x][curr_pos.y] = ' '
						new_temp_board[next_pos.x][next_pos.y] = piece
						
						var next_moves = get_next_captures(next_pos, new_temp_board)
						if next_moves.empty():
							moves.append([next_pos])
						else:
							for move in next_moves:
								var full_move = [next_pos]
								full_move.append_array(move)
								moves.append(full_move)
					break
				k += 1
	else:
		# Рекурсивный поиск взятий для обычной шашки
		var pawn_directions = [[2,2], [2,-2], [-2,2], [-2,-2]]
		for dir in pawn_directions:
			var new_pos = Vector2i(pos.x + dir[0], pos.y + dir[1])
			var jumped_pos = Vector2i(pos.x + dir[0]/2, pos.y + dir[1]/2)
			
			if is_valid_position(new_pos) and temp_board[new_pos.x][new_pos.y] == ' ':
				var jumped_piece = temp_board[jumped_pos.x][jumped_pos.y]
				if is_enemy_piece(piece, jumped_piece):
					var new_temp_board = temp_board.duplicate(true)
					new_temp_board[pos.x][pos.y] = ' '
					new_temp_board[jumped_pos.x][jumped_pos.y] = ' '
					new_temp_board[new_pos.x][new_pos.y] = piece
					
					var next_moves = get_next_captures(new_pos, new_temp_board)
					if next_moves.empty():
						moves.append([new_pos])
					else:
						for move in next_moves:
							var full_move = [new_pos]
							full_move.append_array(move)
							moves.append(full_move)
	
	return moves

func is_valid_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8

func is_enemy_piece(piece: String, other_piece: String) -> bool:
	return (piece.to_lower() == 'w' and other_piece.to_lower() == 'b') or \
		   (piece.to_lower() == 'b' and other_piece.to_lower() == 'w')

func get_king_moves(pos: Vector2i) -> Array:
	var moves = []
	var piece = current_board[pos.x][pos.y]
	var directions = [[1,1], [1,-1], [-1,1], [-1,-1]]
	
	for dir in directions:
		var k = 1
		while true:
			var new_x = pos.x + k * dir[0]
			var new_y = pos.y + k * dir[1]
			
			if not (0 <= new_x < 8 and 0 <= new_y < 8):
				break
				
			if current_board[new_x][new_y] != ' ':
				# Проверяем возможность взятия
				if is_enemy_piece(piece, current_board[new_x][new_y]):
					var next_x = new_x + dir[0]
					var next_y = new_y + dir[1]
					if 0 <= next_x < 8 and 0 <= next_y < 8 and current_board[next_x][next_y] == ' ':
						moves.append([Vector2i(pos.x, pos.y), Vector2i(next_x, next_y), Vector2i(new_x, new_y)])
				break
			
			moves.append([Vector2i(pos.x, pos.y), Vector2i(new_x, new_y)])
			k += 1
	
	return moves
