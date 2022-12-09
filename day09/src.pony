use "collections"
use "files"

class Move
    let direction: String
    let count: USize

    new create(move_string: String) ? =>
        let items = move_string.split()
        direction = items(0) ?
        count = items(1)?.usize() ?

    fun box string(): String iso^ =>
        direction + " " + count.string()

class Coord
    let x: ISize
    let y: ISize

    new create() =>
        x = 0
        y = 0

    new move_one(c: Coord, direction: String) =>
        x = match direction
        | "R" => c.x + 1
        | "L" => c.x - 1
        else 
            c.x
        end

        y = match direction
        | "U" => c.y + 1
        | "D" => c.y - 1
        else
            c.y
        end

    new move(h: Coord, t: Coord) =>
        let hy = h.y
        let hx = h.x
        var ty = t.y
        var tx = t.x 
        if (hy - ty).abs() > 1 then
            if hy > ty then
                ty = ty + 1
            else
                ty = ty - 1
            end

            if (hx - tx).abs() >= 1 then
                if hx > tx then
                    tx = tx + 1
                else
                    tx = tx - 1
                end
            end

        elseif (hx - tx).abs() > 1 then
            if hx > tx then
                tx = tx + 1
            else
                tx = tx - 1
            end

            if (hy - ty).abs() >= 1 then
                if hy > ty then
                    ty = ty + 1
                else
                    ty = ty - 1
                end
            end
        end

        x = tx
        y = ty

    fun box string(): String iso^ =>
        "(" + x.string() + ", " + y.string() + ")"

class State
    let rope: Array[Coord]
    let t_locs: Set[String] = Set[String]

    new create(length: USize) ? =>
        rope = Array[Coord].init(Coord, length)
        update_t()?

    fun box string(): String iso^ =>
        var s = "".string()
        for c in rope.values() do
            s = s + " " + c.string()
        end
        s

    fun num_moves(): USize =>
        t_locs.size()

    fun ref make_move(env: Env, move: Move) ? =>
        for i in Range(0, move.count) do 
            rope(0) ? = Coord.move_one(rope(0)?, move.direction)
            update_t() ?
            env.out.print(string())
        end

    fun ref update_t() ? =>
        for i in Range(1, rope.size()) do
            rope(i)? = Coord.move(rope(i-1)?, rope(i)?)
        end

        t_locs.set(rope(rope.size() - 1)?.string())


actor Main
    new create(env: Env) =>
        try
            let moves = readInput(env, "input.txt") ?
            env.out.print(run(env, moves)?.string())
        end

    fun readInput(env: Env, name: String): Array[Move] ? =>
            let path = FilePath(FileAuth(env.root), name)
            match OpenFile(path)
            | let file: File =>
                let contents = file.read_string(1024 * 1024).string()
                let lines = (consume val contents).split("\n")
                let moves: Array[Move] = []
                for line in (consume val lines).values() do
                    moves.push(Move(line) ?)
                end
                consume moves
            else
                env.err.print("Error opening file '" + name + "'")
                []
            end

    fun run(env: Env, moves: Array[Move]): USize ? =>
        var state = State(10)?
        for move in moves.values() do
            state.make_move(env, move)?
            env.out.print(move.string() + ": " + state.num_moves().string())
        end
        state.num_moves()
        