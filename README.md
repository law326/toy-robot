# Toy Robot Simulator

A Ruby simulation of a toy robot roaming a 5x5 table. Commands are read from a
text file. The robot can never fall off the table.

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
bin/toy_robot example_commands/basic.txt
bin/toy_robot --verbose example_commands/edges.txt   # also log ignored lines to stderr
bin/toy_robot --help
```

Exit status: `0` success, `1` file cannot be read, `2` bad command-line usage (including a missing FILE).
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

## Approach

### Four small classes, each with one job

| Class       | Responsibility                                                         |
|-------------|------------------------------------------------------------------------|
| `Table`     | Knows which cells are walkable (`walkable?`); size is configurable     |
| `Robot`     | Owns position and heading; refuses unsafe or premature actions         |
| `Simulator` | Parses lines of text and drives the robot; skips and logs bad lines    |
| `CLI`       | Argument handling; wires the input file to the simulator               |

### Key decisions/assumptions

1. The "never fall off" rule is enforced where
   the state is, so it holds no matter who calls the robot. Every action returns
   true if carried out and false if ignored; the simulator only reports it.
2. Invalid commands never abort a run.
   Unknown commands, malformed or out-of-range `PLACE`, and commands before the
   first valid `PLACE` are skipped, with the reason shown by `--verbose`.
3. The robot takes a `surface` object which implements
   `walkable?` method; the simulator takes the robot and the output/log streams. Each
   class is tested in isolation, and a new kind of surface (for example one with
   obstacles) needs no change to the robot.
4. The parser allows any case, tabs, CRLF, spaces around commas, blank lines 
   and `#` comments.

### Trade-offs

- Adding a command means editing both `Robot` and `Simulator#execute`. A
  command-object design would remove that, but seemed over-engineered for this task.
- Errors are streamed to an injected log. They aren't collected for later inspection.

## Future Improvements

- **Make the table size configurable from the CLI.** Table already takes width and height, but the CLI always uses 5x5. A --size WxH flag would be good, and this would make the simulator more extendable to different use cases.
- **Improve `execute` method** Refactor the method to make it easier to understand and easier to extend should more commands are to be added.
- **Command objects.** The current design is based on the five commands in the task, but as mentioned in the trade-offs, a command-object may be required if future requirement includes adding more than a few new commands.
- **Obstacle surface.** Add obstacle surface class and commands to support different kind of surface.
- **Animated work through display.** Add terminal animation so user can see each of the step and makes it easier to verify the result.
- **Gamify this app** With the introduction of obstcale surface and the animated display, this app can potentially extend into a video game with maze built and user control the robot to lead the robot out of the maze.
- **Structured error reporting.** Replace the log: stream with an injected reporter, if error counts, exit codes, some kind of anaylsis or different error display format is required.
