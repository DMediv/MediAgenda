package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Contadores del día en el panel del médico (→ resumen_hoy)
// programadas incluye las reprogramadas
data class dataResumenHoy(
    @SerializedName("programadas") val programadas: Int = 0,
    @SerializedName("atendidas") val atendidas: Int = 0
)
