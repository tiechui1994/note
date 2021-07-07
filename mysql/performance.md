## OPTIMIZER_TRACE 详解

### OPTIMIZER_TRACE相关参数

- optimizer_trace

optimizer_trace 总开关, 默认值: `enabled=off, one_line=off`

enabled: 是否开启 optimizer_trace, on表示开启, off表示关闭

one_line: 是否开启单行存储.

- optimizer_trace_features

控制 optimizer_trace 跟踪的内容, 默认值: `greedy_search=on,range_optimizer=on,dynamic_range=on,
repeated_subselect=on`, 表示开启所有的追踪项.

greedy_search: 是否跟踪贪心搜索,

range_optimizer: 是否跟踪范围优化器

dynamic_range: 是否跟踪动态范围优化

repeated_subselect: 是否跟踪子查询, 如果设置为 off, 只跟踪第一条 item_subselect 的执行.

- optimizer_trace_limit

控制 optimizer_trace 展示的条数, 默认是1

- optimizer_trace_max_mem_size

控制 optimizer_trace 堆栈信息允许的最大内存, 默认 1048576

### OPTIMIZER_TRACE结果分析

#### join_preparation

展示准备阶段的执行过程.

#### join_optimization

展示了优化阶段执行过程, 分析 OPTIMIZER TRACE 的重点. 

- condition_processing: 条件处理, 主要对 WHERE 条件进行优化处理

1) condition: 优化对象类型. WHERE条件语句或者是HAVING条件句
2) origin_condition: 优化前的原始语句
3) steps: 主要包括三步, 分别是 quality_propagation(等值条件转换), constant_propagation(常量条件句转换), 以及
trivial_condition_removal(无效条件剔除转换)


- substitute_generated_columns

用于替换虚拟生成列


- table_dependencies

分析表的依赖关系

1) row_may_be_null: 行是否可能为NULL, 这里是指JOIN操作之后, 这张表里的数据是不是可能为NULL/ 如果语句中使用了 `LEFT
JOIN`, 则后一张表的 row_may_be_null 会显示为 true

2) map_bit: 表的映射编号, 从0开始递增

3) depends_on_map_bits: 依赖的映射表, 主要是当使用 STRAIGHT_JOIN 强行控制连接顺序或者LEFT JON/RIGHT JOIN 有顺
序差别时, 会在 depends_on_map_bits 中展示前置表的 map_bit 值.


- ref_optimizer_key_uses

列出所有可用的ref类型的索引. 如果使用了组合索引的多个部分,则会在ref_optimizer_key_uses下列出多个元素, 每个元素中会
列出ref使用的索引及对应值.


- rows_estimation

估算扫描的记录数.

1) range_analysis:

1.1) table_scan: 如果全表扫描的话, 需要扫描多少行, 以及需要的代价

1.2) potential_range_indexes: 列出表中所有索引并分析其是否可用. 如果不可用, 列出不可用的原因; 可用列出索引中可用的
字段.

1.3) setup_range_conditions: 如果有可下推条件, 则带条件考虑范围查询(ICP)

1.4) group_index_range: 当使用了 GROUP BY 或 DISTINCT 时, 是否有合适的索引可用. 当未使用 GROUP BY 或 DISTINCT 
时, 会显示 chosen=false. 如使用了 GROUP BY 或 DISTINCT, 但是多表查询时, 会显示 chosen=false, cause=not_single_table.
其他状况下会尝试分析可用的(potential_group_range_indexes)并计算对应的扫描行数及其所需的代价.

1.5) skip_scan_range: 是否使用了 skip scan

2) analyzing_range_alternatives: 分析各个索引的使用成本.

2.1) range_scan_alternatives: range 扫描分析

index: 索引; ranges: range 扫描的条件范围; index_dives_for_eq_ranges: 是否使用了 index dive, 该值会被参数
eq_range_index_dive_limit 变量值影响. rowid_ordered: 该range扫描的结果集是否根据PK值进行排序; index_only: 表
示是否使用覆盖索引.

2.2) analyzing_roworder_intersect: 分析是否使用了索引合并(index merge), 如果未使用, 会在 cause 当中展示原因;
如果使用了索引合并, 会展示索引合并的代价.

3) chosen_range_access_summary: 在summary阶段汇总前一个阶段的中间结果确认最后的方案

3.1) range_access_plan: range 扫描最终选择的执行计划

type: 展示执行计划的type, 如果使用了索引合并, 则会显示 index_roworder_intersect;

3.2) rows_for_plan: 该计划的扫描行数

3.3) cost_for_plan: 该执行计划的执行代价

3.3) chosen: 是否选择该执行计划


- considered_execution_plans

负责对比各可执行计划的开销, 选择相对最优的执行计划.

1) best_access_path: 通过对比 consider_access_paths, 选择一个最优的访问路径.

1.1) access_type: 使用索引的方式. 参考 explain 中的 type 字段
1.2) chosen: 是否选用这种执行路径

2) condition_filtering_pct: 类似于 explain 的 filter 列, 是一个估算值

3) rows_for_plan: 执行计划最终的扫描行数, 由 consider_access_paths.rows x condition_filtering_pct 计算获得

4) cost_for_plan: 执行计划的代价, 由 condition_access_paths.cost 相加获得

5) chosen: 是否选择了该计划


- attaching_conditions_to_tables

基于 considered_execution_plans 中选择的执行计划, 改造原有 WHERE 条件, 并针对表增加适当的附加条件, 类似单表数据筛
选.

1) attached_conditions_computation: 使用启发式算法计算已使用的索引, 如果已使用的索引的访问类型是 ref, 则计算 range
能否使用组合索引中更多的列, 如果可以, 使用 range 方式替换 ref.

2) attached_conditions_summary: 附加之后的情况汇总

- refine_plan

改善执行计划.
