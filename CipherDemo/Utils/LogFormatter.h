//  Copyright (c) 2013 Evgeny Aleksandrov. All rights reserved.

@interface LogFormatter : NSObject <DDLogFormatter> {
    int atomicLoggerCount;
    NSDateFormatter *threadUnsafeDateFormatter;
}
@end
