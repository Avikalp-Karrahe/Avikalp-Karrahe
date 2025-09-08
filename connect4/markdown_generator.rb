require_relative './game'

module Connect4
  class MarkdownGenerator
    PIECE_URLS = {
      Game::EMPTY => 'https://raw.githubusercontent.com/Avikalp-Karrahe/Avikalp-Karrahe/main/images/blank.svg',
      Game::RED => 'https://raw.githubusercontent.com/Avikalp-Karrahe/Avikalp-Karrahe/main/images/red.svg',
      Game::BLUE => 'https://raw.githubusercontent.com/Avikalp-Karrahe/Avikalp-Karrahe/main/images/blue.svg'
    }.freeze

    def initialize(repository:, game:, recent_moves: [], leaderboard: {})
      @repository = repository
      @game = game
      @recent_moves = recent_moves
      @leaderboard = leaderboard
    end

    def generate_game_section
      <<~MARKDOWN
        ## 🎮 Join my community Connect Four game!
        ![](https://img.shields.io/badge/Moves%20played-#{@game.moves_played}-blue)
        ![](https://img.shields.io/badge/Game%20status-#{game_status}-#{status_color})
        ![](https://img.shields.io/badge/Current%20turn-#{current_player_name}-#{current_player_color})

        Everyone is welcome to participate! To make a move, click on the **column number** you wish to drop your disk in.

        #{game_status_message}

        #{generate_board}

        #{generate_ai_link}

        **⏰ Most recent moves**
        #{generate_recent_moves_table}

        **🏆 Leaderboard: Top 10 players with the most game winning moves 🥇**
        #{generate_leaderboard_table}
      MARKDOWN
    end

    private

    def game_status
      return 'Finished' if @game.game_over
      'Active'
    end

    def status_color
      return 'red' if @game.game_over
      'brightgreen'
    end

    def current_player_name
      return 'Game Over' if @game.game_over
      @game.current_player == Game::RED ? 'Red' : 'Blue'
    end

    def current_player_color
      return 'lightgrey' if @game.game_over
      @game.current_player == Game::RED ? 'red' : 'blue'
    end

    def game_status_message
      if @game.game_over
        if @game.winner
          winner_name = @game.winner == Game::RED ? 'Red' : 'Blue'
          "🎉 **#{winner_name}** team wins! [Start a new game](#{new_game_url}) to play again."
        else
          "🤝 It's a tie! [Start a new game](#{new_game_url}) to play again."
        end
      else
        "It is the **#{current_player_name.downcase}** team's turn to play."
      end
    end

    def generate_board
      header = (1..Game::COLUMNS).map do |col|
        if @game.game_over
          col.to_s
        else
          "[#{col}](#{move_url(col - 1)})"
        end
      end.join('|')

      separator = Array.new(Game::COLUMNS, ' - ').join('|')
      
      rows = @game.board.map do |row|
        row.map { |cell| "![](#{PIECE_URLS[cell]})" }.join('|')
      end

      "|#{header}|\n|#{separator}|\n" + rows.map { |row| "|#{row}|" }.join("\n")
    end

    def generate_ai_link
      return "" if @game.game_over
      
      "Tired of waiting? [Request a move](#{ai_move_url}) from Connect4Bot 🤖"
    end

    def generate_recent_moves_table
      return "| Team | Move | Made by |\n| ---- | ---- | ------- |\n| - | - | - |" if @recent_moves.empty?

      header = "| Team | Move | Made by |\n| ---- | ---- | ------- |"
      rows = @recent_moves.first(3).map do |move|
        team = move[:team] == Game::RED ? 'Red' : 'Blue'
        column = move[:column] + 1
        user = move[:user] ? "[@#{move[:user]}](https://github.com/#{move[:user]})" : 'Connect4Bot 🤖'
        "| #{team} | #{column} | #{user} |"
      end
      
      "#{header}\n#{rows.join("\n")}"
    end

    def generate_leaderboard_table
      return "| Player | Wins |\n| ------ | -----|\n| - | - |" if @leaderboard.empty?

      header = "| Player | Wins |\n| ------ | -----|"  
      rows = @leaderboard.first(10).map do |entry|
        player = entry[:user] ? "[@#{entry[:user]}](https://github.com/#{entry[:user]})" : 'Connect4Bot 🤖'
        wins = entry[:wins]
        "| #{player} | #{wins} |"
      end
      
      "#{header}\n#{rows.join("\n")}"
    end

    def move_url(column)
      base_url = "https://github.com/#{@repository}/issues/new"
      title = "connect4|drop|#{@game.current_player == Game::RED ? 'red' : 'blue'}|#{column}"
      body = "Just push 'Submit new issue' without editing the title. The README will be updated after approximately 30 seconds."
      
      "#{base_url}?title=#{CGI.escape(title)}&body=#{CGI.escape(body)}"
    end

    def ai_move_url
      base_url = "https://github.com/#{@repository}/issues/new"
      title = "connect4|drop|#{@game.current_player == Game::RED ? 'red' : 'blue'}|ai"
      body = "Just push 'Submit new issue' without editing the title. The README will be updated after approximately 30 seconds."
      
      "#{base_url}?title=#{CGI.escape(title)}&body=#{CGI.escape(body)}"
    end

    def new_game_url
      base_url = "https://github.com/#{@repository}/issues/new"
      title = "connect4|new"
      body = "Just push 'Submit new issue' without editing the title. The README will be updated after approximately 30 seconds."
      
      "#{base_url}?title=#{CGI.escape(title)}&body=#{CGI.escape(body)}"
    end
  end
end