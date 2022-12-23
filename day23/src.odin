package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

main :: proc() {
    fmt.println(part_1("example.txt"))
    fmt.println(part_1("input.txt"))
    fmt.println(part_2("example.txt"))
    fmt.println(part_2("input.txt"))
}

Point :: [2]int

north := Point{-1, 0}
north_west := Point{-1,-1}
west := Point{0,-1}
south_west := Point{1, -1}
south := Point{1, 0}
south_east := Point{1, 1}
east := Point{0, 1}
north_east := Point{-1, 1}
directions := [4]Point{north, south, west, east}
north_check := [3]Point{north_west, north, north_east}
south_check := [3]Point{south_west, south, south_east}
west_check := [3]Point{north_west, west, south_west}
east_check := [3]Point{north_east, east, south_east}
checks := [4][3]Point{north_check, south_check, west_check, east_check} 
check_all := [8]Point{north, north_west, west, south_west, south, south_east, east, north_east}

read_file :: proc(path: string) -> map[Point]int {
    bytes, err := os.read_entire_file_from_filename(path)
    content := strings.clone_from_bytes(bytes)
	fmt.println(content)
    lines := strings.split_lines(content)
    coords := make(map[Point]int)
    id := 1
    for line, row in lines {
        for c, col in line {
            if c == '#' {
                coords[[2]int{row, col}] = id
                id += 1
            }
        }
    }
    return coords
}

part_1 :: proc(path: string) -> int {
    coords := read_file(path)
    num_elves := len(coords)
    for i in 0..<10 {
        coords = step(coords, i)
        // print_coords(coords)
    }
    return get_bounding_box_area(coords) - num_elves
}

part_2 :: proc(path: string) -> int {
    coords := read_file(path)
    next_coords := step(coords, 0)
    i := 1
    for ;!coords_equal(coords, next_coords); {
        coords = next_coords
        next_coords = step(coords, i)
        i += 1
    }
    return i
}

coords_equal :: proc(a : map[Point]int, b : map[Point]int) -> bool {
    for k, v in a {
        ov, ok := b[k]
        if !ok || ov != v {
            return false
        }
    }
    return true
}

print_coords :: proc(coords: map[Point]int) {
    minx, maxx, miny, maxy := get_bounding_box(coords)
    for x in minx..=maxx {
        for y in miny..=maxy {
            point := Point{x, y}
            if point in coords {
                fmt.print("#")
            } else {
                fmt.print(".")
            }
        }
        fmt.println()
    }
}

get_idx :: proc(i: int, num: int) -> int {
    return (i + num) % len(directions)
}

step :: proc(coords: map[Point]int, num: int) -> map[Point]int {
    elf_moves := make(map[int]Point)
    elf_coords := make(map[int]Point)
    proposed_coords := make(map[Point]int)

    for coord, elf in coords {
        elf_coords[elf] = coord

        all_free := true
        for check in check_all {
            if (coord + check) in coords {
                all_free = false
                break
            }
        }

        if all_free {
            elf_moves[elf] = coord
            proposed_coords[coord] = elf
            continue
        }

        for i in 0..<len(directions) {
            check_set := checks[get_idx(i, num)]
            check_free := true
            for check in check_set {
                if (coord + check) in coords {
                    check_free = false
                    break
                }
               
            }

            if check_free {
                proposed_coord := coord + directions[get_idx(i, num)]
                clash_elf, ok := proposed_coords[proposed_coord]
                if ok {
                    elf_moves[elf] = coord
                    last_coord, ok := elf_coords[clash_elf]
                    elf_moves[clash_elf] = last_coord // unmove the elf
                } else {
                    elf_moves[elf] = proposed_coord
                    proposed_coords[proposed_coord] = elf
                }
                break
            }

        }
        
        if !(elf in elf_moves) {
            elf_moves[elf] = coord

            clash_elf, ok := proposed_coords[coord]
            if ok {
                last_coord, ok := elf_coords[clash_elf]
                elf_moves[clash_elf] = last_coord // unmove the elf
            } else {
                proposed_coords[coord] = elf
            }
        }
    }

    next_coords := make(map[Point]int)
    for elf, move in elf_moves {
        next_coords[move] = elf
    }

    return next_coords
}

get_bounding_box :: proc(coords : map[Point]int ) -> (int, int, int, int) {
    minx := 99999999999
    maxx := -99999999999
    miny := 99999999999
    maxy := -99999999999
    for c, _ in coords {
        if c[0] < minx {
            minx = c[0]
        }
        if c[0] > maxx {
            maxx = c[0]
        }
        if c[1] < miny {
            miny = c[1]
        }
        if c[1] > maxy {
            maxy = c[1]
        }
    }

    return minx, maxx, miny, maxy
}

get_bounding_box_area :: proc(coords: map[Point]int) -> int {
    minx, maxx, miny, maxy := get_bounding_box(coords)
    return (maxx - minx + 1) * (maxy - miny + 1)
}