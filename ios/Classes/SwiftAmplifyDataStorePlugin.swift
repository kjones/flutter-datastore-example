import Flutter

import Amplify
import AmplifyPlugins

// TODO: There are a couple places where Swift try! was used. They shouldn't happen but if they do
// TODO: it will crash the app.
// TODO: Handle additional parameters to save, delete, and query
// TODO: Lots of repeated parameter validation. Can it be combined?
// TODO: Can stream handlers be consolidated? Seems like they all have a similar structure.
// TODO: Can the AmplifyModels be used to make any of this easier?

public class SwiftAmplifyDataStorePlugin: NSObject, FlutterPlugin {
    public init(messenger: FlutterBinaryMessenger) {
        binaryMessenger = messenger

        dataStoreEventChannel = FlutterEventChannel(name: "com.kjones.amplify_datastore/dataStoreEvents", binaryMessenger: messenger)
        dataStoreStreamHandler = DataStoreObserveStreamHandler()
        dataStoreEventChannel.setStreamHandler(dataStoreStreamHandler)
    }

    let binaryMessenger: FlutterBinaryMessenger
    let dataStoreEventChannel: FlutterEventChannel
    let dataStoreStreamHandler: DataStoreObserveStreamHandler

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.kjones.amplify_datastore/amplify", binaryMessenger: registrar.messenger())
        let instance = SwiftAmplifyDataStorePlugin(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

        do {
            let amplifyModels = AmplifyModels()
            let apiPlugin = AWSAPIPlugin(modelRegistration: amplifyModels)
            let dataStorePlugin = AWSDataStorePlugin(modelRegistration: amplifyModels)
            try Amplify.add(plugin: apiPlugin)
            try Amplify.add(plugin: dataStorePlugin)
        } catch {
            print("Could not initialize Amplify plugins: \(error)")
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion": getPlatformVersion(call: call, result: result)
        case "dataStoreClear": onDataStoreClear(call: call, result: result)
        case "dataStoreSave": onDataStoreSave(call: call, result: result)
        case "dataStoreDelete": onDataStoreDelete(call: call, result: result)
        case "dataStoreQuery": onDataStoreQuery(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getPlatformVersion(call: FlutterMethodCall, result: @escaping FlutterResult) {
        result("iOS " + UIDevice.current.systemVersion)
    }

    private func onDataStoreClear(call: FlutterMethodCall, result: @escaping FlutterResult) {
        Amplify.DataStore.clear { clearResult in
            switch clearResult {
            case .success:
                result(true)

            case .failure(let error):
                result(FlutterError(code: "DataStoreClearFailure", message: error.errorDescription, details: error.debugDescription))
            }
        }
    }

    private func onDataStoreSave(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "InvalidParameter", message: "Required `arguments` missing.", details: nil))
            return
        }

        guard let flutterItemClass = args["itemClass"] as? String else {
            result(FlutterError(code: "InvalidParameter", message: "RequiredParameter 'itemClass' missing.", details: nil))
            return
        }

        guard let itemJson = args["item"] as? String else {
            result(FlutterError(code: "InvalidParameter", message: "RequiredParameter 'item' missing", details: nil))
            return
        }

        guard let saveStreamHandler = try? toDataStoreSaveStreamHandler(flutterItemClass: flutterItemClass, itemJson: itemJson) else {
            result(FlutterError(code: "InvalidClass", message: "Unrecognized query class \(flutterItemClass).", details: nil))
            return
        }

        let eventChannelName = eventChannel(forStreamHandler: saveStreamHandler, result)
        result(eventChannelName)
    }

    private func onDataStoreDelete(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "InvalidParameter", message: "Required `arguments` missing.", details: nil))
            return
        }

        guard let flutterItemClass = args["itemClass"] as? String else {
            result(FlutterError(code: "InvalidParameter", message: "RequiredParameter 'itemClass' missing.", details: nil))
            return
        }

        guard let itemJson = args["id"] as? String else {
            result(FlutterError(code: "InvalidParameter", message: "RequiredParameter 'id' missing", details: nil))
            return
        }

        guard let deleteStreamHandler = try? toDataStoreDeleteStreamHandler(flutterItemClass: flutterItemClass, itemId: itemJson) else {
            result(FlutterError(code: "InvalidClass", message: "Unrecognized query class \(flutterItemClass).", details: nil))
            return
        }

        let eventChannelName = eventChannel(forStreamHandler: deleteStreamHandler, result)
        result(eventChannelName)
    }

    private func onDataStoreQuery(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(code: "InvalidParameter", message: "Required `arguments` missing.", details: nil))
            return
        }

        guard let flutterItemClass = args["itemClass"] as? String else {
            result(FlutterError(code: "InvalidParameter", message: "RequiredParameter 'itemClass' missing.", details: nil))
            return
        }

        guard let queryStreamHandler = toDataStoreQueryStreamHandler(flutterItemClass: flutterItemClass) else {
            result(FlutterError(code: "InvalidClass", message: "Unrecognized query class \(flutterItemClass).", details: nil))
            return
        }

        let eventChannelName = eventChannel(forStreamHandler: queryStreamHandler, result)
        result(eventChannelName)
    }

    private func eventChannel(forStreamHandler: DataStoreStreamHandler, _ result: FlutterResult) -> String {
        let eventChannelName = "com.kjones.amplify_datastore/dataStoreStream-\(UUID().uuidString)"
        let queryEventChannel = FlutterEventChannel(name: eventChannelName, binaryMessenger: binaryMessenger)
        queryEventChannel.setStreamHandler(forStreamHandler)
        return eventChannelName
    }

    private func toDataStoreQueryStreamHandler(flutterItemClass: String) -> DataStoreStreamHandler? {
        switch flutterItemClass {
        case "Todo":
            return DataStoreQueryStreamHandler<Todo>()
        default:
            return nil
        }
    }

    private func toDataStoreSaveStreamHandler(flutterItemClass: String, itemJson: String) throws -> DataStoreStreamHandler? {
        switch flutterItemClass {
        case "Todo":
            let item = try Todo.from(json: itemJson)
            return DataStoreSaveStreamHandler<Todo>(item: item)
        default:
            return nil
        }
    }

    private func toDataStoreDeleteStreamHandler(flutterItemClass: String, itemId: String) throws -> DataStoreStreamHandler? {
        switch flutterItemClass {
        case "Todo":
            return DataStoreDeleteStreamHandler<Todo>(itemId: itemId)
        default:
            return nil
        }
    }
}
