## Protobuf

### protobuf 基本类型:

| Proto类型            | Go类型           |
| ------------------ | -------------- |
| double             | float64        |
| float              | float32        |
|                    |                |
| int32, int64       | int32, int64   |
|                    |                |
| uint32, uint64     | uint32, uint64 |
|                    |                |
| sint32, sint64     | int32, sint64  |
|                    |                |
| sfixed32, sfixed64 | int32, int64   |
|                    |                |
| fixed32, fixed64   | uint32, uint64 |
|                    |                |
| bool               | bool           |
| string             | string         |
| bytes              | []byte         |

> 说明:
1. uint32, uint64 使用变长编码
2. int32, int64 使用变长编码, 负值的效率很低(使用sint32, sint64替换)
3. sint32, sint64 使用变长编码, 有符号的整型值. 编码比int高效
4. sfixed32, sfixed64 总是4/8个字节
5. fixed32, fixed64 总是4/8个字节, 如果数值大于(228|256), 这个类型比uint高效

6. string 字符串必须是UTF-8编码或者7-bit ASCII编码的文本
7. bytes 包含任意顺序的字节数据.


### 枚举

- 必须有一个0值, 可以使用这个0值作为默认值
- 零值必须为第一个元素, 为了兼容proto2语义, 枚举值的第一个值总是默认值
- 可以通过将不同的枚举常量指定为相同的值(需要将allow_alias设置为true).
```
enum EnumAllowAlias {
    option allow_alias = true;
    UNKNOWN = 0;
    STARTED = 1;
    RUNNING = 1;
}
```

> 枚举常量必须在32位整型值的范围内. 因为enum值使用可变编码方式(int32)的, 对负数不够高效, 
因此不推荐使用enum使用负数

> 可以在一个消息定义的内部或外部定义枚举 -- 这些枚举可以在.proto文件中的任何消息定义里重用.

```
message Arg {
    int32 argI32 = 1;
    enum Level {
        A = 0;
        B = 1;
        C = 2;
        D = 3;
    }
    Level level = 2;
}

message Enum {
    int64 argI64 = 1;
    Arg.Level other = 3;
}
```

### 更新消息类型

如果一个已有的消息个格式无法满足新的需求 -- 如, 要在消息中添加一个额外的字段, 但是同时旧版本写的
代码仍然可用. 规则如下:

- 不要更改任何已有的字段的数值标识.

- 如果增加新的字段, 使用旧格式的字段任然可以新产生的代码所解析. 需要记住这些元素的默认值, 新的代码
口可以以适当的方式和旧的代码产生数据交互. 相似的, 通过新代码产生的消息可以被旧代码解析:只不过新的字
段会被忽略掉. 

> 注意: 未被识别的字段会在反序列化的过程中丢掉,所以如果消息再被传递给新的代码,新的字段仍然是不可用
的, 这与proto2的行为是不同的.

- 非required的字段可以移除 -- 只要它们的标识号在新的消息类型中不再使用(更好的做法是重命名那个字段,
例如在字段前添加"obsolete_"前缀, 那样的话, 使用的.proto文件的用户将来就不会无意中重新使用那些不该
使用的标识号)

- int32,uint32,int64,uint64和bool是全部兼容的.

- sint32和sint64是互相兼容的, 但是它们与其他整数类型不兼容.

- fixed32与sfixed32是兼容的, fixed64与sfixed64是兼容的

- string和bytes是兼容的 -- 只要bytes是有效的UTF-8编码

- 嵌套消息与bytes是兼容的 -- 只要bytes包含该消息的一个编码过的版本.


### Any

Any消息类型允许在没有指定它们的.proto的情况下使用消息作为一个嵌套类型. 一个Any类型包括
一个可以被序列化bytes类型的任意消息, 以及一个URL作为全局标识符和解析消息类型.

为了使用Any类型,需要导入`import google/protobuf/any.proto`

```
import "google/protobuf/any.proto";

message ErrorStatus {
    string message = 1;
    repeated google.protobuf.Any details = 2;
}
```

对于给定的消息类型的默认类型URL是type.googleapis.com/package.messagename


### oneof

消息中有很多可选字段, 并且同时至多一个字段会被设置. 可以使用oneof特性节省内存.

oneof字段就像可选字段, 除了它们会共享内存, 至多一个字段会被设置. 设置其中一个字段会
清除其他手段.

```proto
message SampleMessage {
    oneof One {
        string name = 4;
        bytes sub_message = 9;
    }
}
```

> 注意: 在oneof当中增加的任意字段不能使用repeated关键字修饰.

- 设置oneof会自动清除其它oneof字段的值, 所以设置多次后, 只有最后一次设置的字段有值.

- 如果解析器遇到同一个oneof中有多个成员, 只有最后一个会被解析成消息.

- oneof不支持repeated

- 反射API对oneof字段有效.

- 向后兼容性问题: 当增加或者删除oneof字段时一定要小心. 如果检查oneof的值返回None/
NOT_SET, 它意味着oneof字段没有赋值或者在一个不同的版本中被赋值了. 

### map

关联映射:
```
map<key_type, value_type> map_field = N;
```

> 其中key_type可以是任意Integer或者string类型(所以, 除了floating和bytes的任意标量类型都是可
以的), value_type可以是任意类型.

- map的字段可以是repeated

- 序列化后的顺序和map迭代器的顺序是不确定的.
 
- 当为.proto文件产生文本格式的时候, map会按照key的顺序排序, 数值化的key会按照数值排序.

- 从序列化中解析时, 如果有重复的key则后一个key不会被使用, 当从文本格式中解析map时, 如果存在
重复的key, 生成map的API现在对所有proto3支持的语言都可用了.

### reversed

reserved可以用来指明此message不使用某些字段, 也就是忽略这些字段.

```proto
syntax = "proto3";
message AllNormalypes {
    // 忽略编号2和4,5,6
    reserved 2, 4 to 6;
    // 忽略字段 field14, field11
    reserved "field14", "field11";
    
    double field1 = 1;
    // float field2 = 2;
    int32 field3 = 3;
    // int64 field4 = 4;
    // uint32 field5 = 5;
    // uint64 field6 = 6;
    sint32 field7 = 7;
    sint64 field8 = 8;
    fixed32 field9 = 9;
    fixed64 field10 = 10;
    // sfixed32 field11 = 11;
    sfixed64 field12 = 12;
    bool field13 = 13;
    // string field14 = 14;
    bytes field15 = 15;
}
```

---


## ProtoBuf协议解析

protobuf协议:

[!image](images/protobuf.png)

PB以 "1~5个字节"的编号和类型开头, 格式: 编号<<3 | 类型

编号: proto文件中各个字段的编号

类型: proto文件中各个字段的类型, 使用3位表示类型, 可用表示0到7, 共8种类型.
PB类型只使用了0,1,2,3,4,5这6种类型.

| 类型 | 描述 | proto类型 |
| --- | --- | --- |
| 0 | varint | int32,int64,uint32,uint64,sint32,sint64,bool,enum |
| 1 | 64-bit | fixed64,sfixed64,double |
| 2 | length-delimited | string, bytes, embedded messages, repeated fields |
| 3 | start group | groups(deprecated) |
| 4 | end group | groups(deprecated) |
| 5 | 32-bit | fixed32, sfixed32, float | 


协议分析:
```proto
syntax="proto3";

enum AuctionType {
    FIRST_PRICE = 0;
    SECOND_PRICE = 1;
    FIXED_PRICE = 2;
}

message VarintMsg {
    int32 argI32 = 1;
    int64 argI64 = 2;
    uint32 argUI32 = 3;
    uint64 argUI64 = 4;
    sint32 argSI32 = 5;
    sint64 argSI64 = 6;
    repeated bool argBool = 7;
    AuctionType argEnum = 8;
}
```

```
var varintMsg = &pb.VarintMsg{
    ArgI32:  0x41,
    ArgI64:  0x12345678,
    ArgUI32: 0x332211,
    ArgUI64: 0x998877,
    ArgSI32: -100,
    ArgSI64: -200,
    ArgBool: []bool{true, false},
    ArgEnum: pb.AuctionType_SECOND_PRICE,
}
data, _ := proto.Marshal(varintMsg)
fd, _ := os.Create("varint.bin")
fd.Write(data)
```

data:
```
00000000  08 41 10 f8 ac d1 91 01  18 91 c4 cc 01 20 f7 90  |.A........... ..|
00000010  e6 04 28 c7 01 30 8f 03  3a 02 01 00 40 01        |..(..0..:...@.|
0000001e
```

1.第一个字段分析:

int32 argI32 = 1; // **int32, int64 采用补码表示值, 16进制(正数的补码是其本身, 负数的补码
是其原码的基础上, 符号位不变, 其余各位取反, 最后+1)**

0841

字节08, 表示编号和类型: 1<<3 | 0 = 8 = 0x08
字节41, 表示值是0x41

2.第二个字段分析:

int64 argI64 = 2;

10 f8 ac d1 91

字节10, 表示编号和类型: 2<<3 | 0 = 16 = 0x10
字节f8 ac d1 91 01 表示值:        
11111000 10101100 11010001 10010001 00000001

小端转本地:  
00000001 10010001 11010001 10101100 11111000

还原varint编码:
00000001  0010001  1010001  0101100  1111000

重新组合:
00000000 00010010 00110100 01010110 01111000 = 0x12345678

3.第三个字段分析

uint32 argUI32 = 3; // **uint32, uint64 采用16进制表示, 没有负数**

18 91 c4 cc 01

字节18, 表示型号和类型: 3<<3 | 0 = 24 = 0x18

字节 91 c4 cc 01 表示的值:
10010001 11000100 11001100 00000001

小端口转本地:
00000001 11001100 11000100 10010001

还原varint编码:
00000001  1001100  1000100  0010001

重新组合:
00000000 00110011 00100010 00010001 = 0x332211


...

5.第5个字段

sint32 argSI32 = 5; // **sint32 和 sint64 使用了Zigzag算法(无论正数或者负数)**

28 c7 01

字节: 5<<3 | 0 = 40 =0x28

字节 c7 01 表示:
1100111 00000001

小端转本地:
00000001 1100111

还原varint编码
00000000 1100111 = 0xc7 = 199

7.第7个字段

repeated bool argBool = 7; // **repeated值表示: 元素类型|元素个数, 元素的值**

3a 02 01 00

字节3a表示: 7<<3 | 2 = 58 = 0x3a

字节02 01 00

字节02元素的类型和元素的个数: 0|2 = 2 = 0x02
字节01: 表示true
字节00: 表示false


---


bit64:

```proto
syntax="proto3";

message Bit64 {
    fixed64 argFixed64 = 1;
    sfixed64 argSFixed64 = 2;
    double argDouble = 3;
}
```

```
var bit64 = &pb.Bit64{
    ArgFixed64:  0x123456,
    ArgSFixed64: -100,
    ArgDouble:   3.1415926,
}
```

data:
```
00000000  09 56 34 12 00 00 00 00  00 11 9c ff ff ff ff ff  |.V4.............|
00000010  ff ff 19 4a d8 12 4d fb  21 09 40                 |...J..M.!.@|
0000001b
```

1.第一个字段

fixed64 argFixed64 = 1; //**fixedX, sfixedX, double, float 固定字节数, 采用补码表示**

字节09: 1<<3 | 1 = 9 = 0x09

字节 56 34 12 00 00 00 00 00对应的值:
01010110 00110100 00010010 00000000 00000000 00000000 00000000 00000000
 
小端转本地: 
00010010 00110100 01010110 = 0x123456


2. 第二个字段:

sfixed64 argSFixed64 = 2;

字节11: 2<<3 | 1 = 17 = 0x11

字节 9c ff ff ff ff ff ff ff 对应的值:
10011100 11111111 11111111 11111111 11111111 11111111 11111111 11111111

小端转本地:(补码)
11111111 11111111 11111111 11111111 11111111 11111111 11111111 10011100

