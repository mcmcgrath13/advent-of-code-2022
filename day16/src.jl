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
        return (cache[cache_key], [rate])
    end

    if depth == 0
        return (0, [rate])
    end
    
    if num_nodes == length(opened)
        max = rate * depth
        cache[cache_key] = max
        return (max, [rate])
    end

    max = 0
    rates = []

    # open this valve
    if current_node.rate > 0 && !insorted(current_node.name, opened)
        now_openened = vcat([current_node.name], opened)
        sort!(now_openened)
        (cur_max, cur_rates) = search_step(cache, num_nodes, current_node, now_openened, depth - 1, rate + current_node.rate)
        if cur_max > max
            max = cur_max
            rates = cur_rates
        end
    end

    # search to's
    for node in current_node.to
        (cur_max, cur_rates) = search_step(cache, num_nodes, node, opened, depth - 1, rate)
        if cur_max > max
            max = cur_max
            rates = cur_rates
        end
    end    

    max += rate

    cache[cache_key] = max
    return (max, vcat([rate], rates))
end

function search_2_step(targets, cache, num_nodes, my_node, elephant_node, opened, depth, rate)
    if depth == 1
        return rate
    end

    # bail out early
    if rate < targets[depth]
        return 0
    end

    where_are_we = join(sort([my_node.name, elephant_node.name]), "-")
    cache_key = (where_are_we, hash_opened(opened), depth)
    if haskey(cache, cache_key)
        return cache[cache_key]
    end

    if num_nodes == length(opened)
        return rate * depth
    end
    
    max = 0

    my_next_steps = map(node -> (node, 0), my_node.to)
    # open this valve
    if my_node.rate > 0 && !insorted(my_node.name, opened)
        push!(my_next_steps, (my_node, my_node.rate))
    end

    elephant_next_steps = map(node -> (node, 0), elephant_node.to)
    # open this valve
    if elephant_node.rate > 0 && !insorted(elephant_node.name, opened)
        push!(elephant_next_steps, (elephant_node, elephant_node.rate))
    end

    for (my_next_node, my_rate_incr) in my_next_steps
        for (elephant_next_node, elephant_rate_incr) in elephant_next_steps
            # we can't both open the same valve at once
            if my_rate_incr > 0 && elephant_rate_incr > 0 && my_next_node.name == elephant_next_node.name
                continue
            end

            now_opened = opened
            new_rate = rate
            if my_rate_incr > 0 
                now_opened = vcat([my_next_node.name], now_opened)
                sort!(now_opened)
                new_rate += my_rate_incr
            end
            if elephant_rate_incr > 0 
                now_opened = vcat([elephant_next_node.name], now_opened)
                sort!(now_opened)
                new_rate += elephant_rate_incr
            end
            cur_max = rate + search_2_step(targets, cache, num_nodes, my_next_node, elephant_next_node, now_opened, depth - 1, new_rate)

            if cur_max > max
                max = cur_max
            end
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
    max, rate_path = search_step(cache, num_nodes_to_visit, start_node, Node[], depth, 0)
    println(max)
    return (cache, rate_path)
end

function part_2(path, start, depth)
    p1_cache, p1_path = part_1(path, start, depth)
    p2_targets = reverse(p1_path)
    while length(p2_targets) != depth
        pushfirst!(p2_targets, p2_targets[1])
    end
    println(p2_targets)

    nodes = read_file(path)
    start_node = nodes[start]
    cache = Dict{Tuple{String, String, Int}, Int}()
    num_nodes_to_visit = length(filter(p -> p.second.rate > 0, nodes))
    

    println(search_2_step(p2_targets, cache, num_nodes_to_visit, start_node, start_node, Node[], depth, 0))
    cache
end