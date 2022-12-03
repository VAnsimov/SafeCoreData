# SafeCoreData - CoreData layer

Thread safe database layer. This layer works with the Core Data. You create entities in the Data model (* .xcdatamodel) and SafeCoreData will work with them: create, fetch, change, delete

- [Installation](#installation)
- [Initialization](#initialization)
- [Usage - Callbacks](#usage-callbacks)
- [Usage - Async/Await](#usage-async/await)
- [Usage - Combine](#usage-combine)

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but Alamofire does support its use on supported platforms.

Once you have your Swift package set up, adding Alamofire as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/VAnsimov/SafeCoreData.git", .upToNextMajor(from: "2.1.0"))
],
targets: [
    .target(name: "<YourPackageManager>", dependencies: ["SafeCoreData"]),
]
```

## Initialization

#### Step 1

You need to create a *.xcdatamodel file
- Select File -> New -> File...
- Select "Data Module"

#### Step 2

After that you need to create an NSManagedObject in the *.xcdatamodel

Sometimes it is necessary to reload Xcode so that the created NSManagedObject xcode can see

#### Step 3

```swift
import SafeCoreData
```

#### Step 4

```swift
let databaseName = "<your *.xcdatamodel name>"
let safeCoreData = try? SafeCoreData(databaseName: databaseName, bundle: .main)
```

OR

It is possible to create a SafeConfiguration with different settings

```swift
let databaseName = "<your *.xcdatamodel name>"
let configuration = SafeCoreData.DataBase.Configuration(modelName: databaseName, bundleType: .bundle(.main))
        .persistentType(.sqlLite)
        .modelVersion(7)
        .pathDirectory(.cachesDirectory) // FileManager.SearchPathDirectory.cachesDirectory is for temporary storage

/* OR
let configuration = SafeConfiguration.DataBase(
    modelName: databaseName,
    bundleType: .bundle(.main),
    persistentType: .sqlLite,
    modelVersion: 7,
    printTypes: [.pathCoreData(prefix: "Database path: ")]
)
*/

let safeCoreData = try? SafeCoreData(database: configuration)
```

## Usage-Callbacks

#### Important

The SafeCoreData.Service.Data type is returned for all operations. Calling deinit from this structure all data in the NSManagedObject will be erased.

All operations are performed in a private context and when SafeCoreData.Service.Data deinit is called, the private context is also destroyed and the results that are bound to it are also deleted.

When did you get data it is recommended NSManagedObject to map into another type to save the data 

### Create single object

```swift
safeCoreData
    .withCreateParameters
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

### Create list objects

```swift
let names = ["Anna", "Jack", "Harry"]

safeCoreData
    .withCreateParameters
    .createListOfObjects(type: UserEntity.self, list: names, updateProperties: { item, newObject in
        newObject.name = item
    }, success: { object in
        // Entity created and saved
    }, failure: { error in 
        // Something went wrong
    })
```

### Fetch

```swift
// Fetch all result
safeCoreData
    .withFetchParameters
    .fetch(withType: UserEntity.self, success: { object in
        // Results
    }, failure: { error in
        // Something went wrong
    })
   
// Fetch filter result 
safeCoreData
    .withFetchParameters
    .filter(NSPredicate(format: "age == \(Int16(29))"))
    .sort([NSSortDescriptor(key: "age", ascending: true)])
    .outputThread(.global)
    .fetch(withType: UserEntity.self, success: { object in
        // Results
    }, failure: { error in
        // Something went wrong
    })
```

### Save/Change

```swift
safeCoreData
    .withFetchParameters
    .fetch(withType: UserEntity.self, success: { result in
        let firstObject = result.value?.first
        
        firstObject?.personalQualities = "Initiative"
    
        // Synchronous save
        firstObject?.saveСhangesSync()
    
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

// Removes all results
safeCoreData
    .withRemoveParameters    
    .remove(withType: UserEntity.self, success: { object in
        // Found results deleted
    }, failure: { error in
        // Something went wrong
    })
    
// Removes results by filter
safeCoreData
    .withRemoveParameters
    .filter(NSPredicate(format: "age == \(Int16(29))"))
    .remove(withType: UserEntity.self, success: { object in
        // Found results deleted
    }, failure: { error in
        // Something went wrong
    })
```

Or

```swift
safeCoreData
    .withFetchParameters
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

## Usage-Async/Await

#### Important

The SafeCoreData.Service.Data type is returned for all operations. Calling deinit from this structure all data in the NSManagedObject will be erased.

All operations are performed in a private context and when SafeCoreData.Service.Data deinit is called, the private context is also destroyed and the results that are bound to it are also deleted.

When did you get data it is recommended NSManagedObject to map into another type to save the data 

### Create single object

```swift
let result = try await safeCoreData
    .withCreateParameters
    .createObject(withType: UserEntity.self, updateProperties: { newObject in
        newObject.name = "Anna"
        newObject.age = Int16(29)
        newObject.personalQualities = "Versatile"
    })
    
let createdObject = result.value
```

### Create list objects

```swift
let names = ["Anna", "Jack", "Harry"]

let createdResult = try? await safeCoreData
    .withCreateParameters
    .createListOfObjects(withType: UserEntity.self, list: names, updateProperties: { item, newObject in
        newObject.name = item
    }).value
    
let createdObjects = createdResult.value
```

### Fetch

```swift
// Fetch all results
let fetchAllResult = try? await safeCoreData
    .withFetchParameters
    .fetch(withType: UserEntity.self)
    
let fetchAllObjects = fetchAllResult.value

// Fetch filter results
let fetchResult = try? await safeCoreData
    .withFetchParameters
    .filter(NSPredicate(format: "age == \(Int16(29))"))
    .fetch(withType: UserEntity.self)
    
let fetchObjects = fetchResult.value
```

### Save/Change

```swift
let fetchResult = try? await safeCoreData
    .withFetchParameters
    .fetch(withType: UserEntity.self)
    
let firstObject = fetchResult.value?.first
        
firstObject?.personalQualities = "Initiative"
    
// Synchronous save
firstObject?.saveСhangesSync()
    
// Or asynchronous save
await firstObject?.saveСhanges()
```

### Remove

```swift
// Removes all results
let removeAllResult = try? await safeCoreData
    .withRemoveParameters
    .remove(withType: UserEntity.self)
    
let removeAllIds = removeAllResult.value

// Removes results by filter
let removeResult = try? await safeCoreData
    .withRemoveParameters
    .filter(NSPredicate(format: "age == \(Int16(29))"))
    .remove(withType: UserEntity.self)

let removeIds = removeResult.value
```

Or

```swift
let fetchResult = try? await safeCoreData
    .withFetchParameters
    .fetch(withType: UserEntity.self)
    
let firstObject = fetchResult.value?.first

// Synchronous deletion
firstObject?.deleteSync()
    
// Or asynchronous deletion
await firstObject?.delete()
```

## Usage-Combine

#### Important

The SafeCoreData.Service.Data type is returned for all operations. Calling deinit from this structure all data in the NSManagedObject will be erased.

All operations are performed in a private context and when SafeCoreData.Service.Data deinit is called, the private context is also destroyed and the results that are bound to it are also deleted.

When did you get data it is recommended NSManagedObject to map into another type to save the data 

### Create single object

```swift
        
let createFuture = safeCoreData
    .withCreateParameters
    .createObjectFuture(withType: UserEntity.self, updateProperties: { newObject in
        newObject.name = "Anna"
        newObject.age = Int16(29)
        newObject.personalQualities = "Versatile"
    })
    .sink { _ in
        // Completion
    } receiveValue: { result in
        // Entity created and saved
    }
    .store(in: &cancellable)

```

### Create list objects

```swift
let names = ["Anna", "Jack", "Harry"]

safeCoreData
    .withCreateParameters
    .createListOfObjectsFuture(withType: UserEntity.self, list: names, updateProperties: { item, newObject in
        newObject.name = item
    })
    .sink { _ in
        // Completion
    } receiveValue: { result in
        // Entity created and saved
    }
    .store(in: &cancellable)
```

### Fetch

```swift
safeCoreData
    .withFetchParameters
    .fetchFuture(withType: UserEntity.self)
    .sink {  _ in
        // Completion
    } receiveValue: { fetchResult in
        // Results
    }
    .store(in: &cancellable)
```

### Save/Change

```swift
safeCoreData
    .withFetchParameters
    .fetchFuture(withType: UserEntity.self)
    .flatMap { fetchResult in
        let firstObject = $0.value.first
        
        firstObject?.personalQualities = "Initiative"
        
        // Save object
        return firstObject?.saveСhangesFeature() ?? Empty().eraseToAnyPublisher()
    }
    .sink {  _ in
        // Completion
    } receiveValue: { fetchResult in
        // The first object is successfully deleted
    }
    .store(in: &cancellable)
```

### Remove

```swift
// Removes all results
safeCoreData
    .withRemoveParameters
    .removeFuture(withType: UserEntity.self)
    .sink { _ in
        // completion
    } receiveValue: { removeIds in
        // Found results deleted
    }
    .store(in: &cancellable)
    
// Removes results by filter
safeCoreData
    .withRemoveParameters
    .filter(NSPredicate(format: "age == \(Int16(29))"))
    .removeFuture(withType: UserEntity.self)
    .sink {  _ in
        // Completion
    } receiveValue: { removeIds in
        // Found results deleted
    }
    .store(in: &cancellable)
```

Or

```swift
safeCoreData
    .withFetchParameters
    .fetchFuture(withType: UserEntity.self)
    .flatMap { 
        // Remove object
        $0.value.first?.deleteFeature() ?? Empty().eraseToAnyPublisher() 
    }
    .sink { _ in
        // Completion
    } receiveValue: { _ in
        // The first object is successfully deleted
    }
    .store(in: &cancellable)
```
