//
//  FBFilterProvider.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 17.02.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBFilterProvider.h"

@implementation FBFilterProvider

#pragma mark Initialization and Deallocation

- (id)init
{
    self = [super init];
    if (self) {
		NSArray *filters = [FBFilterProvider constructFilters];
		
		// Create filter attribute dictionaries (filter + name)
		NSMutableArray *attributeDictionaries = [NSMutableArray arrayWithCapacity: filters.count];
		
		for (CIFilter *filter in filters) {
			NSString *className = [[filter class] description];
			NSString *name = [CIFilter localizedNameForFilterName: className];
			
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
										filter, @"filter",
										name, @"name",
										nil];
			
			[attributeDictionaries addObject: attributes];
		}
		
		filterDescriptions = [[NSArray alloc] initWithArray: attributeDictionaries];
    }
    
    return self;
}

- (void)dealloc
{
	[filterDescriptions release];
	filterDescriptions = nil;
	
	delegate = nil;
	
    [super dealloc];
}

#pragma mark -
#pragma mark Delegate

@synthesize delegate;

#pragma mark -
#pragma mark Accessing Filter Attributes

@synthesize filterDescriptions;

#pragma mark -
#pragma mark Filter Construction

+ (NSArray *) constructFilters
{
	// NOTE: Die Methode CIFilter+filterNamesInCategories: ermoeglicht die Einschraenkung der Suche auf Filter, die allen angegebenen Kategorien angehoeren
// 	NSArray *categories = [NSArray arrayWithObjects: @"CICategoryStylize", @"CICategoryVideo", nil];
	NSMutableArray *names = [NSMutableArray array];
	
	[names addObjectsFromArray:	[CIFilter filterNamesInCategory: @"CICategoryStylize"]];
	[names addObjectsFromArray: [CIFilter filterNamesInCategory: @"CICategoryDistortionEffect"]];
	[names addObjectsFromArray: [CIFilter filterNamesInCategory: @"CICategoryBlur"]];
	[names addObjectsFromArray: [CIFilter filterNamesInCategory: @"CICategorySharpen"]];
	
	NSMutableArray *filters = [NSMutableArray arrayWithCapacity: names.count];
	
	for (NSString *name in names) {
		CIFilter *filter = [CIFilter filterWithName: name];
		
		[filter setDefaults];
		[filters addObject: filter];
	}
	
	return filters;
}

#pragma mark -
#pragma mark Accessing the Currently Selected Filter

- (CIFilter *) artisticFilter
{
	return artisticFilter;
}

- (void) setArtisticFilter: (CIFilter *) aFilter
{
	[self willChangeValueForKey: @"artisticFilter"];
	[artisticFilter autorelease];
	artisticFilter = [aFilter retain];
	[filterAttributesView reloadData];
	[self didChangeValueForKey: @"artisticFilter"];
}

- (NSDictionary *) artisticFilterAttributes
{
	NSArray *acceptableAttributeClasses = [NSArray arrayWithObjects: @"NSNumber", @"CIVector", nil];
	NSMutableDictionary *a = [NSMutableDictionary dictionary];
	
	for (NSString *x in self.artisticFilter.attributes)
		if ([x hasPrefix: @"input"] 
			&& [acceptableAttributeClasses containsObject: [[self.artisticFilter.attributes objectForKey: x] objectForKey: @"CIAttributeClass"]])
			[a setObject: [self.artisticFilter.attributes objectForKey: x] forKey: x];
	
	return a;
}

#pragma mark -
#pragma mark Table View Data Source

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [[self artisticFilterAttributes] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSDictionary *attributes = [self artisticFilterAttributes];
	NSString *key = [[attributes allKeys] objectAtIndex: rowIndex];
	
	if ([aTableColumn.identifier isEqualToString: @"ColumnFilterAttributeValue"])
		return [self.artisticFilter valueForKey: key];
	else if ([aTableColumn.identifier isEqualToString: @"ColumnFilterAttributeName"])
		return [[attributes objectForKey: key] objectForKey: @"CIAttributeDisplayName"];
	else
		return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([aTableColumn.identifier isEqualToString: @"ColumnFilterAttributeValue"]) {
		NSDictionary *attributes = [self artisticFilterAttributes];
		
		NSString *key = [[attributes allKeys] objectAtIndex: rowIndex];
		
		[self.artisticFilter setValue: anObject forKey: key];
		
		[delegate filterProviderDidEditFilter: self];
	}
}

#pragma mark -
#pragma mark Table View Delegate

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if ([tableColumn.identifier isEqualToString: @"ColumnFilterAttributeValue"]) {
		NSDictionary *attributes = [self artisticFilterAttributes];
		NSDictionary *info = [attributes objectForKey: [[attributes allKeys] objectAtIndex: row]];
		
		if ([[info CIAttributeClass] isEqualToString: @"NSNumber"]) {
			NSSliderCell *cell = [[NSSliderCell alloc] init];
			
			[cell setMinValue: [[info objectForKey: @"CIAttributeSliderMin"] doubleValue]];
			[cell setMaxValue: [[info objectForKey: @"CIAttributeSliderMax"] doubleValue]];
			
			return [cell autorelease];
		} else
			return nil;
	} else
		return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
	return 24;
}

@end
