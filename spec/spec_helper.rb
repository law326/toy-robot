# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  skip '/spec/'
  minimum_coverage line: 100, branch: 100
end

require 'stringio'
require 'tempfile'
require 'toy_robot'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
end
