#import "Blurminal.h"
#import "CGSPrivate.h"
#import "JRSwizzle.h"

extern OSStatus CGSNewConnection(const void **attr, CGSConnectionID *id);

@implementation NSWindow (TTWindow)
// Found here:
// http://www.aeroxp.org/board/index.php?s=d18e98cabed9ce5ad27f9449b4e2298f&showtopic=8984&pid=116022&st=0&#entry116022
- (void)enableBlurFilter
{
  CGSConnectionID cid;
  CGSNewConnection(NULL, &cid);

  CGSWindowFilterRef filter;
  CGSNewCIFilterByName(cid, (CFStringRef)@"CIGaussianBlur", &filter);

  NSNumber *blurRadius = [[NSUserDefaults standardUserDefaults]
                          objectForKey:@"Blurminal Radius"];
  NSDictionary* options = [NSDictionary dictionaryWithObject:blurRadius
                                                      forKey:@"inputRadius"];
  CGSSetCIFilterValuesFromDictionary(cid, filter, (CFDictionaryRef)options);

  CGSAddWindowFilter(cid, [self windowNumber], filter, 0x3001);
}

- (void)enableBlur
{
  if([self isKindOfClass:NSClassFromString(@"TTWindow")] ||
     [self isKindOfClass:NSClassFromString(@"VisorWindow")]) {
    [self performSelector:@selector(enableBlurFilter)
               withObject:nil
               afterDelay:0];
  }
}

- (id)Blurred_initWithContentRect:(NSRect)contentRect
                        styleMask:(NSUInteger)windowStyle
                          backing:(NSBackingStoreType)bufferingType
                            defer:(BOOL)deferCreation
{
  if ((self = [self Blurred_initWithContentRect:contentRect
                                      styleMask:windowStyle
                                        backing:bufferingType
                                          defer:deferCreation])) {
    // The window has to be onscreen to get a windowNumber,
    // so we run the enableBlur after the event loop.
    [self enableBlur];
  }
  return self;
}

@end

@implementation Blurminal
+ (void)load
{
  [[NSUserDefaults standardUserDefaults] registerDefaults:
   [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0]
                               forKey:@"Blurminal Radius"]];
  SEL old = @selector(initWithContentRect:styleMask:backing:defer:);
  SEL new = @selector(Blurred_initWithContentRect:styleMask:backing:defer:);
  [[NSWindow class] jr_swizzleMethod:old withMethod:new error:NULL];
  for (id window in [NSApp orderedWindows]) {
    [window enableBlur];
  }
}
@end
