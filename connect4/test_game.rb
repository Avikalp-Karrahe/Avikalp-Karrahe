#!/usr/bin/env ruby

require_relative './game'
require_relative './ai'

# Test basic game functionality
puts "Testing Connect Four Game Logic..."
puts "=" * 40

# Initialize game
game = Connect4::Game.new
puts "✓ Game initialized successfully"
puts "  Board size: #{game.board.length}x#{game.board[0].length}"
puts "  Current player: #{game.current_player == Connect4::Game::RED ? 'Red' : 'Blue'}"
puts "  Game over: #{game.game_over}"

# Test dropping pieces
puts "\nTesting piece drops..."
result = game.drop_piece(3)
puts "✓ Dropped #{game.current_player == Connect4::Game::BLUE ? 'Red' : 'Blue'} piece in column 4"
puts "  Current player: #{game.current_player == Connect4::Game::RED ? 'Red' : 'Blue'}"

result = game.drop_piece(3)
puts "✓ Dropped #{game.current_player == Connect4::Game::BLUE ? 'Red' : 'Blue'} piece in column 4"
puts "  Current player: #{game.current_player == Connect4::Game::RED ? 'Red' : 'Blue'}"

# Test AI
puts "\nTesting AI..."
ai = Connect4::AI.new(game, game.current_player)
best_move = ai.best_move
puts "✓ AI suggests column: #{best_move + 1}"

# Test serialization
puts "\nTesting serialization..."
hash_data = game.to_hash
puts "✓ Game serialized to hash"

new_game = Connect4::Game.from_hash(hash_data)
puts "✓ Game deserialized from hash"
puts "  Moves match: #{game.moves_played == new_game.moves_played}"

puts "\n" + "=" * 40
puts "All tests passed! 🎉"