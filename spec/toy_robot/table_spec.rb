# frozen_string_literal: true

RSpec.describe ToyRobot::Table do
  let(:table) { described_class.new }

  it 'defaults to 5x5' do
    expect([table.width, table.height]).to eq([5, 5])
  end

  it 'accepts all four corners' do
    [[0, 0], [4, 0], [0, 4], [4, 4]].each { |x, y| expect(table.walkable?(x, y)).to be true }
  end

  it 'rejects positions just outside each edge' do
    [[-1, 0], [0, -1], [5, 0], [0, 5], [5, 5], [-1, -1], [100, 2]].each do |x, y|
      expect(table.walkable?(x, y)).to be false
    end
  end

  it 'supports custom sizes' do
    t = described_class.new(width: 2, height: 3)
    expect(t.walkable?(1, 2)).to be true
    expect(t.walkable?(2, 2)).to be false
    expect(t.walkable?(1, 3)).to be false
  end

  it 'rejects invalid dimensions' do
    [[0, 5], [5, 0], [-1, 5], [5.5, 5], ['5', 5]].each do |w, h|
      expect { described_class.new(width: w, height: h) }.to raise_error(ArgumentError)
    end
  end
end
