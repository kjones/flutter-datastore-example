package com.kjones.amplify_datastore

import android.app.Activity
import android.util.Log
import androidx.annotation.NonNull
import com.amplifyframework.api.aws.AWSApiPlugin
import com.amplifyframework.core.Amplify
import com.amplifyframework.core.Amplify.DataStore
import com.amplifyframework.core.model.Model
import com.amplifyframework.datastore.AWSDataStorePlugin
import com.amplifyframework.datastore.generated.model.Todo
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.*

// TODO: Lots of duplicated validation code that could probably be eliminated.
// TODO: Can the StreamHandler classes be consolidated.

class AmplifyDataStorePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    private lateinit var channel: MethodChannel
    private lateinit var dataStoreEventChannel: EventChannel
    private lateinit var dataStoreStreamHandler: DataStoreObserveStreamHandler

    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.kjones.amplify_datastore/amplify")
        channel.setMethodCallHandler(this)

        dataStoreEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "com.kjones.amplify_datastore/dataStoreEvents")
        dataStoreStreamHandler = DataStoreObserveStreamHandler()
        dataStoreEventChannel.setStreamHandler(dataStoreStreamHandler)

        Amplify.addPlugin(AWSApiPlugin())
        Amplify.addPlugin(AWSDataStorePlugin())
        Log.i(TAG, "Added DataStore plugin")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        dataStoreEventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        dataStoreStreamHandler.activity = activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        dataStoreStreamHandler.activity = activity
    }

    override fun onDetachedFromActivity() {
        activity = null
        dataStoreStreamHandler.activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        dataStoreStreamHandler.activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) =
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            "dataStoreClear" -> onDataStoreClear(result)
            "dataStoreSave" -> onDataStoreSave(call, result)
            "dataStoreDelete" -> onDataStoreDelete(call, result)
            "dataStoreQuery" -> onDataStoreQuery(call, result)
            else -> result.notImplemented()
        }

    private fun onDataStoreClear(result: Result) {
        DataStore.clear(
            { Log.d(TAG, "onDataStoreClearComplete") },
            { Log.d(TAG, "onDataStoreClearError: $it") }
        )

        result.success(true)
    }

    private fun onDataStoreSave(call: MethodCall, result: Result) {
        if (activity == null) {
            result.error("InvalidState", "Plugin not attached to an Activity", null)
            return
        }

        val flutterItemClass = call.argument<String>("itemClass")
        if (flutterItemClass == null) {
            result.error("InvalidParameter", "RequiredParameter 'itemClass' missing.", null)
            return
        }

        val itemJson = call.argument<String>("item")
        if (itemJson == null) {
            result.error("InvalidParameter", "RequiredParameter 'item' missing", null)
            return
        }

        val itemBuilder = toPlatformItemBuilder(flutterItemClass)
        if (itemBuilder == null) {
            result.error("InvalidClass", "Unrecognized query class $flutterItemClass", null)
            return
        }

        // TODO: Do these need to be kept track of and updated based on activity lifecycle events?
        val eventChannelName = "com.kjones.amplify_datastore/dataStoreSave-${UUID.randomUUID()}"
        val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, eventChannelName)
        val streamHandler = DataStoreSaveStreamHandler(itemBuilder(itemJson), activity!!)
        eventChannel.setStreamHandler(streamHandler)

        result.success(eventChannelName)
    }

    private fun onDataStoreDelete(call: MethodCall, result: Result) {
        if (activity == null) {
            result.error("InvalidState", "Plugin not attached to an Activity", null)
            return
        }

        // TODO: Handle query parameters.
        val flutterItemClass = call.argument<String>("itemClass")
        if (flutterItemClass == null) {
            result.error("InvalidParameter", "RequiredParameter 'itemClass' missing.", null)
            return
        }

        val itemId = call.argument<String>("id")
        if (itemId == null) {
            result.error("InvalidParameter", "RequiredParameter 'id' missing", null)
            return
        }

        val itemIdBuilder = toPlatformItemIdBuilder(flutterItemClass)
        if (itemIdBuilder == null) {
            result.error("InvalidClass", "Unrecognized query class $flutterItemClass", null)
            return
        }

        // TODO: Do these need to be kept track of and updated based on activity lifecycle events?
        val eventChannelName = "com.kjones.amplify_datastore/dataStoreDelete-${UUID.randomUUID()}"
        val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, eventChannelName)
        val streamHandler = DataStoreDeleteStreamHandler(itemIdBuilder(itemId), activity!!)
        eventChannel.setStreamHandler(streamHandler)

        result.success(eventChannelName)
    }

    private fun onDataStoreQuery(call: MethodCall, result: Result) {
        if (activity == null) {
            result.error("InvalidState", "Plugin not attached to an Activity", null)
            return
        }

        // TODO: Handle query parameters.
        val flutterItemClass = call.argument<String>("itemClass")
        if (flutterItemClass == null) {
            result.error("InvalidParameter", "RequiredParameter 'itemClass' missing.", null)
            return
        }

        val itemClass = toPlatformItemClass(flutterItemClass)
        if (itemClass == null) {
            result.error("InvalidClass", "Unrecognized query class $flutterItemClass", null)
            return
        }

        // TODO: Do these need to be kept track of and updated based on activity lifecycle events?
        val eventChannelName = "com.kjones.amplify_datastore/dataStoreQuery-${UUID.randomUUID()}"
        val queryEventChannel = EventChannel(flutterPluginBinding.binaryMessenger, eventChannelName)
        val queryStreamHandler = DataStoreQueryStreamHandler(itemClass, activity!!)
        queryEventChannel.setStreamHandler(queryStreamHandler)

        result.success(eventChannelName)
    }

    private fun toPlatformItemClass(flutterItemClass: String?): Class<out Model>? {
        return when (flutterItemClass) {
            "Todo" -> Todo::class.java
            else -> null
        }
    }

    private fun toPlatformItemIdBuilder(flutterItemClass: String?): ((String) -> Model)? {
        return when (flutterItemClass) {
            "Todo" -> Todo::justId
            else -> null
        }
    }

    private fun toPlatformItemBuilder(flutterItemClass: String?): ((String) -> Model)? {
        return when (flutterItemClass) {
            "Todo" -> { json -> modelSerializer.fromJson(json, Todo::class.java) }
            else -> null
        }
    }

    companion object {
        private const val TAG = "AmplifyDataStorePlugin"
    }
}
