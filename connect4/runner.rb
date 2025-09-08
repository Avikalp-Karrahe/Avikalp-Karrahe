require_relative './game'
require_relative './ai'
require_relative './octokit_client'
require_relative './markdown_generator'
require_relative './synchronization_error'
require_relative './malformed_command_error'
require_relative './invalid_move_error'

require 'yaml'
require 'base64'
require 'cgi'

module Connect4
  class Runner
    GAME_DATA_PATH = 'connect4/connect4.yml'
    METADATA_FILE_PATH = 'connect4/metadata.yml'
    README_PATH = 'README.md'

    def initialize(
      github_token:,
      issue_number:,
      issue_title:,
      repository:,
      user:,
      development: false
    )
      @github_token = github_token
      @repository = repository
      @issue_number = issue_number
      @issue_title = issue_title
      @user = user
      @development = development
      @client = OctokitClient.new(github_token: github_token, repository: repository)
    end

    def run
      split_input = @issue_title.split('|')
      command = split_input[1]
      team = split_input[2]
      move = split_input[3]

      acknowledge_issue

      if command == 'drop'
        handle_move(team: team, move: move)
      elsif command == 'new'
        handle_new_game
      else
        raise MalformedCommandError, "unrecognized command: #{command}"
      end

      write_game_state(command: command, team: team, move: move)
    rescue InvalidMoveError, MalformedCommandError => e
      puts "Error: #{e.message}"
    end

    private

    def acknowledge_issue
      @client.close_issue(issue_number: @issue_number)
    end

    def handle_move(team:, move:)
      game_data = load_game_data
      game = Game.from_hash(game_data[:game])
      
      raise InvalidMoveError, "Game is over" if game.game_over
      
      expected_team = game.current_player == Game::RED ? 'red' : 'blue'
      raise InvalidMoveError, "It's #{expected_team} team's turn" unless team == expected_team

      if move == 'ai'
        ai = AI.new(game, game.current_player)
        column = ai.best_move
        user = nil
      else
        column = move.to_i
        raise InvalidMoveError, "Invalid column: #{move}" unless (1..Game::COLUMNS).include?(column)
        column -= 1 # Convert to 0-based index
        user = @user
      end

      result = game.drop_piece(column)
      
      # Update recent moves
      game_data[:recent_moves].unshift({
        team: game.current_player == Game::RED ? Game::BLUE : Game::RED, # Previous player
        column: column,
        user: user
      })
      game_data[:recent_moves] = game_data[:recent_moves].first(10)
      
      # Update leaderboard if game is won
      if game.winner && user
        update_leaderboard(game_data[:leaderboard], user)
      end
      
      game_data[:game] = game.to_hash
    end

    def handle_new_game
      game_data = load_game_data
      game_data[:game] = Game.new.to_hash
      # Keep recent moves and leaderboard
    end

    def load_game_data
      if @client.file_exists?(path: GAME_DATA_PATH)
        content = @client.get_file_content(path: GAME_DATA_PATH)
        yaml_content = Base64.decode64(content.content)
        data = YAML.safe_load(yaml_content)
        
        # Handle case where data might not be a hash
        if data.is_a?(Hash)
          # Convert string keys to symbols for consistency
          {
            game: data['game'] || data[:game] || Game.new.to_hash,
            recent_moves: data['recent_moves'] || data[:recent_moves] || [],
            leaderboard: data['leaderboard'] || data[:leaderboard] || []
          }
        else
          # If data is not a hash, start fresh
          {
            game: Game.new.to_hash,
            recent_moves: [],
            leaderboard: []
          }
        end
      else
        {
          game: Game.new.to_hash,
          recent_moves: [],
          leaderboard: []
        }
      end
    end

    def update_leaderboard(leaderboard, user)
      entry = leaderboard.find { |e| e[:user] == user }
      if entry
        entry[:wins] += 1
      else
        leaderboard << { user: user, wins: 1 }
      end
      leaderboard.sort_by! { |e| -e[:wins] }
    end

    def write_game_state(command:, team:, move:)
      game_data = load_game_data
      
      # Save game data
      yaml_content = YAML.dump(game_data)
      encoded_content = Base64.strict_encode64(yaml_content)
      
      if @client.file_exists?(path: GAME_DATA_PATH)
        current_file = @client.get_file_content(path: GAME_DATA_PATH)
        @client.update_file(
          path: GAME_DATA_PATH,
          content: encoded_content,
          message: "Update game state: #{command} #{team} #{move}",
          sha: current_file.sha
        )
      else
        @client.create_file(
          path: GAME_DATA_PATH,
          content: encoded_content,
          message: "Initialize Connect Four game"
        )
      end
      
      # Update README
      update_readme(game_data)
    end

    def update_readme(game_data)
      game = Game.from_hash(game_data[:game])
      generator = MarkdownGenerator.new(
        repository: @repository,
        game: game,
        recent_moves: game_data[:recent_moves],
        leaderboard: game_data[:leaderboard]
      )
      
      # Get current README
      readme_file = @client.get_file_content(path: README_PATH)
      current_content = Base64.decode64(readme_file.content).force_encoding('UTF-8')
      
      # Replace or add game section
      game_section = generator.generate_game_section
      
      # Simple approach: if game section exists, replace it; otherwise add it
      if current_content.include?('🎮 **CONNECT FOUR CHAMPIONSHIP**')
        # Find the start and end of the game section
        start_marker = '🎮 **CONNECT FOUR CHAMPIONSHIP**'
        end_marker = '## 🌟 Why the Best Companies Choose Me'
        
        start_index = current_content.index(start_marker)
        end_index = current_content.index(end_marker)
        
        if start_index && end_index
          # Replace the section between markers
          before_section = current_content[0...start_index]
          after_section = current_content[end_index..-1]
          updated_content = before_section + game_section + "\n\n" + after_section
        else
          # Fallback: just append
          updated_content = current_content + "\n\n" + game_section + "\n"
        end
      else
        # Add game section before "Why the Best Companies Choose Me"
        if current_content.include?('## 🌟 Why the Best Companies Choose Me')
          updated_content = current_content.gsub(
            '## 🌟 Why the Best Companies Choose Me',
            game_section + "\n\n## 🌟 Why the Best Companies Choose Me"
          )
        else
          # Add at the end
          updated_content = current_content + "\n\n" + game_section + "\n"
        end
      end
      
      @client.update_file(
        path: README_PATH,
        content: updated_content,
        message: "Update Connect Four game board",
        sha: readme_file.sha
      )
    end
  end
end