# SafeCoreData - CoreData layer

Thread safe database layer. This layer works with the Core Data. You create entities in the Data model (* .xcdatamodel) and SafeCoreData will work with them: create, fetch, change, delete

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but Alamofire does support its use on supported platforms.

Once you have your Swift package set up, adding Alamofire as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/VAnsimov/SafeCoreData.git", .upToNextMajor(from: "2.0.0"))
],
targets: [
    .target(name: "<YourPackageManager>", dependencies: ["SafeCoreData"]),
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
let databaseName = "<your *.xcdatamodel name>"
let dataStorage = SafeCoreData(databaseName: databaseName, bundle: .main)
```

It is possible to create a SafeConfiguration with different settings

```swift
let databaseName = "<your *.xcdatamodel name>"
let configuration = SafeCoreData.DataBase.Configuration(modelName: databaseName, bundleType: .bundle(.main))
        .persistentType(.sqlLite)
        .modelVersion(7)
        .printTypes([.pathCoreData(prefix: "Database path: ")])

/* OR
let configuration = SafeConfiguration.DataBase(
    modelName: databaseName,
    bundleType: .bundle(.main),
    persistentType: .sqlLite,
    modelVersion: 7,
    printTypes: [.pathCoreData(prefix: "Database path: ")]
)
*/

let dataStorage = SafeCoreData(database: configuration)
```

## Usage

### Create single object

```swift

SafeCoreDataCreate(dataStorage: dataStorage)
            .outputThread(.global)
            .createObject(withTyp: UserEntity.self, updateProperties: { newObject in
                newObject.name = "Anna"
                newObject.age = Int16(29)
                newObject.personalQualities = "Versatile"
            }, success: { object in
                // Entity created and saved
            }, failure: { error in 
                // Something went wrong
            })
```

Or Async/Await version

```swift
Task {
    let data = try? await SafeCoreDataCreate(dataStorage: dataStorage)
        .createObject(withType: UserEntity.self, updateProperties: { newObject in
            newObject.name = "Anna"
            newObject.age = Int16(29)
            newObject.personalQualities = "Versatile"
        }).value
        
    // Entity created and saved
}
```

Or Combine version

```swift
let createFuture = SafeCoreDataCreate(dataStorage: dataStorage)
        .createObjectFuture(withType: UserEntity.self, updateProperties: { newObject in
            newObject.name = "Anna"
            newObject.age = Int16(29)
            newObject.personalQualities = "Versatile"
        })

createFuture.sink(receiveCompletion: { completion in
    switch completion {
    case let .failure(error):
        // Something went wrong
    case .finished:
        break
    }
}, receiveValue: { result in
    // Entity created and saved
}).store(in: &cancellable)

```

### Create list objects

```swift
let names = ["Anna", "Jack", "Harry"]

SafeCoreDataCreate(dataStorage: dataStorage)
            .outputThread(.main)
            .createListOfObjects(type: UserEntity.self, list: names, updateProperties: { item, newObject in
                newObject.name = item
            }, success: { object in
                // Entity created and saved
            }, failure: { error in 
                // Something went wrong
            })
```

Or Async/Await version

```swift
Task {
    let names = ["Anna", "Jack", "Harry"]

    let data = try? await SafeCoreDataCreate(dataStorage: dataStorage)
        .createListOfObjects(withType: UserEntity.self, list: names, updateProperties: { item, newObject in
            newObject.name = item
        }).value
        
    // Entity created and saved
}
```

Or Combine version

```swift
let createFuture = SafeCoreDataCreate(dataStorage: dataStorage)
        .createListOfObjectsFuture(withType: UserEntity.self, list: names, updateProperties: { item, newObject in
            newObject.name = item
        })

createFuture.sink(receiveCompletion: { completion in
    switch completion {
    case let .failure(error):
        // Something went wrong
    case .finished:
        break
    }
}, receiveValue: { result in
    // Entity created and saved
}).store(in: &cancellable)

```

### Fetch

```swift
SafeCoreDataFetch(dataStorage: dataStorage)
    .filter(NSPredicate(format: "age == \(Int16(29))"))
    .sort([NSSortDescriptor(key: "age", ascending: true)])
    .outputThread(.global)
    .fetch(withType: UserEntity.self, success: { object in
        // Results
    }, failure: { error in
        // Something went wrong
    })
```

Or Async/Await version

```swift
Task {
    let fetchResult = try? await SafeCoreDataFetch(dataStorage: dataStorage)
        .filter(NSPredicate(format: "age == \(Int16(29))"))
        .fetch(withType: UserEntity.self).value
        
    // Results
}
```

Or Combine version

```swift
let fetchFuture = SafeCoreDataFetch(dataStorage: dataStorage)
    .sort([NSSortDescriptor(key: "age", ascending: true)])
    .fetchFuture(withType: UserEntity.self).eraseToAnyPublisher()

fetchFuture
    .sink { completion in
        switch completion {
        case let .failure(error):
            // Something went wrong

        case .finished:
            break
        }
    } receiveValue: { fetchResult in
        // Results
    }.store(in: &cancellable)
```

### Save


```swift
SafeCoreDataFetch(dataStorage: dataStorage)
    .fetch(withType: UserEntity.self, success: { result in
        let firstObject = result.value?.first
        
        firstObject?.personalQualities = "Initiative"
    
        // Synchronous save
        firstObject?.saveСhangesSync()
    
        firstObject?.personalQualities = "Versatile"
    
        // Or asynchronous save
        firstObject?.saveСhangesAsync(sucsess: {
            // Changes saved
        }, fail: { error in 
            // Something went wrong
        })
    })
```

### Remove

```swift

let removeStorage = SafeCoreDataRemove(dataStorage: dataStorage)

// Removes results by filter
removeStorage
    .filter(NSPredicate(format: "age == \(Int16(29))"))
    .remove(withType: UserEntity.self, success: { object in
        // Found results deleted
    }, failure: { error in
        // Something went wrong
    })
    
// Removes all results
removeStorage    
    .remove(withType: UserEntity.self, success: { object in
        // Found results deleted
    }, failure: { error in
        // Something went wrong
    })
```

Or

```swift
SafeCoreDataFetch(dataStorage: dataStorage)
    .fetch(withType: UserEntity.self, success: { result in
        let firstObject = result.value?.first
        
        // Synchronous deletion
        firstObject?.deleteSync()
    
        // Or asynchronous deletion
        firstObject?.deleteAsync(sucsess: {
            // Entity deleted successfully
        }, fail: { error in
            // Something went wrong
        })
    })
```
