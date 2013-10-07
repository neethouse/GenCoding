//
//  SampleNSCodingClass.h
//  GenCoding
//
//  Created by mironal on 2013/10/05.
//  Copyright (c) 2013年 Neet House. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NGCCoding.h"

@interface SampleNSCodingClass : NSObject<NGCCoding>

typedef NS_ENUM(int, SampleIntEnum) {
    kOne,
    kTwo
};

@property (readonly, nonatomic) NSString *stringVal;

@property (readonly, nonatomic) int intVal;

@property (readonly, nonatomic) double doubleVal;

@property (readonly, nonatomic) float floatVal;

@property (readonly, nonatomic) BOOL boolVal;

@property (readonly, nonatomic) NSInteger nsIntegerVal;

@property (readonly, nonatomic) int32_t int32Val;


@property (readonly, nonatomic) int64_t int64Val;

@property (readonly, nonatomic) NSString *ignoreString NGC_IGNORE_PROPERTY;

@property (readonly, nonatomic) SampleIntEnum type NGC_EXPLICATE_TYPE(int);

@end

@interface SecondClass : NSObject<NGCCoding>

@property (readonly, nonatomic) NSString *string;

@end

@interface NoImpleClass : NSObject<NGCCoding>

@end

@interface NotExtendsNGCCoding : NSObject

@end