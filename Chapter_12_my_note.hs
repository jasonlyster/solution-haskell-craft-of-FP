module Chapter_12_my_note where

import           Pictures (horse)
import           Test.QuickCheck
import           Chapter_8_my_note (randInt)
import           Prelude hiding ((<*>))

type Picture = [String]

_flipH :: Picture -> Picture
_flipH    = reverse

_flipV :: Picture -> Picture
_flipV    = map reverse

_above :: Picture -> Picture -> Picture
_above    = (++)

_beside :: Picture -> Picture -> Picture
_beside    = zipWith (++)

_invertColor :: Picture -> Picture
_invertColor    = map (map (\ch -> if ch == '.' then '#' else '.'))

_superImpose :: Picture -> Picture -> Picture
_superImpose    = zipWith (zipWith (\c1 c2 -> if c1 == c2 then c1 else '#'))

_printPicture :: Picture -> IO ()
_printPicture    = putStr . concat . map (++ "\n")

_chessBoard :: Int -> Picture
_chessBoard size    = zipWith ($)
    ((fst . splitAt size . concat . replicate size) [fst, reverse . snd])
    ((replicate size . splitAt size . concat . replicate size) "#.")

type Bicture = [[Bool]]

_binvertColor :: Bicture -> Bicture
_binvertColor    = map (map not)

_bsuperImpose :: Bicture -> Bicture -> Bicture
_bsuperImpose    = zipWith (zipWith (\b1 b2 -> (b1 == b2) && b2))

_bprintPicture :: Bicture -> IO ()
_bprintPicture    = putStr . concat . map ((++ "\n") . map (\b -> if b
                                                                  then '#'
                                                                  else '.'))

createPic :: Int -> Int -> Picture
createPic h w    = replicate h ((concat . replicate w) ".")

addPt :: (Int, Int) -> Picture -> Picture
addPt (h, w) pic    = take h pic ++ [take w (pic !! h) ++ "#" ++ drop (w + 1) (pic !! h)]
                      ++ drop (h + 1) pic

addPts :: [(Int, Int)] -> Picture -> Picture
addPts pts pic    = foldr addPt pic pts

qualify :: [(Int, Int)] -> (Int, Int) -> [(Int, Int)]
qualify ptl sz    = filter (\(y, x) -> (fst sz >= y) && (x >= 0)
                                       && (snd sz >= x) && (y >= 0)) ptl

makePicture :: Int -> Int -> [(Int, Int)] -> Picture
makePicture w h pts    = addPts (qualify pts (h, w)) (createPic h w)

picSize :: Picture -> (Int, Int)
picSize pic    = (length (head pic), length pic)

pointsCreate :: Int -> Int -> [(Int, Int)]
pointsCreate w h    = zip
    ((concat . (map (concat . replicate w))) (map (\x -> [x]) [0 .. (h - 1)]))
    ((concat . replicate h) [0 .. (w - 1)])

isBlack :: (Int, Int) -> Picture -> Bool
isBlack (h, w) pic    = (pic !! h) !! w == '#'

blackList :: Picture -> [(Int, Int)]
blackList pic    = filter (`isBlack` pic) (uncurry pointsCreate (picSize pic))

picToRep :: Picture -> (Int, Int, [(Int, Int)])
picToRep pic    = ((fst . picSize) pic, (snd . picSize) pic, blackList pic)

type Rep = (Int, Int, [(Int, Int)])

repRotate :: Rep -> Rep
repRotate (w, h, locs)    = (h, w, map (\(y, x) -> (x, h - 1 - y)) locs)

data Move = Rock | Paper | Scissors
            deriving (Show, Eq)

type Strategy = [Move] -> Move

beat :: Move -> Move
beat Rock  = Paper
beat Paper = Scissors
beat _     = Rock

lose :: Move -> Move
lose Rock  = Scissors
lose Paper = Rock
lose _     = Paper

alternate :: Strategy -> Strategy -> [Move] -> Move
alternate str1 str2 moves    = map ($ moves) [str1, str2] !! (length moves `mod` 2)

sToss :: Strategy -> Strategy -> Strategy
sToss str1 str2    = [str1, str2] !! (fromInteger (randInt 2) :: Int)

sTossList :: [Strategy] -> Strategy
sTossList []    = \moves -> head moves
sTossList ls    = ls !! (fromInteger (randInt ((toInteger . length) ls)) :: Int)

alternativeList :: [Strategy] -> [Move] -> Strategy
alternativeList strs moves    = strs !! (length moves `mod` length strs)

type Moves = [Move]

counterMoves :: Moves -> Strategy -> Moves
counterMoves mv str    = map (str . flip take mv) [1 .. length mv]

mvCompete :: Move -> Move -> Integer
mvCompete mv1 mv2
    | mv1 == mv2         = 0
    | beat mv1 == mv2    = 1
    | otherwise          = -1

outcome :: Strategy -> Moves -> Integer
outcome str mvs    = sum (zipWith mvCompete (counterMoves mvs str) mvs)

outcomes :: [Strategy] -> Moves -> [Integer]
outcomes strs mvs    = map (`outcome` mvs) strs

maxWins :: [Strategy] -> Moves -> [Strategy]
maxWins strs moves    = filter (\x -> outcome x moves == maximum (outcomes strs moves)) strs

train :: Moves -> [Strategy] -> Strategy
train moves strs    = bestStrategy !! (fromInteger
                                        (randInt ((toInteger . length) strs)) :: Int)
  where bestStrategy :: [Strategy]
        bestStrategy    = maxWins strs moves

type RegExp = String -> Bool

epsilon :: RegExp
epsilon    = (== "")

char :: Char -> RegExp
char ch    = (== [ch])

(|||) :: RegExp -> RegExp -> RegExp
e1 ||| e2    = \x -> e1 x || e2 x

(&&&) :: RegExp -> RegExp -> RegExp
e1 &&& e2    = \x -> e1 x && e2 x

rnot :: RegExp -> RegExp
rnot e    = not . e

splits :: String -> [(String, String)]
splits str    = map (`splitAt` str) [1 .. length str]

(<*>) :: RegExp -> RegExp -> RegExp
e1 <*> e2    = \x -> or [e1 y && e2 z | (y, z) <- splits x]

star :: RegExp -> RegExp
star p    = epsilon ||| (p <*> star p)

a, b :: RegExp
a    = char 'a'
b    = char 'b'

test1 :: RegExp
test1    = star ((a ||| b) <*> (a ||| b))

-- (a ||| b) <*> (a ||| b) matches "aa" "bb" "ab" "ba"
-- test1 matches with 2n string with "ab" "aa" "bb" "ba"

test2 :: RegExp
test2    = star test1

-- test2 do the same thing as test1 do

prop_test12 :: String -> Bool
prop_test12 str    = test1 str == test2 str

subseqs :: String -> [String]
subseqs str    = map fst (concat (map (splits . snd . (`splitAt` str)) [0 .. length str]))

partlyMatch :: RegExp -> (Int -> Bool) -> RegExp
partlyMatch e i    = i . length . filter e . subseqs

plus, option :: RegExp -> RegExp
option e    = partlyMatch e (== 0) ||| partlyMatch e (== 1)
plus e      = partlyMatch e (>= 2)
