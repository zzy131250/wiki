# 基础
## defer 语句
将 defer 语句后的函数放入一个栈，等到外层函数返回之后，按序执行栈中的函数

### 规则
1. defer 函数的参数在 defer 语句执行的时候被赋值
```go
func a() {
    i := 0
    defer fmt.Println(i) // print 0
    i++
    return
}
```
2. defer 函数按照后进先出的顺序执行
```go
// print 3210
func b() {
    for i := 0; i < 4; i++ {
        defer fmt.Print(i)
    }
}
```
3. defer 函数可以对函数返回值进行读取和修改
```go
// return 2
func c() (i int) {
    defer func() { i++ }()
    return 1
}
```