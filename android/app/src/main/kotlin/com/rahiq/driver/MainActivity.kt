package com.rahiq.driver

import android.graphics.Color
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Once the app targets SDK 35+, Flutter stops honouring
        // SystemUiOverlayStyle.systemNavigationBarColor (see SystemChrome's
        // docs). Android 14 and below still paint an opaque
        // navigationBarBackground decor view on top of the Flutter surface,
        // which is what showed up as a black strip under the SafeArea. Clearing
        // it here lets the white ColoredBox in main.dart show through instead.
        @Suppress("DEPRECATION")
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }
}
