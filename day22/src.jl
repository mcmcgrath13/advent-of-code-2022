abstract type TileType end
struct Wall <: TileType end
struct Open <: TileType end

mutable struct Tile
    column::Int
    row::Int
    type::TileType
    face::Symbol
    normalized_col::Int
    normalized_row::Int

    # neighbors
    up::Tile
    right::Tile
    down::Tile
    left::Tile

    function Tile(column, row, type, face, normalized_col, normalized_row)
        new(column, row, type, face, normalized_col, normalized_row)
    end
end

function parse_file(path, face_size, face_map, transition_map; fold_cube = false)
    contents = read(path, String)
    sections = split(contents, "\n\n")
    map = parse_map(sections[1], fold_cube, face_size, face_map, transition_map)
    path = parse_path(sections[2])

    return map, path
end

const FACES = (:top, :front, :back, :left, :right, :bottom)


function parse_map(content, fold_cube, face_size, face_map, transition_map)
    tiles = Dict{Tuple{Int,Int},Tile}()
    tiles_cube = Dict(face => Dict{Tuple{Int,Int},Tile}() for face in FACES)
    lines = split(content, '\n')
    start = nothing

    # build up the nodes
    for (row, line) in enumerate(lines)
        for (col, char) in enumerate(line)
            if char == ' '
                continue
            end

            face_col = (col - 1) ÷ face_size
            face_row = (row - 1) ÷ face_size
            normalized_col = col - (face_col * face_size)
            normalized_row = row - (face_row * face_size)
            face = face_map[(face_col, face_row)]

            tile = if char == '.'
                Tile(col, row, Open(), face, normalized_col, normalized_row)
            elseif char == '#'
                Tile(col, row, Wall(), face, normalized_col, normalized_row)
            end

            tiles[(col, row)] = tile
            tiles_cube[face][(normalized_col, normalized_row)] = tile

            if start == nothing
                start = tile
            end
        end
    end

    # build up the edges
    if fold_cube
        for (face, face_tiles) in tiles_cube
            for (coord, tile) in face_tiles
                tile.right = get_next_cube(
                    face_tiles,
                    coord,
                    :right,
                    transition_map,
                    tiles_cube,
                    face_size,
                )
                tile.left = get_next_cube(
                    face_tiles,
                    coord,
                    :left,
                    transition_map,
                    tiles_cube,
                    face_size,
                )
                tile.up = get_next_cube(
                    face_tiles,
                    coord,
                    :up,
                    transition_map,
                    tiles_cube,
                    face_size,
                )
                tile.down = get_next_cube(
                    face_tiles,
                    coord,
                    :down,
                    transition_map,
                    tiles_cube,
                    face_size,
                )
            end
        end
    else
        for (coord, tile) in tiles
            tile.right = get_next(tiles, coord, :right)
            tile.left = get_next(tiles, coord, :left)
            tile.up = get_next(tiles, coord, :up)
            tile.down = get_next(tiles, coord, :down)
        end
    end

    return start
end

const DIRECTIONS = (up = (0, -1), down = (0, 1), left = (-1, 0), right = (1, 0))

function get_next(tiles, coord, direction)
    diff = DIRECTIONS[direction]
    get(tiles, coord .+ diff) do
        next_coord = coord .- diff
        while haskey(tiles, next_coord)
            next_coord = next_coord .- diff
        end
        tiles[next_coord.+diff]
    end
end

function get_next_cube(tiles, coord, direction, transition_map, tile_cube, face_size)
    diff = DIRECTIONS[direction]
    get(tiles, coord .+ diff) do
        col, row = coord
        cur_tile = tiles[coord]
        map_fn = transition_map[cur_tile.face]
        next_face, next_coord = map_fn(col, row, face_size)[direction]
        next_tiles = tile_cube[next_face]
        next_tiles[next_coord]
    end
end

function parse_path(content)
    commands = Union{Int,Char}[]
    cur_idx = 1
    while cur_idx <= length(content)
        if isdigit(content[cur_idx])
            stop =
                cur_idx + something(findfirst(x -> !isdigit(x), content[cur_idx+1:end]), 1)
            push!(commands, parse(Int, content[cur_idx:(stop-1)]))
            cur_idx = stop
        else
            push!(commands, content[cur_idx])
            cur_idx += 1
        end
    end
    return commands
end

function walk_path(tile, direction, commands; cube = false, pivots = nothing)
    next_tile = tile
    next_direction = direction
    for command in commands
        println("command: ", command)
        next_tile, next_direction = move(next_tile, next_direction, command, cube, pivots)
        println(
            "now at: ",
            next_tile.column,
            ", ",
            next_tile.row,
            " facing ",
            next_direction,
        )
    end
    return (next_tile, next_direction)
end

const ROTATE_LEFT = (up = :left, left = :down, down = :right, right = :up)
const ROTATE_RIGHT = (up = :right, right = :down, down = :left, left = :up)

function move(tile, direction, rotate::Char, cube, pivots)
    new_direction = if rotate == 'L'
        ROTATE_LEFT[direction]
    else
        ROTATE_RIGHT[direction]
    end
    return tile, new_direction
end

function move(tile, direction, count::Int, cube, pivots)
    next_tile = getproperty(tile, direction)
    if count == 0
        return tile, direction
    elseif next_tile.type == Wall()
        return tile, direction
    else
        if cube && next_tile.face != tile.face
            println("new face ", next_tile.face)
            new_direction = pivots[tile.face][direction]
            return move(next_tile, new_direction, count - 1, cube, pivots)
        else
            return move(next_tile, direction, count - 1, cube, pivots)
        end
    end
end

const HEADING = (right = 0, down = 1, left = 2, up = 3)

function part_1(path, face_size, face_map, transition_map)
    start_tile, path = parse_file(path, face_size, face_map, transition_map)
    end_tile, direction = walk_path(start_tile, :right, path)
    println(1000 * end_tile.row + 4 * end_tile.column + HEADING[direction])
end

function part_2(path, face_size, face_map, transition_map, pivots)
    start_tile, path =
        parse_file(path, face_size, face_map, transition_map; fold_cube = true)
    end_tile, direction = walk_path(start_tile, :right, path; cube = true, pivots)
    println(1000 * end_tile.row + 4 * end_tile.column + HEADING[direction])
end

# we crossed faces, which way are we going now?
const EXAMPLE_PIVOTS = (
    top = (left = :down, up = :down, right = :left, down = :down),
    front = (left = :left, up = :up, right = :down, down = :down),
    bottom = (left = :up, up = :up, right = :right, down = :up),
    back = (left = :up, up = :down, right = :right, down = :up),
    left = (left = :left, up = :right, right = :right, down = :right),
    right = (left = :left, up = :left, right = :left, down = :right),
)

# cube space goes from 1 -> face_size in all directions, column/row already normalized
# return dir -> next face, which cube tuples
function example_top(column, row, face_size)
    (
        left = (:left, (row, face_size)),
        up = (:back, (1, row)),
        right = (:right, (face_size, face_size - row + 1)),
        down = (:front, (column, 1)),
    )
end

function example_front(column, row, face_size)
    (
        left = (:left, (face_size, row)),
        up = (:top, (column, face_size)),
        right = (:right, (face_size - row + 1, 1)),
        down = (:bottom, (column, 1)),
    )
end

function example_bottom(column, row, face_size)
    (
        left = (:left, (face_size - row + 1, face_size)),
        up = (:front, (column, face_size)),
        right = (:right, (1, row)),
        down = (:back, (face_size - column + 1, face_size)),
    )
end

function example_left(column, row, face_size)
    (
        left = (:back, (face_size, row)),
        up = (:top, (1, column)),
        right = (:front, (1, row)),
        down = (:bottom, (1, face_size - column + 1)),
    )
end

function example_back(column, row, face_size)
    (
        left = (:right, (face_size - column + 1, face_size)),
        up = (:top, (face_size - column + 1, 1)),
        right = (:left, (1, row)),
        down = (:bottom, (face_size - column + 1, face_size)),
    )
end

function example_right(column, row, face_size)
    (
        left = (:bottom, (face_size, row)),
        up = (:front, (face_size, face_size - column + 1)),
        right = (:top, (face_size, face_size - row + 1)),
        down = (:back, (1, face_size - column + 1)),
    )
end

# which face are we on?
const EXAMPLE_CUBE_MAP = Dict(
    (2, 0) => :top,
    (0, 1) => :back,
    (1, 1) => :left,
    (2, 1) => :front,
    (2, 2) => :bottom,
    (3, 2) => :right,
)

# faces to functions on how to transition
const EXAMPLE_TRANSITION_MAP = (
    top = example_top,
    back = example_back,
    left = example_left,
    front = example_front,
    bottom = example_bottom,
    right = example_right,
)

const INPUT_PIVOTS = (
    top = (left = :right, up = :right, right = :right, down = :down),
    front = (left = :down, up = :up, right = :up, down = :down),
    bottom = (left = :left, up = :up, right = :left, down = :left),
    back = (left = :down, up = :up, right = :up, down = :down),
    left = (left = :right, up = :right, right = :right, down = :down),
    right = (left = :left, up = :up, right = :left, down = :left),
)

function input_top(column, row, face_size)
    (
        left = (:left, (1, face_size - row + 1)),
        up = (:back, (1, column)),
        right = (:right, (1, row)),
        down = (:front, (column, 1)),
    )
end

function input_front(column, row, face_size)
    (
        left = (:left, (row, 1)),
        up = (:top, (column, face_size)),
        right = (:right, (row, face_size)),
        down = (:bottom, (column, 1)),
    )
end

function input_bottom(column, row, face_size)
    (
        left = (:left, (face_size, row)),
        up = (:front, (column, face_size)),
        right = (:right, (face_size, face_size - row + 1)),
        down = (:back, (face_size, column)),
    )
end

function input_left(column, row, face_size)
    (
        left = (:top, (1, face_size - row + 1)),
        up = (:front, (1, column)),
        right = (:bottom, (1, row)),
        down = (:back, (column, 1)),
    )
end

function input_back(column, row, face_size)
    (
        left = (:top, (row, 1)),
        up = (:left, (column, face_size)),
        right = (:bottom, (row, face_size)),
        down = (:right, (column, 1)),
    )
end

function input_right(column, row, face_size)
    (
        left = (:top, (face_size, row)),
        up = (:back, (column, face_size)),
        right = (:bottom, (face_size, face_size - row + 1)),
        down = (:front, (face_size, column)),
    )
end

const INPUT_CUBE_MAP = Dict(
    (1, 0) => :top,
    (2, 0) => :right,
    (1, 1) => :front,
    (0, 2) => :left,
    (1, 2) => :bottom,
    (0, 3) => :back,
)

const INPUT_TRANSITION_MAP = (
    top = input_top,
    back = input_back,
    left = input_left,
    front = input_front,
    bottom = input_bottom,
    right = input_right,
)
