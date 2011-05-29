//
//  FileDownload.m
//  FileDownLoadApp
//

#import "FileDownload.h"
#import "ASIHTTPRequestConfig.h"
#import "ASIHTTPRequestDelegate.h"
#import "ASIProgressDelegate.h"
#import "ASICacheDelegate.h"
#import "ASIHTTPRequest.h"
#import "ASIDataCompressor.h"
#import "ASIDataDecompressor.h"
#import "ASIFormDataRequest.h"
#import "ASINetworkQueue.h"
#import "ASIDownloadCache.h"
#import "ASIAuthenticationDialog.h"
#import "Reachability.h"

@implementation FileDownload

@synthesize successCallback, failCallback, progressCallback, networkQueue;

//
// entry point to  the javascript plugin for PhoneGap
//
-(void) downloadFile:(NSMutableArray*)paramArray withDict:(NSMutableDictionary*)options {
	
	NSLog(@"in FileDownload.downloadFile",nil);
    
    NSUInteger argc = [paramArray count];

	NSString * sourceUrl = [paramArray objectAtIndex:0];
	NSString * fileName = [paramArray objectAtIndex:1];
    NSString * destinationPath = [paramArray objectAtIndex:2];
    
    if (argc > 3) {
        self.successCallback = [paramArray objectAtIndex:3];
    }
    if (argc > 4) {
        self.failCallback = [paramArray objectAtIndex:4];
	}
    if (argc > 5) {
        self.progressCallback = [paramArray objectAtIndex:5];
	}
	
	params = [[NSMutableArray alloc] initWithCapacity:3];	
	[params addObject:sourceUrl];
	[params addObject:fileName];
    [params addObject:destinationPath];
	
	if (![self networkQueue]) {
        // Stop anything already in the queue before removing it
        //[[self networkQueue] cancelAllOperations];
        
        // Creating a new queue each time we use it means we don't have to worry about clearing delegates or resetting progress tracking
        [self setNetworkQueue:[ASINetworkQueue queue]];
        [[self networkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
        [[self networkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
        [[self networkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
        [[self networkQueue] setRequestDidReceiveResponseHeadersSelector:@selector(requestStarted:)];
        [[self networkQueue] setShowAccurateProgress:YES];
        //[[self networkQueue] setDownloadProgressDelegate:self];
        [[self networkQueue] setDelegate:self];
        [[self networkQueue] go];
        [self downloadFileFromUrl:params];

    }else{
        [self downloadFileFromUrl:params];
    }
}


//
// call to excute the download in a background queue
//
-(void) downloadFileFromUrl:(NSMutableArray*)paramArray
{
	NSLog(@"in FileDownload.downloadFileFromUrl %@", [paramArray objectAtIndex:0]);
	NSString * sourceUrl = [paramArray objectAtIndex:0];
	NSString * fileName = [paramArray objectAtIndex:1];
	NSString * destinationPath = [paramArray objectAtIndex:2];
    
	// save file in documents directory
    NSString *documentsDirectory = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), destinationPath]; // String Path
	NSString *newFilePath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat: @"/%@", fileName]];

    // Create and Queue request
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:sourceUrl]];
    [request setDownloadDestinationPath:newFilePath];
    [request setPersistentConnectionTimeoutSeconds:20];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [request setDownloadProgressDelegate:self]; 
    [request setShowAccurateProgress:YES]; 
    [request setDelegate:self];
    [[self networkQueue] addOperation:request];
	
}


- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes; 
{
    downloadIdx += bytes;
    //if (downloadIdx++ %5 == 0) { // Send data by 10% steps
        NSLog(@"in FileDownload.ProgressCallBack Received ->%qu", downloadIdx/1024);
        NSLog(@"in FileDownload.ProgressCallBack Total ->%qu", totalBytes/1024);
        NSLog(@"in FileDownload.ProgressCallBack Speed ->%lu", [ASIHTTPRequest averageBandwidthUsedPerSecond]);
        NSString * jsCallBack = [NSString stringWithFormat:@"%@(%qu, %qu, %li);", self.progressCallback, downloadIdx, totalBytes, [ASIHTTPRequest averageBandwidthUsedPerSecond] ];
        [self writeJavascript: jsCallBack]; 
    //}
}

- (void)request:(ASIHTTPRequest *)request incrementDownloadSizeBy:(long long)newLength; 
{
    NSLog(@"incrementDownloadSizeBy %@",[NSString stringWithFormat:@"%quKb", newLength/1024]);
    totalBytes = newLength; // Keep totalBytes
}

- (void)requestStarted:(ASIHTTPRequest *)request
{
    int statusCode = [request responseStatusCode];
    if (statusCode == 404) {
        // Cancel request
        [request cancel];
        NSString * jsCallBack = [NSString stringWithFormat:@"%@(%i);", self.failCallback, statusCode ];
        [self writeJavascript: jsCallBack];
    }
    NSLog(@"statusCode : %i", statusCode);
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
	// Release the queue here if no more request
	if ([[self networkQueue] requestsCount] == 0) {
            [self setNetworkQueue:nil];
        [networkQueue release];
	}
    
	//... Handle success
    NSString *response = [request responseString];
    NSString * jsCallBack = [NSString stringWithFormat:@"%@(\"%@\");", self.successCallback, response ];
	[self writeJavascript: jsCallBack];
	NSLog(@"Request finished");
    
    // Reset values
    downloadIdx = 0;
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
	// Release the queue here if no more request
	if ([[self networkQueue] requestsCount] == 0) {
		[self setNetworkQueue:nil];
        [networkQueue release];
	}
    
	//... Handle failure
    NSError *error = [request error];
    NSString * jsCallBack = [NSString stringWithFormat:@"%@(\"%@\");", self.failCallback, error ];
	[self writeJavascript: jsCallBack];
	NSLog(@"Request failed");
}


- (void)queueFinished:(ASINetworkQueue *)queue
{
	// Release the queue here if no more request
	if ([[self networkQueue] requestsCount] == 0) {
		[self setNetworkQueue:nil];
        [networkQueue release];
	}
	NSLog(@"Queue finished");
    // Reset values
    downloadIdx = 0;
}


- (void)dealloc
{
	if (params) {
		[params release];
	}
    [networkQueue release];
    [super dealloc];
}

@end