#import <UIKit/UIKit.h>
#import "CDROTestHelper.h"
#import "CedarApplicationDelegate.h"
#import "HeadlessSimulatorWorkaround.h"
#import "CDRFunctions.h"
#import <objc/runtime.h>


@implementation NSBundle (MainBundleHijack)
static NSBundle *mainBundle__ = nil;

NSBundle *CDRMainBundle(id self, SEL _cmd) {
    return mainBundle__;
}

+ (void)load {
    suppressStandardPipesWhileLoadingClasses();

    NSString *extension = nil;;

    if (CDRIsXCTest()) {
        extension = @".xctest";
    } else if (CDRIsOCTest()) {
        extension = @".octest";
    }

    if (!extension)
        return;

    BOOL mainBundleIsApp = [[[NSBundle mainBundle] bundlePath] hasSuffix:@".app"];
    BOOL mainBundleIsTestBundle = [[[NSBundle mainBundle] bundlePath] hasSuffix:extension];

    if (!mainBundleIsApp && !mainBundleIsTestBundle) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        for (NSBundle *bundle in [NSBundle allBundles]) {
            if ([[bundle bundlePath] hasSuffix:extension]) {
                mainBundle__ = [bundle retain];
                Class nsBundleMetaClass = objc_getMetaClass("NSBundle");
                class_replaceMethod(nsBundleMetaClass, @selector(mainBundle), (IMP)CDRMainBundle, "v@:");
            }
        }
        [pool drain];
    }
}

@end
