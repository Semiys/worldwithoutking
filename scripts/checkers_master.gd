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
		var direction = 1 if color == 'black' else -1
		
		# Сначала проверяем ходы с захватом
		var capture_moves = []
		
		# Проверяем все шашки на возможность захвата
		for row in range(8):
			for col in range(8):
				if board[row][col] == piece:
					var is_king = is_king([row, col])
					# Для дамок проверяем все направления
					var directions = [-2, 2] if not is_king else range(-7, 8)
					
					for dy in directions:
						for dx in directions:
							if abs(dx) < 2 or abs(dy) < 2:
								continue
							
							var new_row = row + dy
							var new_col = col + dx
							
							if new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8:
								var middle_row = row + dy/2
								var middle_col = col + dx/2
								
								if board[new_row][new_col] == ' ':
									var opposite_piece = 'w' if color == 'black' else 'b'
									if board[middle_row][middle_col] == opposite_piece:
										# Проверяем возможность множественного захвата
										var multi_captures = get_additional_captures([new_row, new_col], color, is_king)
										if multi_captures.size() > 0:
											for capture in multi_captures:
												var full_capture = [[row, col]]
												full_capture.append_array(capture)
												capture_moves.append(full_capture)
										else:
											capture_moves.append([[row, col], [new_row, new_col]])
		
		# Если есть ходы с захватом, они обязательны
		if capture_moves.size() > 0:
			return capture_moves
		
		# Если нет ходов с захватом, проверяем обычные ходы
		for row in range(8):
			for col in range(8):
				if board[row][col] == piece:
					var is_king = is_king([row, col])
					# Для обычных шашек - только вперед, для дамок - в любом направлении
					var directions = [-1, 1] if is_king else [direction]
					var dx_range = [-1, 1]
					
					for dy in directions:
						for dx in dx_range:
							var new_row = row + dy
							var new_col = col + dx
							
							if new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8:
								if board[new_row][new_col] == ' ':
									moves.append([[row, col], [new_row, new_col]])
		
		return moves

	# Функция для проверки дополнительных захватов (множественный захват)
	func get_additional_captures(start_pos: Array, color: String, is_king: bool) -> Array:
		var additional_moves = []
		var piece = 'b' if color == 'black' else 'w'
		
		# Временно помещаем шашку на новую позицию
		var original_piece = board[start_pos[0]][start_pos[1]]
		board[start_pos[0]][start_pos[1]] = piece
		
		# Проверяем возможные захваты с новой позиции
		for dy in [-2, 2]:
			for dx in [-2, 2]:
				var new_row = start_pos[0] + dy
				var new_col = start_pos[1] + dx
				
				if new_row >= 0 and new_row < 8 and new_col >= 0 and new_col < 8:
					var middle_row = start_pos[0] + dy/2
					var middle_col = start_pos[1] + dx/2
					
					if board[new_row][new_col] == ' ':
						var opposite_piece = 'w' if color == 'black' else 'b'
						if board[middle_row][middle_col] == opposite_piece:
							var next_captures = get_additional_captures([new_row, new_col], color, is_king)
							if next_captures.size() > 0:
								for capture in next_captures:
									var full_capture = [start_pos]
									full_capture.append_array(capture)
									additional_moves.append(full_capture)
							else:
								additional_moves.append([start_pos, [new_row, new_col]])
		
		# Возвращаем шашку на место
		board[start_pos[0]][start_pos[1]] = original_piece
		
		return additional_moves

	func make_move(move):
		# Если это множественный захват
		if move.size() > 2:
			for i in range(move.size() - 1):
				var start = move[i]
				var end = move[i + 1]
				
				var piece = board[start[0]][start[1]]
				var was_king = is_king(start)
				
				# Очищаем начальную позицию и убираем из списка дамок
				board[start[0]][start[1]] = ' '
				if was_king and start in kings:
					kings.erase(start)
				
				# Устанавливаем шашку на новую позицию
				board[end[0]][end[1]] = piece
				
				# Если шашка была дамкой, добавляем новую позицию в список дамок
				if was_king:
					kings.append(end)
				
				# Удаляем захваченную шашку
				var middle_row = (start[0] + end[0]) / 2
				var middle_col = (start[1] + end[1]) / 2
				
				# Если бьем дамку, удаляем её из списка
				if [middle_row, middle_col] in kings:
					kings.erase([middle_row, middle_col])
				board[middle_row][middle_col] = ' '
				
				# Проверяем на превращение в дамку
				check_for_king(end, piece)
		else:
			var start = move[0]
			var end = move[1]
			
			var piece = board[start[0]][start[1]]
			var was_king = is_king(start)
			
			board[start[0]][start[1]] = ' '
			if was_king and start in kings:
				kings.erase(start)
			
			board[end[0]][end[1]] = piece
			
			if was_king:
				kings.append(end)
			
			if abs(start[0] - end[0]) == 2:
				var middle_row = (start[0] + end[0]) / 2
				var middle_col = (start[1] + end[1]) / 2
				if [middle_row, middle_col] in kings:
					kings.erase([middle_row, middle_col])
				board[middle_row][middle_col] = ' '
			
			# Проверяем на превращение в дамку
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
	
	# Создаем спрайт
	var sprite = ColorRect.new()
	sprite.size = Vector2(32, 32)
	sprite.position = Vector2(-16, -16)  # Центрируем спрайт
	sprite.color = Color(0.7, 0.3, 0.3)  # Красноватый цвет
	add_child(sprite)
	
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
		
		# Проверяем, есть ли еще ходы с взятием для той же шашки
		var more_captures = false
		var possible_moves = current_game.get_possible_moves(current_game.player_color)
		for move in possible_moves:
			if move[0] == end_pos and move.size() > 2:
				more_captures = true
				break
		
		if not more_captures:
			# Даём небольшую паузу для анимации
			await get_tree().create_timer(0.5).timeout
			
			# Ход ИИ
			var ai_moves = current_game.get_possible_moves(current_game.ai_color)
			
			if ai_moves.size() > 0:
				var success = current_game.make_ai_move()
				if success:
					update_game_display()
					await get_tree().create_timer(0.5).timeout
					
					var player_moves = current_game.get_possible_moves(current_game.player_color)
					if player_moves.size() == 0:
						show_victory_message("ИИ победил!")
						await get_tree().create_timer(1.0).timeout
						end_game()
			else:
				show_victory_message("Вы победили!")
				await get_tree().create_timer(1.0).timeout
				end_game()

func show_victory_message(message: String):
	var victory_label = Label.new()
	victory_label.text = message
	victory_label.position = Vector2(-100, -60)
	add_child(victory_label)
	
	await get_tree().create_timer(2.0).timeout
	victory_label.queue_free()
