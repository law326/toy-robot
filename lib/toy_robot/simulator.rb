# frozen_string_literal: true

module ToyRobot
  # Interprets lines of text as commands for a robot. Invalid or rejected
  # lines are skipped (and optionally logged), never fatal.
  #
  # Case, surrounding whitespace, blank lines and `#` comments are ignored.
  class Simulator
    PLACE_ARGS = /\A(-?\d+)\s*,\s*(-?\d+)\s*,\s*([A-Za-z]+)\z/

    # @param output [#puts] receives REPORT output
    # @param log [#puts, nil] receives a note for each ignored line
    def initialize(robot:, output: $stdout, log: nil)
      @robot = robot
      @output = output
      @log = log
    end

    # @param input [#each_line]
    def run(input)
      input.each_line.with_index(1) do |line, number|
        text = line.sub(/#.*/, '').strip
        next if text.empty?

        problem = execute(*text.split(/\s+/, 2))
        @log&.puts("line #{number}: ignored (#{problem})") if problem
      end
    end

    private

    # @return [String, nil] why the command was ignored, or nil on success
    def execute(word, args = nil)
      name = word.upcase

      case name
      when 'PLACE'  then place(args)
      when 'MOVE'   then command(name, args) { 'would fall off the table' unless @robot.move }
      when 'LEFT'   then command(name, args) { @robot.left && nil }
      when 'RIGHT'  then command(name, args) { @robot.right && nil }
      when 'REPORT' then command(name, args) { @output.puts(@robot.report) }
      else               "unknown command #{word.inspect}"
      end
    end

    # Shared preconditions for every command except PLACE; runs the block
    # only if they hold.
    # @return [String, nil] why the command was ignored, or nil on success
    def command(name, args)
      return "#{name} takes no arguments" if args
      return 'robot is not placed' unless @robot.placed?

      yield
    end

    def place(args)
      match = PLACE_ARGS.match(args.to_s)
      return "PLACE expects X,Y,F but got #{args.inspect}" unless match

      x, y, facing = match.captures
      'invalid placement' unless @robot.place(x.to_i, y.to_i, facing)
    end
  end
end
