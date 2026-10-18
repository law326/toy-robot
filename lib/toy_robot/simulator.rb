# frozen_string_literal: true

module ToyRobot
  # Interprets lines of text as robot commands; bad lines are skipped, never fatal.
  # Case, surrounding whitespace, blank lines and `#` comments are ignored.
  class Simulator
    PLACE_ARGS = /\A(-?\d+)\s*,\s*(-?\d+)\s*,\s*([A-Za-z]+)\z/

    def initialize(robot:, output: $stdout, log: nil)
      @robot = robot
      @output = output
      @log = log
    end

    def run(input)
      input.each_line.with_index(1) do |line, number|
        text = line.sub(/#.*/, '').strip
        next if text.empty?

        problem = execute(*text.split(/\s+/, 2))
        @log&.puts("line #{number}: ignored (#{problem})") if problem
      end
    end

    private

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

    # Runs the block only if the robot is placed and no arguments were given.
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
