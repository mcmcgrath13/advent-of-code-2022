def read_file(path : String)
  content = File.read(path)
  content.split('\n').map_with_index {|el, i| {i, el.to_i64}}
end

def update_array(arr, orig_idx)
  if cur_idx = arr.index {|v| v[0] == orig_idx }
    el = arr.delete_at(cur_idx)
    val = el[1]
    arr.rotate!(val)
    arr.insert(cur_idx, el)
  end
end

def find_grove(arr)
  res = 0.to_i64
  if zero_idx = arr.index {|v| v[1] == 0 }
    {1000, 2000, 3000}.each do |idx|
      arr_idx = (zero_idx + idx) % arr.size
      res += arr[arr_idx][1]
    end
  end
  res
end

def part1(path : String)
  values = read_file(path)
  (0...(values.size)).each do |i|
    update_array(values, i)
  end
  find_grove(values)
end

def part2(path : String)
  decryption_key = 811589153
  values = read_file(path)
  values.map! { |el| {el[0], el[1] * decryption_key} }
  (0...10).each do
    (0...(values.size)).each do |i|
      update_array(values, i)
    end
  end
  find_grove(values)
end

# TODO: Put your code here
p! part1("example.txt")
p! part1("input.txt")
p! part2("example.txt")
p! part2("input.txt")