# frozen_string_literal: true

module ToyRobot
  # Command-line entry point: toy_robot [-v|--verbose] [-h|--help] [FILE]
  # Reads from FILE, or from standard input when FILE is omitted or '-'.
  class CLI
    USAGE = <<~TEXT
      Usage: toy_robot [options] [FILE]
          -v, --verbose   Log ignored commands to stderr
          -h, --help      Show this help
    TEXT

    VERBOSE_FLAGS = %w[-v --verbose].freeze

    def initialize(argv, stdin: $stdin, stdout: $stdout, stderr: $stderr)
      @argv = argv
      @stdin = stdin
      @stdout = stdout
      @stderr = stderr
    end

    # @return [Integer] exit status: 0 ok, 1 unreadable file, 2 bad usage
    def run
      flags, files = @argv.partition { |arg| arg.start_with?('-') && arg != '-' }
      return help if flags.intersect?(%w[-h --help])

      problem = usage_problem(flags, files)
      return usage_error(problem) if problem

      simulate(files.first, verbose: !flags.empty?)
    rescue SystemCallError => e
      @stderr.puts("toy_robot: #{e.message}")
      1
    end

    private

    # @return [String, nil] what is wrong with the arguments, if anything
    def usage_problem(flags, files)
      unknown = flags - VERBOSE_FLAGS
      return "unknown option #{unknown.first}" unless unknown.empty?

      'too many arguments' if files.size > 1
    end

    def simulate(path, verbose:)
      simulator = Simulator.new(robot: Robot.new(Table.new), output: @stdout,
                                log: (@stderr if verbose))
      if path.nil? || path == '-'
        simulator.run(@stdin)
      else
        File.open(path) { |file| simulator.run(file) }
      end
      0
    end

    def help
      @stdout.puts(USAGE)
      0
    end

    def usage_error(message)
      @stderr.puts("toy_robot: #{message}", USAGE)
      2
    end
  end
end
