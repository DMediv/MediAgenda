package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Respuesta de obtener_info_paciente.php
// historialMedico es null si el paciente no tiene citas no canceladas con el médico
data class dataInfoPaciente(
    @SerializedName("paciente") val paciente: dataPacienteDetalle = dataPacienteDetalle(),
    @SerializedName("historial_medico") val historialMedico: dataHistorialMedico? = null
)
