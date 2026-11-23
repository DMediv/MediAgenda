package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Respuesta de obtener_horarios_disponibles.php
// horarios: bloques libres de 30 min en formato HH:MM
data class dataHorariosDia(
    @SerializedName("fecha") val fecha: String = "",
    @SerializedName("horarios") val horarios: List<String> = emptyList()
)
