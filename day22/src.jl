abstract type TileType end
struct Wall <: TileType end
struct Open <: TileType end

mutable struct Tile
    column::Int
    row::Int
    type::TileType
    face::Symbol
    x::Int
    y::Int
    z::Int

    # neighbors
    up::Tile
    right::Tile
    down::Tile
    left::Tile

    function Tile(column, row, type, x, y, z)
        new(column, row, type, x, y, z)
    end
end

function parse_file(path, face_size, face_map; fold_cube = false)
    contents = read(path, String)
    sections = split(contents, "\n\n")
    map = parse_map(sections[1], fold_cube, face_size, face_map)
    path = parse_path(sections[2])
    
    return map, path
end

const FACES = (:top, :front, :back, :left, :right, :bottom)


function parse_map(content, fold_cube, face_size, face_map)
    tiles = Dict{Tuple{Int, Int}, Tile}()
    tiles_cube = Dict{Tuple{Int, Int, Int}, Tile}()
    lines = split(content, '\n')
    start = nothing

    # build up the nodes
    for (row, line) in enumerate(lines)
        for (col, char) in enumerate(line)
            if char == ' ' 
                continue
            end

            normalized_col = (col % face_size) + 1
            normalized_row = (row % face_size) + 1
            face, (x, y, x) = face_map[(col ÷ face_size, row ÷ face_size)](normalized_col, normalized_row, face_size)

            tile = if char == '.'
                Tile(col, row, Open(), face, x, y, z)
            elseif char == '#'
                Tile(col, row, Wall(), face, x, y, z)
            end

            tiles[(col, row)] = tile
            tiles_cube[(x, y, z)] = tile

            if start == nothing
                start = tile
            end
        end
    end

    # build up the edges
    if fold_cube
        for (coord, tile) in tiles_cube
            tile.right = get_next_cube(tiles, coord, :right)
            tile.left = get_next_cube(tiles, coord, :left)
            tile.up = get_next_cube(tiles, coord, :up)
            tile.down = get_next_cube(tiles, coord, :down)
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
        tiles[next_coord .+ diff]
    end
end

const FACE_TRANSITIONS = (
    top = (left = (-1, 0, 0), up = (0, 0, 1), right = (1, 0, 0), down = (0, 0, -1))
    front = (left = (-1, 0, 0), up = (0, 1, 0), right = (1, 0, 0), down = (0, -1, 0))
    bottom = (left = (1, 0, 0), up = (0, 0, -1), right = (-1, 0, 0), down = (0, 0, 1))
    back = (left = (1, 0, 0), up = (0, -1, 0), right = (-1, 0, 0), down = (0, 1, 0))
    left = (left = (0, 0, 1), up = (0, 1, 0), right = (0, 0, -1), down = (0, -1, 0))
    right = (left = (0, 0, -1), up = (0, 1, 0), right = (0, 0, 1), down = (0, -1, 0))
)

function get_next_cube(tiles, coord, direction, cube_map)
    cur_tile = tiles[coord]
    diff = FACE_TRANSITIONS[cur_tile.face][direction]

    get(tiles, coord .+ diff) do
        
        
    end
end

function parse_path(content)
    commands = Union{Int, Char}[]
    cur_idx = 1
    while cur_idx <= length(content)
        if isdigit(content[cur_idx])
            stop = cur_idx + something(findfirst(x -> !isdigit(x), content[cur_idx+1:end]), 1)
            push!(commands, parse(Int, content[cur_idx:(stop-1)]))
            cur_idx = stop
        else
            push!(commands, content[cur_idx])
            cur_idx += 1
        end
    end
    return commands
end

function walk_path(tile, direction, commands)
    next_tile = tile
    next_direction = direction
    for command in commands
        println("command: ", command)
        next_tile, next_direction = move(next_tile, next_direction, command)
        println("now at: ", next_tile.column, ", ", next_tile.row, " facing ", next_direction)
    end
    return (next_tile, next_direction)
end

const ROTATE_LEFT = (up = :left, left = :down, down = :right, right = :up)
const ROTATE_RIGHT = (up = :right, right = :down, down = :left, left = :up)

function move(tile, direction, rotate::Char)
    new_direction = if rotate == 'L'
        ROTATE_LEFT[direction]
    else
        ROTATE_RIGHT[direction]
    end
    return  tile, new_direction
end

function move(tile, direction, count::Int)
    next_tile = getproperty(tile, direction)
    if count == 0
        return tile, direction
    elseif next_tile.type == Wall()
        return tile, direction
    else
        return move(next_tile, direction, count - 1)
    end
end

const HEADING = (right = 0, down = 1, left = 2, up = 3)

function part_1(path, face_size, face_map)
    start_tile, path = parse_file(path, face_size, face_map)
    end_tile, direction = walk_path(start_tile, :right ,path)
    println(1000 * end_tile.row + 4 * end_tile.column + HEADING[direction])
end

function part_2(path, face_size, face_map)
    start_tile, path = parse_file(path, face_size, face_map, fold_cube = true)
    return path
end

# cube space goes from 1 -> face_size in all directions, column/row already normalized
# top x = 1 -> face size, y = face_size, z = 1 -> face_size

function example_top(column, row, face_size)
    column, face_size, face_size - row
end

function example_front(column, row, face_size)
    column, row, 1
end

function example_bottom(column, row, face_size)
    face_size - column, 1, row
end

function example_left(column, row, face_size)
    1, row, face_size - column 
end

function example_back(column, row, face_size)
    face_size - column, face_size - row, face_size
end

function example_right(column, row, face_size)
    face_size, face_size - column, row
end

const EXAMPLE_CUBE_MAP = Dict(
    (3,1) => (:top, example_top), 
    (1,2) => (:back, example_back), 
    (2,2) => (:left, example_left), 
    (2,3) => (:front, example_front), 
    (3,3) => (:bottom, example_bottom), 
    (3,4) => (:right, example_right)
    )

function fold_back(coord)
    [1 0 0;
    0 0 -1;
    0 1 0] * coord
end

const R_LEFT = [0 -1; 1 0]
const R_RIGHT = [0 1; -1 0]
const R_SPIN = [-1 0; 0; -1]
const R_NOOP = [1 1; 1 1]