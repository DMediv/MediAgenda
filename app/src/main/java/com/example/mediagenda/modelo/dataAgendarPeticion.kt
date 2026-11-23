package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Lo que la app ENVÍA a agendar_cita.php (fecha AAAA-MM-DD, hora HH:MM)
data class dataAgendarPeticion(
    @SerializedName("id_medico") val idMedico: Int = 0,
    @SerializedName("fecha") val fecha: String = "",
    @SerializedName("hora") val hora: String = ""
)
