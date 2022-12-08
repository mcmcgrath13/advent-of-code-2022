struct File
    name :: String
    size :: Int
end

struct Dir
    name :: String
    parent :: Union{Dir, Nothing}
    children :: Vector{Union{File, Dir}}
end

function parse_line!(dir::Dir, line::String)
    parts = split(line, " ")
    if parts[1] == "\$"
        return parse_command!(dir, parts[2:end])
    else
        return parse_item!(dir, parts)
    end
end

function parse_command!(dir::Dir, parts)
    command = parts[1]
    if command == "cd"
        name = parts[2]
        if name == ".."
            return dir.parent
        else
            new_dir = Dir(name, dir, [])
            push!(dir.children, new_dir)
            return new_dir
        end
    end

    return dir
end

function parse_item!(dir::Dir, parts)
    first, second = parts
    if first != "dir"
        push!(dir.children, File(second, parse(Int, first)))
    end

    return dir
end

get_dirs(root::Dir) = foldl(vcat, get_dirs.(root.children); init=[root])
get_dirs(file::File) = []

size_of(root::Dir) = foldl(+, size_of.(root.children))
size_of(file::File) = file.size

function part1()
    lines = readlines("input.txt")[2:end] # ignore cd / line
    root = Dir("/", nothing, [])
    foldl(parse_line!, lines; init=root)
    dirs = get_dirs(root)
    limit = 100000
    println(sum(filter(s -> s <= limit, size_of.(dirs))))
end

function part2()
    lines = readlines("input.txt")[2:end] # ignore cd / line
    root = Dir("/", nothing, [])
    foldl(parse_line!, lines; init=root)
    dirs = get_dirs(root)

    total_disc = 70000000
    total_need = 30000000
    current = size_of(root)
    available = total_disc - current
    need = total_need - available
    
    println(sort(filter(d -> d >= need, size_of.(dirs)))[1])
end