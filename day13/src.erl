-module(src).
-export([run/1]).

run(S) -> 
    Content = read_file_to_pairs(S),
    Matches = lists:map(fun(X) -> compare_pair(X) end, Content),
    Fun = fun({I, X}, Acc) -> Acc + if X -> I; true -> 0 end end,
    % Results.
    io:format("Enumerated: ~w ~n", [Matches]),
    lists:foldl(Fun, 0, lists:enumerate(Matches)).

read_file_to_pairs(S) ->
    {ok, File} = file:read_file(S),
    Content = unicode:characters_to_list(File),
    PairStrings = string:split(Content, "\n\n", all),
    lists:map(fun(X) -> string:split(X, "\n", all) end, PairStrings).

% thanks, stack overflow
parse_line(S) -> 
    {ok, Ts, _} = erl_scan:string(S), 
    {ok, Result} = erl_parse:parse_term(Ts ++ [{dot,1} || element(1, lists:last(Ts)) =/= dot]),
    Result.

compare_pair(Pair) ->
    Left = parse_line(lists:nth(1, Pair)),
    Right = parse_line(lists:nth(2, Pair)),
    io:format("Left: ~w     Right: ~w ~n", [Left, Right]),
    Res = compare_pair(Left, Right),
    io:format("Valid: ~w ~n", [Res]),
    Res.

compare_pair([LeftH | LeftT], [RightH | RightT]) ->
    io:format("(Left: ~w) (Right: ~w) ~n", [LeftH, RightH]),
    HeadRes = compare_pair(LeftH, RightH),
    io:format("HeadRes: ~w ~n", [HeadRes]),
    if 
        HeadRes == unknown ->
            compare_pair(LeftT, RightT);
        true ->
            HeadRes
    end;
compare_pair([], []) ->
    io:format("[], [] ~n"),
    unknown;
compare_pair([], Right) when is_list(Right) -> 
    io:format("[], Right ~n"),
    true;
compare_pair(Left, []) when is_list(Left) -> 
    io:format("Left, [] ~n"),
    false;
compare_pair(Left, N) when is_list(Left)->
    io:format("Left, N ~n"),
    compare_pair(Left, [N]);
compare_pair(N, Right) when is_list(Right) ->
    io:format("N, Right ~n"),
    compare_pair([N], Right);
compare_pair(Left, Right) ->
    io:format("Left, Right ~n"),
    if
        Left < Right -> 
            true;
        Left > Right ->
            false;
        Left == Right ->
            unknown
    end.