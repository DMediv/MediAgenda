package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Respuesta de verificar_disponibilidad.php: ¿el correo o el usuario están libres?
data class dataDisponibilidad(
    @SerializedName("disponible") val disponible: Boolean = false
)
