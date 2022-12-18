import strutils
import sequtils
import sugar
import std/enumerate
import std/deques

type
  Fill = enum
    air, lava, nothing

proc readCoordinates(line: string): seq[int] =
    let coord_strs = line.split(",")
    # make sure 0 coordinate is empty for easy indexing and air expansion later
    map(coord_strs, c => parseInt(c) + 1)

proc parseFile(path: string): seq[seq[seq[Fill]]] =
    let contents = readFile(path) 
    let lines = splitLines(contents)
    let coords = map(lines, read_coordinates)
    let maxCoord = max(map(coords, proc(c: seq[int]): int = max(c))) + 2
    var grid = newSeqWith(maxCoord, newSeqWith(maxCoord, newSeqWith(maxCoord, nothing)))
    # add in lava
    for c in coords:
        grid[c[0]][c[1]][c[2]] = lava

    let valid = proc(c: int): bool = c >= 0 and c < maxCoord
        
    # add in air
    grid[0][0][0] = air
    var q = [(0,0,0)].toDeque
    while len(q) > 0:
        let (x, y, z) = q.popFirst()
        for xdiff in [x-1, x+1]:
            if valid(xdiff) and grid[xdiff][y][z] == nothing:
                grid[xdiff][y][z] = air
                q.addLast((xdiff, y, z))
        for ydiff in [y-1, y+1]:
            if valid(ydiff) and grid[x][ydiff][z] == nothing:
                grid[x][ydiff][z] = air
                q.addLast((x, ydiff, z))
        for zdiff in [z-1, z+1]:
            if valid(zdiff) and grid[x][y][zdiff] == nothing:
                grid[x][y][zdiff] = air
                q.addLast((x, y, zdiff))
    return grid

proc findExposedFaces(grid: seq[seq[seq[Fill]]], check: (v: Fill) -> bool): int =
    var faces = 0
    for x, xaxis in enumerate(grid):
        for y, yaxis in enumerate(xaxis):
            for z, val in enumerate(yaxis):
                if val == lava:
                    for xdiff in [x-1, x+1]:
                        if check(grid[xdiff][y][z]):
                            faces += 1
                    for ydiff in [y-1, y+1]:
                        if check(grid[x][ydiff][z]):
                            faces += 1
                    for zdiff in [z-1, z+1]:
                        if check(grid[x][y][zdiff]):
                            faces += 1
    return faces

proc part1(path: string) =
    let grid = parseFile(path)
    # echo grid
    echo findExposedFaces(grid, v => v != lava)

proc part2(path: string) =
    let grid = parseFile(path)
    echo findExposedFaces(grid, v => v == air)

part1("example.txt")
part1("input.txt")

part2("example.txt")
part2("input.txt")