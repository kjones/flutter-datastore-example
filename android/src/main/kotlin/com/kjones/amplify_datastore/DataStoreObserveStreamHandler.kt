package com.kjones.amplify_datastore

import android.app.Activity
import com.amplifyframework.core.Amplify
import com.amplifyframework.core.async.Cancelable
import com.amplifyframework.core.model.Model
import com.amplifyframework.datastore.DataStoreItemChange
import io.flutter.plugin.common.EventChannel

class DataStoreObserveStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private var dataStoreSubscription: Cancelable? = null

    var activity: Activity? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        dataStoreSubscribe()
    }

    override fun onCancel(arguments: Any?) {
        dataStoreUnsubscribe()
        eventSink = null
    }

    private fun dataStoreSubscribe() {
        if (dataStoreSubscription != null) {
            return
        }

        Amplify.DataStore.observe(
            { dataStoreSubscription = it },
            {
                if (it.itemClass().name.startsWith("com.amplifyframework.datastore.generated.model")) {
                    sendEvent(it)
                }
            },
            {
                activity?.runOnUiThread {
                    eventSink?.error("ObservationFailure", it.message, it.recoverySuggestion)
                }
            },
            {
                activity?.runOnUiThread {
                    eventSink?.endOfStream()
                }
            }
        )
    }

    private fun dataStoreUnsubscribe() {
        dataStoreSubscription?.cancel()
        dataStoreSubscription = null
    }

    private fun sendEvent(event: DataStoreItemChange<out Model>) {
        val itemChangeMap = mapOf(
            "uuid" to event.uuid().toString(),
            "type" to event.type().name,
            "itemClass" to event.itemClass().name,
            "item" to modelSerializer.toJson(event.item())
        )

        activity?.runOnUiThread {
            eventSink?.success(itemChangeMap)
        }
    }
}