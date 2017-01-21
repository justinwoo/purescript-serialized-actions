# purescript-serialized-actions

This repo is an example of how to use [purescript-foreign-generic](https://github.com/paf31/purescript-foreign-generic) to automatically (de)serialize JSON for a simple ADT.

First, we define our ADT and by deriving `Rep.Generic` (from [purescript-generics-rep](https://github.com/purescript/purescript-generics-rep)), we can use functions of `Rep.Generic` to define `Show` and `IsForeign` (from [purescript-foreign](https://github.com/purescript/purescript-foreign)).

```hs
data Action
  = Increment
  | Add Int
  | Set {count :: Int}
  | Reset

derive instance genericRepAction :: Rep.Generic Action _
instance showAction :: Show Action where show = genericShow
instance isForeignAction :: IsForeign Action where read = readGeneric $ DFG.defaultOptions
```

Having an `IsForeign` instance lets us serialize our Purescript `Action` data into a `Foreign`, the raw Javascript representation:

```hs
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
```

But more importantly, having that `IsForeign` instance lets us then read JSON (or raw Javascript `Foreign` objects) into our `Action` data. Importantly though, if we try to decode invalid JSON that does not have a valid decoder, we can know about it and handle the error.

```hs
logActionJson = log <<< either (const "did not decode") show <<< runExcept <<< jsonToAction
jsonToAction :: String -> F Action
jsonToAction = readJSONGeneric DFG.defaultOptions

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
```

Of course, this is not really the most important usage for decoders. A more likely case is for foreign JSON returned from anything that may return incorrect/invalid JSON, such as JS libraries, remote endpoints, JSON files, etc.

### FAQ

#### Isn't this doable in plain Javascript/Typescript/Flow?

I'd love to see some examples if this actually is doable, but I'm going to be really upset if you show me something that doesn't work.

### This whole "tag" and "contents" thing is exactly like Redux actions!!!!

I honestly don't know of any cases outside of when working with sum types when you'd actually need a "tag" field for disambiguating constructors. For example, I use `unwrapSingleConstructors` [here](https://github.com/justinwoo/purescript-node-telegram-bot-api/blob/master/src/TelegramBot.purs) for all my types.

I would really like to see examples of actions getting de/encoded though. Please let me know of any examples.

#### Why not just use JSON.parse/coerce the type?

I find that I have too many bugs due to inconistent return values and my own mistakes in preparing the JSON. By using decoders, I know what is wrong and develop plans for what should be done when things go wrong.

Also, let's be real. If you write code that just uses JSON.parse and uses it as if it's the correct type and everything, you're basically writing code with `eval`s. If your defense is that you treat them as maps but you're still using specific fields from this supposed map, then you don't even make sense.

#### Why do you "need" automatic de/encoding?

I find that the boilerplate required for writing any kind of decoder/parser/schema is usually too costly to write and too much of a pain to maintain. In the case of javascript, even if I maintain my schema correctly, the tools for working with the type information extracted from the schemas are too low quality for me to have any faith in them. If you disagree with this, please send me some examples, because I would love to use something for when I have to write JS.

Also, it is still very easy to make mistakes in writing decoders, especially if your language doesn't have `newtype` and derived instances: https://twitter.com/eeue56/status/803685045143801856
