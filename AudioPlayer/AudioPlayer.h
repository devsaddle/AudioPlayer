//
//  AudioPlayer.h
//  AudioPlayer
//
//  Created by 马远 on 2017/7/12.
//  Copyright © 2017年 Yuan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AudioPlayer : NSObject

+ (instancetype)shareManager;

- (void)creatPlayList:(NSArray *)listArray;
- (void)addItem:(id)item;
- (void)removeItem:(id)item;
- (NSArray *)getCurrentPlayList;
- (id)getCurrentPlayItem;

- (void)play;
- (void)pause;
- (void)stop;
- (void)next;
- (void)last;


@end
