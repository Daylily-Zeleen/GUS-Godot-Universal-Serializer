
# GUS - Godot Universal Serializer - Godot的通用序列化器 - V1.01

![Image text](https://github.com/Daylily-Zeleen/GUS-Godot-Universal-Serializer/blob/main/icon.png)

支持 Godot 3.x 中除了 Object 和 RID 以外的所有数据类型。
主要用于简单场合的跨端传输数据时代替json使用。

# 特性:
	1、不丢失类型信息，跨端传送 无需 类型检测 与 强制类型转换，如同本地传参一般。
	2、int与float是可变长序列化。
	3、序列化后的数据大小小于 Json 和 原生序列化方法(var2bytes())，尤其适合多人游戏中要传送的结构化小数据序列化。
	可调用 _test() 查看3种方式的序列化后数据大小对比

# 使用方法:
	1、按需求修改脚本开头的几个配置定义常量
	2、将不含有 Object 和 RID 的变量传入 GUS.to_bytes() 获取序列化后的数据,并通过任意 网络对等体 发送给远端。
	3、远端的网络对等体接收到数据后获取序列化后的数据， 传入 GUS.to_var() 即可得到与序列化之前相同的 变量。

	附加：可将获取到的序列化数据 传入 GUS.get_pretty_json_text() 获取经美化后的json文本进行打印显示方便调试。

# 注意事项：
	1、跨端应用的 配置定义 应保持相同。
	2、Array 与 Dictionary 中不应含有 Object 或 RID。
	3、虽然序列化后的数据尺寸较优，但是由于是脚本实现，效率低下，大数组的序列化和反序列化的时间很长，应该避免在即时性敏感的场合序列化和反序列大数组。

# TODO:
	1、编写 Godot4.x 适用的 GUS 2.0。
	2、编写为cpp插件以解决大数组序列化效率低下的问题。

# 编辑历史：
	2022-1-18 :忘忧の - 735170336@qq.com - v1.0
	2022-1-19 :忘忧の - 735170336@qq.com - v1.01
		a、为序列化方法添加类型检测断言以便于调试
		b、为_test()添加 null, bool 两种测试
		c、添加使用方法说明
		d、添加公用方法和测试方法的说明
		e、优化反序列化时 push_error() 的打印信息

