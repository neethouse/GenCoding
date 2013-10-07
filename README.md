GenCoding
=========

Generating NSCoding code.

## help

```sh
gencode <root-dir>

# example
gencode .

# 以下は未実装

# 強制的に上書き.
gencode -f .

# dry run
# 変換対象のファイルが羅列されるだけで実際に処理は行わない.
gencode --dry-run .
```

## なにが自動生成されるか

initWithCoder と encodeWithCoder が gencoding コマンドによって生成される.


```objc

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {

        // 任意の処理

        /*!!!!! [NGCCODING_BEGIN] This is auto generated code by NGCCoding. !!!!!*/
        /*!!!!! [NGCCODING_BEGIN] Do not change this area.                  !!!!!*/
        NGCDecodeObject(name);
        NGCDecodeInteger(age);
        /*!!!!! [NGCCODING_END] End of auto generation.                     !!!!!! */

        // 任意の処理
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {

    // 任意の処理

    /*!!!!! [NGCCODING_BEGIN] This is auto generated code by NGCCoding. !!!!!*/
    /*!!!!! [NGCCODING_BEGIN] Do not change this area.                  !!!!!*/
    NGCEncodeObject(name);
    NGCEncodeInteger(age);
    /*!!!!! [NGCCODING_END] End of auto generation.                     !!!!!! */

    // 任意の処理
}
```

### 細かい仕様

生成されたコードは [NGCCODING] を含むコメントによって挟まれる.

上記コメント外に任意の処理を記述可能

gencodingコマンドを再実行すると、コメントの内側のコードのみを再生成するため既存のコードが変更されることはない.

gencodingコマンド実行時に[NSCODING]コメントを含まない initWithCoder や encodeWithCoder が既に存在していた場合はコードの自動生成は行わない(行わなかった旨の警告メッセージは出す).

ただし-fオプションが指定されていた場合は強制的に上書きする.この場合、既存のコードは保持されない.

### 自動生成の対象から外す

特定のpropertyをNSCodingの対象から外したい場合は NGC_IGNORE_PROPERTY をpropertyにつけることによって自動生成されなくなる.

```objc
@property (readonly, nonatomic) NSString *ignoreString NGC_IGNORE_PROPERTY;
```


### 明示的に型情報を指定する

enumなどは本来の型情報がソースコードから判別できないので明示的に型を指定する必要がある.

NGC_EXPLICATE_TYPE を使用する.

```objc
@property (nonatomic) HogeEnumType type NGC_EXPLICATE_TYPE(int);
```

enumのpropertyには NGC_EXPLICATE_TYPE が付いていないと警告を出す(一応intとして変換を行う)

