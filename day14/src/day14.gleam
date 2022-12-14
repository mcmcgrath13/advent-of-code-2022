import gleam/erlang/file
import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/set
import gleam/string

pub type Coordinate {
  Coordinate(x: Int, y: Int)
}

pub fn main() {
  assert Ok(contents) = file.read("example.txt")
  let coords =
    list.fold(
      over: string.split(contents, "\n"),
      from: set.new(),
      with: parse_line,
    )

  let initial = set.size(coords)
  let lowest_rock =
    set.fold(over: coords, from: 0, with: fn(acc, cur) { int.max(acc, cur.y) })
  let num_grains_1 =
    run(coords, fn(acc, cur) { add_sand_part_1(acc, cur, lowest_rock) })
  let num_grains_2 =
    run(coords, fn(acc, cur) { add_sand_part_2(acc, cur, lowest_rock + 2) })
  io.debug(num_grains_1 - initial)
  io.debug(num_grains_2 - initial)
}

fn run(
  coords: set.Set(Coordinate),
  runner: fn(set.Set(Coordinate), Coordinate) ->
    list.ContinueOrStop(set.Set(Coordinate)),
) -> Int {
  let sand_start = Coordinate(x: 500, y: 0)
  let with_sand =
    iterator.repeatedly(fn() { sand_start })
    |> iterator.fold_until(from: coords, with: runner)
  set.size(with_sand)
}

fn add_sand_part_2(
  coords: set.Set(Coordinate),
  grain: Coordinate,
  lowest_rock: Int,
) -> list.ContinueOrStop(set.Set(Coordinate)) {
  let Coordinate(x, y) = grain
  let can_down =
    y + 1 < lowest_rock && !set.contains(coords, Coordinate(x, y + 1))
  let can_left =
    y + 1 < lowest_rock && !set.contains(coords, Coordinate(x - 1, y + 1))
  let can_right =
    y + 1 < lowest_rock && !set.contains(coords, Coordinate(x + 1, y + 1))
  case grain {
    Coordinate(x, y) if can_down ->
      add_sand_part_2(coords, Coordinate(x, y + 1), lowest_rock)
    Coordinate(x, y) if can_left ->
      add_sand_part_2(coords, Coordinate(x - 1, y + 1), lowest_rock)
    Coordinate(x, y) if can_right ->
      add_sand_part_2(coords, Coordinate(x + 1, y + 1), lowest_rock)
    Coordinate(500, 0) -> list.Stop(set.insert(coords, grain))
    _ -> list.Continue(set.insert(coords, grain))
  }
}

fn add_sand_part_1(
  coords: set.Set(Coordinate),
  grain: Coordinate,
  lowest_rock: Int,
) -> list.ContinueOrStop(set.Set(Coordinate)) {
  let Coordinate(x, y) = grain
  let can_down = !set.contains(coords, Coordinate(x, y + 1))
  let can_left = !set.contains(coords, Coordinate(x - 1, y + 1))
  let can_right = !set.contains(coords, Coordinate(x + 1, y + 1))
  case grain {
    Coordinate(_, y) if y == lowest_rock -> list.Stop(coords)
    Coordinate(x, y) if can_down ->
      add_sand_part_1(coords, Coordinate(x, y + 1), lowest_rock)
    Coordinate(x, y) if can_left ->
      add_sand_part_1(coords, Coordinate(x - 1, y + 1), lowest_rock)
    Coordinate(x, y) if can_right ->
      add_sand_part_1(coords, Coordinate(x + 1, y + 1), lowest_rock)
    _ -> list.Continue(set.insert(coords, grain))
  }
}

fn parse_line(coords: set.Set(Coordinate), line: String) -> set.Set(Coordinate) {
  let path =
    string.split(line, " -> ")
    |> list.map(parse_pair)
    |> list.window_by_2()
    |> list.fold(from: coords, with: follow_path)
  path
}

fn parse_pair(pair_string: String) -> Coordinate {
  assert [Ok(x), Ok(y)] =
    string.split(pair_string, ",")
    |> list.map(fn(v) { int.parse(v) })
  Coordinate(x: x, y: y)
}

fn follow_path(
  coords: set.Set(Coordinate),
  path: #(Coordinate, Coordinate),
) -> set.Set(Coordinate) {
  io.debug(path)
  let #(first, second) = path
  let [x_head, ..x_tail] = list.range(first.x, second.x)
  let [y_head, ..y_tail] = list.range(first.y, second.y)
  let pairs = case list.length(x_tail) == 0 {
    True -> {
      let ys = [y_head, ..y_tail]
      list.zip(list.repeat(x_head, list.length(ys)), ys)
    }
    False -> {
      let xs = [x_head, ..x_tail]
      list.zip(xs, list.repeat(y_head, list.length(xs)))
    }
  }
  io.debug(pairs)
  list.fold(
    over: pairs,
    from: coords,
    with: fn(s, p) { set.insert(s, Coordinate(x: p.0, y: p.1)) },
  )
}
