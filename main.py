from checkers_npc import CheckersNPC

def main():
    game = CheckersNPC()
    
    while True:
        # Показываем доску
        game.display_board()
        
        # Ход игрока
        try:
            start_row = int(input("Введите начальную строку: "))
            start_col = int(input("Введите начальный столбец: "))
            end_row = int(input("Введите конечную строку: "))
            end_col = int(input("Введите конечный столбец: "))
            
            # Проверяем и выполняем ход игрока
            move = ((start_row, start_col), (end_row, end_col))
            game._make_move(move)
            
            # Ход ИИ
            if not game.make_ai_move():
                print("ИИ не может сделать ход! Игра окончена.")
                break
                
        except ValueError:
            print("Пожалуйста, введите числа от 0 до 7")
        except IndexError:
            print("Ход выхо��ит за пределы доски")

if __name__ == "__main__":
    main() 