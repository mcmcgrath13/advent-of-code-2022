module Main where

import Prelude (Unit, bind, (+), (<>), (==))
import Data.Int (fromString, toStringAs, decimal, rem)
import Data.Ord ((>=), (<))
import Data.Maybe (Maybe(..))
import Data.Foldable (foldl)
import Data.HeytingAlgebra ((&&))
import Data.Ring ((-))
import Data.Semiring ((*))
import Data.String.Pattern (Pattern(..))
import Data.String (split, stripPrefix)
import Node.FS.Sync (readTextFile)
import Node.Encoding (Encoding(..))

import Effect (Effect)
import Effect.Console (log)

type State = { value :: Int, cycle  :: Int, res :: String}

formatState :: State -> String
formatState state = (toStringAs decimal state.value) <> ", " <> (toStringAs decimal state.cycle) <> "\n" <> state.res

parseInt :: String -> Int
parseInt s = do
  case fromString s of
    Just i -> i
    Nothing -> 0

getValue :: String -> Int
getValue line = do
  case stripPrefix (Pattern "addx ") line of
    Just v -> parseInt v
    Nothing -> 0

step :: (State -> State) -> State -> String -> State
step f s "noop" = 
  let
    state = f s
  in
    { value: state.value, cycle: state.cycle + 1, res: state.res}
step f s line =
  let
    nextState = step f s "noop"
    state = f nextState
  in
    { value: state.value + (getValue line), cycle: state.cycle + 1, res: state.res}

-- checkStatePart1 :: State -> State
-- checkStatePart1 state = 
--     if (rem (state.cycle - 20) 40) == 0
--       then { cycle: state.cycle, value: state.value, res: state.res + state.cycle * state.value}
--       else state

checkStatePart2 :: State -> State
checkStatePart2 state =
  let
    pixel = rem (state.cycle - 1) 40
    spritePos = state.value - 1
    canDraw = pixel >= spritePos && pixel < spritePos + 3
    start = if pixel == 0
      then "\n"
      else ""
    drawn = start <> if canDraw
      then "#"
      else "."
  in
    { cycle: state.cycle, value: state.value, res: state.res <> drawn }



run :: String -> State
run contents = do
  foldl (step checkStatePart2) { value: 1, cycle: 1, res: "" } (split (Pattern "\n") contents)

main :: Effect Unit
main = do
  contents <- readTextFile UTF8 "input.txt"
  log (formatState (run contents))