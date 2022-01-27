
# GUS - Godot Universal Serializer - Godot的通用序列化器 - V1.03

![Image text](https://github.com/Daylily-Zeleen/GUS-Godot-Universal-Serializer/blob/main/icon.png)

[中文文档](https://github.com/Daylily-Zeleen/GUS-Godot-Universal-Serializer/blob/main/README_zh_cn.md) <- 点击这里。

A Godot's universal serializer for size optimization.    
Support all data types except Object and RID in Godot 3.x.

# Feature:
  1. Without losing type information. Need not type detection and forced typce conversion in Cross end transfer，just like local parameter transfer.
  2. Integer and float are variable length serialization.
  3. The serialized data size is smaller than JSON text to utf8 and the native serialization method (var2bytes ()).GUS is especially suitable for the serialization of structured small dat transfer in multiplayer games.You can call GUS._test() to view the data size comparison after serialization in these three way.

# How to use:
  1. Modify the configuration definition constants at the beginning of the script as required.
  2. Pass variable which without Object and Eid into GUS.to_bytes() and gets the serialized data for sending through any network peer.
  3. After the remote network peer obtains the serialized data, passe it into GUS.to_var () to get the same variable as before serialization.
  
      Additional: The obtained serialized data can be passed into GUS.get_ pretty_ json_text(), a beautified JSON text will be return, which is for printing and display when debugging.


# Be careful:
  1. The configuration definitions of cross end applications should keep the same.
  2. Array and Dictionary should not contain Object or RID.
  3. Because of implementing by GDScript, although the serialized data size is better, it will cost lot of time when serialization and deserialization large array(both Array and PoolArray), you should avoid to use GUS in time sensitive case.
	
# TODO:
  1. Write GUS 2.0 applicable for godot4 X .
  2. Write as C++ addons to solve the problem of low efficiency of large array serialization.

# Edit history:
  - January 21, 2022: Daylily-Zeleen - 735170336@qq.com - v1. 03:
    
    In order to setting default value by string facilitatly in some special specific occasions, I made some change as below: 
  
	  1. Modify and add identification code for Boolean.  
	  2. Modify identification code for Boolean Array and Dictionary.  
	
    For example, the default values of GUS encoded binary fields which stored in the database can be set as '[]', '{}', 'T' or 't', 'F' or 'f', which mean that empty Array, empty Dictionary, True and False .

  - January 19, 2022: Daylily-Zeleen - 735170336@qq.com - v1. 02:
  
	1. Fix empty Array deserialize error.
	2. Fix empty Dictionary deserialize error.
	3. Optimize empty pool arrays serialized size.

  - January 19, 2022: Daylily-Zeleen - 735170336@qq.com - v1. 01:
  
	1. Add type detection assert to GUS.to_bytes() for debugging purposes.
	2. Add 'null' and 'bool' into GUS._test().
	3. Add "How to use".
	4. Add descriptions of common methods and test methods.
	5. Optimize the text for push_error() when deserialize(GUS.to_var()) faild.

  - January 18, 2022: Daylily-Zeleen - 735170336@qq.com - v1. 0:
  
  	Initial submit.
