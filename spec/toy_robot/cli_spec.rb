# frozen_string_literal: true

RSpec.describe ToyRobot::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  def cli(argv, stdin: '')
    described_class.new(argv, stdin: StringIO.new(stdin), stdout: stdout, stderr: stderr)
  end

  def with_file(content)
    Tempfile.create('robot') do |f|
      f.write(content)
      f.flush
      yield f.path
    end
  end

  it 'reads commands from a file' do
    with_file("PLACE 1,1,NORTH\nREPORT\n") { |path| expect(cli([path]).run).to eq(0) }
    expect(stdout.string).to eq("1,1,NORTH\n")
  end

  it 'reads from stdin when no file is given' do
    expect(cli([], stdin: "PLACE 2,2,WEST\nREPORT\n").run).to eq(0)
    expect(stdout.string).to eq("2,2,WEST\n")
  end

  it 'reads from stdin when the file is "-"' do
    cli(['-'], stdin: "PLACE 2,2,WEST\nREPORT\n").run
    expect(stdout.string).to eq("2,2,WEST\n")
  end

  it 'logs ignored lines only with --verbose or -v' do
    cli([], stdin: "MOVE\n").run
    expect(stderr.string).to be_empty
    cli(['-v'], stdin: "MOVE\n").run
    cli(['--verbose'], stdin: "MOVE\n").run
    expect(stderr.string.scan('line 1: ignored').size).to eq(2)
  end

  it 'prints help' do
    expect(cli(['--help']).run).to eq(0)
    expect(cli(['-h']).run).to eq(0)
    expect(stdout.string).to include('Usage: toy_robot')
  end

  it 'fails cleanly for a missing file' do
    expect(cli(['/no/such/file.txt']).run).to eq(1)
    expect(stderr.string).to include('No such file')
  end

  it 'fails cleanly for a directory' do
    expect(cli([Dir.tmpdir]).run).to eq(1)
  end

  it 'fails with usage for unknown options' do
    expect(cli(['--bogus']).run).to eq(2)
    expect(stderr.string).to include('unknown option --bogus', 'Usage')
  end

  it 'fails with usage for too many files' do
    expect(cli(%w[a b]).run).to eq(2)
    expect(stderr.string).to include('too many arguments')
  end
end
