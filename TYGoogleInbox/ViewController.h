//
//  ViewController.h
//  TYGoogleInbox
//
//  Created by Thabresh on 8/10/16.
//  Copyright © 2016 VividInfotech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLGmail.h"

@interface ViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>
{
    NSInteger totalThreads;
    NSMutableArray *inboxDates;
    NSMutableArray *inboxToAdds;
    NSMutableArray *inboxSubjects;
    NSMutableArray *listThreadID;
    NSInteger nextTag;  
}
@property (nonatomic, strong) GTLServiceGmail *service;
@property (weak, nonatomic) IBOutlet UITableView *inboxTbl;
@end

