function part_1()
    max_elf = 0
    cur_elf = 0
    for line in eachline(joinpath(@__DIR__, "input1.txt"))
        if line == ""
            if cur_elf > max_elf
                max_elf = cur_elf
            end
            cur_elf = 0
        else
            cals = parse(Int, line)
            cur_elf += cals
        end
    end

    return max_elf
end

function part_2()
    max_elfs = [0, 0, 0]
    cur_elf = 0
    for line in eachline(joinpath(@__DIR__, "input1.txt"))
        if line == ""
            i = searchsortedfirst(max_elfs, cur_elf; rev=true)
            if i <= 3
                update_sorted_list!(max_elfs, i, cur_elf)
            end
            cur_elf = 0
        else
            cur_elf += parse(Int, line)
        end
    end

    return sum(max_elfs)
end

function update_sorted_list!(arr, i, value)
    # shuffle inds up til length
    for j in (length(arr) - 1):-1:(i)
        arr[j+1] = arr[j]
    end
    arr[i] = value
end