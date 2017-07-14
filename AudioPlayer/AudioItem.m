//
//  AudioItem.m
//  AudioPlayer
//
//  Created by 马远 on 2017/7/13.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import "AudioItem.h"

@implementation AudioItem

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        _audioURL = url;
    }
    return self;
}

+ (instancetype)itemWithURL:(NSURL *)url {
    AudioItem *item = [[AudioItem alloc] initWithURL:url];
    return item;
}
@end
