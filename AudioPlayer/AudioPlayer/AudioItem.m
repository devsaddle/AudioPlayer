//
//  AudioItem.m
//  AudioPlayer
//
//  Created by 马远 on 2017/7/13.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import "AudioItem.h"

@implementation AudioItem

- (instancetype)initWithUrl:(NSURL *)url title:(NSString *)title artist:(NSString *)artist image:(UIImage *)image itemID:(NSString *)itemID
{
    self = [super init];
    if (self) {
        _audioURL = url;
        _title = title;
        _artist = artist;
        _image = image;
        _itemID = itemID;
        
    }
    return self;
}

+ (instancetype)itemWithUrl:(NSURL *)url title:(NSString *)title artist:(NSString *)artist image:(UIImage *)image itemID:(NSString *)itemID {
    
    AudioItem *item = [[AudioItem alloc] initWithUrl:url title:title artist:artist image:image itemID:itemID];
    return item;
}

- (instancetype)initWithUrl:(NSURL *)url itemID:(NSString *)itemID {
    return [self initWithUrl:url title:nil artist:nil image:nil itemID:itemID];
}

+ (instancetype)itemWithUrl:(NSURL *)url itemID:(NSString *)itemID {
    return [AudioItem itemWithUrl:url title:nil artist:nil image:nil itemID:itemID];
}

@end
