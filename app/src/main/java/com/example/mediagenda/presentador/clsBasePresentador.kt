package com.example.mediagenda.Presentador

import com.example.mediagenda.contrato.BaseVista


open class clsBasePresentador<V : BaseVista>(vista: V) {

    protected var vista: V? = vista

    fun desvincularVista() {
        vista = null
    }
}