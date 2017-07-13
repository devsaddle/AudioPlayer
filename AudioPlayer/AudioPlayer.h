//
//  AudioPlayer.h
//  AudioPlayer
//
//  Created by 马远 on 2017/7/12.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioItem.h"

@interface AudioPlayer : NSObject
/** 是否正在播放 */
@property (nonatomic, assign) BOOL isPlay;

+ (instancetype)shareManager;



- (void)creatPlayList:(NSArray<AudioItem *> *)listArray;
- (void)addItem:(AudioItem *)item;
- (void)removeItem:(AudioItem *)item;
- (NSArray<AudioItem *> *)getCurrentPlayList;
- (AudioItem *)getCurrentPlayItem;
- (NSUInteger)getCurrentIndex;

- (void)play;
- (void)pause;
- (void)stop;
- (BOOL)next;
- (BOOL)last;



/**
 播放完成回调
 */
- (void)playFinish:(void(^)(AudioItem *item))finishBlock;

/**
 播放进度回调
 */
- (void)playProgressValueChanged:(void(^)(AudioItem *currentItem, NSTimeInterval current,NSTimeInterval total))changedBlock;

/**
 加载进度回调
 */
- (void)loadProgressValueChanged:(void(^)(AudioItem *currentItem, NSTimeInterval current,NSTimeInterval total))loadBlock;

@end
