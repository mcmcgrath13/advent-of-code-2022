defmodule AOC do

  def read_file(path) do
    {:ok, contents} = File.read(path)
    String.split(contents, "\n") |> Enum.map(&parse_line/1)
  end

  def parse_line(line) do
    parser = ~r/Sensor at x=(?<sx>[-]?\d+), y=(?<sy>[-]?\d+): closest beacon is at x=(?<bx>[-]?\d+), y=(?<by>[-]?\d+)/
    Regex.named_captures(parser, line)
      |> Enum.map(fn {k, v} -> {String.to_atom(k), String.to_integer(v)} end)
      |> Map.new()
  end

  def range_in_row(ranges, row_num, %{bx: bx, by: by, sx: sx, sy: sy}) do
    distance = abs(bx - sx) + abs(by - sy)

    if sy + distance >= row_num && row_num >= sy - distance do
      start = abs(row_num - sy)
      offset = distance - start
      range = (sx - offset)..(sx + offset)

      [range | ranges]
    else
      ranges
    end
  end

  def merge_ranges(ranges) do
    Enum.sort(ranges, &((&1).first) <= (&2).first)
      |> Enum.reduce([], fn r, acc ->
        if Enum.count(acc) == 0 do
          [r]
        else
          if Range.disjoint?(hd(acc), r) do
            [r | acc]
          else
            [(min(r.first, hd(acc).first))..(max(r.last, hd(acc).last)) | tl(acc)]
          end
        end
      end)
  end

  def ranges_for_rownum(records, row_num) do
    Enum.reduce(records, [], fn r, s -> range_in_row(s, row_num, r) end)
      |> merge_ranges()
  end

  def check_range(ranges, max_xy) do
    0 in Enum.find(ranges, fn r -> max_xy in r end)
  end

  def part_1(path, row_num) do
    records = read_file(path)
    beacons = Enum.reduce(records, MapSet.new(), fn r, acc ->
      if r.by == row_num do
        MapSet.put(acc, r.bx)
      else
        acc
      end
    end)
    range_widths = ranges_for_rownum(records, row_num)
      |> Enum.reduce(0, fn r, acc -> acc + r.last - r.first + 1 end)
    range_widths - Enum.count(beacons)
  end

  def part_2(path, max_xy) do
    multiplier = 4000000

    records = read_file(path)
    [{y, ranges}] = 0..max_xy
      |> Stream.map(fn row_num -> {row_num, ranges_for_rownum(records, row_num)}end)
      |> Stream.drop_while(fn {_i, rs} -> check_range(rs, max_xy) end)
      |> Stream.take(1)
      |> Enum.to_list()

    range = Enum.find(ranges, fn r -> max_xy in r end)
    x = range.first - 1

    multiplier * x + y
  end
end


IO.puts(Integer.to_charlist(AOC.part_1("example.txt", 10)))
IO.puts(Integer.to_charlist(AOC.part_1("input.txt", 2000000)))

IO.puts(Integer.to_charlist(AOC.part_2("example.txt", 20)))
IO.puts(Integer.to_charlist(AOC.part_2("input.txt", 4000000)))
