//
//  ALChatManager.m
//  applozicdemo
//
//  Created by Adarsh on 28/12/15.
//  Copyright © 2015 applozic Inc. All rights reserved.
//

#import "ApplozicCordovaPlugin.h"
#import "ALChatManager.h"
#import <Applozic/ALUserDefaultsHandler.h>
#import <Applozic/ALMessageClientService.h>
#import <Applozic/ALApplozicSettings.h>
#import <Applozic/ALChatViewController.h>
#import <Applozic/ALMessage.h>
#import <Applozic/ALNewContactsViewController.h>
#import <Applozic/ALPushAssist.h>
#import <Applozic/ALContactService.h>
#import <Applozic/AlChannelResponse.h>
#import <Applozic/ALUserService.h>
#import <Applozic/ALChannelService.h>


@implementation ApplozicCordovaPlugin

-(NSString *)getApplicationKey
{
    NSString * appKey = [ALUserDefaultsHandler getApplicationKey];
    NSLog(@"APPLICATION_KEY :: %@",appKey);
    return appKey ? appKey : APPLICATION_ID;
}

- (ALChatManager *)getALChatManager:(NSString*)applicationId
{
    if (!applicationId) {
        applicationId = [self getApplicationKey];
    }
    return [[ALChatManager alloc] initWithApplicationKey:applicationId];
}

- (void)login:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    
    ALUser * alUser = [[ALUser alloc] initWithJSONString:jsonStr];
    ALChatManager *alChatManager = [self getALChatManager:alUser.applicationId];
    
    [ALUserDefaultsHandler setDeviceApnsType:[alUser deviceApnsType]];
    
    [alChatManager registerUserWithCompletion:alUser withHandler:^(ALRegistrationResponse *rResponse, NSError *error) {
        NSString* msg = nil;
        if (!error) {
            msg = [NSString stringWithFormat: @"%@", rResponse];
        } else {
            msg = [NSString stringWithFormat: @"%@", error];
        }
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString:msg];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void) isLoggedIn:(CDVInvokedUrlCommand*)command
{
    NSString* response = @"false";
    if ([ALUserDefaultsHandler isLoggedIn]) {
        response = @"true";
    }
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:response];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) updatePushNotificationToken:(CDVInvokedUrlCommand*)command
{
    NSString* apnDeviceToken = [[command arguments] objectAtIndex:0];
    if (![[ALUserDefaultsHandler getApnDeviceToken] isEqualToString:apnDeviceToken]) {
        ALRegisterUserClientService *registerUserClientService = [[ALRegisterUserClientService alloc] init];
        [registerUserClientService updateApnDeviceTokenWithCompletion:apnDeviceToken
                                                       withCompletion:^(ALRegistrationResponse*rResponse, NSError *error) {
                                                           if (error) {
                                                               NSLog(@"%@",error);
                                                               return;
                                                           }
                                                           NSLog(@"Registration response from server:%@", rResponse);
                                                       }];
    }
}

/*
 -(void) processPushNotification:(CDVInvokedUrlCommand*)command {
 //Todo: create dictionary from command
 ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
 [pushNotificationService notificationArrivedToApplication:application withDictionary:dictionary];
 }
 
 -(void) processBackgrou dPushNotification:(CDVInvokedUrlCommand*)command {
 {
 NSLog(@"Received notification Completion: %@", userInfo);
 ALPushNotificationService *pushNotificationService = [[ALPushNotificationService alloc] init];
 [pushNotificationService notificationArrivedToApplication:application withDictionary:userInfo];
 completionHandler(UIBackgroundFetchResultNewData);
 }
 */

- (void) launchChat:(CDVInvokedUrlCommand*)command
{
    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];
    
    ALPushAssist * assitant = [[ALPushAssist alloc] init];
    [alChatManager launchChat:[assitant topViewController]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) launchChatWithUserId:(CDVInvokedUrlCommand*)command
{
    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];
    NSString* userId = [[command arguments] objectAtIndex:0];
    
    ALPushAssist * assitant = [[ALPushAssist alloc] init];
    [alChatManager launchChatForUserWithDisplayName:userId
                                        withGroupId:nil  //If launched for group, pass groupId(pass userId as nil)
                                 andwithDisplayName:nil //Not mandatory, if receiver is not already registered you should pass Displayname.
                              andFromViewController:[assitant topViewController]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) launchChatWithGroupId:(CDVInvokedUrlCommand*)command
{
    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];
    NSNumber* groupId = [[command arguments] objectAtIndex:0];
    
    ALPushAssist * assitant = [[ALPushAssist alloc] init];
    [alChatManager launchChatForUserWithDisplayName:nil
                                        withGroupId:groupId   //If launched for group, pass groupId(pass userId as nil)
                                 andwithDisplayName:nil //Not mandatory, if receiver is not already registered you should pass Displayname.
                              andFromViewController:[assitant topViewController]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) launchChatWithClientGroupId:(CDVInvokedUrlCommand*)command
{
    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];
    NSString* clientGroupId = [[command arguments] objectAtIndex:0];
    
    ALPushAssist * assitant = [[ALPushAssist alloc] init];
    [alChatManager launchChatForUserWithDisplayName:nil
                                        withGroupId:nil  //If launched for group, pass groupId(pass userId as nil)
                                 andwithDisplayName:nil //Not mandatory, if receiver is not already registered you should pass Displayname.
                              andFromViewController:[assitant topViewController]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void)startNewConversation:(CDVInvokedUrlCommand*)command
{
    ALChatManager *alChatManager = [self getALChatManager: [self getApplicationKey]];
    alChatManager.chatLauncher = [[ALChatLauncher alloc] initWithApplicationId:[self getApplicationKey]];
    ALPushAssist * assitant = [[ALPushAssist alloc] init];
    
    [alChatManager.chatLauncher launchContactList:[assitant topViewController]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) showAllRegisteredUsers:(CDVInvokedUrlCommand*)command
{
    NSString* showAll = [[command arguments] objectAtIndex:0];
    [ALApplozicSettings setFilterContactsStatus:[showAll boolValue]];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) addContact:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    
    ALContact *contact = [[ALContact alloc] initWithJSONString:jsonStr];
    ALContactService * alContactService = [[ALContactService alloc] init];
    [alContactService addContact:contact];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) updateContact:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    
    ALContact *contact = [[ALContact alloc] initWithJSONString:jsonStr];
    ALContactService * alContactService = [[ALContactService alloc] init];
    [alContactService updateContact:contact];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) removeContact:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    ALContact *contact = [[ALContact alloc] initWithJSONString:jsonStr];
    
    ALContactService * alContactService = [[ALContactService alloc] init];
    [alContactService purgeContact:contact];
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) addContacts:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    
    NSError* error;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error:&error];
    NSLog(@"%@", jsonObject);
    NSLog(@"%@", error);
    NSArray * jsonArray = [NSArray arrayWithArray:(NSArray *)jsonObject];
    if(jsonArray.count)
    {
        NSDictionary * JSONDictionary = (NSDictionary *)jsonObject;
        ALContactService * alContactService = [[ALContactService alloc] init];
        for (NSDictionary * theDictionary in JSONDictionary)
        {
            ALContact * userDetail = [[ALContact alloc] initWithDict:theDictionary];
            [alContactService updateOrInsert:userDetail];
            NSLog(@" userDetail ::%@",userDetail.displayName);
        }
    }
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:@"success"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

- (void) createGroup:(CDVInvokedUrlCommand*)command
{
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error:&error];
    NSLog(@"%@", error);
    
    ALChannelService *alChannelService = [[ALChannelService alloc]init];
    ALChannel *alChannel = [[ALChannel alloc] init];
    [alChannel setName:[jsonObject objectForKey:@"groupName"]];
    [alChannel setChannelImageURL:[jsonObject objectForKey:@"imageUrl"]];
    [alChannel setClientChannelKey:[jsonObject objectForKey:@"clientGroupId"]];
    [alChannel setMembersId:[jsonObject objectForKey:@"groupMemberList"]];
    [alChannel setMetadata:[jsonObject objectForKey:@"metadata"]];
    [alChannel setType:[[jsonObject objectForKey:@"type"] shortValue]];
    
    [alChannelService createChannel:alChannel.name orClientChannelKey:alChannel.clientChannelKey andMembersList:alChannel.membersId andImageLink:alChannel.channelImageURL channelType:alChannel.type andMetaData:alChannel.metadata withCompletion:^(ALChannel *alChannel, NSError *error) {
        CDVPluginResult* result = [CDVPluginResult
                                   resultWithStatus:CDVCommandStatus_OK
                                   messageAsString:@"success"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    }];
}

- (void)logout:(CDVInvokedUrlCommand*)command
{
    ALRegisterUserClientService * alUserClientService = [[ALRegisterUserClientService alloc]init];
    if([ALUserDefaultsHandler getDeviceKeyString]) {
        [alUserClientService logoutWithCompletionHandler:^(ALAPIResponse *response, NSError *error) {
            CDVPluginResult* result = [CDVPluginResult
                                       resultWithStatus:CDVCommandStatus_OK
                                       messageAsString:@"success"];
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        }];
    }
}

- (void)getChannelByChannelKey:(CDVInvokedUrlCommand*)command
{
    NSNumber* channelKey = [[command arguments] objectAtIndex:0];
    ALChannelService * channelService = [[ALChannelService alloc] init];
    ALChannel *alChannel = [channelService getChannelByKey:channelKey];
    
    if(alChannel){
        CDVPluginResult* result;
        
        AlChannelResponse * alChannelResponse = [[AlChannelResponse alloc ] init];
        alChannelResponse.key = alChannel.key;
        alChannelResponse.imageUrl = alChannel.channelImageURL;
        alChannelResponse.name = alChannel.name;
        alChannelResponse.notificationAfterTime = alChannel.notificationAfterTime;
        alChannelResponse.deletedAtTime = alChannel.deletedAtTime;
        alChannelResponse.clientGroupId = alChannel.clientChannelKey;
        alChannelResponse.type = alChannel.type;
        alChannelResponse.adminKey = alChannel.adminKey;
        alChannelResponse.userCount = alChannel.userCount;
        alChannelResponse.unreadCount = alChannel.unreadCount;
        alChannelResponse.conversationProxy = alChannel.conversationProxy;
        alChannelResponse.metadata = alChannel.metadata;
        
        NSError * nsError;
        NSData * postdata = [NSJSONSerialization dataWithJSONObject:alChannelResponse.dictionary options:0 error:&nsError];
        NSString *json = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
        
        result = [CDVPluginResult
                  resultWithStatus:CDVCommandStatus_OK
                  messageAsString:json];
        
    }else{
        
        [channelService getChannelInformation:channelKey orClientChannelKey:nil withCompletion:^(ALChannel *alChannel) {
            
            CDVPluginResult* result;
            if(alChannel){
                
                AlChannelResponse * alChannelResponse = [[AlChannelResponse alloc ] init];
                alChannelResponse.key = alChannel.key;
                alChannelResponse.imageUrl = alChannel.channelImageURL;
                alChannelResponse.name = alChannel.name;
                alChannelResponse.notificationAfterTime = alChannel.notificationAfterTime;
                alChannelResponse.deletedAtTime = alChannel.deletedAtTime;
                alChannelResponse.clientGroupId = alChannel.clientChannelKey;
                alChannelResponse.type = alChannel.type;
                alChannelResponse.adminKey = alChannel.adminKey;
                alChannelResponse.userCount = alChannel.userCount;
                alChannelResponse.unreadCount = alChannel.unreadCount;
                alChannelResponse.conversationProxy = alChannel.conversationProxy;
                alChannelResponse.metadata = alChannel.metadata;
                NSError * nsError;
                
                NSData * postdata = [NSJSONSerialization dataWithJSONObject:alChannelResponse.dictionary options:0 error:&nsError];
                NSString *jsonString = [[NSString alloc] initWithData:postdata encoding:NSUTF8StringEncoding];
                result = [CDVPluginResult
                          resultWithStatus:CDVCommandStatus_OK
                          messageAsString:jsonString];
                
            }else{
                
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                           messageAsString:@"error"];
                
            }
            [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
            
        }];
        
        
    }
    
}

- (void)createGroupOfTwo:(CDVInvokedUrlCommand*)command{
    
    NSString *jsonStr = [[command arguments] objectAtIndex:0];
    jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@"\\\"" withString:@"\""];
    jsonStr = [NSString stringWithFormat:@"%@",jsonStr];
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSError* error;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options: NSJSONReadingMutableContainers error:&error];
    NSLog(@"%@", error);
    
    ALChannelService *alChannelService = [[ALChannelService alloc]init];
    ALChannel *alChannel = [[ALChannel alloc] init];
    [alChannel setName:[jsonObject objectForKey:@"groupName"]];
    [alChannel setChannelImageURL:[jsonObject objectForKey:@"imageUrl"]];
    [alChannel setClientChannelKey:[jsonObject objectForKey:@"clientGroupId"]];
    [alChannel setMembersId:[jsonObject objectForKey:@"groupMemberList"]];
    [alChannel setMetadata:[jsonObject objectForKey:@"metadata"]];
    [alChannel setType:[[jsonObject objectForKey:@"type"] shortValue]];
    
    [alChannelService createGoupOfTwo:alChannel.name orClientChannelKey:alChannel.clientChannelKey andMembersList:alChannel.membersId andImageLink:alChannel.channelImageURL channelType:alChannel.type andMetaData:alChannel.metadata adminUser:nil withCompletion:^(ALChannel *alChannel, NSError *error) {
        CDVPluginResult* result;
        
        if(alChannel){
            
            result = [CDVPluginResult
                      resultWithStatus:CDVCommandStatus_OK
                      messageAsString:[NSString stringWithFormat:@"%@", alChannel.key]];
            
        }else{
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                       messageAsString:@"error"];
        }
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];

        
    }];
    
    
}

- (void) getUnreadCount:(CDVInvokedUrlCommand*)command
{
    
    ALUserService * alUserService = [[ALUserService alloc] init];
    NSNumber * totalUnreadCount = [alUserService getTotalUnreadCount];
    
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:[totalUnreadCount stringValue]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}

- (void) getUnreadCountForGroup:(CDVInvokedUrlCommand*)command
{
    NSNumber* channelKey = [[command arguments] objectAtIndex:0];
    
    ALChannelService *channelService = [ALChannelService new];
    ALChannel *alChannel = [channelService getChannelByKey:channelKey];
    NSNumber *unreadCount = [alChannel unreadCount];
    
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:[unreadCount stringValue]];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}

- (void) getUnreadCountForUser:(CDVInvokedUrlCommand*)command
{
    NSString* userId = [[command arguments] objectAtIndex:0];
    
    ALContactService* contactService = [ALContactService new];
    ALContact *contact = [contactService loadContactByKey:@"userId" value:userId];
    NSNumber *unreadCount = [contact unreadCount];
    
    CDVPluginResult* result = [CDVPluginResult
                               resultWithStatus:CDVCommandStatus_OK
                               messageAsString:[unreadCount stringValue] ];
    
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    
}

@end
