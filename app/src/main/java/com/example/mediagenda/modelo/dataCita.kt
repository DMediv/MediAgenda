package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Una cita. La regresan: agendar, reprogramar, mis citas, detalle, agenda,
// historial del paciente y la siguiente cita del panel del médico.
// puedeCancelar y puedeReprogramar solo vienen en el detalle para el paciente.
data class dataCita(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("fecha") val fecha: String = "",
    @SerializedName("hora") val hora: String = "",
    @SerializedName("estado") val estado: String = "",
    @SerializedName("id_paciente") val idPaciente: Int = 0,
    @SerializedName("paciente") val paciente: String = "",
    @SerializedName("id_medico") val idMedico: Int = 0,
    @SerializedName("medico") val medico: String = "",
    @SerializedName("especialidad") val especialidad: String = "",
    @SerializedName("consultorio") val consultorio: String = "",
    @SerializedName("ubicacion") val ubicacion: String = "",
    @SerializedName("puede_cancelar") val puedeCancelar: Boolean? = null,
    @SerializedName("puede_reprogramar") val puedeReprogramar: Boolean? = null
)
