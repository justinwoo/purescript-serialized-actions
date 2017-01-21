module Main where

import Prelude
import Data.Foreign.Generic as DFG
import Data.Generic.Rep as Rep
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Console (CONSOLE, log)
import Control.Monad.Except (runExcept)
import Data.Either (either)
import Data.Foldable (traverse_)
import Data.Foreign (F)
import Data.Foreign.Class (class IsForeign)
import Data.Foreign.Generic (readGeneric, readJSONGeneric, toForeignGeneric)
import Data.Generic.Rep.Show (genericShow)

data Action
  = Increment
  | Add Int
  | Set {count :: Int}
  | Reset

derive instance genericRepAction :: Rep.Generic Action _
instance showAction :: Show Action where show = genericShow
instance isForeignAction :: IsForeign Action where read = readGeneric $ DFG.defaultOptions

main :: forall e. Eff (console :: CONSOLE | e) Unit
main = do
  traverse_ logForeign
    [ Reset
    , Set {count: 5}
    , Increment
    , Add 2
    ]
  -- result:
  -- { tag: 'Reset' }
  -- { contents: { count: 5 }, tag: 'Set' }
  -- { tag: 'Increment' }
  -- { contents: 2, tag: 'Add' }

  logActionJson "{ \"tag\": \"Reset\" }"
  logActionJson "{ \"contents\": { \"count\": 5 }, \"tag\": \"Set\" }"
  logActionJson "{ \"tag\": \"Increment\" }"
  logActionJson "{ \"contents\": 2, \"tag\": \"Add\" }"
  logActionJson "{ \"tag\": \"Invalid\"}"
  -- result:
  -- Reset
  -- (Set { count: 5 })
  -- Increment
  -- (Add 2)
  -- did not decode
  where
    logForeign = dangerousLog <<< toForeignGeneric DFG.defaultOptions
    logActionJson = log <<< either (const "did not decode") show <<< runExcept <<< jsonToAction
    jsonToAction :: String -> F Action
    jsonToAction = readJSONGeneric DFG.defaultOptions

foreign import dangerousLog :: forall a e. a -> Eff (console :: CONSOLE | e) Unit
