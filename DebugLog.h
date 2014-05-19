//
//  DebugLog.h
//  NSLog-ing my way.
//
//  Sticktron 2014
//

#ifdef DEBUG_MODE_ON

	/* default log prefix */
	#ifndef DEBUG_PREFIX
		#define DEBUG_PREFIX @"[[ DebugLog ]]"
	#endif

	/* prints class::selector >> message */
	#define DebugLog(s, ...) \
		NSLog(@"%@ %@::%@ >> %@", DEBUG_PREFIX, \
		NSStringFromClass([self class]), \
		NSStringFromSelector(_cmd), \
		[NSString stringWithFormat:(s), ##__VA_ARGS__] \
	)

	/* prints message */
	#define DebugLog1(s, ...) \
		NSLog(@"%@ >> %@", DEBUG_PREFIX, \
		[NSString stringWithFormat:(s), ##__VA_ARGS__] \
	)

	/* prints class::selector */
	#define DebugLog0 \
		NSLog(@"%@ %@::%@", DEBUG_PREFIX, \
		NSStringFromClass([self class]), \
		NSStringFromSelector(_cmd) \
	)

	/* prints filename:(line number) >> method signature >> message */
//	#define DebugLogMore(s, ...) \
//		NSLog(@"%@ %s:(%d) >> %s >> %@", \
//		DEBUG_PREFIX, \
//		[[NSString stringWithUTF8String:__FILE__] lastPathComponent], \
//		__LINE__, \
//		__PRETTY_FUNCTION__, \
//		[NSString stringWithFormat:(s), \
//		##__VA_ARGS__] \
//	)

#else
	/* ignore macros */
	#define DebugLog0
	#define DebugLog1(s, ...)
	#define DebugLog(s, ...)
	#define DebugLogMore(s, ...)
#endif
//----------------------------------------------------------------------------------------------->>>
