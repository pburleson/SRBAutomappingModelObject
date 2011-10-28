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
#import "NSString+BooleanAdditions.h"			

#import <objc/runtime.h>

#define kSourceKey				@"sourceKey"
#define kFormattingBlockKey		@"formattingBlockKey"

@interface SRBAutomappingModelObject()
{
	NSMutableDictionary 	*_mappingDictionary;
}
-(NSString *) classStringForPropertyNamed: (NSString *) propertyName;
-(BOOL) classCanTakeBooleanValue: (NSString *) className;
-(BOOL) validatePropertyName: (NSString *) propertyName;
@end


@implementation SRBAutomappingModelObject

@synthesize disableAutomaticBOOLHandling;
@synthesize enableStrictMapping;

-(id) init
{
	if( self = [super init] )
	{
		_mappingDictionary = [NSMutableDictionary dictionary];
#ifdef DEBUG
		self.enableStrictMapping = YES;
#endif
	}
	return self;
}

-(void) addAllPropertiesForMapping
{
	unsigned int propertyCount = 0;
	objc_property_t *properties = class_copyPropertyList( [self class], &propertyCount );
	for( NSInteger index=0; index<propertyCount; ++index )
	{
		const char *propName = property_getName( properties[index] );
		if( propName )
		{
			[self addMappingWithDestinationKey: [NSString stringWithUTF8String: propName]];
		}
	}
	
	if( properties ) free( properties );
}


-(void) addMappingWithDestinationKey: (NSString *) destKey
{
	if( [self validatePropertyName: destKey] )
	{
		[self addMappingWithDestinationKey: destKey sourceKeyPath: [destKey copy]];
	}
}


-(void) addMappingWithDestinationKey: (NSString *) destKey
					   sourceKeyPath: (NSString *) sourceKeyPath
{
	if( destKey && sourceKeyPath )
	{
		if( [self validatePropertyName: destKey] )
		{
			NSDictionary *dictionary = [NSDictionary dictionaryWithObject: sourceKeyPath forKey: kSourceKey];
			[_mappingDictionary setObject: dictionary forKey: destKey];
		}
	}
}

-(void) addMappingWithDestinationKey: (NSString *) destKey
					   sourceKeyPath:(NSString *)sourceKeyPath
					 formattingBlock: (AutomappingFormatBlock) formattingBlock
{
	if( destKey && sourceKeyPath )
	{
		if( [self validatePropertyName: destKey] )
		{
			NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject: sourceKeyPath forKey: kSourceKey];
			if( formattingBlock )
			{
				[dictionary setObject: [formattingBlock copy] forKey: kFormattingBlockKey];
			}
			[_mappingDictionary setObject: [NSDictionary dictionaryWithDictionary: dictionary] forKey: destKey];
		}
	}
	
}

-(BOOL) removeMappingForDestKey: (NSString *) destKey
{
	BOOL willRemove = [_mappingDictionary objectForKey: destKey] != nil;
	[_mappingDictionary removeObjectForKey: destKey];
	return willRemove;
}



-(BOOL) updateFromDictionary: (NSDictionary *) dictionary
{
    for( NSString *destKey in [_mappingDictionary allKeys] )
    {
		NSDictionary *mapDict = [_mappingDictionary objectForKey: destKey];
		NSString *sourceKey = [mapDict objectForKey: kSourceKey];
		AutomappingFormatBlock formatBlock = [mapDict objectForKey: kFormattingBlockKey];

		if( !sourceKey ) continue;
		NSString *destClassString = [self classStringForPropertyNamed: destKey];		
		// if the source key is ... wrong, bail
		if( [destClassString length] == 0 )
		{
			if( self.enableStrictMapping )
			{
				NSAssert( NO, @"Property not found:%@", destKey );
			}
			continue;
		}
		Class destClass = NSClassFromString(destClassString);
		
		// get our value...
		id value = nil;
		@try 
		{
			value = [dictionary valueForKeyPath: sourceKey];
		}
		@catch (NSException *exception) 
		{
		}
		
		// special case: handling JSON bool types and converting them to BOOL/NSNumber destinations
		if( [value isKindOfClass: [NSString class]] && [value isBooleanValue] && [self classCanTakeBooleanValue: destClassString] && !self.disableAutomaticBOOLHandling )
		{
			NSNumber *boolValue = [NSNumber numberWithBool: [value booleanValue]];
			[self setValue: boolValue forKey: destKey];
		}
		else
		{
			if( formatBlock )
			{
				value = formatBlock(value);
			}
			
			// dest class primitive? Count on setValue wrapping/unwrapping
			if( !destClass )
			{
				[self setValue: value forKey: destKey];
			}
			// NSNumber from NSString?
			else if( destClass == [NSNumber class] && [value isKindOfClass: [NSString class]] )
			{
				[self setValue: [NSNumber numberWithFloat:[value floatValue]] forKey: destKey];				
			}
			// NSString from NSNumber?
			else if( destClass == [NSString class] && [value isKindOfClass: [NSNumber class]] )
			{
				[self setValue: [value stringValue] forKey: destKey];
			}
			else if( [value isKindOfClass: destClass] )
			{
				[self setValue: value forKey: destKey];
			}
			// hmm.  types could be mis-matched.  strict check below will verify things are cool.
			else 
			{
				[self setValue: value forKey: destKey];
			}
			
			// if strict mapping, make sure the property's value has the same class (no funky boxing occurred)
			if( self.enableStrictMapping )
			{
				id newValue = [self valueForKey: destKey];
				if( newValue )
				{
					Class expectedClass = NSClassFromString([self classStringForPropertyNamed: destKey]);
					if( expectedClass )
					{
						NSAssert( [newValue isKindOfClass: expectedClass], @"Class isn't as expected for value %@ for property %@ expectedClass=%@ actualClass %@", newValue, destKey, expectedClass, [newValue class] );
					}
				}
			}
		}
    }
}

-(id) valueForUndefinedKey:(NSString *)key
{
	return nil;
}

-(void) setValue:(id)value forUndefinedKey:(NSString *)key
{
	
}

#pragma mark- Internal 
								   
-(NSString *) classStringForPropertyNamed: (NSString *) propertyName
{
	NSString *classString = nil;
	objc_property_t prop = class_getProperty( [self class], [propertyName UTF8String] );
	if( prop )
	{
		const char *propAttr = property_getAttributes( prop );
		if( propAttr )
		{
			NSString *attributeStr = [NSString stringWithUTF8String: propAttr];
			NSArray *attributes = [attributeStr componentsSeparatedByString: @","];
			for( NSString *attribute in attributes )
			{
				if( [attribute hasPrefix: @"T"] && [attribute length] > 1 )
				{
					NSString *typeName = [attribute substringFromIndex: 1];
					if( [typeName hasPrefix: @"@\""] )
					{
						typeName = [typeName substringWithRange: NSMakeRange(2, [typeName length] - 3)];
					}
					classString = typeName;
					break;
				}
			}
		}
	}
	return classString;
}


-(BOOL) classCanTakeBooleanValue: (NSString *) className
{
	return [className isEqualToString: @"NSNumber"] || [className isEqualToString: @"i"] || [className isEqualToString: @"c"];
}

-(BOOL) validatePropertyName: (NSString *) propertyName
{
	if( self.enableStrictMapping )
	{
		objc_property_t prop = class_getProperty( [self class], [propertyName UTF8String] );
#ifdef DEBUG
		if( !prop )
		{
			NSAssert( NO, @"Property name %@ is not valid for this object %@", propertyName, self );
		}
#endif
		return prop != NULL;
	}
	else
	{
		return YES;
	}
}


@end