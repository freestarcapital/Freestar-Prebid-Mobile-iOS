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

#import <AdSupport/AdSupport.h>
#import "PrebidCache.h"
#import <sys/utsname.h>
#import <UIKit/UIKit.h>

#import "PBBidResponse.h"
#import "PBBidResponseDelegate.h"
#import "PBLogging.h"
#import "PBServerAdapter.h"
#import "PBServerFetcher.h"
#import "PBTargetingParams.h"
#import "PBServerRequestBuilder.h"
#import "PBException.h"

static NSString *const kAPNAdServerCacheIdKey = @"hb_cache_id";

static NSString *const kAPNPrebidServerUrl = @"https://prebid.adnxs.com/pbs/v1/openrtb2/auction";
static NSString *const kRPPrebidServerUrl = @"https://prebid-server.rubiconproject.com/openrtb2/auction";
static NSString *const kFSPrebidServerUrl = @"https://prebid.pub.network/openrtb2/auction";
static int const kBatchCount = 10;

@interface PBServerAdapter ()

@property (nonatomic, strong) NSString *accountId;

@property (assign) PBPrimaryAdServerType primaryAdServer;

@property (nonatomic, assign, readwrite) PBServerHost host;

@end

@implementation PBServerAdapter

- (nonnull instancetype)initWithAccountId:(nonnull NSString *)accountId andAdServer:(PBPrimaryAdServerType) adServer{
    if (self = [super init]) {
        _accountId = accountId;
        _isSecure = TRUE;
        _host = PBServerHostAppNexus;
        _primaryAdServer = adServer;
    }
    return self;
}

- (nonnull instancetype)initWithAccountId:(nonnull NSString *)accountId andHost:(PBServerHost) host andAdServer:(PBPrimaryAdServerType) adServer{
    if (self = [super init]) {
        _accountId = accountId;
        _isSecure = TRUE;
        _host = host;
        _primaryAdServer = adServer;
    }
    return self;
}

- (void)requestBidsWithAdUnits:(nullable NSArray<PBAdUnit *> *)adUnits
                  withDelegate:(nonnull id<PBBidResponseDelegate>)delegate {
    
    [[PBServerRequestBuilder sharedInstance] setHost:_host];
    
    //batch the adunits to group of 10 & send to the server instead of this bulk request
    int adUnitsRemaining = (int)[adUnits count];
    int j = 0;
    
    while(adUnitsRemaining) {
        NSRange range = NSMakeRange(j, MIN(kBatchCount, adUnitsRemaining));
        NSArray<PBAdUnit *> *subAdUnitArray = [adUnits subarrayWithRange:range];
        adUnitsRemaining-=range.length;
        j+=range.length;
        
        NSURLRequest *request = [[PBServerRequestBuilder sharedInstance] buildRequest:subAdUnitArray withAccountId:self.accountId withSecureParams:self.isSecure];
        
        [[PBServerFetcher sharedInstance] makeBidRequest:request withCompletionHandler:^(NSDictionary *adUnitToBidsMap, NSError *error) {
            if (error) {
                [delegate didCompleteWithError:error];
                return;
            }
            for (NSString *adUnitId in [adUnitToBidsMap allKeys]) {
                NSArray *bidsArray = (NSArray *)[adUnitToBidsMap objectForKey:adUnitId];
                NSMutableArray *bidResponsesArray = [[NSMutableArray alloc] init];
                for (NSDictionary *bid in bidsArray) {
                    PBBidResponse *bidResponse = [PBBidResponse bidResponseWithAdUnitId:adUnitId adServerTargeting:bid[@"ext"][@"prebid"][@"targeting"]];
                    PBLogDebug(@"Bid Successful with rounded bid targeting keys are %@ for adUnit id is %@", [bidResponse.customKeywords description], adUnitId);
                    [bidResponsesArray addObject:bidResponse];
                }
                [delegate didReceiveSuccessResponse:bidResponsesArray];;
            }
        }];
    }
}

@end
