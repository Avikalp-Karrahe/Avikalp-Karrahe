require_relative './invalid_move_error'

module Connect4
  class Game
    ROWS = 6
    COLUMNS = 7
    EMPTY = 0
    RED = 1
    BLUE = 2

    attr_reader :board, :current_player, :winner, :game_over, :moves_played

    def initialize(board: nil, current_player: BLUE, winner: nil, game_over: false, moves_played: 0)
      @board = board || Array.new(ROWS) { Array.new(COLUMNS, EMPTY) }
      @current_player = current_player
      @winner = winner
      @game_over = game_over
      @moves_played = moves_played
    end

    def drop_piece(column)
      raise InvalidMoveError, "Game is already over" if @game_over
      raise InvalidMoveError, "Invalid column: #{column}" unless (0...COLUMNS).include?(column)
      raise InvalidMoveError, "Column #{column + 1} is full" if column_full?(column)

      row = find_lowest_empty_row(column)
      @board[row][column] = @current_player
      @moves_played += 1

      if winning_move?(row, column)
        @winner = @current_player
        @game_over = true
      elsif board_full?
        @game_over = true
      else
        @current_player = @current_player == RED ? BLUE : RED
      end

      { row: row, column: column }
    end

    def valid_moves
      (0...COLUMNS).select { |col| !column_full?(col) }
    end

    def to_hash
      {
        board: @board,
        current_player: @current_player,
        winner: @winner,
        game_over: @game_over,
        moves_played: @moves_played
      }
    end

    def self.from_hash(hash)
      new(
        board: hash[:board],
        current_player: hash[:current_player],
        winner: hash[:winner],
        game_over: hash[:game_over],
        moves_played: hash[:moves_played]
      )
    end

    private

    def column_full?(column)
      @board[0][column] != EMPTY
    end

    def board_full?
      @board[0].all? { |cell| cell != EMPTY }
    end

    def find_lowest_empty_row(column)
      (ROWS - 1).downto(0) do |row|
        return row if @board[row][column] == EMPTY
      end
    end

    def winning_move?(row, column)
      player = @board[row][column]
      
      # Check horizontal
      return true if check_direction(row, column, 0, 1, player) >= 4
      
      # Check vertical
      return true if check_direction(row, column, 1, 0, player) >= 4
      
      # Check diagonal (top-left to bottom-right)
      return true if check_direction(row, column, 1, 1, player) >= 4
      
      # Check diagonal (top-right to bottom-left)
      return true if check_direction(row, column, 1, -1, player) >= 4
      
      false
    end

    def check_direction(row, column, row_delta, col_delta, player)
      count = 1 # Count the current piece
      
      # Check in positive direction
      r, c = row + row_delta, column + col_delta
      while r >= 0 && r < ROWS && c >= 0 && c < COLUMNS && @board[r][c] == player
        count += 1
        r += row_delta
        c += col_delta
      end
      
      # Check in negative direction
      r, c = row - row_delta, column - col_delta
      while r >= 0 && r < ROWS && c >= 0 && c < COLUMNS && @board[r][c] == player
        count += 1
        r -= row_delta
        c -= col_delta
      end
      
      count
    end
  end
end