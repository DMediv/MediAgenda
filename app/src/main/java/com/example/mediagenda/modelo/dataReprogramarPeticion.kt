package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Lo que la app ENVÍA a reprogramar_cita.php (motivo es opcional)
data class dataReprogramarPeticion(
    @SerializedName("id_cita") val idCita: Int = 0,
    @SerializedName("fecha") val fecha: String = "",
    @SerializedName("hora") val hora: String = "",
    @SerializedName("motivo") val motivo: String? = null
)
