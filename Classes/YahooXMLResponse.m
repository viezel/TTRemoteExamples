//
//  YahooXMLResponse.m
//

#import "YahooXMLResponse.h"
#import "SearchResult.h"

@implementation YahooXMLResponse

@synthesize results, currentResult, currentProperty;

/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark TTURLResponse

- (NSError*)request:(TTURLRequest*)request processResponse:(NSHTTPURLResponse*)response data:(id)data
{
    // Configure the parser to parse the XML data that we received from the server.
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser setShouldProcessNamespaces:NO];
    [parser setShouldReportNamespacePrefixes:NO];
    [parser setShouldResolveExternalEntities:NO];
    
    // The XML data itself was downloaded from the internet on a background thread,
    // but the XML will be *parsed* on the main thread... If your XML document is very large,
    // you will want to rewrite this class to parse on a background thread instead.
    [parser parse];
    
    NSError *parseError = [parser parserError];
    if (parseError) {
        NSLog(@"YahooXMLResponse - parse error %@", parseError);
    }
    
    [parser release];
    return parseError;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSXMLParserDelegate

- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    self.results = [NSMutableArray array];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
    // Now wrap the results from the server into a domain-specific object.
    for (NSDictionary *rawResult in results)
        [self.objects addObject:[SearchResult searchResultFromDictionary:rawResult]]; 
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if (qName)
        elementName = qName;
    
    if ([elementName isEqualToString:@"Result"]) {
        self.currentResult = [NSMutableDictionary dictionary];
        return;
    }
    
    // These are the attributes that we are interested in
    NSSet *searchProperties = [NSSet setWithObjects:@"Title", @"Url", nil];
    if ([searchProperties containsObject:elementName]) {
        self.currentProperty = [NSMutableString string];            
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if (qName)
        elementName = qName;
    
    if ([elementName isEqualToString:@"Result"]) {
        [self.results addObject:self.currentResult];
        return;
    }
    
    // If we are not building up a property, then we are not interested in this end element.
    if (!self.currentProperty)
        return;
    
    [self.currentResult setObject:self.currentProperty forKey:elementName];
    
    self.currentProperty = nil;
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // If currentProperty is not nil, then we are interested in the 
    // content of the current element being parsed. So append it to the buffer.
    if (self.currentProperty)
        [self.currentProperty appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"YahooXMLResponse: a parse error occurred: %@", parseError);
}

//////////////////////////////////////////////////////////////////////////
#pragma mark -

- (void)dealloc
{
    [results release];
    [currentResult release];
    [currentProperty release];
    [super dealloc];
}

@end
