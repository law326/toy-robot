# Toy Robot Simulator

A Ruby simulation of a toy robot roaming a 5x5 table. Commands are read from a
text file (or standard input). The robot can never fall off the table.

## Requirements

- Ruby 3.0+ (developed on 3.4)
- Bundler (only needed for running the tests)

## Build / install

There is nothing to compile. The application itself uses only the Ruby standard
library. For the test tooling:

```sh
bundle install
```

## Run

```sh
bin/toy_robot examples/basic.txt        # from a file
bin/toy_robot < examples/basic.txt      # from stdin
cat examples/basic.txt | bin/toy_robot -
bin/toy_robot --verbose examples/edges.txt   # also log ignored lines to stderr
bin/toy_robot --help
```

Exit status: `0` success, `1` file cannot be read, `2` bad command-line usage.
Invalid *commands* never abort the run; they are skipped.

### Input format

One command per line:

| Command         | Effect                                                    |
|-----------------|-----------------------------------------------------------|
| `PLACE X,Y,F`   | Put robot at X,Y facing `NORTH`/`EAST`/`SOUTH`/`WEST`      |
| `MOVE`          | Move one unit forward                                     |
| `LEFT`/`RIGHT`  | Rotate 90° without moving                                 |
| `REPORT`        | Print `X,Y,F` to standard output                          |

(0,0) is the south-west corner; valid coordinates are 0–4.

Example:

```
PLACE 1,2,EAST
MOVE
MOVE
LEFT
MOVE
REPORT
```
outputs `3,3,NORTH`.

### Rules and edge cases handled

- Everything before the first **valid** `PLACE` is ignored (including `REPORT`).
- A `PLACE` outside 0–4 (including negatives) is ignored; if the robot was
  already placed it stays where it was. A later valid `PLACE` re-places it.
- A `MOVE` that would fall off the table is ignored; later commands still work.
- Commands and directions are case-insensitive; leading/trailing whitespace,
  tabs, CRLF line endings and spaces around the commas (`PLACE 1, 2, north`)
  are accepted.
- Blank lines and `#` comments (whole-line or trailing) are ignored.
- Unknown commands, missing/extra/non-integer `PLACE` arguments, unknown
  directions, and arguments on `MOVE`/`LEFT`/`RIGHT`/`REPORT` are ignored.
- Empty input, and a last line without a trailing newline, work.
- `REPORT` before placement prints nothing.

## Test

```sh
bundle exec rspec        # or: bundle exec rake
```

Style is checked with RuboCop (`bundle exec rubocop`). `bundle exec rake`
runs RuboCop and then the specs.

Coverage is measured by SimpleCov and the suite **fails if line or branch
coverage drops below 100%**. An HTML report is written to `coverage/`.

## Design

Four small classes, each with one job:

| Class       | Responsibility                                                         |
|-------------|------------------------------------------------------------------------|
| `Table`     | Knows its bounds only (`in_bounds?`); size is configurable             |
| `Robot`     | Owns position and heading; refuses unsafe or premature actions         |
| `Simulator` | Parses lines of text and drives the robot; skips and logs bad lines    |
| `CLI`       | Argument handling; wires a file or stdin to the simulator              |

Collaborators are injected (the robot takes a table; the simulator takes the
robot and the output/log streams), so each class is tested in isolation.
Adding a simple command means a new `Robot` method and one entry in
`Simulator::ACTIONS`.
