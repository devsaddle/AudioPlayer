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
    [self addObserver];
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
    return self.avplayer.currentItem;
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

- (void)playbackFinished:(NSNotification *)notifi {
    
    NSLog(@"播放完成 %@",notifi);
    
}

- (void)playtime:(NSNotification *)notifi {
    NSLog(@"时间改变 %@",notifi);
    
}

#pragma mark - Observer 
- (void)addObserver {
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.avplayer.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    
    //监控缓冲加载情况属性
    [self.avplayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    
    //监控播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avplayer.currentItem];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playtime:) name:AVPlayerItemTimeJumpedNotification object:self.avplayer.currentItem];
    
    //监控时间进度
    [self.avplayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        CMTimeShow(time);
        
    }];
    
}

- (void)removeServer {
    [self.avplayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.avplayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:AVPlayerItemDidPlayToEndTimeNotification];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    NSLog(@"%@--- %@",keyPath,change);
    
}

#pragma mark - Lazy Load

- (NSMutableArray *)playItemList {
    if (_playItemList == nil) {
        _playItemList = [NSMutableArray array];
    }
    return _playItemList;
}


@end
