package com.ts.toolshare

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE: el propio sistema operativo bloquea screenshots,
        // grabación de pantalla y oculta la vista en el selector de apps recientes.
        // Desactivado TEMPORALMENTE para poder tomar capturas durante pruebas.
        // Antes de entregar/producción, reactivar (idealmente solo en las
        // pantallas de KYC/pago, no en toda la app).
        // window.setFlags(
        //     WindowManager.LayoutParams.FLAG_SECURE,
        //     WindowManager.LayoutParams.FLAG_SECURE
        // )
    }
}
