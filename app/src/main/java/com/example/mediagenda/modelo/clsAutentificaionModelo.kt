package com.example.mediagenda.modelo

import com.example.mediagenda.conexion.retrofitCliente

class clsAutentificaionModelo {
    suspend fun iniciarSesion(usuario: String, contrasena: String): dataRespuesta<dataSesion> {
        val respuesta = retrofitCliente.api.iniciarSesion(dataLoginPeticion(usuario, contrasena))
        val resultado = retrofitCliente.leerRespuesta(respuesta)

        // Si entró, guardamos el token para las siguientes peticiones
        if (resultado.status == "success" && resultado.data != null) {
            retrofitCliente.token = resultado.data.token
        }
        return resultado
    }
}