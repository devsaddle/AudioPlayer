//
//  AudioPlayer.m
//  AudioPlayer
//
//  Created by 马远 on 2017/7/12.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AudioPlayer ()

/** AVPlayer Item List */
@property (nonatomic, strong) NSMutableArray<AVPlayerItem *> *playItemList;

/** Audio Item List */
@property (nonatomic, strong) NSMutableArray<AudioItem *> *audioItemList;

/** AVPlayer */
@property (nonatomic, strong) AVQueuePlayer *avplayer;

/** Play Progress Block */
@property (nonatomic, copy) void(^playProgressBlock)(AudioItem *item ,NSTimeInterval current,NSTimeInterval total);

/** Load Progress Block */
@property (nonatomic, copy) void(^loadProgressBlock)(AudioItem *item,NSTimeInterval current,NSTimeInterval total);

/** Play Finsish  Block */
@property (nonatomic, copy) void(^playFinishBlock)(AudioItem *item);


- (void)remoteControlReceivedWithEvent:(UIEvent *)event;

@end

@implementation UIApplication (AudioRemote)

- (void)configRemotePlay {
    [self beginReceivingRemoteControlEvents];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

#pragma mark - Remote Control
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    [[AudioPlayer shareManager] remoteControlReceivedWithEvent:event];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

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
    
    // 配置远程控制
    [[UIApplication sharedApplication] configRemotePlay];
    
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
            strongSelf.playProgressBlock([strongSelf getCurrentPlayItem],current,total);
        }
        
    }];
}


#pragma mark - Data Handle

- (void)creatPlayList:(NSArray<AudioItem *> *)listArray {
    if (listArray && [listArray count] > 0) {
        [self.audioItemList addObjectsFromArray:listArray];
        [self addQueueToPlayerFromArray:listArray];
        [self avplayerInit];

    }
}

- (void)addItem:(AudioItem *)item {
    if (item && ![self filterListWithItem:item]) {
        AVPlayerItem *playerItem = [self avplayItemConvertForAudioItem:item];

        if ([self.avplayer canInsertItem:playerItem afterItem:nil]) {
            [self.playItemList addObject:playerItem];
            [self.audioItemList addObject:item];
            [self.avplayer insertItem:playerItem afterItem:nil];
        }
    }
}

- (void)removeItem:(AudioItem *)item {
    [self.audioItemList removeObject:item];
    AVPlayerItem *playerItem = [self avplayItemConvertForAudioItem:item];
    [self.playItemList removeObject:playerItem];
    [self removeObserverForItem:playerItem];
    [self.avplayer removeItem:playerItem];
}

- (void)removeAllItem {
    [self.avplayer removeAllItems];
    [self.playItemList removeAllObjects];
    [self.audioItemList removeAllObjects];
}

- (NSArray<AudioItem *> *)getCurrentPlayList {
    return [self.audioItemList copy];
}

- (AudioItem *)getCurrentPlayItem {
    NSUInteger index = [self getCurrentIndex];
    return self.audioItemList[index];
}

- (NSUInteger)getCurrentIndex {
    AVPlayerItem *currentItem = [self.avplayer currentItem];
    NSUInteger currentIndex = [self.playItemList indexOfObject:currentItem];
    return currentIndex;
}

- (void)addQueueToPlayerFromArray:(NSArray<AudioItem *> *)array {
    for (AudioItem *item in array) {
        if (item.audioURL && item.audioURL.absoluteString.length > 0) {
           AVPlayerItem *avItem = [self avplayItemConvertForAudioItem:item];
            [self.playItemList addObject:avItem];
        }
    }

}

/**
 转换AVPlayerItem 模型
 */
- (AVPlayerItem *)avplayItemConvertForAudioItem:(AudioItem *)item {

    AVPlayerItem *avItem = [[AVPlayerItem alloc] initWithURL:item.audioURL];
    [self addObserverForItem:avItem];
    
    return avItem;
}

// 判断 Item列表是否存在相同的资源
- (BOOL)filterListWithItem:(AudioItem *)item {
    if ([self.audioItemList containsObject:item]) {
        return YES;
    }
    for (AudioItem *tempItem in self.audioItemList) {
        if ([tempItem.itemID isEqualToString:item.itemID]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Player Control

- (void)play {
    [self.avplayer play];
    [self configNowPlaying];
}

- (void)pause {
    [self.avplayer pause];
    [self configNowPlaying];
}

- (void)stop {
    
}

- (BOOL)next {
    
    NSUInteger currentIndex = [self getCurrentIndex];
    AVPlayerItem *currentItem = self.avplayer.currentItem;
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


- (void)configNowPlaying {
    /*
     MPNowPlayingInfoPropertyElapsedPlaybackTime
     MPNowPlayingInfoPropertyPlaybackRate
     MPNowPlayingInfoPropertyDefaultPlaybackRate 
     MPNowPlayingInfoPropertyPlaybackQueueIndex
     MPNowPlayingInfoPropertyPlaybackQueueCount
     MPNowPlayingInfoPropertyChapterNumber 
     MPNowPlayingInfoPropertyChapterCount 
     MPNowPlayingInfoPropertyIsLiveStream
     MPNowPlayingInfoPropertyAvailableLanguageOptions
     MPNowPlayingInfoLanguageOptionGroup
     MPNowPlayingInfoPropertyCurrentLanguageOptions
     MPNowPlayingInfoCollectionIdentifier 
     MPNowPlayingInfoPropertyExternalContentIdentifier
     MPNowPlayingInfoPropertyExternalUserProfileIdenti
     MPNowPlayingInfoPropertyPlaybackProgress
     MPNowPlayingInfoPropertyMediaType
     MPNowPlayingInfoPropertyAssetURL
     */
    AudioItem *currentItem = [self getCurrentPlayItem];
    
    NSMutableDictionary *playInfo = [NSMutableDictionary dictionary];

    [playInfo setObject:@(self.playItemList.count) forKey:MPNowPlayingInfoPropertyPlaybackQueueCount];
    [playInfo setObject:@([self getCurrentIndex]) forKey:MPNowPlayingInfoPropertyPlaybackQueueIndex];
    [playInfo setObject:[NSString stringWithFormat:@"%@",currentItem.title] forKey:MPMediaItemPropertyTitle];
    [playInfo setObject:[NSString stringWithFormat:@"%@",currentItem.artist]  forKey:MPMediaItemPropertyArtist];
    
    if (currentItem.image) {
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:currentItem.image];
        [playInfo setObject:artwork forKey:MPMediaItemPropertyArtwork];
    }

    [playInfo setObject:@(CMTimeGetSeconds(self.avplayer.currentItem.duration)) forKey:MPMediaItemPropertyPlaybackDuration];
    [playInfo setObject:@(CMTimeGetSeconds(self.avplayer.currentTime)) forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
    [playInfo setObject:[self isPlay] ? @(1) : @(0) forKey:MPNowPlayingInfoPropertyPlaybackRate];

    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:playInfo];
}

#pragma mark - Remote Control
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    NSLog(@"%ld",event.subtype);
    
    switch (event.subtype)    {
        case UIEventSubtypeRemoteControlPlay:
            [self play];
            break;
        case UIEventSubtypeRemoteControlPause:
            [self pause];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            [self next];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self last];
            break;
        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self isPlay] ? [self pause]: [self play];
            break;
        default:
            break;
            
    }
    
}
                                        
                                        
#pragma mark - Call Back

- (void)playFinish:(void(^)(AudioItem *item))finishBlock {
    _playFinishBlock = finishBlock;
}


- (void)playProgressValueChanged:(void(^)(AudioItem *currentItem, NSTimeInterval current,NSTimeInterval total))changedBlock {
    _playProgressBlock = changedBlock;
}

- (void)loadProgressValueChanged:(void(^)(AudioItem *currentItem, NSTimeInterval current,NSTimeInterval total))loadBlock {
    _loadProgressBlock = loadBlock;
}

- (void)seekToValue:(CGFloat)value completionHandler:(void (^)(BOOL finished))completionHandler {
    AVPlayerItem *currentItem = self.avplayer.currentItem;
    if (value < 0 || value > 1) {

        if (completionHandler) {
            completionHandler(YES);
        }
        return;
    }
    
    
    Float64 dura = CMTimeGetSeconds(currentItem.duration);
    int64_t time = dura * value;
    
    [currentItem seekToTime:CMTimeMake(time , 1) completionHandler:^(BOOL finished) {
        
        if (completionHandler) {
            completionHandler(finished);
        }
    }];
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
    [item removeObserver:self forKeyPath:@"status"];
    [item removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [item removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    
    AVPlayerItem *item = (AVPlayerItem *)object;

    if ([keyPath isEqualToString:@"status"]) {
        if (item.status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"准备播放");
            [self configNowPlaying];

        } else {
            NSLog(@"播放错误");
            
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval loadTime = [self availableDurationWithplayerItem:item];
        NSTimeInterval totalTime = CMTimeGetSeconds(item.duration);
        if (_loadProgressBlock) {
            _loadProgressBlock([self getCurrentPlayItem], loadTime,totalTime);
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
    
    NSUInteger index = [self getCurrentIndex];
    AudioItem *audioItem = self.audioItemList[index];
    if (_playFinishBlock) {
        _playFinishBlock(audioItem);
    }
}

#pragma mark - Lazy Load

- (NSMutableArray<AVPlayerItem *> *)playItemList {
    if (_playItemList == nil) {
        _playItemList = [NSMutableArray array];
    }
    return _playItemList;
}
- (NSMutableArray<AudioItem *> *)audioItemList {
    if (_audioItemList == nil) {
        _audioItemList = [NSMutableArray array];
    }
    return _audioItemList;
}

- (BOOL)isPlay {
    if (self.avplayer.rate > 0.0 && self.avplayer.error == nil) {
        return YES;
    }
    return NO;
}



@end


