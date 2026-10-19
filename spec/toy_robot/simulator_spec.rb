# frozen_string_literal: true

RSpec.describe ToyRobot::Simulator do
  let(:out) { StringIO.new }
  let(:log) { StringIO.new }
  let(:robot) { ToyRobot::Robot.new(surface: ToyRobot::Table.new) }
  let(:simulator) { described_class.new(robot: robot, output: out, log: log) }

  def run(text) = simulator.run(StringIO.new(text))

  it 'handles the specification examples' do
    run("PLACE 0,0,NORTH\nMOVE\nREPORT\n")
    run("PLACE 0,0,NORTH\nLEFT\nREPORT\n")
    run("PLACE 1,2,EAST\nMOVE\nMOVE\nLEFT\nMOVE\nREPORT\n")
    expect(out.string).to eq("0,1,NORTH\n0,0,WEST\n3,3,NORTH\n")
  end

  it 'discards commands until a valid PLACE' do
    run("MOVE\nLEFT\nRIGHT\nREPORT\nPLACE 5,5,NORTH\nREPORT\nPLACE 1,1,SOUTH\nREPORT\n")
    expect(out.string).to eq("1,1,SOUTH\n")
  end

  it 'ignores falling moves and continues with valid ones' do
    run("PLACE 4,4,NORTH\nMOVE\nREPORT\nRIGHT\nMOVE\nREPORT\nLEFT\nLEFT\nMOVE\nREPORT\n")
    expect(out.string).to eq("4,4,NORTH\n4,4,EAST\n3,4,WEST\n")
  end

  it 'walks the whole perimeter without falling' do
    run("PLACE 0,0,NORTH\n#{"MOVE\n" * 10}RIGHT\n#{"MOVE\n" * 10}RIGHT\n#{"MOVE\n" * 10}" \
        "RIGHT\n#{"MOVE\n" * 10}REPORT\n")
    expect(out.string).to eq("0,0,WEST\n")
  end

  it 'leaves the robot where it was after an invalid PLACE' do
    run("PLACE 2,2,EAST\nPLACE 9,9,WEST\nREPORT\n")
    expect(out.string).to eq("2,2,EAST\n")
  end

  it 're-places the robot on every valid PLACE' do
    run("PLACE 0,0,NORTH\nREPORT\nPLACE 3,3,WEST\nREPORT\nMOVE\nREPORT\n")
    expect(out.string).to eq("0,0,NORTH\n3,3,WEST\n2,3,WEST\n")
  end

  it 'ignores case, whitespace, tabs, CRLF and spaces around commas' do
    run("  place 1, 2 ,North \r\n\tmove\t\r\nreport\r\n")
    expect(out.string).to eq("1,3,NORTH\n")
  end

  it 'skips blank lines and comments, including trailing ones' do
    run("\n   \n# c\nPLACE 1,1,NORTH # start\nMOVE # go\nREPORT\n")
    expect(out.string).to eq("1,2,NORTH\n")
  end

  it 'survives garbage and malformed commands' do
    run("hello\nPLACE\nPLACE 1,2\nPLACE 1,2,UP\nPLACE a,b,NORTH\nPLACE 1.5,2,NORTH\n" \
        "PLACE 1,2,NORTH,3\nPLACE 1 2 NORTH\nPLACE1,1,NORTH\nMOVE 1\nREPORT now\n\u0000\n" \
        "REPORT\nPLACE 1,1,NORTH\nREPORT")
    expect(out.string).to eq("1,1,NORTH\n")
  end

  it 'handles empty input and a last line without a newline' do
    run('')
    run('PLACE 0,0,SOUTH')
    run('REPORT')
    expect(out.string).to eq("0,0,SOUTH\n")
  end

  it 'logs the reason and line number of ignored lines' do
    run("MOVE\nLEFT\nREPORT\nJUMP\nMOVE 1\nPLACE 9,9,NORTH\nPLACE x\nPLACE 4,4,NORTH\nMOVE\n")
    expect(log.string.lines.map(&:chomp)).to eq(
      ['line 1: ignored (robot is not placed)',
       'line 2: ignored (robot is not placed)',
       'line 3: ignored (robot is not placed)',
       'line 4: ignored (unknown command "JUMP")',
       'line 5: ignored (MOVE takes no arguments)',
       'line 6: ignored (invalid placement)',
       'line 7: ignored (PLACE expects X,Y,F but got "x")',
       'line 9: ignored (would fall off the table)']
    )
  end

  it 'rejects negative and oversized PLACE coordinates as invalid placements' do
    run("PLACE -1,0,NORTH\nPLACE 0,-1,NORTH\nPLACE 99999999999999999999,0,NORTH\nREPORT\n")
    expect(out.string).to be_empty
    expect(log.string.lines.map(&:chomp)).to eq(
      ['line 1: ignored (invalid placement)',
       'line 2: ignored (invalid placement)',
       'line 3: ignored (invalid placement)',
       'line 4: ignored (robot is not placed)']
    )
  end

  it 'does not accept non-ASCII digits in PLACE' do
    run("PLACE ９,0,NORTH\nREPORT\n")
    expect(out.string).to be_empty
    expect(log.string).to include('line 1: ignored (PLACE expects X,Y,F')
  end

  it 'treats # inside PLACE arguments as the start of a comment' do
    run("PLACE 1,#1,NORTH\nREPORT\nPLACE 2,2,NORTH#\nREPORT\n")
    expect(out.string).to eq("2,2,NORTH\n")
    expect(log.string.lines.map(&:chomp)).to eq(
      ['line 1: ignored (PLACE expects X,Y,F but got "1,")',
       'line 2: ignored (robot is not placed)']
    )
  end

  it 'logs unknown commands in their original case' do
    run("Jump\nfLy 1\n")
    expect(log.string.lines.map(&:chomp)).to eq(
      ['line 1: ignored (unknown command "Jump")',
       'line 2: ignored (unknown command "fLy")']
    )
  end

  it 'reports the same state on consecutive REPORTs' do
    run("PLACE 2,3,WEST\nREPORT\nREPORT\nREPORT\n")
    expect(out.string).to eq("2,3,WEST\n" * 3)
  end

  it 'works without a log' do
    quiet = described_class.new(robot: robot, output: out)
    expect { quiet.run(StringIO.new("JUMP\n")) }.not_to raise_error
  end

  it 'defaults output to $stdout' do
    expect { described_class.new(robot: robot).run(StringIO.new("PLACE 0,0,NORTH\nREPORT\n")) }
      .to output("0,0,NORTH\n").to_stdout
  end
end
