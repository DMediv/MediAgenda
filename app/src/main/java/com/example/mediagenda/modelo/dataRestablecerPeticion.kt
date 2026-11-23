package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Lo que la app ENVÍA a restablecer_contrasena.php
data class dataRestablecerPeticion(
    @SerializedName("correo") val correo: String = "",
    @SerializedName("codigo") val codigo: String = "",
    @SerializedName("contrasena") val contrasena: String = "",
    @SerializedName("confirmacion") val confirmacion: String = ""
)
