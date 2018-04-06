# 基础
## 生成器
生成器是迭代器的一种，以更优雅的方式实现的迭代器，其中含有 yield 关键字。

## staticmethod vs classmethod
### staticmethod
- 函数既不与类绑定，也不与对象绑定

### classmethod
- 第一个参数是 cls
- 模拟 java 中的多个构造函数
- 函数与类绑定

## 下划线
- \_\_foo\_\_：一种约定，表示 python 内部函数，区别于用户自定义函数
- \_foo：一种约定，指定变量为保护成员，不能用 from module import \* 导入，其他和公有成员一样
- \_\_foo：私有成员，解析器用 \_classname\_\_foo 来代替这个名字，以区别和其他类相同的命名，它无法直接像公有成员一样随便访问，必须通过 对象名.\_类名\_\_xxx 的方式访问