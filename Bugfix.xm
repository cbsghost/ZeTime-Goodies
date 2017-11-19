//
//  Bugfix.xm
//  Zetime-Goodies
//
//  Created by cbs_ghost on 2017/11/18.
//  Copyright (c) 2017 CbS Ghost. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>


// Fix a bug that official ZeTime app called a API in CBCentralManager where only exists on iOS 10 or later
%hook CBCentralManager
- (instancetype)init
{
    if(![NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}]) {
        return [[CBCentralManager alloc] initWithDelegate:nil queue:nil];
    }

    return %orig;
}
%end
