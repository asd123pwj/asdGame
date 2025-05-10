using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using Newtonsoft.Json;
using System.Reflection;
using System.Linq;
using System;
// using Force.DeepCloner;

public class ObjectClass{
    public static Dictionary<string, ObjectConfig> _ObjCfgs = new();

    public ObjectClass(){
        new ObjectClassBasic();
    }

    public static void _add(string name, ObjectConfig info){
        _ObjCfgs[name] = info;
    }

    public static ObjectConfig _set_default(string type, string name){
        ObjectConfig info = _set_default(type);
        if (name != ""){
            info.name = name;
        }
        return info;
    }
    public static ObjectConfig _set_default(Type type, ObjectConfig info = null){
        return _set_default(type.Name, info);
    }
    public static ObjectConfig _set_default(string type, ObjectConfig info=null){
        ObjectConfig info_ = info ?? _ObjCfgs[type];
        if (info == null){
            info_ = _ObjCfgs[type];
        } 
        else {
            info_ = cover_default(info_);
        }
        if (info_.name == ""){
            info_.name = info_.class_type;
        }
        
        return info_.Copy();
    }
    static ObjectConfig cover_default(ObjectConfig new_UIInfo){
        ObjectConfig base_UIInfo = _ObjCfgs[new_UIInfo.class_type];
        ObjectConfig cover_UIInfo =  inherit(base_UIInfo, new_UIInfo);
        return cover_UIInfo;
    }

    static T inherit<T>(T base_UIInfo, T new_UIInfo){
        Type type = base_UIInfo.GetType();
        while (type != typeof(object)){
            var fields = type.GetFields(BindingFlags.NonPublic | BindingFlags.Instance);
            foreach (var field in fields){
                var baseValue = field.GetValue(base_UIInfo);
                var newValue = field.GetValue(new_UIInfo);
                if (newValue == null){
                    field.SetValueDirect(__makeref(new_UIInfo), baseValue);
                }
            }
            type = type.BaseType;
        }
        return new_UIInfo;
    }

    static ObjectConfig convert_baseClass_to_subClass(ObjectConfig base_UIInfo, ObjectConfig sub_UIInfo){
        if (sub_UIInfo == null || (base_UIInfo.GetType() == sub_UIInfo.GetType()))
            return base_UIInfo;
        OverwriteBaseValuesToSubClass(base_UIInfo, sub_UIInfo);
        return sub_UIInfo;
    }
    static void OverwriteBaseValuesToSubClass<TBase, TSub>(TBase baseObject, TSub subObject) where TBase : class where TSub : TBase{
        if (baseObject == null){
            throw new ArgumentNullException(nameof(baseObject));
        }

        if (subObject == null){
            throw new ArgumentNullException(nameof(subObject));
        }

        Type baseType = typeof(TBase);
        Type subType = typeof(TSub);

        // Copy all fields from baseObject to subObject
        foreach (var field in baseType.GetFields(BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Public)){
            var subField = subType.GetField(field.Name, BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Public);
            if (subField != null){
                var value = field.GetValue(baseObject);
                subField.SetValue(subObject, value);
            }
        }

        // Copy all properties from baseObject to subObject
        foreach (var prop in baseType.GetProperties(BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Public)){
            var subProp = subType.GetProperty(prop.Name, BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Public);
            if (subProp != null && subProp.CanWrite){
                var value = prop.GetValue(baseObject);
                subProp.SetValue(subObject, value);
            }
        }
    }
}
