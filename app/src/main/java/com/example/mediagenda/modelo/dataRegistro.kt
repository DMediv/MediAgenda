package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Respuesta de registrar_paciente.php (201)
data class dataRegistro(
    @SerializedName("id_usuario") val idUsuario: Int = 0
)
