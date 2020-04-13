//
//  free_sidecar_xpc.m
//  free-sidecar-xpc
//
//  Created by Ben Zhang on 2020-04-13.
//  Copyright © 2020 Ben Zhang. All rights reserved.
//

#import "free_sidecar_xpc.h"

@implementation free_sidecar_xpc

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
