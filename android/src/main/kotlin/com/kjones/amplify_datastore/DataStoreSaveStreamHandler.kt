package com.kjones.amplify_datastore

import android.app.Activity
import com.amplifyframework.core.Amplify
import com.amplifyframework.core.model.Model
import io.flutter.plugin.common.EventChannel

class DataStoreSaveStreamHandler<T : Model>(
    private val item: T,
    private var activity: Activity) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        dataStoreSave(item)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun dataStoreSave(item: T) {
        Amplify.DataStore.save<T>(
            item,
            {
                val newItem = mapOf(
                    "itemClass" to it.itemClass().name,
                    "item" to modelSerializer.toJson(it.item()))

                activity.runOnUiThread {
                    eventSink?.success(newItem)
                    eventSink?.endOfStream()
                }
            },
            {
                activity.runOnUiThread {
                    eventSink?.error("DataStoreSaveException", it.message, it.recoverySuggestion)
                }
            }
        )
    }
}