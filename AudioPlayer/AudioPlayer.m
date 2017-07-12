//
//  AudioPlayer.m
//  AudioPlayer
//
//  Created by 马远 on 2017/7/12.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioPlayer ()

/** Play List */
@property (nonatomic, strong) NSMutableArray *playItemList;

/** AVPlayer */
@property (nonatomic, strong) AVQueuePlayer *avplayer;

@end

@implementation AudioPlayer

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    static AudioPlayer *instance;
    dispatch_once(&onceToken, ^{
        instance = [[AudioPlayer alloc] init];
    });
    return instance;
}

#pragma mark - Player Init
- (void)avplayerInit {
    AVQueuePlayer *avplayer = [[AVQueuePlayer alloc] initWithItems:self.playItemList];
    avplayer.volume = 0.5;
    self.avplayer = avplayer;

}

- (AVPlayerItem *)playerItemWithUrl:(NSURL *)url {
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:url];
    return item;
}

#pragma mark - Data Handle

- (void)creatPlayList:(NSArray *)listArray {
    if (listArray && [listArray count] > 0) {
        [self addQueueToPlayerFromArray:listArray];
    }
}

- (void)addItem:(id)item {
    if (item) {
        [self.playItemList addObject:item];
        AVPlayerItem *playerItem = [self playerItemWithUrl:[NSURL URLWithString:item]];
        if ([self.avplayer canInsertItem:playerItem afterItem:[[self.avplayer items] lastObject]]) {
            [self.avplayer insertItem:playerItem afterItem:[[self.avplayer items] lastObject]];
        }
    }
}

- (void)removeItem:(id)item {
    [self.playItemList removeObject:item];
    AVPlayerItem *playerItem = [self playerItemWithUrl:[NSURL URLWithString:item]];
    [self.avplayer removeItem:playerItem];
}

- (NSArray *)getCurrentPlayList {
    return [self.playItemList copy];
}

- (id)getCurrentPlayItem {
    return nil;
}

- (void)addQueueToPlayerFromArray:(NSArray *)array {
    for (NSString *url in array) {
        if (url && url.length > 0) {
           AVPlayerItem *item = [self playerItemWithUrl:[NSURL URLWithString:url]];
            [self.playItemList addObject:item];
        }
    }
    [self avplayerInit];

}

#pragma mark - Player Control

- (void)play {
    [self.avplayer play];
}

- (void)pause {
    [self.avplayer pause];
}

- (void)stop {
    
}

- (void)next {
    [self.avplayer advanceToNextItem];
}

- (void)last {
    AVPlayerItem *currentItem = [self.avplayer currentItem];
    NSUInteger currentIndex = [self.playItemList indexOfObject:currentItem];
    if (currentIndex > 0) {
        AVPlayerItem *lastItem = [self.playItemList objectAtIndex:--currentIndex];
        [self.avplayer replaceCurrentItemWithPlayerItem:lastItem];
        [self play];
    }
}


#pragma mark - Observer 
- (void)addObserver {
    
}

- (void)removeServer {

}

#pragma mark - Lazy Load

- (NSMutableArray *)playItemList {
    if (_playItemList == nil) {
        _playItemList = [NSMutableArray array];
    }
    return _playItemList;
}


@end
