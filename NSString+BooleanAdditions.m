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

#import "NSString+BooleanAdditions.h"

@implementation NSString (BooleanAdditions)

-(NSArray *) trueValues
{
	return [NSArray arrayWithObjects: @"true", @"t", @"yes", @"y",  nil];
}

-(NSArray *) falseValues
{
	return [NSArray arrayWithObjects: @"false", @"f", @"no", @"n", nil];
}

-(NSArray *) allValues
{
	return [[NSArray arrayWithArray: [self trueValues]] arrayByAddingObjectsFromArray: [self falseValues]];
}

-(BOOL) isBooleanValue
{
	return [[self allValues] containsObject: [self lowercaseString]];
}

-(BOOL) booleanValue
{
	return [[self trueValues] containsObject: [self lowercaseString]];
}

@end
