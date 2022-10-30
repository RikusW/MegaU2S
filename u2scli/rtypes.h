
#ifndef RTYPES_H
#define RTYPES_H

typedef signed char s8;
typedef unsigned char u8;

typedef signed short s16;
typedef unsigned short u16;

typedef signed long s32;
typedef unsigned long u32;

#ifdef _WIN32
typedef signed __int64 s64;
typedef unsigned __int64 u64;
#else
//#if defined(__GNUC__) && !defined(__STRICT_ANSI__)
typedef signed long long s64;
typedef unsigned long long u64;
//#endif
#endif

#endif //RTYPES_H

