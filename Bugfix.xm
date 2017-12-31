//
//  Bugfix.xm
//  Zetime-Goodies
//
//  Created by cbs_ghost on 2017/11/18.
//  Copyright (c) 2017 CbS Ghost. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>


%group IOS9_BELOW_BUGS

// Fix a bug that official ZeTime app calls an API in CBCentralManager where only exists on iOS 10 or later
// Issued in: v1.0 - v1.4
%hook CBCentralManager
- (instancetype)init
{
    return [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
}
%end

%end


%group IOS8_BUGS

// Fix a bug that official ZeTime app calls an API in UIAppearance protocol where only exists on iOS 9 or later
// Issued in: v1.5.1 - current
%hook NSObject
%new
+ (instancetype)appearanceWhenContainedInInstancesOfClasses:(NSArray<Class <UIAppearanceContainer>> *)containerTypes
{
    return [self appearanceWhenContainedIn:[containerTypes firstObject], nil];
}
%end

%end

// Inject bugfix groups depend on iOS version
%ctor {
    if (![NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9,0,0}]) {
        %init(IOS8_BUGS);
    }
    if (![NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}]) {
        %init(IOS9_BELOW_BUGS);
    }
}
