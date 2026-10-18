# frozen_string_literal: true

module ToyRobot
  # Owns position and heading; refuses unsafe or premature actions.
  # Every action returns true if carried out, false if ignored.
  class Robot
    STEPS = { 'NORTH' => [0, 1], 'EAST' => [1, 0], 'SOUTH' => [0, -1], 'WEST' => [-1, 0] }.freeze
    COMPASS = STEPS.keys.freeze

    def initialize(surface:)
      @surface = surface
    end

    def placed?
      !@facing.nil?
    end

    def place(x, y, facing)
      facing = facing.to_s.upcase
      return false unless COMPASS.include?(facing) && @surface.walkable?(x, y)

      @x = x
      @y = y
      @facing = facing
      true
    end

    def move
      return false unless placed?

      dx, dy = STEPS.fetch(@facing)
      return false unless @surface.walkable?(@x + dx, @y + dy)

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
