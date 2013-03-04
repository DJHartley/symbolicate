#import "demangle.h"

#include <cxxabi.h>

/*
   Demangle names generated by Logos preprocessor.
   Original code provided by Dustin Howett (creator of Logos).

   Supports the following formats:
       _logos_
       static_metaclass_lookup$CLASS
       static_class_lookup$CLASS
       meta_
       orig$GROUP$CLASS$SELECTOR$PARTS$
       method$GROUP$CLASS$SELECTOR$PARTS$
       super$GROUP$CLASS$SELECTOR$PARTS$
       orig$GROUP$CLASS$SELECTOR$PARTS$
       method$GROUP$CLASS$SELECTOR$PARTS$
       super$GROUP$CLASS$SELECTOR$PARTS$
*/
static NSString *logos_demangle(NSString *mangled) {
    NSString *symname = nil;
    if ([mangled hasPrefix:@"__Z"]) {
        const char *temp = [mangled UTF8String];
        char *charp = NULL;
        int symlen = 0;
        symlen = (int)strtoul(temp+4, &charp, 10);
        symname = [[[NSString alloc] initWithBytes:charp length:symlen encoding:NSUTF8StringEncoding] autorelease];
    } else if ([mangled hasPrefix:@"__l"]) {
        symname = [mangled substringFromIndex:1];
    } else {
        symname = [[mangled copy] autorelease];
    }
    if (![symname hasPrefix:@"_logos"]) return mangled;

    NSString *stripped = nil;
    NSInteger paren = [symname rangeOfString:@"("].location;
    if (paren != NSNotFound) {
        stripped = [symname substringFromIndex:paren];
        symname = [symname substringToIndex:paren];
    }

    NSArray *comp = [symname componentsSeparatedByString:@"$"];

    // Lookup Functions -- always have two or more components
    if (comp.count < 2) return mangled;
    NSString *sigil = [[comp objectAtIndex:0] substringFromIndex:7];
    BOOL metabit = NO;
    if ([sigil hasSuffix:@"lookup"]) {
        metabit = [sigil hasPrefix:@"static_meta"];
        return [NSString stringWithFormat:@"Logos class lookup for %c%@%@", metabit ? '+' : '-', [comp objectAtIndex:1], stripped ?: @""];
    }

    // Hook Functions -- always have three or more components
    if (comp.count < 3) return mangled;
    if ([sigil hasPrefix:@"meta"]) {
        metabit = true;
        sigil = [sigil substringFromIndex:5];
    }

    NSString *type = nil;
    if ([sigil isEqualToString:@"method"]) {
        type = @"hook";
    } else if ([sigil isEqualToString:@"super"]) {
        type = @"supercall thunk";
    }
    if (type == nil) return mangled;

    NSString *group = [comp objectAtIndex:1];
    NSString *klass = [comp objectAtIndex:2];
    NSString *selector = [[comp subarrayWithRange:(NSRange){3, comp.count - 3}] componentsJoinedByString:@":"];
    return [NSString stringWithFormat:@"Logos %@ for %c[%@(%@) %@]%@", type, metabit ? '+' : '-', klass, group, selector, stripped ?: @""];
}

NSString *demangle(NSString *mangled) {
    NSString *demangled = mangled;

    const char *before = [mangled cStringUsingEncoding:NSASCIIStringEncoding];
    if (strlen(before) > 0) {
        // NOTE: When attempting to demangle name, skip initial underscore.
        int status;
        char *after = abi::__cxa_demangle(before + 1, NULL, NULL, &status);
        if (after != NULL) {
            demangled = [NSString stringWithCString:after encoding:NSASCIIStringEncoding];
        }
        free(after);
    }

    return logos_demangle(demangled);
}

/* vim: set ft=objcpp ff=unix sw=4 ts=4 tw=80 expandtab: */
