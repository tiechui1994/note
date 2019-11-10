# Redis底层的数据结构

## List

list-max-ziplist-size: 每个quicklist的节点都是一个ziplist, 这个参数指定的是内部节点的最大大小

list-compress-depth: 列表的压缩策略. 这个参数指定的是quicklist两端不被压缩的节点的个数.

- QuickList

32个字节

```c
typedef struct quicklist {
    quicklistNode *head;
    quicklistNode *tail;
    unsigned long count;   // 数据项总和
    unsigned int len;      // 节点总数
    int fill : 16;         // ziplist大小限定(list-max-ziplist-size指定, 默认是16)
    unsigned int compress : 16; // 节点压缩深度(list-compress-depth指定, 默认是16)
} quicklist

typedef struct quicklistNode {
    struct quicklistNode *prev;
    struct quicklistNode *next;
    
}
```

- 
