---

layout: post
title:  "UserDefaultsPersistable: Save and Load any struct to/from UserDefaults"
date:   2021-10-10 21:03:36 +0530
categories: Swift UserDefaults iOS Protocols
doctest: false

---

The user’s defaults database is a key-value store that let’s you persist data across app launches. It is meant to be used to store user preferences. Using the `Codeable` protocol and a `JSONEncoder` you can very easily convert Swift types to JSON data in order to store them.

Save/Load Codeable structs
--------------------------

To save data into `UserDefaults` you must first encode it as JSON, and then save it using a specified key like this:
```swift
struct Settings: Codeable {
  ...
}

let userSettings = Settings()

let encoder = JSONEncoder()
if let encoded = try? encoder.encode(userSettings) {
    UserDefaults.standard.set(encoded, forKey: "archiveKey")
}
```

Then you can load it like this:
```swift
if let savedSettingsData = UserDefaults.standard.object(forKey: "archiveKey") as? Data else {
    let decoder = JSONDecoder()
    let loadedSettings = try? decoder.decode(Settings.self, from: savedSettingsData) // Settings?
}
```

Reusability
-----------

Using Swift protocols and [protocol inheritance](https://docs.swift.org/swift-book/LanguageGuide/Protocols.html#ID280), we can define a`UserDefaultsPersistable` protocol:
```swift
protocol DefaultInitializable {
  init()
}

protocol UserDefaultsPersistable: Codable, DefaultInitializable {
    static var key: String {get}
}
```

We also defined another protocol called `DefaultInitializable` for types than can be initialized with a default value using a default initializer. The default value will be used in cases where we’re looking for the specific type in `UserDefaults` and it does not exist.

In order to provide a default implementation of `save` and `load` functions we will also create a `UserDefaultsPersister`:

```swift
struct UserDefaultsPersister<A: UserDefaultsPersistable> {
    static func save(_ value: A) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(value) {
            UserDefaults.standard.set(encoded, forKey: A.key)
        }
    }

    static func load() -> A {
        guard let savedSettingsData = UserDefaults.standard.object(forKey: A.key) as? Data else {
            return A()
        }

        let decoder = JSONDecoder()
        let loadedSettings = try? decoder.decode(A.self, from: savedSettingsData)
        return loadedSettings ?? A()
    }
}
```

And provide the default implementations for `UserDefaultsPersistable` protocol:
```swift
extension UserDefaultsPersistable {
    func save() {
        UserDefaultsPersister.save(self)
    }

    static func load() -> Self {
        return UserDefaultsPersister.load()
    }
}
```

Usage
-----

For example, if you want to persist your app’s Audio settings:
```swift
struct AudioPreferences: UserDefaultsPersistable {
    static var key = "userAudioPreferences"
    var volume = 1.0 // default value
    var bass = 0.5
    var treble = 0.5
    var quality = 1.0
}

var audioPreferences = AudioPreferences.load()

// user modifies volume
audioPreferences.volume = 1.0
audioPreferences.save() // Audio preferences are saved in user defaults
```

Declaring a type to be `UserDefaultsPersistable` allows you to easily store it in `UserDefaults` by only specifying a key. Obviously with this approach you can’t store more than one instance of the same type but when it comes to storing user preferences this is a safety mechanism rather than a limitation.

Feel free to [contact me](mailto:orjpap@gmail.com) for tips, feedback, opinions.

Thank you for reading!