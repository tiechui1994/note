# MySQL 专题 - 大表分页

优化思路是转换 offset, 让 offset 尽可能的小, 最好能每次查询都是第一页, 也就是 offset 为 0.

1. 如果查询根据 id 排序的, 并且 id 是连续的.

根据查询的页数直接计算 id 的范围. 例如, offset=40 limit=10, 表示要查询第5页数据. 那么第5页开始的id是41, 查询条件
为: id>40 limit 0

> 这种是理想情况, 很难遇到这种情况的.

2. 如果查询根据 id 排序的, 并且 id 是不连续的.

通常翻页页数跳转都不会很大, 那么可以根据上一次查询的记录, 计算出下一次分页查询对应的"新的offset"(离上一次查询记录的offset) 
和 limit. 假设 limit=10.

需要额外的参数:

lastEndID: 上一次查询的最后一条记录ID

lastEndOffset: 上一次查询的最后一条记录对应的　offset. 

1) 第一种情况: 跳转到下一页, 查询条件为: id > lastEndOffset LIMIT 10

2) 第二种情况: 往后翻页, 跳转到任意页, 计算出新的 newOffset = offset - lastOffset. 这里的offset值当前查询的偏移.
查询条件为: id > lastEndID OFFSET newoffset LIMIT 10. 如果 newOffset 依旧很大, 例如, 直接从第一页跳转到
最后一页, 这时候可以考虑id逆序查询. 先要查询表中最后一条数据, 然后更新 lastEndID. 此时 newOffset = totalCount - offset - limit, 
查询条件为: id < lastEndID OFFSET newoffset LIMIT 10. 然后对查询结果进行倒序. 注意: 最后一页 offset+limit >= totalCount, 
按照上述计算 newOffset 可能小于 0, 所以最后一页的 newOffset=0, limit= totalCount - offset

3) 第三种情况: 往前翻页, 跳转到任意页, 根据 id 逆序, newOffset = lastEndOffset - offset - limit - 1, 查询条
件为: id < lastEndId OFFSET newOffset LIMIT 10, 然后对结果进行逆序排序.

3. 如果查询是根据其他字段, 比如一般使用创建时间(createtime)排序.

这种情况与第二种情况差不多, 区别是 createtime 不是唯一的, 因此不能确定上一次最后一条记录对应的创建时间, 哪些是下一页的,
哪些是上一页的.

增加额外参数:

lastEndCreateTime: 上一次查询最后一条记录的创建时间.

lastEndOffset: 上一次查询最后一条记录对应的偏移量. 

lastEndCount: 上一次查询的时间为lastEndCreateTime的数量(这个是查询结果代码手动统计的).

1) 第一种情况: 跳转到下一页, 查询条件为: createtime > lastEndCreateTime OFFSET lastEndCount LIMIT 10.

2) 第二种情况: 往后翻页, 跳转到任意页, 计算出新的 newOffset = offset - lastOffset + lastEndCount. 查询条件为:
createtime > lastEndCreateTime OFFSET newOffset LIMIT 10. 如果 newOffset 很大, 可以考虑逆序查询, 先要查询表
中最大的 createtime 作为 lastEndCreateTime, 以及该 lastEndCreateTime 在表中的数量 lastEndCount, 然后更新那么
计算出新的 newOffset = (totalCount - lastEndCount) - offset - limit, 查询条件为: createtime < lastEndCreateTime OFFSET newOffset LIMIT 10.
然后对查询结果进行倒序.

3) 第三种情况: 往前翻页, 跳转到任意页, 计算出新的 newOffset = lastOffset - lastEndCount - offset, 查询条件为:
createtime < lastEndCreateTime OFFSET newOffset LIMIT 10. 然后对此查询结果进行逆序排序.
