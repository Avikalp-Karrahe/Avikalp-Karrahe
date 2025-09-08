require 'octokit'

module Connect4
  class OctokitClient
    def initialize(github_token:, repository:)
      @client = Octokit::Client.new(access_token: github_token)
      @repository = repository
    end

    def close_issue(issue_number:)
      @client.close_issue(@repository, issue_number)
    end

    def get_file_content(path:)
      @client.contents(@repository, path: path)
    end

    def update_file(path:, content:, message:, sha:)
      @client.update_contents(
        @repository,
        path,
        message,
        sha,
        content
      )
    end

    def create_file(path:, content:, message:)
      @client.create_contents(
        @repository,
        path,
        message,
        content
      )
    end

    def file_exists?(path:)
      @client.contents(@repository, path: path)
      true
    rescue Octokit::NotFound
      false
    end
  end
end