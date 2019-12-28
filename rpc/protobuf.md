## Protobuf 协议解析

protobuf 基本类型:

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





