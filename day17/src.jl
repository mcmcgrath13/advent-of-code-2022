mutable struct Rock
    shape:: BitMatrix
    bottom_offset:: Int
    left_offset:: Int
    height:: Int
    width:: Int

    function Rock(shape, bottom_offset)
        (height, width) = size(shape)
        new(shape, bottom_offset + 2, (9 - width - 2), height, width)
    end
end

const FLAT_ROCK = BitArray([1 1 1 1])
const T_ROCK = BitArray(
    [0 1 0;
    1 1 1;
    0 1 0]
)
const L_ROCK = BitArray([
    1 1 1;
    1 0 0;
    1 0 0;
])
const I_ROCK = trues(4, 1) # otherwise it gets interpreted as a vector
const SQUARE_ROCK = BitArray([
    1 1;
    1 1;
])

const ROCKS = [FLAT_ROCK, T_ROCK, L_ROCK, I_ROCK, SQUARE_ROCK]

abstract type Direction end
struct Right <: Direction end
struct Left <: Direction end
struct Down <: Direction end

const EMPTY_ROW = BitArray([1 0 0 0 0 0 0 0 1])
const FLOOR = trues(1, 9)

mutable struct Column
    height:: Int
    floor_height:: Int
    bit_mask:: BitMatrix

    function Column()
        # upside down for easier pushing and index math
        mask = vcat(FLOOR, repeat(EMPTY_ROW, 3))
        new(0, 0, mask)
    end
end

function move!(d::Direction, rock::Rock, column::Column)
    check_area = get_check_area(d, rock, column)
    if !any(check_area .& rock.shape)
        update_rock!(rock, d)
        return true
    end

    return false
end

function step!(d::Direction, rock::Rock, column::Column)
    move!(d, rock, column)
    can_move = move!(Down(), rock, column)
    if !can_move
        update_column!(column, rock)
    end
    return can_move
end

next_ind(cur_i, size) = cur_i == size ? 1 : cur_i + 1

function run_rock!(column::Column, directions::Vector{Direction}, direction_index::Int, shape::BitMatrix)
    rock = Rock(shape, (column.height - column.floor_height) + 3)
    # println(rock)
    make_column_taller!(column, rock)
    i = direction_index
    direction = directions[i]
    num_dirs = length(directions)
    # print_state(rock, column)
    while step!(direction, rock, column)
        # println(direction)
        # print_state(rock, column)
        i = next_ind(i, num_dirs)
        direction = directions[i]
    end

    # println(direction)
    # print_state(rock, column)

    return next_ind(i, num_dirs)
end

function print_state(rock, column)
    c = deepcopy(column)
    update_column!(c, rock)
    display(c.bit_mask)
end

function update_rock!(rock::Rock, ::Left)
    rock.left_offset += 1
end
function update_rock!(rock::Rock, ::Right)
    rock.left_offset -= 1
end
function update_rock!(rock::Rock, ::Down)
    rock.bottom_offset -= 1
end

function get_check_area(::Left, rock::Rock, column::Column)
    view(column.bit_mask, rock.bottom_offset:(rock.bottom_offset + rock.height - 1), (rock.left_offset + 1):(rock.left_offset + rock.width))
end
function get_check_area(::Right, rock::Rock, column::Column)
    view(column.bit_mask, rock.bottom_offset:(rock.bottom_offset + rock.height - 1), (rock.left_offset - 1):(rock.left_offset + rock.width - 2))
end
function get_check_area(::Down, rock::Rock, column::Column)
    view(column.bit_mask, (rock.bottom_offset - 1):(rock.bottom_offset + rock.height - 2), (rock.left_offset):(rock.left_offset + rock.width - 1))
end
function get_check_area(rock::Rock, column::Column)
    view(column.bit_mask, rock.bottom_offset:(rock.bottom_offset + rock.height - 1), (rock.left_offset):(rock.left_offset + rock.width - 1))
end


function update_column!(column::Column, rock::Rock)
    area = get_check_area(rock, column)
    area .=  area .| rock.shape
    column.height = max(column.height, column.floor_height + rock.bottom_offset + rock.height - 2)
    
    # check if there's a new functional floor
    for i in (rock.bottom_offset):(column.height - column.floor_height)
        if all(column.bit_mask[i, :])
            # println("new floor at $i")
            column.bit_mask = column.bit_mask[i:end, :]
            column.floor_height = column.floor_height + i - 1
            break
        end
    end
end

function make_column_taller!(column::Column, rock::Rock)
    num_new_rows = ((column.height - column.floor_height) + 1 + 3 + rock.height) - size(column.bit_mask)[1]
    if num_new_rows > 0
        new_rows = repeat(EMPTY_ROW, num_new_rows)
        column.bit_mask = vcat(column.bit_mask, new_rows)
    end
end

function parse_direction(c)
    if c == '<'
        Left()
    elseif c == '>'
        Right()
    else
        Down()
    end
end

function read_file(path)
    parse_direction.(collect(read(path, String)))
end

function part_1(path, num_rocks)
    directions = read_file(path)
    column = Column()
    rock_idx = 1
    dir_idx = 1
    n = length(ROCKS)
    for i in 1:num_rocks
        if i % 1000000 == 0
            println(i)
        end
        rock_shape = ROCKS[rock_idx]
        dir_idx = run_rock!(column, directions, dir_idx, rock_shape)
        rock_idx = next_ind(rock_idx, n)
    end
    # show(stdout, "text/plain", column.bit_mask)
    return column.height
end