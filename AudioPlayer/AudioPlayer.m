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

/** Play Progress Block */
@property (nonatomic, copy) void(^playProgressBlock)(NSTimeInterval current,NSTimeInterval total);

/** Load Progress Block */
@property (nonatomic, copy) void(^loadProgressBlock)(NSTimeInterval current,NSTimeInterval total);

/** Play Finsish  Block */
@property (nonatomic, copy) void(^playFinishBlock)(id item);

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
    avplayer.volume = 1.0;
    self.avplayer = avplayer;
    
    //监控播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avplayer.currentItem];
    
    __weak typeof(self)weakSelf = self;
    //监控时间进度
    [self.avplayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        __strong typeof(self)strongSelf = weakSelf;
        
        //当前播放的时间
        NSTimeInterval current = CMTimeGetSeconds(time);
        //视频的总时间
        NSTimeInterval total = CMTimeGetSeconds(strongSelf.avplayer.currentItem.duration);
        
        // 回调上层
        if (strongSelf.playProgressBlock) {
            strongSelf.playProgressBlock(current,total);
        }
        
    }];
}

- (AVPlayerItem *)playerItemWithUrl:(NSURL *)url {
    AVPlayerItem *item = [[AVPlayerItem alloc] initWithURL:url];
    [self addObserverForItem:item];
    
    return item;
}

#pragma mark - Data Handle

- (void)creatPlayList:(NSArray *)listArray {
    if (listArray && [listArray count] > 0) {
        [self addQueueToPlayerFromArray:listArray];
        [self avplayerInit];

    }
}

- (void)addItem:(id)item {
    if (item) {
        [self.playItemList addObject:item];
        AVPlayerItem *playerItem = [self playerItemWithUrl:[NSURL URLWithString:item]];
        if ([self.avplayer canInsertItem:playerItem afterItem:nil]) {
            [self.avplayer insertItem:playerItem afterItem:nil];
        }
    }
}

- (void)removeItem:(id)item {
    [self.playItemList removeObject:item];
    AVPlayerItem *playerItem = [self playerItemWithUrl:[NSURL URLWithString:item]];
    [self removeObserverForItem:playerItem];
    [self.avplayer removeItem:playerItem];
}

- (NSArray *)getCurrentPlayList {
    return [self.playItemList copy];
}

- (id)getCurrentPlayItem {
    // TODO: 对外数据包装
    return self.avplayer.currentItem;
}

- (NSUInteger)getCurrentIndex {
    AVPlayerItem *currentItem = [self.avplayer currentItem];
    NSUInteger currentIndex = [self.playItemList indexOfObject:currentItem];
    return currentIndex;
}

- (void)addQueueToPlayerFromArray:(NSArray *)array {
    for (NSString *url in array) {
        if (url && url.length > 0) {
           AVPlayerItem *item = [self playerItemWithUrl:[NSURL URLWithString:url]];
            [self.playItemList addObject:item];
        }
    }

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

- (BOOL)next {
    NSUInteger currentIndex = [self getCurrentIndex];
    AVPlayerItem *currentItem = [self getCurrentPlayItem];
    [currentItem seekToTime:kCMTimeZero];
    
    if (currentIndex < self.playItemList.count - 1) {
        [self.avplayer advanceToNextItem];
        [self play];
    }
    
//    if (currentIndex == self.playItemList.count - 1) {
//        return NO;
//    }
    return YES;
    
}

- (BOOL)last {
    NSUInteger currentIndex = [self getCurrentIndex];
    

    if (currentIndex > 0) {
        AVPlayerItem *lastItem = [self.playItemList objectAtIndex:--currentIndex];
        AVPlayerItem *currentItem = self.avplayer.currentItem;
        [currentItem seekToTime:kCMTimeZero];
        
        // 交换两个Item
        if ([self.avplayer canInsertItem:lastItem afterItem:currentItem]) {
            [self.avplayer insertItem:lastItem afterItem:currentItem];
            [self.avplayer advanceToNextItem];
            [self play];
            
            if ([self.avplayer canInsertItem:currentItem afterItem:lastItem]) {
                [self.avplayer insertItem:currentItem afterItem:lastItem];
            }   
        }
    
    }
//    if (currentIndex ==  0) {
//        return NO;
//    }
    return YES;
}


#pragma mark - Call Back

- (void)playFinish:(void(^)(id item))finishBlock {
    _playFinishBlock = finishBlock;
}


- (void)playProgressValueChanged:(void(^)(NSTimeInterval current,NSTimeInterval total))changedBlock {
    _playProgressBlock = changedBlock;
}

- (void)loadProgressValueChanged:(void(^)(NSTimeInterval current,NSTimeInterval total))loadBlock {
    _loadProgressBlock = loadBlock;
}



#pragma mark - Observer 
- (void)addObserverForItem:(AVPlayerItem *)item {
    //监控状态属性
    [item addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];

    //监控缓冲加载情况属性
    [item addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
    
    [item addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)removeObserverForItem:(AVPlayerItem *)item {
    [self.avplayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.avplayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.avplayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    
    AVPlayerItem *item = (AVPlayerItem *)object;

    if ([keyPath isEqualToString:@"status"]) {
        if (item.status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"准备播放");

        } else {
            NSLog(@"播放错误");
            
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval loadTime = [self availableDurationWithplayerItem:item];
        NSTimeInterval totalTime = CMTimeGetSeconds(item.duration);
        if (_loadProgressBlock) {
            _loadProgressBlock(loadTime,totalTime);
        }
        
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSLog(@"playbackBufferEmpty %i",item.playbackBufferEmpty);
    }
    
}

- (NSTimeInterval)availableDurationWithplayerItem:(AVPlayerItem *)playerItem
{
    NSArray *loadedTimeRanges = [playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    NSTimeInterval startSeconds = CMTimeGetSeconds(timeRange.start);
    NSTimeInterval durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (void)playbackFinished:(NSNotification *)notifi {
    
    AVPlayerItem *item = notifi.object;
    [item seekToTime:kCMTimeZero];
    if (_playFinishBlock) {
        // TODO: 对外数据包装
        _playFinishBlock(item);
    }
}

#pragma mark - Lazy Load

- (NSMutableArray *)playItemList {
    if (_playItemList == nil) {
        _playItemList = [NSMutableArray array];
    }
    return _playItemList;
}

- (BOOL)isPlay {
    if (self.avplayer.rate > 0.0 && self.avplayer.error == nil) {
        return YES;
    }
    return NO;
}

@end
