# SRBAutomappingModelObject
## Automatically update Objective-C Data Model Objects from NSDictionary objects

When working with web services, it's common to get NSDictionary objects from JSON or XML parse steps.  From here, creating a model object can take a fair bit of elbow grease.  SRBAutomappingModelObject is designed to take a lot of this work out of the process.

## Example Usage

###  Updating a model object when the NSDictionary keys match 1:1

The simplest use case, take our model object:

``` objective-c
@interface foo : SRBAutomappingModelObject
@property (nonatomic, strong) NSString 	*prop1;
@property (nonatomic, assign) BOOL		 	prop2
@end

```
With our dictionary:

``` objective-c
NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: @"Value 1", @"prop1", [NSNumber numberWithBool: YES], @"prop2", nil];
```

In our -init class, we setup the mapping:

``` objective-c
-(id) init
{
	self = [super init];
	if( self )
	{
		[self addAllPropertiesForMapping];
	}
}
```

And create a convenience method for creating our model object from a NSDictionary:

``` objective-c
-(foo *) fooWithDictionary: (NSDictionary *) dict
{
	foo *foo = [[self alloc] init];
	[foo updateFromDictionary: dict];
	return foo;
}
```

That's it! we've updated our model object from the dictionary with ease.

But what about a more complex case, where the source NSDictionary is a bit more complicated and the keys don't match?

Let's try this out with a more complex NSDictionary:

``` objective-c
NSDictionary *nestedDict1 = [NSDictionary dictionaryWithObject: @"value 1" forKey: @"nestedfookey"];
NSDictionary *nestedDict2 = [NSDictionary dictionaryWithObhect: [NSNumber numberWithBool: NO] forKey: @"nestedbarkey"];
NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys: nestedDict1, @"rootfookey", nestedDict2, @"rootbarkey", nil];
```

Here's our mapping now:

``` objective-c
-(id) init
{
	self = [super init];
	if( self )
	{
		[self addMappingWithDestinationKey: @"prop1" sourceKeyPath: @"rootfookey.nestedfookey"];
		[self addMappingWithDestinationKey: @"prop2" sourceKeyPath: @"rootbarkey.nestedbarkey"];
	}
}
```

Good to go.

Now, what about super complex types?  Like, nested NSArray's that themselves have model objects?  Or NSStrings that need to be converted to NSDates?  For that, we have formatter blocks which are invoked for each mapping to do our custom conversion.

Let's add an NSDate to our foo class and convert a string using NSDateFormatter:

``` objective-c
@interface foo : AutomappingDataObject
@property (nonatomic, strong) NSDate 	  *dateprop;
@end

Our dictionary:
``` objective-c
NSDictionary *dict = [NSDictionary dictionaryWithObject: @"12-12-2015T12:20:10" forKey: @"stringDate"];
@end

Our mapping would now look like:


``` objective-c
-(id) init
{
	self = [super init];
	if( self )
	{
		[self addMappingWithDestinationKey: @"dateprop" 
													sourceKeyPath: @"stringDate" formattingBlock: ^ id (id data) {
															return [someDateFormatter: dateFromString: data];
		}];
	}
}
```

And off you go.

## Dependencies

* [iOS 4.0+]
* ARC
* No other external dependencies.

### ARC Support Comments

The code library ASSUMES ARC SUPPORT.
If you want to use this with pre-ARC code, please run through and add the needed -retain calls to the mapping dictionary ivar.

## Contact

Steve Breen - breeno@me.com

## License

SRBAutomappingModelObject is available under the BSD license.
