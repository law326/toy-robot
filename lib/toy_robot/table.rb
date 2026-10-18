# frozen_string_literal: true

module ToyRobot
  # South-west corner is (0,0).
  class Table
    attr_reader :width, :height

    def initialize(width: 5, height: 5)
      unless [width, height].all? { |d| d.is_a?(Integer) && d.positive? }
        raise ArgumentError, 'table dimensions must be positive integers'
      end

      @width = width
      @height = height
    end

    def walkable?(x, y)
      x.between?(0, width - 1) && y.between?(0, height - 1)
    end
  end
end
