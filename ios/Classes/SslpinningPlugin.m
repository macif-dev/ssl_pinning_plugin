#import "SslpinningPlugin.h"
#import <sslpinning_plugin/sslpinning_plugin-Swift.h>

@implementation SslpinningPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftSslpinningPlugin registerWithRegistrar:registrar];
}
@end
