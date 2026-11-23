package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Lo que la app ENVÍA a solicitar_codigo.php (también es «Reenviar código»)
data class dataCorreoPeticion(
    @SerializedName("correo") val correo: String = ""
)
