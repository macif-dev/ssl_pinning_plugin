#import "SslPinningPlugin.h"
#import <ssl_pinning_plugin/ssl_pinning_plugin-Swift.h>

@implementation SslPinningPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSslPinningPlugin registerWithRegistrar:registrar];
}
@end
