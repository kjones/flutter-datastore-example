package com.kjones.amplify_datastore

import android.app.Activity
import com.amplifyframework.core.Amplify
import com.amplifyframework.core.model.Model
import io.flutter.plugin.common.EventChannel

class DataStoreDeleteStreamHandler<T : Model>(
    private val item: T,
    private var activity: Activity) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        dataStoreDelete(item)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun dataStoreDelete(item: T) {
        Amplify.DataStore.delete<T>(
            item,
            {
                activity.runOnUiThread {
                    eventSink?.success(true)
                    eventSink?.endOfStream()
                }
            },
            {
                activity.runOnUiThread {
                    eventSink?.error("DataStoreDeleteException", it.message, it.recoverySuggestion)
                }
            }
        )
    }
}