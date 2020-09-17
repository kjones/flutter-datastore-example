import Combine
import Amplify

protocol DataStoreStreamHandler: NSObject, FlutterStreamHandler {}

class DataStoreSaveStreamHandler<M: Model>: NSObject, DataStoreStreamHandler {
    init(item: M) {
        self.item = item
    }

    let item: M

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Amplify.DataStore.save(item) { result in
            switch result {
            case .success(let savedItem):
                let newItem = ["itemClass": M.modelName, "item": try! savedItem.toJSON()]
                events(newItem)
                events(FlutterEndOfEventStream)

            case .failure(let error):
                events(FlutterError(code: "DataStoreSaveFailure", message: error.errorDescription, details: error.debugDescription))
            }
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

class DataStoreDeleteStreamHandler<M: Model>: NSObject, DataStoreStreamHandler {
    init(itemId: String) {
        self.itemId = itemId
    }

    let itemId: String

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Amplify.DataStore.delete(M.self, withId: itemId) { result in
            switch result {
            case .success:
                events(true)
                events(FlutterEndOfEventStream)

            case .failure(let error):
                events(FlutterError(code: "DataStoreDeleteFailure", message: error.errorDescription, details: error.debugDescription))
            }
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

class DataStoreQueryStreamHandler<M: Model>: NSObject, DataStoreStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        Amplify.DataStore.query(M.self) { result in
            switch result {
            case .success(let itemIterator):
                let items = itemIterator.map { item in
                    ["itemClass": M.modelName, "item": try! item.toJSON()]
                }

                events(items)
                events(FlutterEndOfEventStream)

            case .failure(let error):
                events(FlutterError(code: "DataStoreQueryFailure", message: error.errorDescription, details: error.debugDescription))
            }
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}

class DataStoreObserveStreamHandler: NSObject, DataStoreStreamHandler {
    var subscriptions: [AnyCancellable]?

    let models: [() -> AnyPublisher<MutationEvent, DataStoreError>] = [
        getDataStorePublisher(for: Todo.self),
    ]

    static func getDataStorePublisher<M: Model>(for type: M.Type) -> () -> AnyPublisher<MutationEvent, DataStoreError> {
        return { () in Amplify.DataStore.publisher(for: M.self) }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        subscriptions = models.map { getDataStorePublisher in
            getDataStorePublisher()
                .sink(
                    receiveCompletion: { _ in events(FlutterEndOfEventStream) },
                    receiveValue: { mutationEvent in
                        let itemChange = [
                            "uuid": mutationEvent.id,
                            "type": mutationEvent.mutationType,
                            "itemClass": mutationEvent.modelName,
                            "item": mutationEvent.json,
                        ]
                        events(itemChange)
                    })
        }

        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        subscriptions?.removeAll()
        return nil
    }
}
