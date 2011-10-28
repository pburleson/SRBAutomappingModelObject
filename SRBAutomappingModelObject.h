/**
 Copyright (c) 2011 - Steve Breen
 All rights reserved.
 
 Redistribution and use in source and binary forms are permitted
 provided that the above copyright notice and this paragraph are
 duplicated in all such forms and that any documentation,
 advertising materials, and other materials related to such
 distribution and use acknowledge that the software was developed
 by the <organization>.  The name of the
 University may not be used to endorse or promote products derived
 from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.*/

#import "SRBAutomappingModelObject.h"

typedef id (^AutomappingFormatBlock)( id data);									// called once we retrieve the data from the source object.

@interface  SRBAutomappingModelObject : NSObject


@property (nonatomic, assign) 	BOOL  	disableAutomaticBOOLHandling;			// by default, we convert from bool string types, e.g., "yes", "true" to numeric destination types
@property (nonatomic, assign) 	BOOL 	enableStrictMapping;					// DEBUG style option; will toss NSAsserts if source keys don't exist. (default is YES for DEBUG builds)

-(void) addAllPropertiesForMapping;												// if your object properties match the incoming dictionary 100%, call this in your -init
-(void) addMappingWithDestinationKey: (NSString *) destKey;						// if source == destination
-(void) addMappingWithDestinationKey: (NSString *) destKey						// if source != destination
					   sourceKeyPath: (NSString *) sourceKeyPath;

-(void) addMappingWithDestinationKey: (NSString *) destKey						// after mapping, we need to format the data (e.g., NSDate conversion from NSString -> NSDate via NSDateFormatter)
					   sourceKeyPath: (NSString *) sourceKeyPath
					 formattingBlock: (AutomappingFormatBlock) formattingBlock;

-(BOOL) removeMappingForDestKey: (NSString *) destKey;

-(BOOL) updateFromDictionary: (NSDictionary *) dictionary;


@end


