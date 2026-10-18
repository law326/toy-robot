# frozen_string_literal: true

RSpec.describe ToyRobot::Robot do
  let(:robot) { described_class.new(ToyRobot::Table.new) }

  context 'when not yet placed' do
    it 'ignores everything' do
      expect(robot).not_to be_placed
      expect([robot.move, robot.left, robot.right]).to all(be false)
      expect(robot.report).to be_nil
    end
  end

  describe '#place' do
    it 'places on the table, accepting any case' do
      expect(robot.place(1, 2, 'east')).to be true
      expect(robot.report).to eq('1,2,EAST')
    end

    it 'rejects off-table coordinates and keeps prior state' do
      robot.place(1, 1, 'NORTH')
      [[5, 0], [0, 5], [-1, 0], [0, -1]].each do |x, y|
        expect(robot.place(x, y, 'SOUTH')).to be false
      end
      expect(robot.report).to eq('1,1,NORTH')
    end

    it 'rejects an unknown direction' do
      expect(robot.place(1, 1, 'UP')).to be false
      expect(robot.place(1, 1, nil)).to be false
      expect(robot).not_to be_placed
    end

    it 're-places the robot' do
      robot.place(1, 1, 'NORTH')
      robot.place(3, 3, 'WEST')
      expect(robot.report).to eq('3,3,WEST')
    end
  end

  describe '#move' do
    it 'moves one unit in each direction' do
      { 'NORTH' => '2,3', 'EAST' => '3,2', 'SOUTH' => '2,1', 'WEST' => '1,2' }.each do |d, xy|
        robot.place(2, 2, d)
        expect(robot.move).to be true
        expect(robot.report).to eq("#{xy},#{d}")
      end
    end

    it 'refuses to fall off any edge' do
      [[0, 4, 'NORTH'], [4, 0, 'EAST'], [0, 0, 'SOUTH'], [0, 0, 'WEST']].each do |x, y, d|
        robot.place(x, y, d)
        expect(robot.move).to be false
        expect(robot.report).to eq("#{x},#{y},#{d}")
      end
    end

    it 'allows later valid moves after a refused one' do
      robot.place(0, 0, 'WEST')
      robot.move
      robot.right
      expect(robot.move).to be true
      expect(robot.report).to eq('0,1,NORTH')
    end
  end

  describe 'turning' do
    {
      'NORTH' => %w[WEST EAST], 'EAST' => %w[NORTH SOUTH],
      'SOUTH' => %w[EAST WEST], 'WEST' => %w[SOUTH NORTH]
    }.each do |start, (l, r)|
      it "turns #{start} left to #{l} and right to #{r} without moving" do
        robot.place(0, 0, start)
        expect(robot.left).to be true
        expect(robot.report).to eq("0,0,#{l}")
        robot.place(0, 0, start)
        expect(robot.right).to be true
        expect(robot.report).to eq("0,0,#{r}")
      end
    end

    it 'returns to the start after four turns' do
      robot.place(0, 0, 'NORTH')
      4.times { robot.left }
      expect(robot.report).to eq('0,0,NORTH')
    end
  end
end
