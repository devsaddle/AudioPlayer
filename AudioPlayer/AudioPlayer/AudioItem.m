//
//  AudioItem.m
//  AudioPlayer
//
//  Created by 马远 on 2017/7/13.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import "AudioItem.h"

@implementation AudioItem

- (instancetype)initWithID:(NSString *)itemID url:(NSURL *)url
{
    self = [super init];
    if (self) {
        _itemID = itemID;
        _audioURL = url;
    }
    return self;
}

+ (instancetype)itemWithID:(NSString *)itemID url:(NSURL *)url {
    
    AudioItem *item = [[AudioItem alloc] initWithID:itemID url:url];
    return item;
}
@end
