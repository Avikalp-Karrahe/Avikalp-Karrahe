#!/usr/bin/env ruby

require_relative 'game'
require_relative 'markdown_generator'

# Create a sample game with some moves
game = Connect4::Game.new

# Make some sample moves to show the enhanced UI
game.drop_piece(3)  # Red move in column 4
game.drop_piece(3)  # Blue move in column 4
game.drop_piece(2)  # Red move in column 3
game.drop_piece(4)  # Blue move in column 5
game.drop_piece(1)  # Red move in column 2

# Sample recent moves data
recent_moves = [
  { team: Connect4::Game::RED, column: 3, user: 'Avikalp-Karrahe', created_at: Time.now - 300 },
  { team: Connect4::Game::BLUE, column: 3, user: 'testuser1', created_at: Time.now - 600 },
  { team: Connect4::Game::RED, column: 2, user: 'Avikalp-Karrahe', created_at: Time.now - 900 },
  { team: Connect4::Game::BLUE, column: 4, user: nil, created_at: Time.now - 1200 },  # AI move
  { team: Connect4::Game::RED, column: 1, user: 'testuser2', created_at: Time.now - 1500 }
]

# Sample leaderboard data
leaderboard = [
  { user: 'Avikalp-Karrahe', wins: 15 },
  { user: 'testuser1', wins: 8 },
  { user: 'testuser2', wins: 5 },
  { user: 'gamemaster', wins: 12 },
  { user: nil, wins: 3 }  # AI wins
]

# Generate enhanced markdown
generator = Connect4::MarkdownGenerator.new(
  repository: 'Avikalp-Karrahe/Avikalp-Karrahe',
  game: game,
  recent_moves: recent_moves,
  leaderboard: leaderboard
)

# Generate and display the enhanced game section
enhanced_section = generator.generate_game_section

puts "=" * 80
puts "ENHANCED CONNECT FOUR UI PREVIEW"
puts "=" * 80
puts
puts enhanced_section
puts
puts "=" * 80
puts "Preview generated successfully! Check the output above."
puts "=" * 80

# Also write to a file for easy viewing
File.write('enhanced_ui_preview.md', enhanced_section)
puts "\nEnhanced UI preview saved to: enhanced_ui_preview.md"
puts "You can view this file to see the enhanced Connect Four game UI!"