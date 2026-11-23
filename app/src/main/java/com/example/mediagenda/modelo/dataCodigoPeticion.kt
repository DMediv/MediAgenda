package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Lo que la app ENVÍA a verificar_codigo.php
data class dataCodigoPeticion(
    @SerializedName("correo") val correo: String = "",
    @SerializedName("codigo") val codigo: String = ""
)
