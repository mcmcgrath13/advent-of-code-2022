mutable struct Node
    name::String
    rate::Int
    to::Vector{Node}

    Node(name) = new(name, 0, [])
end

function build_nodes!(nodes, line)
    rx = r"Valve ([A-Z]+) has flow rate=(\d+); tunnel[s]? lead[s]? to valve[s]? (.*)"
    captures = match(rx, line).captures
    name = captures[1]
    rate = parse(Int, captures[2])
    to_str = split(captures[3], ", ")

    node = get!(nodes, name, Node(name))
    node.rate = rate

    for to in to_str
        push!(node.to, get!(nodes, to, Node(to)))
    end
end

function read_file(path)
    nodes = Dict{String, Node}()
    map(line -> build_nodes!(nodes, line), readlines(path))
    return nodes
end

hash_opened(opened) = join(opened, "-")

function search_step(cache, num_nodes, current_node, opened, depth, rate)
    cache_key = (current_node.name, hash_opened(opened), depth)
    if haskey(cache, cache_key)
        return cache[cache_key]
    end

    if depth == 0
        return 0
    end
    
    if num_nodes == length(opened)
        return rate * depth
    end

    max = 0

    # open this valve
    if current_node.rate > 0 && !insorted(current_node.name, opened)
        now_openened = vcat([current_node.name], opened)
        sort!(now_openened)
        cur_max = rate + search_step(cache, num_nodes, current_node, now_openened, depth - 1, rate + current_node.rate)
        if cur_max > max
            max = cur_max
        end
    end

    # search to's
    for node in current_node.to
        cur_max = rate + search_step(cache, num_nodes, node, opened, depth - 1, rate)
        if cur_max > max
            max = cur_max
        end
    end    

    cache[cache_key] = max
    return max
end

function part_1(path, start, depth)
    nodes = read_file(path)
    start_node = nodes[start]
    cache = Dict{Tuple{String, String, Int}, Int}()
    num_nodes_to_visit = length(filter(p -> p.second.rate > 0, nodes))
    println(search_step(cache, num_nodes_to_visit, start_node, Node[], depth, 0))
    cache
end