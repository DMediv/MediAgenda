package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Lo que la app ENVÍA a cancelar_cita.php (motivo es opcional)
data class dataCancelarPeticion(
    @SerializedName("id_cita") val idCita: Int = 0,
    @SerializedName("motivo") val motivo: String? = null
)
