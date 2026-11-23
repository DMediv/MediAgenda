package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Respuesta de obtener_dias_disponibles.php (paciente) y obtener_dias_con_citas.php (médico)
// dias: fechas AAAA-MM-DD que llevan punto en el calendario
data class dataDiasMes(
    @SerializedName("mes") val mes: String = "",
    @SerializedName("dias") val dias: List<String> = emptyList()
)
