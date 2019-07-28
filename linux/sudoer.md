# sudoers 配置文件

## 描述

sudoers策略插件确定用户的sudo权限. suoders是默认的sudo策略插件. 该策略由 `/etc/sudoers` 文件驱动, 或者可选地在
LDAP中驱动. 策略格式在 **SUDOERS FILE FORMAT** 部分中有详细描述.

### configure sudo.conf for sudoers

sudo查询sudo.conf文件以确定要加载的策略和I/O日志记录插件. 如果没有sudo.conf文件, 或者它不包含插件行, 则sudoers将用
于策略决策和I/O日志记录. 要显式配置sudo.conf以使用sudoers插件, 可以使用以下配置.
  Plugin sudoers_policy sudoers.so
  Plugin sudoers_io sudoers.so

从 sudo 1.8.5开始, 可以在sudo.conf文件中为sudoers插件指定可选参数. 这些参数(如果存在)应该在插件的路径之后列出(即在
sudoers.so之后). 可以指定多个参数, 用空格分隔. 例如:
  Plugin sudoers_policy sudoers.so sudoers_mode = 0400

  支持以下插件参数:
     ldap_conf=pathname
        ldap_conf参数可用于覆盖ldap.conf文件的缺省路径.

     ldap_secret=pathname
        ldap_secret参数可用于覆盖ldap.secret文件的缺省路径

     sudoers_file=pathname
        sudoers_file参数可用于覆盖sudoers文件的默认路径.

     sudoers_uid=UID
        sudoers_uid参数可用于覆盖sudoers文件的默认所有者. 应将其指定为数字用户ID.

     sudoers_gid=GID
        sudoers_gid参数可用于覆盖sudoers文件的默认组. 必须将其指定为数字组ID(不是组名).

     sudoers_mode=mode
        sudoers_mode参数可用于覆盖sudoers文件的默认文件模式. 应将其指定为八进制值.


### User Authentication

sudoers安全策略要求大多数用户在使用sudo之前进行身份验证. 如果调用用户是root用户, 目标用户与调用用户相同, 或者策略已禁
用用户或命令的身份验证, 则不需要密码. 与su不同, 当sudoers需要身份验证时, 它会验证调用用户的凭据, 而不是目标用户(或root)
的凭据. 这可以通过rootpw, targetpw和runaspw标志进行更改.

如果未在策略中列出的用户尝试通过sudo运行命令, 则会将邮件发送给相应的权限. 用于此类邮件的地址可通过mailto Defaults条目
进行配置, 默认为root.

>请注意, 如果未经授权的用户尝试使用-l或-v选项运行sudo, 则不会发送邮件, 除非存在身份验证错误并且启用了 mail_always 或 
mail_badpass标志. 这允许用户自己确定是否允许他们使用sudo. 无论是否发送邮件, 都将记录所有运行sudo(成功与否)的尝试.

sudoers使用per-user时间戳文件进行凭证缓存. 一旦用户通过身份验证, 就会写入一条记录, 其中包含用于进行身份验证的uid, 终
端会话ID和时间戳(如果单调时钟可用的话, 则使用之). 然后, 用户可以在短时间内使用没有密码的sudo(15分钟, 除非被超时选项覆盖).
默认情况下, sudoers为每个tty使用单独的记录, 这意味着用户的登录会话将单独进行身份验证. 可以禁用tty_tickets选项以强制对
所有用户的会话使用单个时间戳.

### Logging

sudoers可以将成功和不成功的尝试(以及错误)记录到syslog, 日志文件或两者., 默认情况下, sudoers将通过syslog进行登录, 但
这可以通过syslog和logfile Defaults设置进行更改. 

sudoers还能够在伪tty中运行命令并记录所有输入和/或输出. 即使与终端无关, 也可以记录标准输入, 标准输出和标准错误. 默认情况
下, I/O日志记录未启用, 但可以使用log_input和log_output选项以及LOG_INPUT和LOG_OUTPUT命令标记启用. 


### Command environment

由于环境变量可以影响程序行为, 因此sudoers提供了一种方法来限制要运行的命令继承用户环境中的哪些变量. sudoers可以通过两种
不同的方式处理环境变量.

默认情况下, 启用env_reset选项. 这会导致命令在新的最小环境中执行. 在AIX(以及没有PAM的Linux系统)上, 使用/etc/environment
文件的内容初始化环境. 除了env_check和env_keep选项允许的调用过程中的变量之外, 新环境还包含TERM, PATH, HOME, MAIL,
SHELL, LOGNAME, USER, USERNAME和SUDO_*变量. 这实际上是环境变量的白名单. 除非 name 和 value 部分都由 env_keep
或 env_check 匹配, 否则将删除值以 `()` 开头的环境变量, 因为它们将被旧版本的bash shell解释为函数. 在1.8.11版之前, 
总是删除这些变量.

但是, 如果禁用了 env_reset 选项, 则 env_check 和 env_delete 选项未明确拒绝的任何变量都将从调用进程继承. 在这种情况
下,  env_check 和 env_delete 的行为类似于黑名单. 始终以 `()` 开头的环境变量将被删除, 即使它们与其中一个黑名单不匹配
也是如此. 由于无法将所有潜在危险的环境变量列入黑名单, 因此鼓励使用默认的env_reset行为.

默认情况下, 环境变量按名称匹配. 但是, 如果模式包含等号 ('='), 则变量name和value必须匹配. 例如, 旧式(pre-shellshock)
bash shell函数可以匹配如下:
    env_keep += "my_func=()*"
    
没有"=()*"后缀, 这将不匹配, 因为默认情况下不保留旧式bash shell函数.

当以 root 身份运行时, sudo 允许或拒绝的环境变量的完整列表包含在 "sudo -V" 的输出中. 请注意, 此列表因运行 sudo 的操作
系统而异.

在支持为sudo启用pam_env模块的PAM的系统上, PAM环境中的变量可能会合并到环境中. 如果PAM环境中的变量已存在于用户环境中, 则
只有在变量未被sudoers保留时才会覆盖该值. 启用env_reset时, env_keep列表从调用用户环境中保留的变量优先于PAM环境中的变量.
禁用env_reset时, 变量表示调用用户的环境优先于PAM环境中的环境, 除非它们与env_delete列表中的模式匹配.

请注意, 大多数操作系统上的动态链接器将删除可以控制来自setuid可执行文件(包括sudo)环境的动态链接的变量. 根据操作系统的不同,
这可能包括_RLD*, DYLD_\*, LD_\*, LDR_\*, LIBPATH, SHLIB_PATH等. 在sudo甚至开始执行之前, 这些类型的变量将从环境中
删除, 因此, sudo不可能保留它们.

作为特殊情况, 如果指定了sudo的-i选项(初始登录), 则无论env_reset的值如何, sudoers都将初始化环境. DISPLAY, PATH和TERM
变量保持不变; HOME, MAIL, SHELL, USER和LOGNAME基于目标用户进行设置. 在AIX(以及没有PAM的Linux系统)上. 还包括/etc/environment
的内容. 将删除所有其他环境变量.

最后, 如果定义了env_file选项, 则该文件中存在的任何变量都将设置为其指定值, 只要它们不与现有环境变量冲突即可.


## SUDOERS文件格式

sudoers文件由两种类型的条目组成: aliases(基本上是变量)和user specifications(指定谁可以运行什么).

当多个条目与用户匹配时, 将按顺序应用它们. 如果存在多个匹配项, 则使用最后一个匹配项(不一定是最具体的匹配项).

sudoers文件语法将在下面以Extended Backus-Naur Form(EBNF)描述.

### EBNF快速指南

EBNF是一种描述语言语法的简洁而准确的方法. 每个EBNF定义都由生产规则组成.
例如, 
    symbol :: = definition | alternate1 | alternate2 ...

每个规则都引用其他规则, 从而构成语言的语法. EBNF还包含以下运算符, 许多读者将从正则表达式中识别这些运算符. 但是, 不要将它
们与具有不同含义的"通配符"混淆.
  
  ? 表示前面的符号(或符号组)是可选的. 也就是说, 它可能会出现一次或根本不出现.

  * 表示前面的符号(或符号组)可能出现零次或多次.

  + 表示前一个符号(或一组符号)可能出现一次或多次.

括号可用于将符号组合在一起. 为清楚起见, 我们将使用单引号('')来指定什么是逐字符字符串(而不是符号名称).


### Aliases

aliases包括4种类型: User_Alias, Runas_Alias, Host_Alias, Cmnd_Alias.

Alias ::= 'User_Alias'  User_Alias (':' User_Alias)* |
          'Runas_Alias' Runas_Alias (':' Runas_Alias)* |
          'Host_Alias'  Host_Alias (':' Host_Alias)* |
          'Cmnd_Alias'  Cmnd_Alias (':' Cmnd_Alias)*
          
User_Alias ::= NAME '=' User_List

Runas_Alias :: = NAME '=' Runnas_List

Host_Alias :: NAME '=' Host_Alias

Cmnd_Alias :: NAME '=' Cmnd_Alias

NAME ::= \[A-Z](\[A-Z]\[0-9]_)*


每个alias定义都是类型: Alias_Type NAME = item1, item2, ...

其中Alias_Type是User_Alias, Runas_Alias, Host_Alias或Cmnd_Alias之一. NAME是一个由大写字母, 数字和下划线字符组
成的字符串('_'). NAME必须以大写字母开头. 可以在一行上放置几个相同类型的别名定义, 用冒号(':')连接. 例如,

Alias_Type NAME = item1,item2,item3: NAME = item4,item5

重新定义现有别名是语法错误. 可以对不同类型的别名使用相同的名称, 但不建议这样做。

有效别名成员的定义如下.

User_List ::= User | 
              User ',' User_List

User ::= '!'* user name |
         '!'* #uid |
         '!'* %group |
         '!'* %#gid |
         '!'* +netgroup |
         '!'* %:nonunix_group |
         '!'* %:#nonuix_gid |
         '!'* User_Alias
         
User_List由一个或多个用户名, 用户ID(前缀为"#"), 系统组名称和ID(前缀分别为'%'和'%#'), netgroups(前缀为'+')组成, 
非Unix组名称和ID(分别以'%:'和'%:#'为前缀)和User_Aliases. 每个列表项可以以零个或多个"!"运算符为前缀. 奇数个"!"运算
符否定了该项的值; 一个偶数只是相互取消. 用户网络组仅使用用户和域成员进行匹配; 匹配时不使用主机成员.

