package com.kjones.amplify_datastore

import android.app.Activity
import com.amplifyframework.core.Amplify
import com.amplifyframework.core.model.Model
import io.flutter.plugin.common.EventChannel

class DataStoreQueryStreamHandler(
    private val itemClass: Class<out Model>,
    private var activity: Activity) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        dataStoreQuery(itemClass)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun <T : Model> dataStoreQuery(itemClass: Class<T>) {
        Amplify.DataStore.query<T>(
            itemClass,
            { resultIterator ->
                val items = resultIterator.asSequence()
                    .map { item ->
                        return@map mapOf(
                            "itemClass" to itemClass.name,
                            "item" to modelSerializer.toJson(item))
                    }
                    .toList()

                activity.runOnUiThread {
                    eventSink?.success(items)
                    eventSink?.endOfStream()
                }
            },
            {
                activity.runOnUiThread {
                    eventSink?.error("DataStoreQueryFailure", it.message, it.recoverySuggestion)
                }
            }
        )
    }
}