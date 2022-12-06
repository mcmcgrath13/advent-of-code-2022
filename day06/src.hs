main = do
  contents <- readFile "input.txt"
  print . findHeader 14 $ contents

testStr = "bvwbjplbgvbhsrlpgdmjqwftvncz" -- ans = 5

findHeader :: Int -> String -> Int
findHeader n s = foldUntil isUnique n (iterHeaders n s)

foldUntil :: (String -> Bool) -> Int -> [String] -> Int
foldUntil f n [] = n
foldUntil f n (h:t) = if (f h) then n else foldUntil f (n + 1) t

iterHeaders :: Int -> String -> [String]
iterHeaders n [] = []
iterHeaders n (h:t) = (take n (h:t)) : (iterHeaders n t)

isUnique :: String -> Bool
isUnique [] = True
isUnique (h:t) = if (elem h t) then False else isUnique t