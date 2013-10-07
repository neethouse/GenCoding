//
//  NGCCoding.h
//  GenCoding
//
//  Created by mironal on 2013/10/05.
//  Copyright (c) 2013年 Neet House. All rights reserved.
//

#import <Foundation/Foundation.h>

#define NGC_IGNORE_PROPERTY
#define NGC_EXPLICATE_TYPE(type)

/**
 
 initWithCoder と encodeWithCoder
 を自動生成したいクラスに使用するプロトコル.
 
 */
@protocol NGCCoding <NSCoding>

@end


// macros


/**
 NSCoding 実装時の便利マクロ集.
 
 型が足りなかったら適宜追加.
 
 使用例:
 
 @implementation SampleObject {
 NSString *_name;
 int _age;
 }
 
 /// 引数名 (aDecoder) は変更不可.
 - (id)initWithCoder:(NSCoder *)aDecoder {
 self = [super init];
 if(self) {
 decodeObject(name);
 // -> _name = [aDecoder decodeObjectForKey:@"name"]
 
 decodeInt(age);
 // -> _age = [aDecoder decodeIntForKey:@"age"]
 }
 return self;
 }
 
 /// 引数名 (aCoder) は変更不可.
 - (void)encodeWithCoder:(NSCoder *)aCoder {
 encodeObject(name);
 // -> [aCoder encodeObject:_name forKey:@"name"]
 
 encodeInt(age);
 // -> [aCoder encodeObject:_age forKey:@"age"]
 }
 
 @end
 
 @see: [NSCoding が捗るマクロ | Cocoaの日々情報局](http://cocoadays-info.blogspot.jp/2013/09/nscoding.html)
 */

// 内部的に使用するのでprivateをつけている.
#define NGC_private_STRINGIFY(x) #x
#define NGC_private_MEMBER(x) _##x

/*
 – encodeArrayOfObjCType:count:at:

 – encodeBycopyObject:
 – encodeByrefObject:
 – encodeBytes:length:
 – encodeBytes:length:forKey:
 – encodeConditionalObject:
 – encodeConditionalObject:forKey:
 – encodeDataObject:
 – encodeRootObject:
 – encodeValueOfObjCType:at:
 – encodeValuesOfObjCTypes:


 – decodeArrayOfObjCType:count:at:
 – decodeBytesForKey:returnedLength:
 – decodeBytesWithReturnedLength:
 – decodeDataObject
 – decodeValueOfObjCType:at:
 – decodeValuesOfObjCTypes:
 – decodeObjectOfClass:forKey:
 – decodeObjectOfClasses:forKey:
 – decodePropertyListForKey:

*/



// object
// – encodeObject:forKey:
// – decodeObjectForKey:
#define NGCEncodeObject(x) [aCoder encodeObject:NGC_private_MEMBER(x) forKey:@NGC_private_STRINGIFY(x)]
#define NGCDecodeObject(x) NGC_private_MEMBER(x) = [aDecoder decodeObjectForKey:@NGC_private_STRINGIFY(x)]

// int
// – encodeInt:forKey:
// – decodeIntForKey:
#define NGCEncodeInt(x) [aCoder encodeInt:NGC_private_MEMBER(x) forKey:@NGC_private_STRINGIFY(x)]
#define NGCDecodeInt(x) NGC_private_MEMBER(x) = [aDecoder decodeIntForKey:@NGC_private_STRINGIFY(x)]

// BOOL
// – encodeBool:forKey:
// – decodeBoolForKey:
#define NGCEncodeBool(x) [aCoder encodeBool:NGC_private_MEMBER(x) forKey:@NGC_private_STRINGIFY(x)]
#define NGCDecodeBool(x) NGC_private_MEMBER(x) = [aDecoder decodeBoolForKey:@NGC_private_STRINGIFY(x)]

// Double
// – encodeDouble:forKey:
// – decodeDoubleForKey:
#define NGCEncodeDouble(x) [aCoder encodeDouble:NGC_private_MEMBER(x) forKey:@NGC_private_STRINGIFY(x)]
#define NGCDecodeDouble(x) NGC_private_MEMBER(x) = [aDecoder decodeDoubleForKey:@NGC_private_STRINGIFY(x)]


// Float
// – encodeFloat:forKey:
// – decodeFloatForKey:
#define NGCEncodeFloat(x) [aCoder encodeFloat:NGC_private_MEMBER(x) forKey:@NGC_private_STRINGIFY(x)]
#define NGCDecodeFloat(x) NGC_private_MEMBER(x) = [aDecoder decodeFloatForKey:@NGC_private_STRINGIFY(x)]


// NSInteger
// – encodeInteger:forKey:
//  – decodeIntegerForKey:
#define NGCEncodeInteger(x) [aCoder encodeInteger:NGC_private_MEMBER(x) forKey:@NGC_private_STRINGIFY(x)]
#define NGCDecodeInteger(x) NGC_private_MEMBER(x) = [aDecoder decodeIntegerForKey:@NGC_private_STRINGIFY(x)]


// int32_t
//  – encodeInt32:forKey:
//  – decodeInt32ForKey:
#define NGCEncodeInt32(x) [aCoder encodeInt32:NGC_private_MEMBER(x) forKey:@NGC_private_STRINGIFY(x)]
#define NGCDecodeInt32(x) NGC_private_MEMBER(x) = [aDecoder decodeInt32ForKey:@NGC_private_STRINGIFY(x)]


// int64_t
// – encodeInt64:forKey:
// – decodeInt64ForKey:
#define NGCEncodeInt64(x) [aCoder encodeInt64:NGC_private_MEMBER(x) forKey:@NGC_private_STRINGIFY(x)]
#define NGCDecodeInt64(x) NGC_private_MEMBER(x) = [aDecoder decodeInt64ForKey:@NGC_private_STRINGIFY(x)]

