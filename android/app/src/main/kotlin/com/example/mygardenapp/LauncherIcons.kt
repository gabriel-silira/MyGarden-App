package com.example.mygardenapp

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build

internal class LauncherIcons(private val context: Context) {
    private val preferences = context.getSharedPreferences("launcher_icon", Context.MODE_PRIVATE)
    private val aliases = listOf("LauncherSystem", "LauncherLight", "LauncherDark")

    fun setTheme(mode: String) {
        require(mode in listOf("light", "dark", "system"))
        applyTheme(mode)
        preferences.edit().putString("theme", mode).apply()
    }

    fun refresh() = applyTheme(preferences.getString("theme", "system") ?: "system")

    private fun applyTheme(mode: String) {
        val night = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
            Configuration.UI_MODE_NIGHT_YES
        val target = if (mode == "dark" || (mode == "system" && night)) "LauncherDark" else "LauncherLight"
        val manager = context.packageManager
        val changes = aliases.map { name ->
            val component = ComponentName(context.packageName, "${context.packageName}.$name")
            val enabled = manager.getComponentEnabledSetting(component).let { setting ->
                setting == PackageManager.COMPONENT_ENABLED_STATE_ENABLED ||
                    (setting == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT && name == "LauncherSystem")
            }
            Triple(component, enabled, name == target)
        }.filter { (_, current, desired) -> current != desired }
        if (changes.isEmpty()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            manager.setComponentEnabledSettings(changes.map { (component, _, enabled) ->
                PackageManager.ComponentEnabledSetting(component, state(enabled), PackageManager.DONT_KILL_APP)
            })
        } else {
            // Enable the replacement first, so there is always a launchable alias.
            changes.sortedByDescending { it.third }.forEach { (component, _, enabled) ->
                manager.setComponentEnabledSetting(component, state(enabled), PackageManager.DONT_KILL_APP)
            }
        }
    }

    private fun state(enabled: Boolean) = if (enabled)
        PackageManager.COMPONENT_ENABLED_STATE_ENABLED else PackageManager.COMPONENT_ENABLED_STATE_DISABLED
}
