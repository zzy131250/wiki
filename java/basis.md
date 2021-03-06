# 基础
## 传值 or 传引用
Java 中都是传值，即使是对象也只是传对象地址值的副本。

## 重载 vs 重写
- 重载：函数名相同，参数不同。没有实现多态。
- 重写：子类对父类方法进行改写。实现了多态。

## 修饰符访问权限
| 作用域 | 当前类 | 同一包 | 子孙类 | 其他包 |
| ----- | ----- | ----- | ----- | ----- |
| public | √ | √ | √ | √ |
| protected | √ | √ | √ | × |
| default | √ | √ | × | × |
| private | √ | × | × | × |

## 枚举
反编译后发现，在静态代码块中生成 public static final 实例，并拥有私有构造函数

## 循环中删除元素
- 使用迭代器删除
- 使用普通 for 循环，并修正 index；或者由后向前遍历
- 使用增强 for 循环，底层仍然使用迭代器，删除时会抛出异常

## Object 类的方法
- hashCode()：返回对象的哈希值，默认根据对象地址计算，用来在 map 接口中对对象寻址，防止遍历调用 equals() ，提高效率
- equals()：比较对象是否相等，默认比较对象地址。重写 equals() 时须同时重写 hashCode()，保证 equals 的两个对象 hashCode 也一样
 - 若 equals 的两个对象 A、B 的 hashCode 不一样，则都会被放入 HashSet（put 方法认为对象相同时，要求 hashCode 相同且equals 返回 true），但不符合实际，因为 A、B 应当认为是相同对象，只能放入一次
- clone()：创建并返回当前对象的拷贝，默认浅拷贝
 - 浅拷贝：对于引用对象仅拷贝指针，指向相同的对象实例
 - 深拷贝：对于引用对象会建立新的对象实例。可使用序列化实现深拷贝
- toString()：输出类信息的字符串，默认是——类的名字@实例的哈希码的16进制
- getClass()、wait()、notify()、finalize()

## 子类继承父类
- 所有字段、方法和嵌套类，其中 private 修饰的父类成员子类可以继承但无法使用
- 不继承父类构造方法，但可以调用超类的构造方法

## 抽象类 vs 接口
### 相同点
- 都不能被实例化

### 区别
| | 抽象类 | 接口 |
| ----- | ----- | ----- |
| 构造器 | √ | × |
| 多继承 | × | √ |
| 非 public 方法 | √ | × |
| main 方法 | √ | × |

## 内部类
### 成员内部类
- 成员内部类中不能存在任何 static 的变量和方法
- 成员内部类是依附于外围类的，所以只有先创建了外围类才能够创建内部类
- 持有指向外部类对象的引用

### 静态内部类
- 创建不依赖于外部类，没有指向外部类对象的引用
- 不能使用任何外围类的非 static 成员变量和方法

### 局部内部类
- 嵌套在方法和作用域内，只能在该方法和作用域中被使用
- 只能访问局部 final 变量，原理是在内部类中创建一个变量的拷贝

### 匿名内部类
- 没有访问修饰符，没有构造方法
- 匿名内部类是局部内部类
- 使用匿名内部类时，必须继承一个类或者实现一个接口，但是两者不可兼得

## 异常
### 异常层次结构图
- Error：指虚拟机相关的问题，如系统崩溃、虚拟机错误、内存空间不足、栈溢出。编译器不检查，程序也无法恢复，遇到时建议让程序终止
- Exception：程序可以处理的异常，可以捕获且可能恢复，应尽可能处理
 - RuntimeException（空指针）：编译器不检查
 - 受检查异常（IOException）：如果不处理，编译不会通过

![](http://zia-wiki.oss-cn-hangzhou.aliyuncs.com/18-11-3/26781872.jpg)

### try - catch - finally
- finally 在 try / catch 中的 return 语句执行完，返回结果之前执行
- 若 finally 中有 return，则在 finally 中 return
- 若在 try / catch 块中 return，finally 块中对 return 结果的更改不会影响到 try / catch 块中的结果（相当于方法传值，如果是对象，可能有影响）
- try 和 catch 块中都出现异常，若 finally 有 return，直接返回，不检查异常；若 finally 无 return，抛出异常