package com.example.vitalpulse_app

import android.app.Activity
import android.os.Bundle
import android.text.util.Linkify
import android.view.Gravity
import android.widget.TextView

class PrivacyPolicyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val text = TextView(this).apply {
            text = "VitalPulse privacy policy\n\nHealth data is read only after you grant permission. The app syncs steps, sleep, and heart rate to your private VitalPulse account. You can revoke access in Apple Health or Health Connect and delete records from your account. Meal photos are sent to the configured AI provider only when you request a scan; VitalPulse does not store the photo. Nutrition estimates are approximate.\n\nRead the full policy: https://github.com/yeshwanthkushi25-glitch/VitalPulse/blob/main/docs/privacy-policy.md"
            textSize = 16f
            setPadding(40, 48, 40, 48)
            gravity = Gravity.START
            Linkify.addLinks(this, Linkify.WEB_URLS)
        }
        setContentView(text)
    }
}
