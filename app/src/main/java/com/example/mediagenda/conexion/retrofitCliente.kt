package com.example.mediagenda.conexion

import com.example.mediagenda.interfaceApi.apiService
import com.example.mediagenda.modelo.dataRespuesta
import com.google.gson.Gson
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit


object retrofitCliente {
    const val BASE_URL = "https://mediagenda.4buthh.com/api/"

    var token: String = ""

    private val clienteHttp: OkHttpClient by lazy {
        val registro = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }
        OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .addInterceptor { cadena ->
                val peticion = cadena.request()
                val peticionConToken = if (token.isNotEmpty()) {
                    peticion.newBuilder().header("Authorization", "Bearer $token").build()
                } else {
                    peticion
                }
                cadena.proceed(peticionConToken)
            }
            .addInterceptor(registro)
            .build()
    }

    val api: apiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(clienteHttp)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(apiService::class.java)
    }

    fun <T> leerRespuesta(respuesta: Response<dataRespuesta<T>>): dataRespuesta<T> {
        val cuerpo = respuesta.body()
        if (respuesta.isSuccessful && cuerpo != null) {
            return cuerpo
        }
        return try {
            val error = Gson().fromJson(respuesta.errorBody()?.string(), dataRespuesta::class.java)
            dataRespuesta(status = "error", message = error.message, data = null)
        } catch (e: Exception) {
            dataRespuesta(status = "error", message = "Ocurrió un error (${respuesta.code()}). Intenta más tarde.", data = null)
        }
    }
}