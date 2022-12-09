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
class State
    var hx: ISize = 0
    var hy: ISize = 0
    var tx: ISize = 0
    var ty: ISize = 0
    let t_locs: Set[String] = Set[String]

    new create() =>
        update_t()

    fun box string(): String iso^ =>
        "T=(" + tx.string() + "," + ty.string() + ") H=(" + hx.string() + "," + hy.string() + ")"

    fun num_moves(): USize =>
        t_locs.size()

    fun ref make_move(env: Env, move: Move) =>
        for i in Range(0, move.count) do 
            match move.direction
            | "R" => hx = hx + 1
            | "L" => hx = hx - 1
            | "U" => hy = hy + 1
            | "D" => hy = hy - 1
            end
            update_t()
            env.out.print(string())
        end

    fun ref update_t() =>
        if (hy - ty).abs() > 1 then
            if hy > ty then
                ty = ty + 1
            else
                ty = ty - 1
            end

            if (hx - tx).abs() == 1 then
                tx = hx
            end

        elseif (hx - tx).abs() > 1 then
            if hx > tx then
                tx = tx + 1
            else
                tx = tx - 1
            end

            if (hy - ty).abs() == 1 then
                ty = hy
            end
        end
        t_locs.set(tx.string() + "," + ty.string())


actor Main
    new create(env: Env) =>
        try
            let moves = readInput(env, "input.txt") ?
            env.out.print(run(env, moves).string())
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

    fun run(env: Env, moves: Array[Move]): USize =>
        var state = State
        for move in moves.values() do
            state.make_move(env, move)
            env.out.print(move.string() + ": " + state.num_moves().string())
        end
        state.num_moves()
        