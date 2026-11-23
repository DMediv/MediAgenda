package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Respuesta de obtener_panel_medico.php
// siguienteCita es null si el médico no tiene citas pendientes
data class dataPanelMedico(
    @SerializedName("medico") val medico: dataMedicoPanel = dataMedicoPanel(),
    @SerializedName("resumen_hoy") val resumenHoy: dataResumenHoy = dataResumenHoy(),
    @SerializedName("siguiente_cita") val siguienteCita: dataCita? = null
)
