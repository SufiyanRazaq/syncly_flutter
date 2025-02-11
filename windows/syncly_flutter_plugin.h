#ifndef FLUTTER_PLUGIN_SYNCLY_FLUTTER_PLUGIN_H_
#define FLUTTER_PLUGIN_SYNCLY_FLUTTER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace syncly_flutter {

class SynclyFlutterPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SynclyFlutterPlugin();

  virtual ~SynclyFlutterPlugin();

  // Disallow copy and assign.
  SynclyFlutterPlugin(const SynclyFlutterPlugin&) = delete;
  SynclyFlutterPlugin& operator=(const SynclyFlutterPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace syncly_flutter

#endif  // FLUTTER_PLUGIN_SYNCLY_FLUTTER_PLUGIN_H_
