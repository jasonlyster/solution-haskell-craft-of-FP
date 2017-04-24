module CalcInpt where

import           System.IO
import           System.IO.Unsafe (unsafePerformIO)
import           Data.Char

data Expr = Lit { value    :: Int }
          | Var { variable :: String }
          | Op { operate   :: Ops
               , express1  :: Expr
               , express2  :: Expr }

data Ops = Add | Sub | Mul | Div | Mod

type Parse a b = [a] -> [(b, [a])]

none :: Parse a b
none _    = []

spot :: (a -> Bool) -> Parse a a
spot f (x : xs) | f x          = [(x, xs)]
                | otherwise    = []
spot _ []                      = []

token :: Eq a => a -> Parse a a
token t    = spot (== t)

-- tc is testcase and tp is testpass
succeed :: b -> Parse a b
succeed tp tc    = [(tp, tc)]

alt :: Parse a b -> Parse a b -> Parse a b
alt p1 p2 tc    = p1 tc ++ p2 tc

-- actually a combinator with originally: [a] to b, c, [a], then to [((b, c), [a])]
infixr 5 >*>
(>*>) :: Parse a b -> Parse a c -> Parse a (b, c)
(parse1 >*> parse2) testcase    = [ ((get1, get2), rem2) | (get1, rem1) <- parse1 testcase
                                                         , (get2, rem2) <- parse2 rem1 ]

-- change the form of parsed val, [(val, rem)] to [(f val, rem)]
build :: Parse a b -> (b -> c) -> Parse a c
build p f t    = map (\(v, r) -> (f v, r)) (p t)

-- list all the parsed until not valid: [a] to [([b], [a])]
list :: Parse a b -> Parse a [b]
list p    = succeed [] `alt` ((p >*> list p) `build` uncurry (:))

bracketL :: Parse Char Char
bracketL    = token '('

digit :: Parse Char Char
digit    = spot isDigit

digList :: Parse Char String
digList    = list digit

neList :: Parse a b -> Parse a [b]
neList p val | null val                      = []
             | (null . snd . head) subres    = subres
             | otherwise                     = []
  where subres                               = _original p val

optional :: Parse a b -> Parse a [b]
optional p val | null subres    = []
               | otherwise      = _original p val
  where subres                  = p val

_original :: Parse a b -> Parse a [b]
_original _ []                 = [([], [])]
_original p val | null res     = succeed [] val
                | otherwise    = ((p >*> _original p) `build` uncurry (:)) val
  where res                    = p val

nTimes :: Integer -> Parse a b -> Parse a [b]
nTimes t p c    = undefined
