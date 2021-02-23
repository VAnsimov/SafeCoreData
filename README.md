# SafeCoreData - CoreData layer

Thread safe database layer. This layer works with the Core Data. You create entities in the Data model (* .xcdatamodel) and SafeCoreData will work with them: create, fetch, change, delete

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate Alamofire into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'SafeCoreData', :git => 'https://github.com/VAnsimov/SafeCoreData.git', :tag => '0.1.1'
```

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but Alamofire does support its use on supported platforms.

Once you have your Swift package set up, adding Alamofire as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/VAnsimov/SafeCoreData.git", .upToNextMajor(from: "0.1.1"))
],
targets: [
    .target(name: "YourPackageManager", dependencies: ["SafeCoreData"]),
]
```


## Initialization


```swift
import SafeCoreData
```

You need to create a *.xcdatamodel file
- Select File -> New -> File...
- Select "Data Module"

After сreate an object that will work with your database


```swift
let dataStorage = SafeCoreData(databaseName: "Storage", bundleIdentifier: "<your bundle Identifier>")
```

It is possible to create a SafeConfiguration with different settings

```swif
let configuration = SafeConfiguration.DataBase(modelName: "Storage", bundleIdentifier: "<your bundle Identifier>")
        .persistentType(NSSQLiteStoreType)
        .fileName("Storage.sqlite")
        .printTypes([.pathCoreData(prefix: "Database path: ")])

/* OR
let configuration = SafeConfiguration.DataBase(
    modelName: "Storage",
    bundleIdentifier: "<your bundle Identifier>",
    persistentType: NSSQLiteStoreType,
    printTypes: [.pathCoreData(prefix: "Database path: ")]
)
*/

let dataStorage = SafeCoreData(database: configuration)
```

## Usage

### Create

```swift
dataStorage.create(type: UserEntity.self, updateProperties: { newObject in
    newObject.name = "Anna"
    newObject.age = Int16(29)
    newObject.personalQualities = "Versatile"
}, success: { object in
    // Entity created and saved
}, fail: { error in 
    // Something went wrong
})
```

Or

```swift
let configuration = SafeConfiguration.Create()
        .concurrency(.sync)
/* OR
let configuration = SafeConfiguration.Create(concurrency: .sync) 
*/

dataStorage.create(type: UserEntity.self, configure: configuration, updateProperties: { newObject in
    newObject.name = "Anna"
    newObject.age = Int16(29)
    newObject.personalQualities = "Versatile"
    
    let bag: BagEntity? = newObject.createChildObject(updateProperties: { newChildObject in
        newChildObject.bagColor = "blue"
    })
    newObject.bag = bag
}, success: { object in
    // Entity created and saved
}, fail: { error in 
    // Something went wrong
})
```

### Fetch

```swift
dataStorage.fetch(withType: UserEntity.self, success: { entities in
    // All results
}, fail: { error in 
    // Something went wrong
})
```

Or

```swift
let configuration = SafeConfiguration.Fetch()
        .filter(NSPredicate(format: "age == \(Int16(29))"))
        .sort([NSSortDescriptor(key: "age", ascending: true)])
        .concurrency(.sync)

dataStorage.fetch(withType: UserEntity.self, configure: configuration, success: { entities in
    // Search results
}, fail: { error in 
    // Something went wrong
})
```

### Save


```swift
let configuration = SafeConfiguration.Fetch()
        .filter(NSPredicate(format: "name == Anna"))

dataStorage.fetch(withType: UserEntity.self, configure: configuration, success: { entities in
    entities.first?.personalQualities = "Initiative"
    
    // Synchronous save
    entities.first?.saveСhangesSync()
    
    entities.first?.personalQualities = "Versatile"
    
    // Or asynchronous save
    entities.first?.saveСhangesAsync(sucsess: {
        // Changes saved
    }, fail: { error in 
        // Something went wrong
    })
})
```


### Remove

```swift
dataStorage.remove(type: UserEntity.self, success: { ids in
    // All entities removed
},fail: { error in 
    // Something went wrong
})
```

Or

```swift
let config = SafeConfiguration.Remove().filter(NSPredicate(format: "name == Anna"))

dataStorage.remove(type: UserEntity.self, config: config, success: { ids in
    // Found results deleted
},fail: { error in 
    // Something went wrong
})
```

Or

```swift
dataStorage.fetch(withType: UserEntity.self, success: { entities in
    // Synchronous deletion
    entities.first?.deleteSync()
    
    // Or asynchronous deletion
    entities.last?.deleteAsync(sucsess: {
        // Entity deleted successfully
    }, fail: { error in
        // Something went wrong
    })
})
```

### Error

```swift
dataStorage.fetch(withType: UserEntity.self, success: { entities in
    // All results
}, fail: { error in 
    // Something went wrong
})
```
