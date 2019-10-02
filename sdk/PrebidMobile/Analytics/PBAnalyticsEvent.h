/*   Copyright 2017 Prebid.org, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PBAnalyticsEventType) {
    PBAnalyticsEventCustom = 0,
    PBAnalyticsEventBidAdjustment,
    PBAnalyticsEventBidResponse,
    PBAnalyticsEventBidWon,
    PBAnalyticsEventDFPResponse,
    PBAnalyticsEventVideoAd,
    PBAnalyticsEventCREImpression    
};

@interface PBAnalyticsEvent : NSObject
@property (nonatomic, readonly) NSDate *__nullable date;
@property (nonatomic, assign, readonly) PBAnalyticsEventType type;
@property (nonatomic) NSString *__nullable title;
@property (nonatomic) NSDictionary *__nullable info;

- (instancetype _Nonnull )initWithEventType:(PBAnalyticsEventType)type;

@end
