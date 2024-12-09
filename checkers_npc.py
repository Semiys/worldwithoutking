import random

class CheckersNPC:
    def __init__(self):
        self.board = self._create_initial_board()
        self.ai_color = 'black'
        self.player_color = 'white'
        
    def _create_initial_board(self):
        # Создаем доску 8x8
        board = [[' ' for _ in range(8)] for _ in range(8)]
        
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
                    
        return board
    
    def make_ai_move(self):
        # Простая ИИ логика: находим все возможные ходы и выбираем случайный
        possible_moves = self._get_possible_moves(self.ai_color)
        if possible_moves:
            move = random.choice(possible_moves)
            self._make_move(move)
            return True
        return False
    
    def _get_possible_moves(self, color):
        moves = []
        piece = 'b' if color == 'black' else 'w'
        
        for row in range(8):
            for col in range(8):
                if self.board[row][col] == piece:
                    # Проверяем возможные ходы для каждой шашки
                    direction = -1 if color == 'black' else 1
                    
                    # Проверяем обычные ходы
                    for dx in [-1, 1]:
                        new_row = row + direction
                        new_col = col + dx
                        
                        if 0 <= new_row < 8 and 0 <= new_col < 8:
                            if self.board[new_row][new_col] == ' ':
                                moves.append(((row, col), (new_row, new_col)))
                    
                    # Проверяем ходы с захватом
                    for dx in [-2, 2]:
                        new_row = row + 2 * direction
                        new_col = col + dx
                        
                        if 0 <= new_row < 8 and 0 <= new_col < 8:
                            middle_row = row + direction
                            middle_col = col + dx // 2
                            
                            if self.board[new_row][new_col] == ' ':
                                opposite_piece = 'w' if color == 'black' else 'b'
                                if self.board[middle_row][middle_col] == opposite_piece:
                                    moves.append(((row, col), (new_row, new_col)))
        
        return moves
    
    def _make_move(self, move):
        start, end = move
        self.board[end[0]][end[1]] = self.board[start[0]][start[1]]
        self.board[start[0]][start[1]] = ' '
        
        # Если это был ход с захватом, удаляем захваченную шашку
        if abs(start[0] - end[0]) == 2:
            middle_row = (start[0] + end[0]) // 2
            middle_col = (start[1] + end[1]) // 2
            self.board[middle_row][middle_col] = ' '
    
    def display_board(self):
        print('  0 1 2 3 4 5 6 7')
        for i, row in enumerate(self.board):
            print(f'{i} {" ".join(row)}') 