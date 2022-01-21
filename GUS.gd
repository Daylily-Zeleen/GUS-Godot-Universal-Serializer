"""
	GUS - Godot Universal Serializer - Godot的通用序列化器 - V1.03
	
	支持 Godot 3.x 中除了 Object 和 RID 以外的所有数据类型。
	主要用于简单场合的跨端传输数据时代替json使用。
	
	特性:
		1、不丢失类型信息，跨端传送 无需 类型检测 与 强制类型转换，如同本地传参一般
		2、int与float是可变长序列化
		3、序列化后的数据大小小于 Json 和 原生序列化方法(var2bytes())，尤其适合多人游戏中要传送的结构化小数据序列化
			可调用 _test() 查看 三种方式 的序列化后数据大小对比
		
	使用方法:
		1、按需求修改脚本开头的几个配置定义常量
		2、将不含有 Object 和 RID 的变量传入 GUS.to_bytes() 获取序列化后的数据,并通过任意 网络对等体 发送给远端
		3、远端的网络对等体接收到数据后获取序列化后的数据， 传入 GUS.to_var() 即可得到与序列化之前相同的 变量
	
		附加：可将获取到的序列化数据 传入 GUS.get_pretty_json_text() 获取经美化后的json文本进行打印显示方便调试
		
	注意事项：
		1、跨端应用的 配置定义 应保持相同
		2、Array 与 Dictionary 中不应含有 Object 或 RID
		3、虽然序列化后的数据尺寸较优，但是由于是脚本实现，效率低下，大数组的序列化和反序列化的时间很长，
			应该避免在即时性敏感的场合序列化和反序列大数组
	
	TODO:
		1、编写 Godot4.x 适用的 GUS 2.0
		2、编写为cpp插件以解决大数组序列化效率低下的问题
	
	编辑历史：
		2022-1-21 ：忘忧の - 735170336@七qq.com - v1.03
			为了方便在特定场合通过字符串设置 GUS 默认值，做出以下修改：
				a、修改并新增 bool 的识别代码
				b、修改字典，数组的识别代码
			例如: 数据库中 存储GUS编码的二进制字段 的默认值,可以字符串'[]','{}','T'或't','F'或'f'设置默认值,分别为 空数组， 空字典, 布尔值 真，布尔值 假
		2022-1-19 :忘忧の - 735170336@qq.com - v1.02
			a、修复反序列化空数组错误
			b、修复反序列化空字典错误
			c、优化空池化数组的序列化长度
		2022-1-19 :忘忧の - 735170336@qq.com - v1.01
			a、为序列化方法添加类型检测断言以便于调试
			b、为_test()添加 null, bool 两种测试
			c、添加使用方法说明
			d、添加公用方法和测试方法的说明
			e、优化反序列化时 push_error() 的打印信息
		2022-1-18 :忘忧の - 735170336@qq.com - v1.0
"""
class_name GUS

# 配置定义
const UTF8_STR :bool= true # 字符串以 utf8 进行编码(允许使用中文，降低解码速度
const ONLY_FLOAT32 :bool= true # 传入的浮点数为双精度浮点数时将被自动 转换为单精度浮点数 进行编码(降低浮点数精度，缩短编码长度


## 序列化
## variant 	: 不含有 Object 和 RID 类型的任意变量
## 返回值		: 序列化后的数据
static func to_bytes(variant)->PoolByteArray:
	var buffer:= StreamPeerBuffer.new()
	var res:=_put_var(variant,buffer)
	assert(res,"被序列化的值中不应含有 Object 与 RID 类型")
	return buffer.data_array
	
## 反序列化
## data		: 由GUS序列化后的数据
## 返回值		: 反序列化后的变量，应与序列化之前的变量相同
static func to_var(data:PoolByteArray):
	var buffer:= StreamPeerBuffer.new()
	buffer.put_data(data)
	buffer.seek(0)
	return _get_var(buffer)

## 将数据流转化为美化后的文本，用于打印显示或存储为Json(注意:转储为Json将丢失类型信息)
## data				: 由GUS序列化后的数据
## pretty_indent	: 用于美化显示的缩进符号，默认为制表符("\t")。
## 						如果是用于转储为Jso格式，为减少数据json的字符长度，建议传入 空字符串（即 “”）
## 返回值		: 经美化后的Json字符串
static func get_pretty_json_text(data:PoolByteArray,pretty_indent:="\t")->String:
	return JSON.print(data,pretty_indent)



# 简单的序列化测试
# inside_tree_node : 场景树中的任意节点（如果传入的节点不在场景树中，将会因为打印溢出而无法显示完整结果
func _test(inside_tree_node:Node)->void:
	var tree:=inside_tree_node.get_tree() if inside_tree_node and inside_tree_node.is_inside_tree() else null
	var datas:={
		"null":null,
		"bool true":true,
		"bool false":false,
		"int 1":0x8a,
		"int 2":0x5c3b,
		"int 3":-0x7a5390,
		"int 4":0xba53c904,
		"int 5":-0x7c340c9041,
		"int 6":0xba53c904d054,
		"int 7":0x3c90a53c90d041,
		"int 8":-0x7aaa53c907a414d0,
		"float":-105.0532,
		"str":"test 测试",
		"vec2":Vector2(-423,46.8005),
		"vec3":Vector3(52011,-541.3327,77441),
		"rect2":Rect2(56.622, -77.85, 8740.2369, 441.044),
		"transform2d":Transform2D.FLIP_Y.translated(Vector2(513,88.5)),
		"plane":Plane(-54.55, 876, 2310,744).normalized(),
		"quat":Quat(-54.55, 876, 2310,744),
		"aabb":AABB(Vector3(-77.85, 8740.2369, 441.044),Vector3(105,50,68)),
		"basis":Transform.FLIP_Y.basis,
		"transform":Transform.FLIP_Z.translated(Vector3(513,-88.5,105)),
		"color":Color.aqua,
		"node path":inside_tree_node.get_path(),
		"array":[574,-21.0,Vector2(-423,46.8005),Color.aqua,"acxx"],
	}
	# 简单类型测试
	for k in datas:
		_print_result(k,datas[k])
		if tree:
			yield(tree,"idle_frame")
			yield(tree,"idle_frame")
	# 字典测试
	_print_result("dictionary",datas)
	if tree:
		yield(tree,"idle_frame")
		yield(tree,"idle_frame")
	# 池化数组测试
	var byte_arr:=PoolByteArray()
	var int_arr:=PoolIntArray()
	var float_arr:=PoolRealArray()
	var string_arr:=PoolStringArray()
	var vector2_arr:=PoolVector2Array()
	var vector3_arr:=PoolVector3Array()
	var color_arr:=PoolColorArray()
	
	var i := 0x7fff
	while i>0:
		byte_arr.push_back(i%256)
		int_arr.push_back(i)
		float_arr.push_back(i/2.5)
		string_arr.push_back(str(i))
		vector2_arr.push_back(Vector2(i,-i))
		vector3_arr.push_back(Vector3(i,0,-i))
		color_arr.push_back(Color(i))
		i-=1
	
	_print_result("pool byte array",byte_arr)
	if tree:
		yield(tree,"idle_frame")
		yield(tree,"idle_frame")
	_print_result("pool int array",int_arr)
	if tree:
		yield(tree,"idle_frame")
		yield(tree,"idle_frame")
	_print_result("pool real array",float_arr)
	if tree:
		yield(tree,"idle_frame")
		yield(tree,"idle_frame")
	_print_result("pool string array",string_arr)
	if tree:
		yield(tree,"idle_frame")
		yield(tree,"idle_frame")
	_print_result("pool vector2 array",vector2_arr)
	if tree:
		yield(tree,"idle_frame")
		yield(tree,"idle_frame")
	_print_result("pool vector3 array",vector3_arr)
	if tree:
		yield(tree,"idle_frame")
		yield(tree,"idle_frame")
	_print_result("pool color array",color_arr)

# 序列化与反序列并打印对比结果
func _print_result(title_name:String, v)->void:
	var gus_bytes:=to_bytes(v) # GUS 序列化后数据
	var gus_length:= gus_bytes.size() # GUS 序列化后数据的长度
	var json_length:= to_json(v).to_utf8().size() # JSON 转 UTF8后的数据长度
	var native_length:= var2bytes(v).size() # 原生序列化方法的数据长度
	var res = to_var(gus_bytes) # GUS 反序列化
	if typeof(v) == typeof(res) and str(v) == str(res): # 检查序列化前后的类型和具体值是否相同
		if typeof(v) >TYPE_ARRAY: # 池化数组不打印具体值（打印溢出
			print("%s 大小: %d \n\t --长度: %d, json长度: %d, 原生编码长度: %d \n" %[title_name,v.size(),gus_length,json_length,native_length])
		else:
			print("%s: %s \n\t --长度: %d, json长度: %d, 原生编码长度: %d \n" %[title_name,str(v),gus_length,json_length,native_length])
	else: # 反序列化异常
		printerr("%s: %s  解码结果:%s   解码失败\n\t - 数据流: %s"%[title_name,str(v),str(res),str(gus_bytes)])






############
#  内部实现
############
enum {
	STR,
	NULL,
	INT_1,
	INT_2,
	INT_3,
	INT_4,
	INT_5,
	INT_6,
	INT_7,
	INT_8,
	FLOAT_TEXT_1,
	FLOAT_TEXT_2,
	FLOAT_TEXT_3,
	FLOAT_4,
	FLOAT_TEXT_5,
	FLOAT_TEXT_6,
	FLOAT_TEXT_7,
	FLOAT_8,	
	VECTOR2,
	RECT2,
	VECTOR3,
	TRANSFORM2D,
	PLANE,
	QUAT,
	AABB_, # 与 AABB 重名，故加下划线
	BASIS,
	TRANSFORM,
	COLOR,
	NODE_PATH,
	# 池化数组元素个数不超过 2^32（Godot自身限定
	RAW_ARR,
	INT32_ARR, 
	FLOAT32_ARR,
	VEC2_ARR,
	STR_ARR,
	VEC3_ARR,
	COLOR_ARR,
	# 为序列化长度优化设置的空对象识别编号
	EMPTY_DICT,
	EMP_ARR,
	EMPTY_RAW_ARR,
	EMPTY_INT32_ARR, 
	EMPTY_FLOAT32_ARR,
	EMPTY_STR_ARR,
	EMPTY_VEC2_ARR,
	EMPTY_VEC3_ARR
	EMPTY_COLOR_ARR,
	# 常用字符,通过字符串进行编码，方便在一些场合设置默认值（例如将 GUS 序列化后的二进制字符串存储在数据库时，通过字符串为该字段设置默认值）
	FALSE_CAP=70, # ‘F’
	TRUE_CAP=84, # 'T'
	ARR_BEGIN = 91, # ‘【’
	ARR_END = 93,  # ‘】’
	FALSE_LOW=102, # ‘f’
	TRUE_LOW=116, # 't'
	DICT_BEGIN = 123, # '{'
	DICT_END = 125, # '}'
}


static func _put_var(v,buffer:StreamPeerBuffer)->bool:
	match typeof(v):
		TYPE_NIL: buffer.put_u8(NULL)
		TYPE_BOOL: buffer.put_u8(TRUE_CAP if v else FALSE_CAP)
		TYPE_INT: _put_int(v,buffer)
		TYPE_REAL: _put_real(v,buffer)
		TYPE_STRING: _put_str(v,buffer)
		TYPE_VECTOR2:_put_vec2(v,buffer)
		TYPE_RECT2: _put_rect2(v,buffer)
		TYPE_VECTOR3: _put_vec3(v,buffer)
		TYPE_TRANSFORM2D: _put_transform2d(v,buffer)
		TYPE_PLANE: _put_plane(v,buffer)
		TYPE_QUAT: _put_quat(v,buffer)
		TYPE_AABB: _put_aabb(v,buffer)
		TYPE_BASIS: _put_basis(v,buffer)
		TYPE_TRANSFORM: _put_transform(v,buffer)
		TYPE_COLOR: _put_color(v,buffer)
		TYPE_NODE_PATH: _put_node_path(v,buffer)
		TYPE_DICTIONARY: _put_dict(v,buffer)
		TYPE_ARRAY: _put_arr(v,buffer)
		TYPE_RAW_ARRAY: _put_raw_arr(v,buffer)
		TYPE_INT_ARRAY: _put_int32_arr(v,buffer)
		TYPE_REAL_ARRAY: _put_float_arr(v,buffer)
		TYPE_STRING_ARRAY: _put_str_arr(v,buffer)
		TYPE_VECTOR2_ARRAY: _put_vec2_arr(v,buffer)
		TYPE_VECTOR3_ARRAY: _put_vec3_arr(v,buffer)
		TYPE_COLOR_ARRAY: _put_color_arr(v,buffer)
		_:
			push_error("Can't serialize Object and RID:"+str(v))
			return false
	return true

static func _get_var(buffer:StreamPeerBuffer):
	var code:=buffer.get_u8()
	match code:
		NULL: return null
		FALSE_CAP,FALSE_LOW: return false
		TRUE_CAP,TRUE_LOW: return true
		STR: return _get_str(buffer)
		VECTOR2: 
			if buffer.get_available_bytes() >=8:
				return Vector2(buffer.get_float(), buffer.get_float())
			else:
				push_error("Illegal data stream, can not convert to Vector2.")
				return Vector2()
		RECT2:
			if buffer.get_available_bytes()>=16:
				return Rect2(buffer.get_float(),buffer.get_float(),buffer.get_float(),buffer.get_float())
			else:
				push_error("Illegal data stream, can not convert to Rect2.")
				return Rect2()
		VECTOR3:
			if buffer.get_available_bytes()>=12:
				return Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float())
			else:
				push_error("Illegal data stream, can not convert to Vector3.")
				return Vector3()
		TRANSFORM2D:
			if buffer.get_available_bytes()>=24:
				return Transform2D(
					Vector2(buffer.get_float(),buffer.get_float()),
					Vector2(buffer.get_float(),buffer.get_float()),
					Vector2(buffer.get_float(),buffer.get_float())
				)
			else:
				push_error("Illegal data stream, can not convert to Transform2D.")
				return Transform2D()
		PLANE:
			if buffer.get_available_bytes()>=16:
				return Plane(buffer.get_float(),buffer.get_float(),buffer.get_float(),buffer.get_float())
			else:
				push_error("Illegal data stream, can not convert to Plane.")
				return Plane()
		QUAT:
			if buffer.get_available_bytes()>=16:
				return Quat(buffer.get_float(),buffer.get_float(),buffer.get_float(),buffer.get_float())
			else:
				push_error("Illegal data stream, can not convert to Quat.")
				return Quat()
		AABB_:
			if buffer.get_available_bytes()>=24:
				return AABB(
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float()),
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float())
				)
			else:
				push_error("Illegal data stream, can not convert to AABB.")
				return AABB()
		BASIS:
			if buffer.get_available_bytes()>=36:
				return Basis(
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float()),
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float()),
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float())
				)
			else:
				push_error("Illegal data stream, can not convert to Basis.")
				return Basis()
		TRANSFORM:
			if buffer.get_available_bytes()>=48:
				return Transform(
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float()),
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float()),
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float()),
					Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float())
				)
			else:
				push_error("Illegal data stream, can not convert to Transform.")
				return Transform()
		COLOR:
			if buffer.get_available_bytes()>=4:
				return Color(buffer.get_32())
			else:
				push_error("Illegal data stream, can not convert to Color.")
				return Color()
		NODE_PATH: return NodePath(_get_str(buffer))
		DICT_BEGIN:
			var r:={}
			while buffer.get_available_bytes()>0:
				if buffer.data_array[buffer.get_position()] == DICT_END:
					buffer.get_u8()
					return r
				var k = _get_var(buffer)
				r[k] = _get_var(buffer)
			push_error("Illegal data stream, can not convert to Dictionary.")
			return {}
		ARR_BEGIN:
			var r:=[]
			while buffer.get_available_bytes()>0:
				if buffer.data_array[buffer.get_position()] == ARR_END:
					buffer.get_u8()
					return r
				r.append(_get_var(buffer))
			push_error("Illegal data stream, can not convert to Array.")
			return []
		INT_1,INT_2,INT_3,INT_4,INT_5,INT_6,INT_7,INT_8: return _get_int(buffer,code)
		FLOAT_TEXT_1,FLOAT_TEXT_2,FLOAT_TEXT_3: _get_float_from_ascii(buffer,code-INT_8)
		FLOAT_4: return buffer.get_float()
		FLOAT_TEXT_5,FLOAT_TEXT_6,FLOAT_TEXT_7: _get_float_from_ascii(buffer,code-INT_8)
		FLOAT_8: return buffer.get_double()
		EMP_ARR: return []
		EMPTY_DICT: return []
		RAW_ARR:
			var int_code:= buffer.get_u8()
			var size:=_get_int(buffer,int_code)
			if buffer.get_available_bytes()>=size:
				var tmp := buffer.get_data(size)
				if tmp[0] == OK:
					return tmp[1]
				else:
					push_error("Get data from stream faild, error code:"%tmp[0])
					return PoolByteArray()
			else:
				push_error("Illegal data stream, can not convert to PoolByteArray.")
				return PoolByteArray()
		INT32_ARR:
			var int_code:= buffer.get_u8()
			var size:=_get_int(buffer,int_code)
			if buffer.get_available_bytes()>=size*4:
				var r := PoolIntArray()
				while size>0:
					size-=1
					r.push_back(buffer.get_32())
				return r
			else:
				push_error("Illegal data stream, can not convert to PoolIntArray.")
				return PoolIntArray()
		FLOAT32_ARR:
			var int_code:= buffer.get_u8()
			var size:=_get_int(buffer,int_code)
			if buffer.get_available_bytes()>=size*4:
				var r := PoolRealArray()
				while size>0:
					size-=1
					r.push_back(buffer.get_float())
				return r
			else:
				push_error("Illegal data stream, can not convert to PoolRealArray.")
				return PoolRealArray()
		STR_ARR:
			var r:=PoolStringArray()
			while buffer.get_available_bytes()>1:
				r.push_back(_get_str(buffer))
				if buffer.data_array[buffer.get_position()] == STR_ARR:
					buffer.get_u8()
					return r
			push_error("Illegal data stream, can not convert to PoolStringArray.")
			return PoolStringArray()
		VEC2_ARR:
			var int_code:= buffer.get_u8()
			var size:=_get_int(buffer,int_code)
			if buffer.get_available_bytes()>=size*8:
				var r := PoolVector2Array()
				while size>0:
					size-=1
					r.push_back(Vector2(buffer.get_float(),buffer.get_float()))
				return r
			else:
				push_error("Illegal data stream, can not convert to PoolVector2Array.")
				return PoolVector2Array()
		VEC3_ARR:
			var int_code:= buffer.get_u8()
			var size:=_get_int(buffer,int_code)
			if buffer.get_available_bytes()>=size*12:
				var r := PoolVector3Array()
				while size>0:
					size-=1
					r.push_back(Vector3(buffer.get_float(),buffer.get_float(),buffer.get_float()))
				return r
			else:
				push_error("Illegal data stream, can not convert to PoolVector3Array.")
				return PoolVector3Array()
		COLOR_ARR:
			var int_code:= buffer.get_u8()
			var size:=_get_int(buffer,int_code)
			if buffer.get_available_bytes()>=size*4:
				var r := PoolColorArray()
				while size>0:
					size-=1
					r.push_back(Color(buffer.get_u32()) )
				return r
			else:
				push_error("Illegal data stream, can not convert to PoolColorArray.")
				return PoolColorArray()
		EMPTY_RAW_ARR: return PoolByteArray()
		EMPTY_INT32_ARR: return PoolIntArray()
		EMPTY_FLOAT32_ARR: return PoolRealArray()
		EMPTY_STR_ARR: return PoolStringArray()
		EMPTY_VEC2_ARR: return PoolVector2Array()
		EMPTY_VEC3_ARR : return PoolVector3Array()
		EMPTY_COLOR_ARR: return PoolColorArray()
		_:
			push_error("Unrecognized code:%d"%code)
			return null
	
# 序列化反序列化
static func _put_int(v:int,buffer:StreamPeerBuffer)->void:#->PoolByteArray:
	var bs:=var2bytes(v).subarray(4,-1)
	var i := bs.size()-1
	if v<0:
		while i > 1:
			if bs[i]!=255: break
			i-=1
		if bs[i]&0b10000000==0: i+=1 # 最高位不能表示负数	
	else:
		while i > 0:
			if bs[i] != 0:break
			i-=1
		if bs[i]&0b10000000!=0: i+=1 # 最高位表示负数
	buffer.put_u8(INT_1 + i)
	buffer.put_data(bs.subarray(0,i))

static func _get_int(buffer:StreamPeerBuffer,size_code:int)->int:
	if size_code == INT_4: return buffer.get_32()
	elif size_code == INT_8: return buffer.get_64()
	else:
		var count:= size_code-NULL
		if count<4: return __get_int32(buffer,count)
		else: return __get_int64(buffer,count)

static func __get_int32(buffer:StreamPeerBuffer,byte_count:int )->int:
	if buffer.get_available_bytes() < byte_count:
		push_error("Illegal data stream, can not convert to int32.")
		return 0
	else:
		var tmp:= buffer.get_data(byte_count)
		if tmp[0] == OK:
			var buf:=PoolByteArray([2,0,0,0])
			buf.append_array(tmp[1])
			if buf[-1] & 0b10000000 == 0b10000000: #负数
				for _i in range(4 - byte_count):
					buf.append(255)
			else:
				for _i in range(4 - byte_count):
					buf.append(0)
			return bytes2var(buf)
		else:
			push_error("Get data from stream faild, error code:"%tmp[0])
			return 0

static func __get_int64(buffer:StreamPeerBuffer,byte_count:int )->int:
	if buffer.get_available_bytes() < byte_count:
		push_error("Illegal data stream, can not convert to int64.")
		return 0
	else:
		var tmp:= buffer.get_data(byte_count)
		if tmp[0] == OK:
			var buf:=PoolByteArray([2,0,1,0])
			buf.append_array(tmp[1])
			if buf[-1] & 0b10000000 == 0b10000000: #负数
				for _i in range(8 - byte_count):
					buf.append(255)
			else:
				for _i in range(8 - byte_count):
					buf.append(0)
			return bytes2var(buf)
		else:
			push_error("Get data from stream faild, error code:"%tmp[0])
			return 0

static func _put_real(v:float, buffer:StreamPeerBuffer)->void:
	var text:= str(v)
	if text.length() < 4:
		buffer.put_u8(INT_8 + text.length())
		buffer.put_data(text.to_ascii())
	else:
		if ONLY_FLOAT32:
			buffer.put_u8(FLOAT_4)
			buffer.put_float(v)
		else:
			if var2bytes(v).size() == 8:
				buffer.put_u8(FLOAT_4)
				buffer.put_float(v)
			elif text.length() < 8:
				buffer.put_u8(INT_8 + text.length())
				buffer.put_data(text.to_ascii())
			else:
				buffer.put_u8(FLOAT_8)
				buffer.put_double(v)

static func _get_float_from_ascii(buffer:StreamPeerBuffer, byte_count:int )->float:
	if buffer.get_available_bytes() < byte_count:
		push_error("Illegal data stream, can not convert to float.")
		return 0.0
	else:
		var tmp := buffer.get_data(byte_count)
		if tmp[0] == OK:
			return PoolByteArray(tmp[1]).get_string_from_ascii().to_float()
		else:
			push_error("Get data from stream faild, error code:"%tmp[0])
			return 0.0

static func _put_str(v:String, buffer:StreamPeerBuffer)->void:
	buffer.put_u8(STR)
	buffer.put_data(v.to_utf8() if UTF8_STR else v.to_ascii())
	buffer.put_u8(STR)

static func _get_str(buffer:StreamPeerBuffer)->String: 
	var pos:= buffer.get_position()
	var idx:=pos
	var size := 0
	while idx < buffer.data_array.size():
		if buffer.data_array[idx] == STR:
			var tmp := buffer.get_data(size)
			buffer.get_u8()
			if tmp[0] == OK:
				if UTF8_STR:
					return PoolByteArray(tmp[1]).get_string_from_utf8()
				else:
					return PoolByteArray(tmp[1]).get_string_from_ascii()
			else:
				push_error("Get data from stream faild, error code:"%tmp[0])
				return ""
		idx+=1
		size+=1
	push_error("Illegal data stream, can not convert to string.")
	return ""

static func _put_vec2(v:Vector2,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(VECTOR2)
	buffer.put_float(v.x)
	buffer.put_float(v.y)
	
static func _put_rect2(v:Rect2,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(RECT2)
	buffer.put_float(v.position.x)
	buffer.put_float(v.position.y)
	buffer.put_float(v.size.x)
	buffer.put_float(v.size.y)

static func _put_vec3(v:Vector3,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(VECTOR3)
	buffer.put_float(v.x)
	buffer.put_float(v.y)
	buffer.put_float(v.z)
	
static func _put_transform2d(v:Transform2D,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(TRANSFORM2D)
	buffer.put_float(v.x.x)
	buffer.put_float(v.x.y)
	buffer.put_float(v.y.x)
	buffer.put_float(v.y.y)
	buffer.put_float(v.origin.x)
	buffer.put_float(v.origin.y)
	
static func _put_plane(v:Plane,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(PLANE)
	buffer.put_float(v.x)
	buffer.put_float(v.y)
	buffer.put_float(v.z)
	buffer.put_float(v.d)
	
static func _put_quat(v:Quat,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(QUAT)
	buffer.put_float(v.x)
	buffer.put_float(v.y)
	buffer.put_float(v.z)
	buffer.put_float(v.w)
	
static func _put_aabb(v:AABB,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(AABB_)
	buffer.put_float(v.position.x)
	buffer.put_float(v.position.y)
	buffer.put_float(v.position.z)
	buffer.put_float(v.size.x)
	buffer.put_float(v.size.y)
	buffer.put_float(v.size.z)
	
static func _put_basis(v:Basis,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(BASIS)
	buffer.put_float(v.x.x)
	buffer.put_float(v.x.y)
	buffer.put_float(v.x.z)
	buffer.put_float(v.y.x)
	buffer.put_float(v.y.y)
	buffer.put_float(v.y.z)
	buffer.put_float(v.z.x)
	buffer.put_float(v.z.y)
	buffer.put_float(v.z.z)

static func _put_transform(v:Transform,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(TRANSFORM)
	buffer.put_float(v.basis.x.x)
	buffer.put_float(v.basis.x.y)
	buffer.put_float(v.basis.x.z)
	buffer.put_float(v.basis.y.x)
	buffer.put_float(v.basis.y.y)
	buffer.put_float(v.basis.y.z)
	buffer.put_float(v.basis.z.x)
	buffer.put_float(v.basis.z.y)
	buffer.put_float(v.basis.z.z)
	buffer.put_float(v.origin.x)
	buffer.put_float(v.origin.y)
	buffer.put_float(v.origin.z)
	
static func _put_color(v:Color,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(COLOR)
	buffer.put_32(v.to_rgba32())
	
static func _put_node_path(v:NodePath,buffer:StreamPeerBuffer)->void:
	buffer.put_u8(NODE_PATH)
	buffer.put_data(str(v).to_utf8() if UTF8_STR else str(v).to_ascii())
	buffer.put_u8(STR)
	
static func _put_arr(v:Array,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(ARR_BEGIN)
		for e in v:
			_put_var(e, buffer)
		buffer.put_u8(ARR_END)
	else: buffer.put_u8(EMP_ARR)
	
static func _put_raw_arr(v:PoolByteArray,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(RAW_ARR)
		_put_int(v.size(),buffer)
		buffer.put_data(v)
	else: buffer.put_u8(EMPTY_RAW_ARR)

static func _put_int32_arr(v:PoolIntArray,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(INT32_ARR)
		_put_int(v.size(),buffer)
		for e in v:
			buffer.put_32(e)
	else: buffer.put_u8(EMPTY_INT32_ARR)
	
static func _put_float_arr(v:PoolRealArray,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(FLOAT32_ARR)
		_put_int(v.size(),buffer)
		for e in v: buffer.put_float(e)
	else: buffer.put_u8(EMPTY_FLOAT32_ARR)
	
static func _put_str_arr(v:PoolStringArray,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(STR_ARR)
		for e in v: 
			buffer.put_data(e.to_utf8() if UTF8_STR else e.to_ascii())
			buffer.put_u8(STR)
		buffer.put_u8(STR_ARR)
	else : buffer.put_u8(EMPTY_STR_ARR)

static func _put_vec2_arr(v:PoolVector2Array,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(VEC2_ARR)
		_put_int(v.size(),buffer)
		for e in v:
			buffer.put_float(e.x)
			buffer.put_float(e.y)
	else: buffer.put_u8(EMPTY_VEC2_ARR)
	
static func _put_vec3_arr(v:PoolVector3Array,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(VEC3_ARR)
		_put_int(v.size(),buffer)
		for e in v:
			buffer.put_float(e.x)
			buffer.put_float(e.y)
			buffer.put_float(e.z)
	else: buffer.put_u8(EMPTY_VEC3_ARR)
	
static func _put_color_arr(v:PoolColorArray,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(COLOR_ARR)
		_put_int(v.size(),buffer)
		for e in v:
			buffer.put_32((e as Color).to_rgba32())
	else: buffer.put_u8(EMPTY_COLOR_ARR)
		
static func _put_dict(v:Dictionary,buffer:StreamPeerBuffer)->void:
	if v.size():
		buffer.put_u8(DICT_BEGIN)
		for k in v:
			_put_var(k,buffer)
			_put_var(v[k],buffer)
		buffer.put_u8(DICT_END)
	else: buffer.put_u8(EMPTY_DICT)
