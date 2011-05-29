//
//  FileDownload.h
//  FileDownLoadApp
//

#import <Foundation/Foundation.h>
#import "PhoneGapCommand.h"
@class ASINetworkQueue;

@interface FileDownload : PhoneGapCommand {
	NSMutableArray* params;
    ASINetworkQueue *networkQueue;
    long long downloadIdx;
    long long totalBytes;
}
@property (nonatomic, copy) NSString* successCallback;
@property (nonatomic, copy) NSString* failCallback;
@property (nonatomic, copy) NSString* progressCallback;
@property (retain) ASINetworkQueue *networkQueue;
-(void) downloadFile:(NSMutableArray*)paramArray withDict:(NSMutableDictionary*)options;
-(void) downloadFileFromUrl:(NSMutableArray*)paramArray;
@end