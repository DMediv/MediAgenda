package com.example.mediagenda.contrato

class LoginContrato {
    interface Vista : BaseVista {
        fun abrirPanelPaciente()
        fun abrirPanelMedico()
    }

    interface Presentador {
        fun iniciarSesion(correo: String, contrasena: String)
    }
}