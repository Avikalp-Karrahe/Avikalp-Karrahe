require_relative './game'

require 'cgi'

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
        <div align="center">
        
        # 🎮 **CONNECT FOUR CHAMPIONSHIP** 🏆
        ### *Join the Ultimate GitHub Gaming Experience!*
        
        </div>
        
        ---
        
        <div align="center">
        
        ![Moves](https://img.shields.io/badge/🎯_Moves_Played-#{@game.moves_played}-4c1?style=for-the-badge&logo=target&logoColor=white)
        ![Status](https://img.shields.io/badge/🚀_Game_Status-#{game_status}-#{status_color}?style=for-the-badge&logo=gamepad&logoColor=white)
        ![Turn](https://img.shields.io/badge/⚡_Current_Turn-#{current_player_name}-#{current_player_color}?style=for-the-badge&logo=bolt&logoColor=white)
        
        </div>
        
        ---
        
        <div align="center">
        
        ### 🎯 **HOW TO PLAY**
        **Click any column number below to drop your piece!** 🪙
        
        #{enhanced_game_status_message}
        
        </div>
        
        ---
        
        <div align="center">
        
        ### ⭐ **GAME BOARD** ⭐
        
        </div>
        
        #{generate_enhanced_board}
        
        <div align="center">
        
        #{generate_enhanced_ai_link}
        
        </div>
        
        ---
        
        <div align="center">
        
        ### ⚡ **RECENT BATTLES** ⚡
        
        </div>
        
        #{generate_enhanced_recent_moves_table}
        
        ---
        
        <div align="center">
        
        ### 🏆 **HALL OF FAME** 🏆
        *Top Champions with the Most Victories*
        
        </div>
        
        #{generate_enhanced_leaderboard_table}
        
        ---
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

    def enhanced_game_status_message
      if @game.game_over
        if @game.winner
          winner_name = @game.winner == Game::RED ? '🔴 **RED TEAM**' : '🔵 **BLUE TEAM**'
          winner_emoji = @game.winner == Game::RED ? '🎊🔥' : '💎⚡'
          "\n\n## #{winner_emoji} #{winner_name} WINS! #{winner_emoji}\n\n🚀 **[START NEW CHAMPIONSHIP](#{new_game_url})** 🚀\n\n*Ready for another epic battle?*\n\n"
        else
          "\n\n## 🤝 **EPIC TIE GAME!** 🤝\n\n🔥 **[REMATCH TIME!](#{new_game_url})** 🔥\n\n*Both teams fought valiantly!*\n\n"
        end
      else
        current_emoji = @game.current_player == Game::RED ? '🔴' : '🔵'
        turn_message = @game.current_player == Game::RED ? '**RED TEAM** - Your move!' : '**BLUE TEAM** - Your turn!'
        "\n\n## #{current_emoji} #{turn_message} #{current_emoji}\n\n*Choose your column wisely... Victory awaits!* ⚔️\n\n"
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

    def generate_enhanced_board
      # Column headers with enhanced styling
      header_row = (1..Game::COLUMNS).map do |col|
        if @game.game_over
          "**#{col}**"
        else
          "**[#{col}](#{move_url(col - 1)})**"
        end
      end

      # Enhanced board with better spacing and alignment
      board_content = <<~BOARD
        <div align="center">
        
        | #{header_row.join(' | ')} |
        |#{Array.new(Game::COLUMNS, ':---:').join('|')}|
      BOARD

      # Add each row of the game board
      @game.board.each do |row|
        row_content = row.map { |cell| "![](#{PIECE_URLS[cell]})" }.join(' | ')
        board_content += "| #{row_content} |\n"
      end

      # Add column selection buttons if game is active
      unless @game.game_over
        button_row = (1..Game::COLUMNS).map do |col|
          "[![Drop](https://img.shields.io/badge/DROP-#{col}-blue?style=for-the-badge)](#{move_url(col - 1)})"
        end
        board_content += "\n#{button_row.join(' ')}\n"
      end

      board_content += "\n</div>\n"
      board_content
    end

    def generate_ai_link
      return "" if @game.game_over
      
      "Tired of waiting? [Request a move](#{ai_move_url}) from Connect4Bot 🤖"
    end

    def generate_enhanced_ai_link
      return "" if @game.game_over
      
      <<~AI_LINK
        
        ### 🤖 **AI ASSISTANT** 🤖
        
        [![AI Move](https://img.shields.io/badge/🤖_REQUEST_AI_MOVE-CLICK_HERE-purple?style=for-the-badge&logo=robot&logoColor=white)](#{ai_move_url})
        
        *Let our AI make the next strategic move for you!*
        
      AI_LINK
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

    def generate_enhanced_recent_moves_table
      if @recent_moves.empty?
        return <<~EMPTY_MOVES
          <div align="center">
          
          | 🎯 **Team** | 🎪 **Column** | 👤 **Player** | 📅 **Time** |
          |:---:|:---:|:---:|:---:|
          | 🎮 | *No moves yet* | *Be the first!* | ⏰ |
          
          </div>
        EMPTY_MOVES
      end

      header = <<~HEADER
        <div align="center">
        
        | 🎯 **Team** | 🎪 **Column** | 👤 **Player** | 📅 **Recent** |
        |:---:|:---:|:---:|:---:|
      HEADER
      
      rows = @recent_moves.first(5).map do |move|
        team_emoji = move[:team] == Game::RED ? '🔴' : '🔵'
        team_name = move[:team] == Game::RED ? '**RED**' : '**BLUE**'
        column = "**#{move[:column] + 1}**"
        user = move[:user] ? "[@#{move[:user]}](https://github.com/#{move[:user]})" : '🤖 **AI**'
        time_ago = move[:created_at] ? time_ago_in_words(move[:created_at]) : 'Just now'
        "| #{team_emoji} #{team_name} | #{column} | #{user} | #{time_ago} |"
      end
      
      "#{header}#{rows.join("\n")}\n\n</div>\n"
    end

    def time_ago_in_words(time)
      return 'Just now' unless time
      
      seconds = Time.now - time
      case seconds
      when 0..59
        '⚡ Just now'
      when 60..3599
        "🕐 #{(seconds / 60).to_i}m ago"
      when 3600..86399
        "🕑 #{(seconds / 3600).to_i}h ago"
      else
        "📅 #{(seconds / 86400).to_i}d ago"
      end
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

    def generate_enhanced_leaderboard_table
      if @leaderboard.empty?
        return <<~EMPTY_LEADERBOARD
          <div align="center">
          
          | 🏆 **Rank** | 👑 **Champion** | 🎯 **Victories** | 🔥 **Status** |
          |:---:|:---:|:---:|:---:|
          | 🥇 | *No champions yet* | *0* | 🎮 *Be the first legend!* |
          
          </div>
        EMPTY_LEADERBOARD
      end

      header = <<~HEADER
        <div align="center">
        
        | 🏆 **Rank** | 👑 **Champion** | 🎯 **Victories** | 🔥 **Status** |
        |:---:|:---:|:---:|:---:|
      HEADER
      
      rows = @leaderboard.first(10).each_with_index.map do |entry, index|
        rank_emoji = case index
                     when 0 then '🥇'
                     when 1 then '🥈' 
                     when 2 then '🥉'
                     else "**#{index + 1}**"
                     end
        
        player = entry[:user] ? "[@#{entry[:user]}](https://github.com/#{entry[:user]})" : '🤖 **AI Master**'
        wins = "**#{entry[:wins]}**"
        
        status = case entry[:wins]
                when 0..2 then '🌱 *Rising*'
                when 3..5 then '⚡ *Skilled*'
                when 6..9 then '🔥 *Expert*'
                when 10..19 then '💎 *Master*'
                else '👑 *LEGEND*'
                end
        
        "| #{rank_emoji} | #{player} | #{wins} | #{status} |"
      end
      
      "#{header}#{rows.join("\n")}\n\n</div>\n"
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