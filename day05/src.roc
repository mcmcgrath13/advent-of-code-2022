app "day05"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.1.1/zAoiC9xtQPHywYk350_b7ust04BmWLW00sjb9ZPtSQk.tar.br" }
    imports [pf.File, pf.Path, pf.Process, pf.Stdout, pf.Task.{ Task }]
    provides [main] to pf

main = 
    path = Path.fromStr "input.txt"
    task = 
        contents <- File.readUtf8 path |> Task.await
        res = parseFile contents
        Stdout.line (run res)
        
    Task.attempt task \result ->
        when result is
            Ok {} -> Stdout.line "yay!"
            Err err ->
                msg =
                    when err is
                        _ -> "Uh oh, there was an error!"

                {} <- Stdout.line msg |> Task.await
                Process.exit 1

run = \{ cargo, moves } ->
    finalCargo = List.walk moves cargo moveCargo
    List.walk finalCargo "\n\n" (\acc, hold -> Str.concat acc (List.last hold |> Result.withDefault "_"))

moveCargo: List (List Str), Move -> List (List Str)
moveCargo = \cargo, { count, from, to } ->
    fromCargo = List.get cargo from |> Result.withDefault []
    { before, others } = List.split fromCargo ((List.len fromCargo) - count)
    removed = List.set cargo from before
    toCargo = List.get removed to |> Result.withDefault []
    newItems = List.concat toCargo others
    # there is a language bug and without this dbg statement the code is wrong
    dbg T removed toCargo others newItems
    List.set removed to newItems

moveCargoPart1 = \cargo, { count, from, to } ->
    if count == 0 then
        cargo
    else
        fromCargo = List.get cargo from |> Result.withDefault []
        toCargo = List.get cargo to |> Result.withDefault []
        item = List.last fromCargo |> Result.withDefault "_"
        List.set cargo from (List.dropLast fromCargo)
            |> List.set to (List.append toCargo item)
            |> moveCargo { count: count - 1, from: from, to: to }


parseFile = \contents -> 
    parts = Str.split contents "\n\n"
    cargo = parseCargo (List.get parts 0 |> Result.withDefault "")
    moves = parseMoves (List.get parts 1 |> Result.withDefault "")    
    { cargo: cargo, moves: moves }

parseCargo = \contents ->
    lines = Str.split contents "\n" |> List.reverse
    inds = List.first lines |> Result.withDefault ""
    cargoHolds = Str.trim inds |> Str.split "   " |> List.map (\_ -> [])

    cargoLines = List.dropFirst lines
    List.walk cargoLines cargoHolds addCargo 

addCargo = \cargoHolds, row ->
    List.mapWithIndex cargoHolds (\el, i -> getAndAdd row el i)

getAndAdd = \row, hold, ind ->
    rowInd = 1 + ind * 4
    res = Str.graphemes row |> List.get rowInd |> Result.withDefault " "
    if res == " " then
        hold
    else
        List.append hold res

parseMoves = \contents ->
    Str.split contents "\n"
        |> List.map (\el -> parseMove (Str.split el " "))
        
Move : { count : Nat, from : Nat, to: Nat }

parseMove: List Str -> Move
parseMove = \moveArr ->
    count = getU32withDefault moveArr 1
    from = getU32withDefault moveArr 3
    to = getU32withDefault moveArr 5
    # account for zero-based inds
    { count: count, from: from - 1, to: to - 1 }
    
getU32withDefault = \list, ind ->
    List.get list ind |> Result.withDefault "0" |> Str.toNat |> Result.withDefault 0