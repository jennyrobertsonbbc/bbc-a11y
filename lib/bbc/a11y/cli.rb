require 'bbc/a11y/configuration'
require 'bbc/a11y/linter'
require 'open-uri'
require 'capybara'

module BBC
  module A11y

    # A very thin wrapper around Cucumber which takes settings on the command-line,
    # stores them somewhere our automation code will be able to find it, and then
    # runs Cucumber
    class CLI
      def initialize(stdin, stdout, stderr, args)
        @stdin, @stdout, @stderr, @args = stdin, stdout, stderr, args
      end

      def call
        all_errors = []
        settings.pages.each do |page|
          errors = check_standards_for(page.url)
          if errors.empty?
            stdout.puts "✓ #{page.url}"
          else
            stdout.puts "✗ #{page.url}"
            stdout.puts errors.map { |error|
              "  - #{error}"
            }.join("\n")
          end
          all_errors += errors
        end
        exit 1 unless all_errors.empty?
      rescue Configuration::ParseError => error
        exit_with_message error.message
      end

      private

      def check_standards_for(url)
        html = open(url).read
        Linter.new(Capybara.string(html)).run.errors.to_a
      end

      def settings
        return Configuration.for_urls(@args) if @args.any?
        configuration_file = File.expand_path("a11y.rb")
        Configuration.parse(configuration_file)
      end

      def exit_with_message(*messages)
        messages.each { |message| stderr.puts message }
        exit 1
      end

      attr_reader :stdin, :stderr, :stdout, :args
      private :stdin, :stderr, :stdout, :args

      HELP = %{
Usage: a11y [url]
}

    end
  end
end
