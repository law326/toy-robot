# frozen_string_literal: true

module ToyRobot
  # Owns position and heading, and refuses any action that would put it
  # off the table or that is attempted before it has been placed.
  # Every action returns true if it was carried out, false if ignored.
  class Robot
    COMPASS = %w[NORTH EAST SOUTH WEST].freeze
    STEPS = { 'NORTH' => [0, 1], 'EAST' => [1, 0], 'SOUTH' => [0, -1], 'WEST' => [-1, 0] }.freeze

    def initialize(table)
      @table = table
    end

    def placed?
      !@facing.nil?
    end

    def place(x, y, facing)
      facing = facing.to_s.upcase
      return false unless COMPASS.include?(facing) && @table.in_bounds?(x, y)

      @x = x
      @y = y
      @facing = facing
      true
    end

    def move
      return false unless placed?

      dx, dy = STEPS.fetch(@facing)
      return false unless @table.in_bounds?(@x + dx, @y + dy)

      @x += dx
      @y += dy
      true
    end

    def left
      rotate(-1)
    end

    def right
      rotate(1)
    end

    # @return [String, nil] "X,Y,F", or nil if not placed
    def report
      "#{@x},#{@y},#{@facing}" if placed?
    end

    private

    def rotate(offset)
      return false unless placed?

      @facing = COMPASS[(COMPASS.index(@facing) + offset) % COMPASS.size]
      true
    end
  end
end
