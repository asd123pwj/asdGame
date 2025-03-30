using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using Newtonsoft.Json;
using System.Reflection;
using System.Linq;
using System;
using Force.DeepCloner;

public class UIClass{
    static Dictionary<string, UIInfo> UIInfos { get { return get_all_UIInfo(); } }
    readonly public static UIInfo UICommandWindow = new(){
        type = "UICommandWindow",
        background_key = "ui_1", 
        sizeDelta = new(800, 400),
        interactions = new List<string>() {
            "UISetTop",
            "UIDrag",
        },
        subUIs = new(){
            new() { type = "UICloseButtom", sizeDelta = new(25, 25)},
            new() { type = "UIResizeButtom", sizeDelta = new(25, 25)},
            new UIInputFieldInfo() { type = "UIInputField", sizeDelta = new(800-25-2*2, 25-2*2),
                    pivot = new(0, 0), anchorMin = new(0, 0), anchorMax = new(0, 0),
                    anchoredPosition = new(2, 2), PixelsPerUnitMultiplier=4,
                    messageID = "COMMAND",
            },
            new UIScrollTextInfo() { type = "UIScrollText", 
                sizeDelta = new(800-25, 400-25*2-12.5f*2), anchoredPosition = new(12.5f, -(25+12.5f)),
                messageID = "COMMAND",
            },
        },
    };
    readonly public static UIInfo UIBackpack = new() {
        type = "UIBackpack",
        // base_type = "UIBase",
        background_key = "ui_1",
        sizeDelta = new(1600, 900), 
        subUIs = new(){
            new() { type = "UICloseButtom" },
            new() { type = "UIResizeButtom" },
        },
        interactions = new List<string>() {
            "UISetTop",
            "UIDrag",
            "UIOpenRightMenu",
            "UIClickCloseRightMenu",
        },
    };
    readonly public static UIInfo UICloseButtom = new() {
        type = "UICloseButtom",
        background_key = "ui_3_16",
        anchorMin = new(1, 1), anchorMax = new(1, 1), pivot = new (1, 1), 
        sizeDelta = new(16, 16),
        interactions = new List<string>() {
            "UIClickClose",
        },
    };
    readonly public static UIInfo UIToggleButtom = new() {
        type = "UIToggleButtom",
        background_key = "Empty",
        sizeDelta = new (120, 40),
        interactions = new List<string>() {
            "UIToggle",
        },
    };
    readonly public static UIInfo UIResizeButtom = new() {
        type = "UIResizeButtom",
        background_key = "ui_4_16",
        anchorMin = new(1, 0), anchorMax = new(1, 0), pivot = new (1, 0), 
        sizeDelta = new (16, 16),
        interactions = new List<string>() {
            "UISetTop",
            "UIResizeScaleConstrait",
        },
    };
    readonly public static UIScrollTextInfo UIScrollText = new(){
        type = "UIScrollText",
        base_type = "UIScrollText",
        prefab_key = "ScrollText",
        background_key = "ui_2", PixelsPerUnitMultiplier=2,
        // sizeDelta = new(0, 0),
        // anchorMin = new(0.01f, 0.01f), anchorMax = new(0.99f, 0.99f), pivot = new (0.5f, 0.5f), 
        enableNavigation = true,
        interactions = new List<string>() {
            "UISetTop",
        },
    };
    readonly public static UIInfo UIImage = new(){
        type = "UIImage", //sizeDelta = new(0, 0),
        // anchorMin = new(0, 0), anchorMax = new(0, 1), pivot = new (0.5f, 0.5f), 
        interactions = new List<string>() {
            "UISetTop",
        },
    };
    readonly public static UIInfo UIRightMenu = new() {
        type = "UIRightMenu",
        background_key = "RightMenu",
        enableNavigation = true,
        sizeDelta = new (300, 200),
        interactions = new List<string>() {
            "UISetTop",
            "UIDeselectClose",
        },
    };
    readonly public static UIInfo UIRightMenuInteractionManager = new() {
        type = "UIRightMenuInteractionManager",
        base_type = "UIRightMenu",
        background_key = "RightMenu",
        enableNavigation = true,
        sizeDelta = new (190 + 40, 230 + 40),
        interactions = new List<string>() {
            "UISetTop",
            // "UIDeselectClose",
        },
        subUIs = new(){
            new UIScrollViewInfo() {
                type = "UIScrollView",
                base_type = "UIScrollView",
                sizeDelta = new (150*1 + 20*0 + 20 + 20, 50*3 + 20*2 + 20 + 20),
                cellSize = new (150, 50),
                constraintCount = 1,
                anchoredPosition = new (20, -20),
                interactions = new List<string>() {
                    "UISetTop",
                },
                items = new(){
                    new() {
                        name = "UIToggleInteraction-UIDrag",
                        type = "UIToggleButtom",
                    },
                    new() {
                        name = "UIToggleSubUI-UICloseButtom",
                        type = "UIToggleButtom",
                    },
                },
                subUIs = new()
            }
        }
    };
    readonly public static UIInfo UIContainer = new() {
        type = "UIContainer",
        background_key = "Empty",
        sizeDelta = new (800, 800),
        interactions = new List<string>() {
            "UISetTop",
            "UIDrop",
        },
    };
    readonly public static UIInputFieldInfo UIInputField = new() {
        type = "UIInputField",
        base_type = "UIInputField",
        prefab_key = "InputField",
        background_key = "ui_2", PixelsPerUnitMultiplier=8, 
        sizeDelta = new (400, 50),
        enableNavigation = true,
        interactions = new List<string>() {
            "UISetTop",
            "UISubmit",
            // "UIDrag",
        }
    };
    readonly public static UIInfo UIKeyboardShortcut = new() {
        type = "UIKeyboardShortcut",
        background_key = "ui_5", 
        sizeDelta = new (800*2, 288*2),
        interactions = new List<string>() {
            "UISetTop",
            "UIDrag",
        },
        subUIs = new(){
            new() { type = "UICloseButtom", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, -7*2) },
            new() { type = "UIResizeButtom", background_key="", sizeDelta = new(16*2, 16*2), anchoredPosition = new(-7*2, 7*2) },
        },
    };
    readonly public static UIScrollViewInfo UIScrollView = new() {
        type = "UIScrollView",
        base_type = "UIScrollView",
        prefab_key = "ScrollView",
        background_key = "Empty",
        // anchorMin = new(0, 1), anchorMax = new(0, 1), pivot = new(0, 1), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
        sizeDelta = new(620, 240),
        constraintCount = 3,
        subUIs = new(){
            new() { type = "UICloseButtom" },
            new() { type = "UIResizeButtom" },
        },
        // subUIs = new Dictionary<string, List<UIInfo>>(){
        //     { "ControlUIs", new (){
        //         new() { type = "UICloseButtom" },
        //         new() { type = "UIResizeButtom" },
        //     } },
        // },
        interactions = new List<string>() {
            "UISetTop",
            "UIDrag",
        },
    };
    readonly public static UIInfo UIThumbnail = new() {
        type = "UIThumbnail",
        base_type = "UIThumbnail",
        interactions = new List<string>() {
            "UISetTop",
            "UIDragInstantiate",
        },
    };

    static Dictionary<string, UIInfo> get_all_UIInfo(){
        FieldInfo[] fields = typeof(UIClass).GetFields(BindingFlags.Static | BindingFlags.Public);
        Dictionary<string, UIInfo> UIInfos = new();

        foreach (var field in fields){
            UIInfo info = (UIInfo)field.GetValue(null);
            if (info == null) continue;
            UIInfo info_ = (UIInfo)field.GetValue(null);
            UIInfos[info_.type] = info_;
        }

        return UIInfos;
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
        UIInfo info_ = info ?? UIInfos[type];
        if (info == null){
            // info_ = UIInfos[type].Copy();
            info_ = UIInfos[type].DeepClone();
        }
        if (info != null){
            info_ = cover_default(info_);
        }
        // info_ = info_.Copy();
        if (info_.name == ""){
            info_.name = info_.type;
        }
        
        return info_;
    }
    static UIInfo cover_default(UIInfo new_UIInfo){
        UIInfo base_UIInfo = UIInfos[new_UIInfo.type];
        UIInfo cover_UIInfo =  inherit(base_UIInfo, new_UIInfo);
        // UIInfo subClass_UIInfo = convert_baseClass_to_subClass(cover_UIInfo, base_UIInfo);
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
        // return new_UIInfo.Copy();
        return new_UIInfo.DeepClone();
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
