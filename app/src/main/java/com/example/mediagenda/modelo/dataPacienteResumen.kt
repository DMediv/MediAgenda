package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Respuesta de obtener_mis_pacientes.php (un paciente de la lista del médico)
data class dataPacienteResumen(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("nombre") val nombre: String = "",
    @SerializedName("ultima_cita") val ultimaCita: String = ""
)
