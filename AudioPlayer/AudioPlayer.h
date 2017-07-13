//
//  AudioPlayer.h
//  AudioPlayer
//
//  Created by 马远 on 2017/7/12.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioPlayer : NSObject
/** 是否正在播放 */
@property (nonatomic, assign) BOOL isPlay;

+ (instancetype)shareManager;



- (void)creatPlayList:(NSArray *)listArray;
- (void)addItem:(id)item;
- (void)removeItem:(id)item;
- (NSArray *)getCurrentPlayList;
- (id)getCurrentPlayItem;
- (NSUInteger)getCurrentIndex;

- (void)play;
- (void)pause;
- (void)stop;
- (BOOL)next;
- (BOOL)last;



/**
 播放进度回调
 */
- (void)playProgressValueChanged:(void(^)(NSTimeInterval current,NSTimeInterval total))changedBlock;


/**
 加载进度回调
 */
- (void)loadProgressValueChanged:(void(^)(NSTimeInterval current,NSTimeInterval total))loadBlock;

@end
