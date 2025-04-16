using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using Newtonsoft.Json;
using System.Reflection;
using System.Linq;
using System;
// using Force.DeepCloner;

public class UIClass{
    public static Dictionary<string, UIInfo> _UIInfos = new();

    public UIClass(){
        new UIClassCommon();
        new UIClassInput();
        new UIClassOutput();
        new UIClassImage();
        new UIClassRightMenu();
        new UIClassContainer();
        new UIClassInteract();

        new UIClassAttributeManager();

        new UIClassBackpack();
        new UIClassCommandWindow();
        new UIClassKeyboardShortcut();

    }

    public static void _add(string name, UIInfo info){
        _UIInfos[name] = info;
    }

    public static UIInfo _set_default(string type, string name){
        UIInfo info = _set_default(type);
        if (name != ""){
            info.name = name;
        }
        return info;
    }
    public static UIInfo _set_default(Type type, UIInfo info = null){
        return _set_default(type.Name, info);
    }
    public static UIInfo _set_default(string type, UIInfo info=null){
        UIInfo info_ = info ?? _UIInfos[type];
        if (info == null){
            info_ = _UIInfos[type];
        } 
        else {
            info_ = cover_default(info_);
        }
        if (info_.name == ""){
            info_.name = info_.type;
        }
        
        return info_.Copy();
    }
    static UIInfo cover_default(UIInfo new_UIInfo){
        UIInfo base_UIInfo = _UIInfos[new_UIInfo.type];
        UIInfo cover_UIInfo =  inherit(base_UIInfo, new_UIInfo);
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

    static UIInfo convert_baseClass_to_subClass(UIInfo base_UIInfo, UIInfo sub_UIInfo){
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
