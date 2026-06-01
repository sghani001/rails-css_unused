# frozen_string_literal: true

require "io/console"

module Rails
  module CssUnused
    # A lightweight TTY spinner shown while scanning is in progress.
    # Automatically disabled when output is not a TTY (CI, pipes, file output).
    class Spinner
      FRAMES  = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏].freeze
      BOLD    = "\e[1m"
      CYAN    = "\e[36m"
      GREEN   = "\e[32m"
      YELLOW  = "\e[33m"
      RESET   = "\e[0m"
      CLEAR   = "\r\e[K"   # move to column 0, erase line

      INTERVAL = 0.08  # seconds between frames

      def initialize(output: $stderr)
        @output  = output
        @tty     = output.respond_to?(:isatty) && output.isatty
        @thread  = nil
        @frame   = 0
        @label   = ""
      end

      # Run a block with a spinner, returning the block's return value.
      # The spinner is suppressed when not on a TTY.
      #
      #   result = Spinner.run("Scanning stylesheets") { expensive_work }
      #
      def self.run(label, output: $stderr, &block)
        new(output: output).run(label, &block)
      end

      def run(label, &block)
        @label = label
        start!
        result = block.call
        stop!(success: true)
        result
      rescue => e
        stop!(success: false)
        raise e
      end

      private

      def start!
        return unless @tty

        @running = true
        @thread  = Thread.new do
          while @running
            render_frame
            sleep INTERVAL
          end
        end
      end

      def stop!(success:)
        return unless @tty

        @running = false
        @thread&.join
        @thread = nil

        icon  = success ? "#{GREEN}✔#{RESET}" : "#{YELLOW}✘#{RESET}"
        @output.print "#{CLEAR}#{icon} #{BOLD}#{@label}#{RESET}\n"
      end

      def render_frame
        frame = FRAMES[@frame % FRAMES.size]
        @frame += 1
        @output.print "#{CLEAR}#{CYAN}#{frame}#{RESET} #{BOLD}#{@label}…#{RESET}"
      end
    end
  end
end
