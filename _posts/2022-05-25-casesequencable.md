---
layout: post
title:  "CaseSequencable: Put your enums in order"
date:   2022-05-25 21:03:36 +0530
categories: Swift CaseIterable Protocols
doctest: false

---

Enums are often used to model states. If we want to move to the next state (in order of declaration) we have to do the switch dance:

```swift
enum MyState {
  case sleeping
  case working
  case chilling
}

var myState: MyState = .sleeping

func nextState() {
	switch myState {
    case sleeping:
    ....
  }
}
```

By conforming an enum to`CaseIterable` type, we can access a collection of all of the type’s cases by using the type’s `allCases` property. The `allCases` property is compiler synthesized (for enums that don’t have associated values) and provides the cases in order of their declaration.

We can implement a simple protocol named `CaseSequencable` which inherits from the `CaseIterable` protocol:
```swift
protocol CaseSequencable: CaseIterable, Equatable {
    var nextCase: Self { get }
}

extension CaseSequencable {
    var nextCase: Self {
        // allCases is compiler synthesized (for enums without associated values)
        // there is no possible way for self to not exist in allCases
        // if you manually conform to CaseIterable it will crash :D
        let selfIndex = Self.allCases.firstIndex(of:self)!

        let nextIndex = Self.allCases.index(after: selfIndex)
        if nextIndex == Self.allCases.endIndex {
            return Self.allCases[Self.allCases.startIndex]
        } else {
            return Self.allCases[nextIndex]
        }
    }
}
```

And use it in the following way:
```swift
enum MyState: CaseSequencable {
  case sleeping
  case working
  case chilling
}

var myState: MyState = .sleeping

myState // .sleeping
myState.next // .working
myState.next.next // .chilling
myState.next.next.next // .sleeping (loops back to the first case)
```

Feel free to [contact me](mailto:orjpap@gmail.com) or tweet to me on [Twitter](https://twitter.com/orjpap) for tips, feedback, opinions.

Thank you for reading!