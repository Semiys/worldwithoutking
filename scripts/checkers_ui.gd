extends CanvasLayer

signal move_made(start_pos, end_pos)

var selected_piece = null
var board_buttons = []
var current_board = []
var current_game = null

func setup(game):
	current_game = game

func _ready():
	layer = 100
	create_board()
	$CenterContainer/Panel/VBoxContainer/CloseButton.grab_focus()
	get_tree().paused = true
	print("UI создан")  # Отладка

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
					for pos in move:  # Подсвечиваем все позиции в цепочке взятия
						var end_button = board_buttons[pos[0]][pos[1]]
						var end_style = end_button.get_theme_stylebox("normal").duplicate()
						end_style.bg_color = Color(0, 1, 0, 0.3)
						end_button.add_theme_stylebox_override("normal", end_style)
	else:
		var start_pos = selected_piece
		var end_pos = [row, col]
		
		if is_valid_move(start_pos, end_pos):
			# Находим полный ход с множественным взятием
			var full_move = null
			var all_moves = current_game.get_possible_moves(current_game.player_color)
			for move in all_moves:
				if move[0] == start_pos:
					# Проверяем, является ли выбранная позиция частью этого хода
					if end_pos in move:
						# Выполняем все промежуточные ходы
						var start_idx = move.find(start_pos)
						var end_idx = move.find(end_pos)
						var partial_move = move.slice(start_idx, end_idx + 1)
						full_move = partial_move
						break
			
			if full_move != null:
				# Выполняем каждый ход в цепочке
				for i in range(full_move.size() - 1):
					emit_signal("move_made", full_move[i], full_move[i + 1])
					await get_tree().create_timer(0.3).timeout  # Небольшая пауза между ходами
			else:
				emit_signal("move_made", start_pos, end_pos)
		
		# Убираем подсветку со всех клеток
		for r in range(8):
			for c in range(8):
				var button = board_buttons[r][c]
				var style = button.get_theme_stylebox("normal").duplicate()
				style.bg_color = Color(0.8, 0.8, 0.8, 0.9) if (r + c) % 2 == 0 else Color(0.3, 0.3, 0.3, 0.9)
				button.add_theme_stylebox_override("normal", style)
		
		selected_piece = null

func is_valid_move(start_pos: Array, end_pos: Array) -> bool:
	# Получаем все возможные ходы
	var all_moves = current_game.get_possible_moves(current_game.player_color)
	
	# Находим все ходы с взятием
	var capture_moves = []
	for move in all_moves:
		if move.size() > 2 or (move.size() == 2 and abs(move[0][0] - move[1][0]) == 2):
			capture_moves.append(move)
	
	# Если есть ходы с взятием
	if capture_moves.size() > 0:
		# Ищем самый длинный ход с взятием, начинающийся с выбранной позиции
		var best_capture = null
		var max_captures = 0
		
		for move in capture_moves:
			if move[0] == start_pos:
				if move.size() > max_captures:
					max_captures = move.size()
					best_capture = move
		
		# Если нашли подходящий ход с взятием
		if best_capture != null:
			# Проверяем, является ли конечная позиция частью этого хода
			return end_pos in best_capture
		return false
	
	# Если нет обязательных взятий, проверяем обычный ход
	if current_board[end_pos[0]][end_pos[1]] != ' ':
		return false
	
	var is_king = current_game.is_king(start_pos)
	
	if is_king:
		var dx = abs(end_pos[1] - start_pos[1])
		var dy = abs(end_pos[0] - start_pos[0])
		
		# Проверяем диагональность хода
		if dx != dy:
			return false
			
		# Проверяем путь и возможность взятия
		var dir_x = sign(end_pos[1] - start_pos[1])
		var dir_y = sign(end_pos[0] - start_pos[0])
		var x = start_pos[1] + dir_x
		var y = start_pos[0] + dir_y
		var enemy_found = false
		var enemy_pos = null
		
		while x != end_pos[1] and y != end_pos[0]:
			if current_board[y][x] != ' ':
				if enemy_found:  # Если уже нашли одну фигуру
					return false  # Путь заблокирован
				if current_board[y][x] == 'b':  # Нашли вражескую фигуру
					enemy_found = true
					enemy_pos = [y, x]
				else:
					return false  # Своя фигура на пути
			x += dir_x
			y += dir_y
		
		return !enemy_found or (enemy_found and enemy_pos != null)
	else:
		# Логика для обычной шашки
		if end_pos[0] >= start_pos[0]:  # Запрещаем ход назад
			return false
			
		var dx = abs(end_pos[1] - start_pos[1])
		var dy = abs(end_pos[0] - start_pos[0])
		
		if dx == 1 and dy == 1:
			return true
		elif dx == 2 and dy == 2:
			var middle_row = (start_pos[0] + end_pos[0]) / 2
			var middle_col = (start_pos[1] + end_pos[1]) / 2
			return current_board[middle_row][middle_col] == 'b'
	
	return false

func _on_close_button_pressed():
	print("Кнопка закрытия нажата")  # Отладка
	queue_free()
