//
//  ViewController.m
//  TYGoogleInbox
//
//  Created by Thabresh on 8/10/16.
//  Copyright © 2016 VividInfotech. All rights reserved.
//

#import "ViewController.h"
#import "CustomCell.h"
static NSString *const kKeychainItemName = @"TYGoogleInbox";
static NSString *const kClientID = @"YOUR CLIENT ID";
@interface ViewController ()
{
    BOOL LoginClicked;
}
@end

@implementation ViewController
@synthesize service = _service;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.inboxTbl.estimatedRowHeight = 50.0;
    self.inboxTbl.rowHeight = UITableViewAutomaticDimension;
    [self.inboxTbl registerNib:[UINib nibWithNibName:@"CustomCell" bundle:nil] forCellReuseIdentifier:@"CustomCell"];
    inboxSubjects = [NSMutableArray new];
    inboxToAdds = [NSMutableArray new];
    inboxDates = [NSMutableArray new];
    self.service = [[GTLServiceGmail alloc] init];
    self.service.authorizer =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName clientID:kClientID clientSecret:nil];
}
- (void)viewDidAppear:(BOOL)animated {
    if (!self.service.authorizer.canAuthorize) {
        [self presentViewController:[self createAuthController] animated:YES completion:nil];
    } else {
        [self fetchLabels];
        self.navigationItem.title = [self.service.authorizer userEmail];
    }
}
- (void)fetchLabels {
    GTLQueryGmail *query = [GTLQueryGmail queryForUsersGetProfile];
    [self.service executeQuery:query
                      delegate:self
             didFinishSelector:@selector(displayResultWithTicket:finishedWithObject:error:)];
}
- (void)displayResultWithTicket:(GTLServiceTicket *)ticket
             finishedWithObject:(GTLGmailProfile *)labelsResponse
                          error:(NSError *)error {
    if (error == nil) {
        self.navigationItem.prompt = [NSString stringWithFormat:@"Total Messages:%@",labelsResponse.threadsTotal];
        totalThreads = [labelsResponse.threadsTotal integerValue];
        if ([labelsResponse.messagesTotal integerValue]>=10 ) {
            [self GetInboxMessagesListIds];
        }
    } else {
        [self showAlert:@"Error" message:error.localizedDescription];
    }
}
-(void)GetInboxMessagesListIds
{
    GTLQueryGmail *query = [GTLQueryGmail queryForUsersMessagesList];
    query.maxResults = totalThreads;
    [self.service executeQuery:query
                      delegate:self
             didFinishSelector:@selector(displayResultWithTickessst:finishedWithObject:error:)];
}
- (void)displayResultWithTickessst:(GTLGmailMessage *)Messages
             finishedWithObject:(GTLGmailListMessagesResponse *)labelsResponse
                          error:(NSError *)error {
    if (error == nil) {
        listThreadID = [NSMutableArray new];
        for (GTLGmailMessage *label in labelsResponse.messages) {
            [listThreadID addObject:label.threadId];
        }
        nextTag = 0;
        [self GetInboxMessagesList];
    } else {
        [self showAlert:@"Error" message:error.localizedDescription];
    }
}
-(void)GetInboxMessagesList
{
    GTLQueryGmail *query = [GTLQueryGmail queryForUsersMessagesGet];
    query.identifier=[listThreadID objectAtIndex:nextTag];
    [self.service executeQuery:query
                      delegate:self
             didFinishSelector:@selector(GetInboxMessagesList:finishedWithObject:error:)];
}
- (void)GetInboxMessagesList:(GTLServiceTicket *)Messages
                finishedWithObject:(GTLGmailMessage *)labelsResponse
                             error:(NSError *)error {
    NSString *subject;
    NSString *date;
    NSString *To;
    NSMutableArray *tempArray = [NSMutableArray new];
    NSArray *arr = labelsResponse.payload.headers;
    for (GTLGmailMessagePartHeader *obj in arr){
        [tempArray addObject:obj.name];
        if ([obj.name isEqualToString:@"Subject"]) {
            subject = obj.value;
        }
        if ([obj.name isEqualToString:@"To"]) {
            To = obj.value;
        }
        if ([obj.name isEqualToString:@"Date"]) {
            date = obj.value;
        }
    }
    if (![tempArray containsObject:@"Subject"]) {
        subject = @" ";
    }
    [self StoreHeaderValues:subject andStrTo:To andDate:date];
}
-(void)StoreHeaderValues:(NSString*)StrSubject andStrTo:(NSString*)StrToo andDate:(NSString*)StrDate
{
    [inboxToAdds addObject:StrToo];
    [inboxDates addObject:StrDate];
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSInteger currentCount = inboxSubjects.count;
    for (int i = 0; i < 1; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:currentCount+i inSection:0]];
    }
    // do the insertion
    [inboxSubjects addObject:StrSubject];
    
    // tell the table view to update (at all of the inserted index paths)
    [self.inboxTbl beginUpdates];
    [self.inboxTbl insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationBottom];
    [self.inboxTbl endUpdates];
    nextTag++;
    if (listThreadID.count>nextTag) {
        [self GetInboxMessagesList];
    }
    
}
// Creates the auth controller for authorizing access to Gmail API.
- (GTMOAuth2ViewControllerTouch *)createAuthController {
    GTMOAuth2ViewControllerTouch *authController;
    NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeGmailReadonly, nil];
    authController = [[GTMOAuth2ViewControllerTouch alloc]
                      initWithScope:[scopes componentsJoinedByString:@" "]
                      clientID:kClientID
                      clientSecret:nil
                      keychainItemName:kKeychainItemName
                      delegate:self
                      finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}

// Handle completion of the authorization process, and update the Gmail API
// with the new credentials.
- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    if (error != nil) {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.service.authorizer = nil;
    }
    else {
        self.service.authorizer = authResult;
        self.navigationItem.title = authResult.userEmail;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// Helper for showing an alert
- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
     {
         [alert dismissViewControllerAnimated:YES completion:nil];
     }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
}
#pragma mark - TableViewDataSource:
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return [inboxSubjects count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CustomCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CustomCell"];
    cell.txtSubject.text = [inboxSubjects objectAtIndex:indexPath.row];
    cell.txtToadds.text = [inboxToAdds objectAtIndex:indexPath.row];
    cell.txtDate.text = [self ConvertDate:[inboxDates objectAtIndex:indexPath.row]];
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}
-(NSString*)ConvertDate:(NSString*)GetDate
{
    NSString *strGetDate = [[GetDate componentsSeparatedByString:@","]objectAtIndex:0];
    if (strGetDate.length>5) {
        strGetDate = [[strGetDate componentsSeparatedByString:@" "]objectAtIndex:0];
        strGetDate = [NSString stringWithFormat:@"%@ %@",strGetDate,[[GetDate componentsSeparatedByString:@" "]objectAtIndex:1]];
    }
    return strGetDate;
}
@end
