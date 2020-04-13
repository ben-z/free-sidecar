//
//  free_sidecar_xpc.h
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "free_sidecar_xpcProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface free_sidecar_xpc : NSObject <free_sidecar_xpcProtocol>
@end
