extends CharacterBody2D

class CheckersGame:
	var board = []
	var kings = []  # Массив для хранения дамок
	var ai_color = 'black'
	var player_color = 'white'
	var game_active = false
	
	func _init():
		create_initial_board()
		kings = []  # Инициализируем пустой массив дамок
	
	# Добавим метод для проверки, является ли шашка дамкой
	func is_king(pos: Array) -> bool:
		return pos in kings
	
	# Метод для превращения в дамку
	func check_for_king(pos: Array, piece: String):
		if piece == 'w' and pos[0] == 0:  # Белая шашка дошла до верхнего края
			if not pos in kings:
				kings.append(pos)
		elif piece == 'b' and pos[0] == 7:  # Черная шашка дошла до нижнего края
			if not pos in kings:
				kings.append(pos)
	
	func create_initial_board():
		# Создаем доску 8x8
		board = []
		for _i in range(8):
			var row = []
			for _j in range(8):
				row.append(' ')
			board.append(row)
		
		# Расставляем черные шашки
		for row in range(3):
			for col in range(8):
				if (row + col) % 2 == 1:
					board[row][col] = 'b'
					
		# Расставляем белые шашки
		for row in range(5, 8):
			for col in range(8):
				if (row + col) % 2 == 1:
					board[row][col] = 'w'

	func get_possible_moves(color):
		var moves = []
		var piece = 'b' if color == 'black' else 'w'
		var opposite_piece = 'w' if color == 'black' else 'b'
		var direction = 1 if color == 'black' else -1
		
		# Сначала проверяем ходы с захватом
		var capture_moves = []
		
		# Проверяем все шашки на возможность захвата
		for row in range(8):
			for col in range(8):
				if board[row][col] == piece:
					var is_king = is_king([row, col])
					
					if is_king:
						# Проверяем все диагональные направления для дамки
						var directions = [[-1,-1], [-1,1], [1,-1], [1,1]]
						for dir in directions:
							var curr_row = row
							var curr_col = col
							
							while true:
								var next_row = curr_row + dir[0]
								var next_col = curr_col + dir[1]
								
								# Проверяем границы доски и черные клетки
								if next_row < 0 or next_row >= 8 or next_col < 0 or next_col >= 8 or (next_row + next_col) % 2 == 0:
									break
								
								# Если нашли вражескую фигуру
								if board[next_row][next_col] == opposite_piece:
									# Проверяем следующую клетку в том же направлении
									var jump_row = next_row + dir[0]
									var jump_col = next_col + dir[1]
									
									# Проверяем, можем ли приземлиться после взятия
									if jump_row >= 0 and jump_row < 8 and jump_col >= 0 and jump_col < 8 and board[jump_row][jump_col] == ' ':
										capture_moves.append([[row, col], [jump_row, jump_col]])
									break
								elif board[next_row][next_col] != ' ':
									break
								
								curr_row = next_row
								curr_col = next_col
					else:
						# Обычное взятие для простой шашки
						for dy in [-2, 2]:
							for dx in [-2, 2]:
								var new_row = row + dy
								var new_col = col + dx
								
								if new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8 and (new_row + new_col) % 2 == 1:
									var middle_row = row + dy/2
									var middle_col = col + dx/2
									
									if board[new_row][new_col] == ' ' and board[middle_row][middle_col] == opposite_piece:
										capture_moves.append([[row, col], [new_row, new_col]])
		
		# Если есть ходы с захватом, они обязательны
		if capture_moves.size() > 0:
			return capture_moves
		
		# Если нет ходов с захватом, проверяем обычные ходы
		for row in range(8):
			for col in range(8):
				if board[row][col] == piece:
					var is_king = is_king([row, col])
					
					if is_king:
						# Ходы дамки по диагоналям на любое расстояние
						var directions = [[-1,-1], [-1,1], [1,-1], [1,1]]
						for dir in directions:
							var curr_row = row
							var curr_col = col
							
							while true:
								var next_row = curr_row + dir[0]
								var next_col = curr_col + dir[1]
								
								# Проверяем границы доски и черные клетки
								if next_row < 0 or next_row >= 8 or next_col < 0 or next_col >= 8 or (next_row + next_col) % 2 == 0:
									break
								
								if board[next_row][next_col] == ' ':
									moves.append([[row, col], [next_row, next_col]])
								else:
									break
								
								curr_row = next_row
								curr_col = next_col
					else:
						# Обычные ходы для простой шашки
						for dx in [-1, 1]:
							var new_row = row + direction
							var new_col = col + dx
							
							if new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8 and (new_row + new_col) % 2 == 1:
								if board[new_row][new_col] == ' ':
									moves.append([[row, col], [new_row, new_col]])
		
		return moves

	func make_move(move):
		var start = move[0]
		var end = move[1]
		
		var piece = board[start[0]][start[1]]
		var was_king = false
		
		# Проверяем, является ли фигура дамкой
		for king in kings:
			if king[0] == start[0] and king[1] == start[1]:
				was_king = true
				kings.erase(king)
				break
		
		# Убираем фигуру с начальной позиции
		board[start[0]][start[1]] = ' '
		
		# Ставим фигуру на конечную позицию
		board[end[0]][end[1]] = piece
		
		# Если была дамкой, добавляем новую позицию в список дамок
		if was_king:
			kings.append(end)
		
		# Проверяем было ли взятие
		var dx = end[1] - start[1]
		var dy = end[0] - start[0]
		

		if abs(dx) > 1 or abs(dy) > 1:  # Если ход больше чем на одну клетку - это взятие
			# Определяем направление движения
			var dir_x = sign(dx)
			var dir_y = sign(dy)
			var curr_row = start[0]
			var curr_col = start[1]
			
			# Ищем вражескую фигуру на пути
			while curr_row != end[0] and curr_col != end[1]:
				curr_row += dir_y
				curr_col += dir_x
				
				if board[curr_row][curr_col] != ' ':
					# Нашли фигуру - удаляем её
					for king in kings:
						if king[0] == curr_row and king[1] == curr_col:
							kings.erase(king)
							break
					board[curr_row][curr_col] = ' '
					break
		
		# Проверяем на превращение в дамку только для обычных шашек
		if not was_king:
			check_for_king(end, piece)

		# Проверяем на превращение в дамк��
		check_for_king(end, piece)


	func make_ai_move():
		var possible_moves = get_possible_moves(ai_color)
		
		# Оцениваем каждый возможный ход
		var best_move = null
		var best_score = -1000
		
		for move in possible_moves:
			var score = evaluate_move(move)
			if score > best_score:
				best_score = score
				best_move = move
		
		if best_move:
			make_move(best_move)
			return true
		
		return false

	func evaluate_move(move) -> float:
		var score = 0.0
		
		# Симулируем ход для оценки
		var board_copy = []
		var kings_copy = []
		for row in board:
			board_copy.append(row.duplicate())
		for king in kings:
			kings_copy.append(king.duplicate())
		
		# Делаем ход на копии
		make_move(move)
		
		# Оцениваем позицию после хода
		score = evaluate_position()
		
		# Смотрим на 3 хода вперед
		score += look_ahead(3, -1000, 1000, true) * 0.5
		
		# Возвращаем доску в исходное состояние
		board = board_copy
		kings = kings_copy
		
		return score

	func look_ahead(depth: int, alpha: float, beta: float, is_maximizing: bool) -> float:
		if depth == 0:
			return evaluate_position()
		
		if is_maximizing:
			var max_eval = -1000.0
			var moves = get_possible_moves(ai_color)
			for move in moves:
				# Сохраняем состояние
				var board_copy = []
				var kings_copy = []
				for row in board:
					board_copy.append(row.duplicate())
				for king in kings:
					kings_copy.append(king.duplicate())
				
				# Делаем ход
				make_move(move)
				var eval = look_ahead(depth - 1, alpha, beta, false)
				
				# Возвращаем состояние
				board = board_copy
				kings = kings_copy
				
				max_eval = max(max_eval, eval)
				alpha = max(alpha, eval)
				if beta <= alpha:
					break
			return max_eval
		else:
			var min_eval = 1000.0
			var moves = get_possible_moves(player_color)
			for move in moves:
				# Сохраняем состояние
				var board_copy = []
				var kings_copy = []
				for row in board:
					board_copy.append(row.duplicate())
				for king in kings:
					kings_copy.append(king.duplicate())
				
				# Делаем ход
				make_move(move)
				var eval = look_ahead(depth - 1, alpha, beta, true)
				
				# Возвращаем состояние
				board = board_copy
				kings = kings_copy
				
				min_eval = min(min_eval, eval)
				beta = min(beta, eval)
				if beta <= alpha:
					break
			return min_eval

	func evaluate_position() -> float:
		var score = 0.0
		
		# Подсчет фигур
		for row in range(8):
			for col in range(8):
				if board[row][col] == 'b':
					score += 10.0  # Базовая ценность шашки
					if is_king([row, col]):
						score += 15.0  # Дополнительные очки за дамку
					
					# Позиционные бонусы
					if row < 4:  # Продвижение вперед
						score += row * 0.5
					if is_protected([row, col]):
						score += 2.0
				elif board[row][col] == 'w':
					score -= 10.0
					if is_king([row, col]):
						score -= 15.0
					
					if row > 3:
						score -= (7 - row) * 0.5
		
		# Контроль центра
		for row in range(2, 6):
			for col in range(2, 6):
				if board[row][col] == 'b':
					score += 1.0
		
		# Защита краев
		for row in range(8):
			if board[row][0] == 'b' or board[row][7] == 'b':
				score += 0.5
		
		return score

	func is_protected(pos: Array) -> bool:
		var row = pos[0]
		var col = pos[1]
		
		# Проверяем, есть ли рядом дружественные шашки
		for dx in [-1, 1]:
			for dy in [-1, 1]:
				var new_row = row + dy
				var new_col = col + dx
				if new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8:
					if board[new_row][new_col] == 'b':
						return true
		
		return false

	func check_victory(color: String) -> bool:
		var opponent_color = 'black' if color == 'white' else 'white'
		var opponent_piece = 'b' if color == 'white' else 'w'
		
		# Проверяем наличие фигур противника
		var has_pieces = false
		for row in range(8):
			for col in range(8):
				if board[row][col] == opponent_piece:
					has_pieces = true
					break
			if has_pieces:
				break
		
		# Проверяем наличие ходов у противника
		if has_pieces:
			var opponent_moves = get_possible_moves(opponent_color)
			return opponent_moves.size() == 0
			
		return true  # Нет фигур - победа

var current_game = null
var game_ui = null
var interaction_area: Area2D
var can_interact = false

func _ready():
	# Создаем простую коллизию
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	add_child(collision)
	
	# Создаем область взаимодействия
	interaction_area = Area2D.new()
	var interaction_shape = CollisionShape2D.new()
	var interaction_circle = CircleShape2D.new()
	interaction_circle.radius = 50.0
	interaction_shape.shape = interaction_circle
	interaction_area.add_child(interaction_shape)
	add_child(interaction_area)
	
	# Подключаем сигналы
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# Создаем подсказку
	var prompt = Label.new()
	prompt.text = "Нажмите E для игры"
	prompt.position = Vector2(-50, -40)
	prompt.visible = false
	prompt.name = "InteractionPrompt"
	add_child(prompt)

func _on_body_entered(body):
	if body.is_in_group("player"):
		can_interact = true
		$InteractionPrompt.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		$InteractionPrompt.visible = false
		end_game()

func _input(event):
	if event.is_action_pressed("interact") and can_interact:
		if current_game == null:
			start_game()
		else:
			end_game()

func start_game():
	current_game = CheckersGame.new()
	current_game.game_active = true
	
	if is_instance_valid(game_ui):
		game_ui.queue_free()
	
	# Добавляем UI к текущей сцене вместо корневого узла
	game_ui = preload("res://scenes/checkers_ui.tscn").instantiate()
	game_ui.setup(current_game)  # Передаем ссылку на игру в UI
	
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(game_ui)
	else:
		get_parent().add_child(game_ui)
		
	game_ui.move_made.connect(_on_player_move)
	update_game_display()

func end_game():
	if is_instance_valid(game_ui):
			game_ui.queue_free()
			game_ui = null
	current_game = null

func update_game_display():
	if current_game and game_ui:
		game_ui.update_board(current_game.board)

func _on_player_move(start_pos, end_pos):
	if current_game and current_game.game_active:
		# Делаем ход игрока
		current_game.make_move([start_pos, end_pos])
		update_game_display()
		
		# Проверяем победу белых (игрока)
		if current_game.check_victory('white'):
			show_victory_message("Белые победили!")
			return
		
		# Ход ИИ
		var ai_moves = current_game.get_possible_moves(current_game.ai_color)
		
		if ai_moves.size() > 0:
			var success = current_game.make_ai_move()
			if success:
				update_game_display()
				
				# Проверяем победу черных (ИИ)
				if current_game.check_victory('black'):
					show_victory_message("Черные победили!")
					return

func show_victory_message(message: String):
	if is_instance_valid(game_ui):
		# Создаем затемнение
		var dim = ColorRect.new()
		dim.color = Color(0, 0, 0, 0.5)
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		# Создаем панель сообщения
		var panel = Panel.new()
		panel.set_anchors_preset(Control.PRESET_CENTER)
		panel.custom_minimum_size = Vector2(300, 150)
		
		# Создаем контейнер для содержимого
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Создаем текст сообщения
		var label = Label.new()
		label.text = message
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		
		# Создаем кнопку закрытия
		var button = Button.new()
		button.text = "Закрыть"
		button.custom_minimum_size = Vector2(100, 40)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		
		# Добавляем элементы в контейнер
		vbox.add_child(label)
		vbox.add_child(button)
		panel.add_child(vbox)
		
		# Добавляем все на экран
		game_ui.add_child(dim)
		game_ui.add_child(panel)
		
		# Подключаем сигнал кнопки
		button.pressed.connect(func():
			dim.queue_free()
			panel.queue_free()
			end_game()
		)
