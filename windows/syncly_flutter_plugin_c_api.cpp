#include "include/syncly_flutter/syncly_flutter_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "syncly_flutter_plugin.h"

void SynclyFlutterPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  syncly_flutter::SynclyFlutterPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
