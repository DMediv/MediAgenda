package com.example.mediagenda.modelo

import com.google.gson.annotations.SerializedName

// Respuesta de obtener_especialidades.php (una por ficha de filtro)
data class dataEspecialidad(
    @SerializedName("id") val id: Int = 0,
    @SerializedName("nombre") val nombre: String = ""
) {
    override fun toString(): String {
        return nombre   // así un Spinner o una ficha muestra el nombre
    }
}
