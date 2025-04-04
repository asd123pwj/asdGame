using UnityEngine;
using System;
using Newtonsoft.Json;

public class DynamicValue{ // Thank Deepseek
    [JsonProperty("type", NullValueHandling = NullValueHandling.Ignore)]  
    private string type;  
    [JsonProperty("value", NullValueHandling = NullValueHandling.Ignore)] 
    private object value; 

    // 支持的公共类型（可根据需要扩展）
    public enum ValueType { Bool, Int, Float, String, Vector2, Vector3, Color }

    // 构造函数
    
    public static implicit operator DynamicValue(int value) => new(value);
    public static implicit operator DynamicValue(float value) => new(value);
    public static implicit operator DynamicValue(bool value) => new(value);
    public static implicit operator DynamicValue(string value) => new(value);
    public static implicit operator DynamicValue(Vector2 value) => new(value);
    public static implicit operator DynamicValue(Vector3 value) => new(value);
    public static implicit operator DynamicValue(Color value) => new(value);
    public DynamicValue(object value){
        set(value);
    }

    // 设置值并自动检测类型
    public void set(object value){
        if (value == null){
            type = ValueType.String.ToString();
            this.value = null;
            return;
        }

        this.value = value;
        type = value switch{
            bool _ => ValueType.Bool.ToString(),
            int _ => ValueType.Int.ToString(),
            float _ => ValueType.Float.ToString(),
            double _ => ValueType.Float.ToString(), // 自动转为float
            string _ => ValueType.String.ToString(),
            Vector2 _ => ValueType.Vector2.ToString(),
            Vector3 _ => ValueType.Vector3.ToString(),
            Color _ => ValueType.Color.ToString(),
            _ => throw new ArgumentException($"Unsupported type: {value.GetType()}")
        };
    }

    // 获取原始object值
    public object get() => value;

    // 类型安全获取方法
    public T get<T>(){
        try{
            if (value is T typedValue)
                return typedValue;

            // 特殊处理：数字类型转换
            if (typeof(T) == typeof(float) && value is int intVal)
                return (T)(object)Convert.ToSingle(intVal);

            if (typeof(T) == typeof(int) && value is float floatVal)
                return (T)(object)Convert.ToInt32(floatVal);

            return (T)Convert.ChangeType(value, typeof(T));
        }
        catch (Exception e){
            throw new InvalidCastException($"Cannot convert {type} to {typeof(T).Name}", e);
        }
    }

    // 安全尝试获取值
    public bool tryGet<T>(out T result){
        try{
            result = get<T>();
            return true;
        }
        catch{
            result = default;
            return false;
        }
    }

    // 编辑器友好显示
    public override string ToString(){
        return $"[{type}] {value}";
    }
}