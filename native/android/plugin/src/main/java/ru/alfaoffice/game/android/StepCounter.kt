package ru.alfaoffice.game.android

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager

/**
 * Counts steps from the moment [start] is first called. TYPE_STEP_COUNTER reports the total since
 * boot, so the first reading becomes the baseline; TYPE_STEP_DETECTOR is the fallback.
 * Requires ACTIVITY_RECOGNITION on Android 10+ (requested from GDScript).
 */
class StepCounter(context: Context, private val onSteps: (Int) -> Unit) : SensorEventListener {

    private val sensors = context.getSystemService(SensorManager::class.java)
    private val counter: Sensor? = sensors?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    private val detector: Sensor? = sensors?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)
    private var baseline = -1f
    private var steps = 0
    private var listening = false

    fun start() {
        if (listening || sensors == null) return
        val sensor = counter ?: detector ?: return
        listening = sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)
    }

    fun stop() {
        if (!listening) return
        sensors?.unregisterListener(this)
        listening = false
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_STEP_COUNTER -> {
                val total = event.values[0]
                if (baseline < 0f) {
                    // Resuming after a pause keeps the steps already counted.
                    baseline = total - steps
                }
                steps = (total - baseline).toInt()
            }
            Sensor.TYPE_STEP_DETECTOR -> steps += event.values.size
            else -> return
        }
        onSteps(steps)
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}
