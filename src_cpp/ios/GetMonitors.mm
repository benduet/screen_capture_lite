#include "ScreenCapture.h"
#include "internal/SCCommon.h"
#include <ApplicationServices/ApplicationServices.h>
#import <Cocoa/Cocoa.h>


namespace SL{
    namespace Screen_Capture{

        // Get the localized display name from NSScreen (e.g., "Built-in Retina Display", "LG UltraFine")
        static std::string GetDisplayName(CGDirectDisplayID displayID) {
            @autoreleasepool {
                uint32_t unitNumber = CGDisplayUnitNumber(displayID);

                for (NSScreen* screen in [NSScreen screens]) {
                    NSNumber* screenNumber = [[screen deviceDescription] objectForKey:@"NSScreenNumber"];
                    if (screenNumber && CGDisplayUnitNumber([screenNumber unsignedIntValue]) == unitNumber) {
                        // Use localizedName if available (macOS 10.15+)
                        if ([screen respondsToSelector:@selector(localizedName)]) {
                            NSString* name = [screen valueForKey:@"localizedName"];
                            if (name && [name length] > 0) {
                                return std::string([name UTF8String]);
                            }
                        }
                        break;
                    }
                }

                // Fallback to generic name
                return std::string("Display");
            }
        }

        std::vector<Monitor> GetMonitors() {
            std::vector<Monitor> ret;
            std::vector<CGDirectDisplayID> displays;
            CGDisplayCount count=0;
            //get count
            CGGetActiveDisplayList(0, 0, &count);
            displays.resize(count);

            CGGetActiveDisplayList(count, displays.data(), &count);
            for(auto  i = 0; i < count; i++) {
                //only include non-mirrored displays
                if(CGDisplayMirrorsDisplay(displays[i]) == kCGNullDirectDisplay){

                    auto dismode =CGDisplayCopyDisplayMode(displays[i]);

                    auto width = CGDisplayModeGetPixelWidth(dismode);
                    auto height = CGDisplayModeGetPixelHeight(dismode);
                    CGDisplayModeRelease(dismode);
                    auto r = CGDisplayBounds(displays[i]);
                    auto scale = static_cast<float>(width)/static_cast<float>(r.size.width);
                    auto name = GetDisplayName(displays[i]);
                    ret.push_back(CreateMonitor(static_cast<int>(ret.size()), displays[i],height,width, int(r.origin.x), int(r.origin.y), name, scale));
                }
            }
            return ret;

        }
    }
}
