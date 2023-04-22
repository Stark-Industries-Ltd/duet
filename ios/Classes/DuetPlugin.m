#import "DuetPlugin.h"
#if __has_include(<duet/duet-Swift.h>)
#import <duet/duet-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "duet-Swift.h"
#endif

@implementation DuetPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftDuetPlugin registerWithRegistrar:registrar];
}
@end
