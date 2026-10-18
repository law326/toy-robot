# frozen_string_literal: true

module ToyRobot
  # Command-line entry point: toy_robot [-v|--verbose] [-h|--help] FILE
  class CLI
    USAGE = <<~TEXT
      Usage: toy_robot [options] FILE
          -v, --verbose   Log ignored commands to stderr
          -h, --help      Show this help
    TEXT

    VERBOSE_FLAGS = %w[-v --verbose].freeze

    def initialize(argv, stdout: $stdout, stderr: $stderr)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
    end

    def run
      flags, files = @argv.partition { |arg| arg.start_with?('-') }
      return help if flags.intersect?(%w[-h --help])

      problem = usage_problem(flags, files)
      return usage_error(problem) if problem

      simulate(files.first, verbose: !flags.empty?)
    rescue SystemCallError => e
      @stderr.puts("toy_robot: #{e.message}")
      1
    end

    private

    def usage_problem(flags, files)
      unknown = flags - VERBOSE_FLAGS
      return "unknown option #{unknown.first}" unless unknown.empty?

      return 'missing input file' if files.empty?

      'too many arguments' if files.size > 1
    end

    def simulate(path, verbose:)
      simulator = Simulator.new(robot: Robot.new(Table.new), output: @stdout,
                                log: (@stderr if verbose))
      File.open(path) { |file| simulator.run(file) }
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
