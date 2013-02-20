/*

File: ReachabilityAppDelegate.m
Abstract: The application's controller.

Version: 2.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the following terms, and your
use, installation, modification or redistribution of this Apple software
constitutes acceptance of these terms.  If you do not agree with these terms,
please do not use, install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject
to these terms, Apple grants you a personal, non-exclusive license, under
Apple's copyrights in this original Apple software (the "Apple Software"), to
use, reproduce, modify and redistribute the Apple Software, with or without
modifications, in source and/or binary forms; provided that if you redistribute
the Apple Software in its entirety and without modifications, you must retain
this notice and the following text and disclaimers in all such redistributions
of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may be used
to endorse or promote products derived from the Apple Software without specific
prior written permission from Apple.  Except as expressly stated in this notice,
no other rights or licenses, express or implied, are granted by Apple herein,
including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2009 Apple Inc. All Rights Reserved.

*/

#import "ReachabilityAppDelegate.h"
#import "SimplePinger.h"
#import "Reachability.h"
#include <netinet/in.h>
#include <arpa/inet.h>


@implementation ReachabilityAppDelegate

- (void) configureTextField: (UITextField*) textField imageView: (UIImageView*) imageView reachability: (Reachability*) curReach
{
    /* curReach is an instance of Reachability */
    NetworkStatus netStatus = [curReach currentReachabilityStatus];
    BOOL connectionRequired= [curReach connectionRequired];
    NSString* statusString= @"";
    switch (netStatus)
    {
        case NotReachable:
        {
            statusString = @"Access Not Available";
            imageView.image = [UIImage imageNamed: @"stop-32.png"] ;
            //Minor interface detail- connectionRequired may return yes, even when the host is unreachable.  We cover that up here...
            connectionRequired= NO;  
            break;
        }
            
        case ReachableViaWWAN:
        {
            statusString = @"Reachable WWAN";
            imageView.image = [UIImage imageNamed: @"WWAN5.png"];
            break;
        }
        case ReachableViaWiFi:
        {
             statusString= @"Reachable WiFi";
            imageView.image = [UIImage imageNamed: @"Airport.png"];
            break;
      }
    }
    if(connectionRequired)
    {
        statusString= [NSString stringWithFormat: @"%@, Connection Required", statusString];
    }
    textField.text= statusString;
}

- (void) updateInterfaceWithReachability: (Reachability*) curReach
{
    
    /* curReach is an instance of Reachability */
    
    
    
    
    
    if(curReach == hostReach)
	{
		[self configureTextField: remoteHostStatusField imageView: remoteHostIcon reachability: curReach];
        
        NetworkStatus netStatus = [curReach currentReachabilityStatus];
        BOOL connectionRequired= [curReach connectionRequired];

        summaryLabel.hidden = (netStatus != ReachableViaWWAN);
        NSString* baseLabel=  @"";
        if(connectionRequired)
        {
            baseLabel=  @"Cellular data network is available.\n  Internet traffic will be routed through it after a connection is established.";
        }
        else
        {
            baseLabel=  @"Cellular data network is active.\n  Internet traffic will be routed through it.";
        }
        summaryLabel.text= baseLabel;
    }
	if(curReach == internetReach)
	{	
		[self configureTextField: internetConnectionStatusField imageView: internetConnectionIcon reachability: curReach];
	}
	if(curReach == wifiReach)
	{	
		[self configureTextField: localWiFiConnectionStatusField imageView: localWiFiConnectionIcon reachability: curReach];
	}
	
}

//Called by Reachability whenever status changes.
- (void) reachabilityChanged: (NSNotification* )note
{
    /* This method is called every time there is a change */
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
    
    
    
    /* Now update the user interface visually
     this might be replaced with some logic and commands of some sort
     
     */
    /* Check Ping again */
    [self simplePingThis:hostItemToReach];
    
	[self updateInterfaceWithReachability: curReach];
}

- (void) simplePingThis:(NSString*) addressToPing
{
    NSLog(@"Going to Ping");
   // dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);

    backgroundQueue = dispatch_queue_create("com.elbsolutions.simpleping", NULL);

    dispatch_async(backgroundQueue, ^{

        /* Add the SImplePinger app into here */
        pingResponseField.Text = [NSString stringWithFormat:@"Pinging %@",addressToPing,nil];

        SimplePinger *mainObj = [[SimplePinger alloc] init];
        //mainObj.stopOnAnyError = true;
        assert(mainObj != nil);
        
        //[mainObj runWithHostName:[NSString stringWithUTF8String:argv[1]]];
        [mainObj runWithHostName:addressToPing];
        
        dispatch_async(dispatch_get_main_queue(), ^(void){
            
            NSString *msg = @"";
            if ([mainObj reachedIpAddress]) {
                msg = [NSString stringWithFormat:@"Successful Ping of %@",addressToPing,nil];;
                
            } else {
                
                msg = [NSString stringWithFormat:@"No Response from %@",addressToPing,nil];;
                
                
            }
            pingResponseField.Text = msg;
            NSLog(@"%@",msg);
            

        });
    });
    

    
    
    


}
- (void) applicationDidFinishLaunching: (UIApplication* )application
{
    NSUserDefaults *ud =     [NSUserDefaults standardUserDefaults];
    hostItemToReach = [ud stringForKey:@"hostItemToReach"];
    
    if (!hostItemToReach) {
        hostItemToReach=@"www.apple.com"; //start off somewhere familiar
    }
    remoteHostIP.text = hostItemToReach;
    [self mainItemsAfterLaunching];
}
-(void) mainItemsAfterLaunching
{
	contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    summaryLabel.hidden = YES;        
    


    // Observe the kNetworkReachabilityChangedNotification. When that notification is posted, the
    // method "reachabilityChanged" will be called. 
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:) name: kReachabilityChangedNotification object: nil];

    //Change the host name here to change the server your monitoring

    

  
    /* initialize each Reachability instance */
    
    /* hostReach is an instance of Reachability
     hostItemToReach = @"www.apple.com";

     remoteHostLabel.text = [NSString stringWithFormat: @"Remote Host: %@", hostItemToReach];
     
	hostReach = [[Reachability reac habilityWithHostName: @"miniserver.local"] retain];
    */
    

    
    /* Since the item below this simplePing does NOT work , this was put here and it works */

    
    [self simplePingThis:hostItemToReach];

    /* This works like a dead horse - many attempts much internet digging.
     */
    remoteHostIP.text = [NSString stringWithFormat: @"%@", hostItemToReach];

    struct sockaddr_in callAddress;
    callAddress.sin_len = sizeof(callAddress);
    callAddress.sin_family = AF_INET;
    callAddress.sin_port = htons(24);
    callAddress.sin_addr.s_addr = inet_addr([hostItemToReach UTF8String]);    
    
    hostReach = [Reachability reachabilityWithAddress:&callAddress];
    
    
    [hostReach startNotifier];
	[self updateInterfaceWithReachability: hostReach];
	
    /* internetReach is an instance of Reachability */
    internetReach = [Reachability reachabilityForInternetConnection];
	[internetReach startNotifier];
	[self updateInterfaceWithReachability: internetReach];

    /* wifiReach is an instance of Reachability */
    wifiReach = [Reachability reachabilityForLocalWiFi];
	[wifiReach startNotifier];
	[self updateInterfaceWithReachability: wifiReach];

	[window makeKeyAndVisible];
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction)ipValueChanged:(id)sender {
    hostItemToReach = remoteHostIP.text;
    NSUserDefaults *ud =     [NSUserDefaults standardUserDefaults];
    [ud setObject:hostItemToReach forKey:@"hostItemToReach"];
    
    [self mainItemsAfterLaunching];
}

- (IBAction)pingNowish:(id)sender {
    [self simplePingThis:hostItemToReach];
}
@end
