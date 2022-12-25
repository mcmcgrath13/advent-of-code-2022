using DataStructures: PriorityQueue, enqueue!, dequeue!

const Point = Tuple{Int, Int}
const Blizzard = Tuple{Point, Point}

const DIRECTIONS = (up = (-1, 0), down = (1, 0), left = (0, -1), right = (0, 1), wait = (0, 0))
const DIRECTION_VALS = collect(values(DIRECTIONS))
const CHAR_TO_DIR = Dict('^' => DIRECTIONS.up, '>' => DIRECTIONS.right, '<' => DIRECTIONS.left, 'v' => DIRECTIONS.down)
const DIR_TO_CHAR = Dict(DIRECTIONS.up => '^', DIRECTIONS.right => '>', DIRECTIONS.left => '<', DIRECTIONS.down => 'v')

function parse_file(path)
    walls = Set(Point[])
    blizzards = Set(Blizzard[])
    lines = readlines(path)
    height = length(lines)
    width = length(lines[1])
    for (row, line) in enumerate(lines)
        for (col, val) in enumerate(line)
            if val == '.'
                continue
            elseif val == '#'
                push!(walls, (row, col))
            else
                dir = CHAR_TO_DIR[val]
                push!(blizzards, ((row, col), dir))
            end
        end
    end

    # add fake walls to block the entrance and exits in
    push!(walls, (0, 2))
    push!(walls, (height + 1, width - 1))

    return walls, blizzards, width, height
end

function print_state(me, walls, blizzards, width, height)
    blizzards_printing = Dict{Point, Char}()
    for (loc, dir) in blizzards
        blizzards_printing[loc] = DIR_TO_CHAR[dir]
    end
    for row in 1:height
        for col in 1:width
            point = (row, col)
            if point == me
                print('E')
            elseif point in walls
                print('#')
            else
                print(get(blizzards_printing, point, '.'))
            end
        end
        println()
    end
end

function update_moves(me, blizzards, walls, width, height)
    can_move = setdiff(map(p -> p .+ me, DIRECTION_VALS), walls)
    updated_blizzards = Set(Blizzard[])
    for blizzard in blizzards
        updated_point = blizzard[1] .+ blizzard[2]
        if updated_point in walls
            row, col = updated_point
            if col <= 1
                col = width - 1
            elseif col == width
                col = 2
            elseif row <= 1
                row = height - 1
            else
                row = 2
            end
            updated_point = (row, col)
        end
        push!(updated_blizzards, (updated_point, blizzard[2]))
        setdiff!(can_move, [updated_point])
    end
    return can_move, updated_blizzards
end

function branch_and_bound(walls, blizzards, width, height, start, target; ord = Base.Order.Reverse)
    best = 99999999999999
    best_blizzards = blizzards
    queue = PriorityQueue{Tuple{Point, Set{Blizzard}, Int}, Int}(ord)
    enqueue!(queue, (start, blizzards, 0), 3)
    branches = 1
    bounds = 0
    been_there = Set(Tuple{Point, Set{Blizzard}}[])

    while !isempty(queue)
        (me, cur_blizzards, step) = dequeue!(queue)

        if (branches + bounds) % 1000 == 0
            println("branches: ", branches, "   bounds: ", bounds, "  queue: ", length(queue))
            println("currently at ", me, "   step: ", step)
        end

        # update optimum
        if me == target
            println("found a new best: ", step)
            best = step
            best_blizzards = cur_blizzards
            continue
        end

        # bound
        if step + abs((target[1] + target[2]) - (me[1] + me[2])) > best
            bounds += 1
            continue
        end

        # branch
        can_move, next_blizzards = update_moves(me, cur_blizzards, walls, width, height)
        for move in can_move
            next_move = (move, next_blizzards, step+1)
            if !haskey(queue, next_move) && !in((move, next_blizzards), been_there)
                branches += 1
                enqueue!(queue, next_move, move[1] + move[2])
                push!(been_there, (move, next_blizzards))
            end
        end
    end
    
    return best, best_blizzards
end

function part_1(path)
    walls, blizzards, width, height = parse_file(path)
    best, _ = branch_and_bound(walls, blizzards, width, height, (1, 2), (height, width - 1))
    return best
end

function part_2(path)
    walls, blizzards, width, height = parse_file(path)
    best_there, there_blizzards = branch_and_bound(walls, blizzards, width, height, (1, 2), (height, width - 1))
    best_back, back_blizzards = branch_and_bound(walls, there_blizzards, width, height, (height, width - 1), (1, 2); ord = Base.Order.Forward)
    best_return, _ = branch_and_bound(walls, back_blizzards, width, height, (1, 2), (height, width - 1))
    return best_there + best_back + best_return
end