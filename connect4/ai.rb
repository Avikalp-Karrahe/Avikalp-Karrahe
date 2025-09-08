require_relative './game'

module Connect4
  class AI
    def initialize(game, player)
      @game = game
      @player = player
    end

    def best_move
      # Try to win first
      winning_move = find_winning_move(@player)
      return winning_move if winning_move

      # Block opponent from winning
      opponent = @player == Game::RED ? Game::BLUE : Game::RED
      blocking_move = find_winning_move(opponent)
      return blocking_move if blocking_move

      # Take center column if available
      center = Game::COLUMNS / 2
      return center if @game.valid_moves.include?(center)

      # Take random valid move
      @game.valid_moves.sample
    end

    private

    def find_winning_move(player)
      @game.valid_moves.each do |column|
        # Simulate the move
        test_game = Game.from_hash(@game.to_hash)
        test_game.instance_variable_set(:@current_player, player)
        
        begin
          test_game.drop_piece(column)
          return column if test_game.winner == player
        rescue InvalidMoveError
          next
        end
      end
      nil
    end
  end
end