package com.kjones.amplify_datastore

import com.amplifyframework.api.aws.TemporalDeserializers
import com.amplifyframework.core.model.temporal.Temporal
import com.google.gson.GsonBuilder

internal val modelSerializer =
    GsonBuilder()
        .registerTypeAdapter(Temporal.Date::class.java, TemporalDeserializers.DateDeserializer())
        .registerTypeAdapter(Temporal.Time::class.java, TemporalDeserializers.TimeDeserializer())
        .registerTypeAdapter(Temporal.Timestamp::class.java, TemporalDeserializers.TimestampDeserializer())
        .registerTypeAdapter(Temporal.DateTime::class.java, TemporalDeserializers.DateTimeDeserializer())
        .create()