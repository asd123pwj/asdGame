// using UnityEngine;
// using UnityEngine.UI;
// using System.Collections.Generic;
// using UnityEngine.EventSystems;
// using Newtonsoft.Json;
// using System.Reflection;
// using System;

// public class UIInfo{
//     // ---------- Name ----------
//     [JsonProperty("name", NullValueHandling = NullValueHandling.Ignore)] 
//     private string? _name;
//     public string name {
//         get => _name ?? type;
//         set => _name = value;
//     }
//     [JsonProperty("type", NullValueHandling = NullValueHandling.Ignore)] 
//     private string? _type;
//     public string type {
//         get => _type ?? base_type;
//         set => _type = value;
//     }
//     [JsonProperty("base_type", NullValueHandling = NullValueHandling.Ignore)] 
//     private string? _base_type;
//     public string base_type {
//         get => _base_type ?? "UIConfig";
//         set => _base_type = value;
//     }
//     [JsonProperty("prefab_key", NullValueHandling = NullValueHandling.Ignore)] 
//     public string? prefab_key;
//     [JsonProperty("background_key", NullValueHandling = NullValueHandling.Ignore)]
//     public string? background_key;

//     // ---------- Position ----------
//     [JsonProperty("rotation", NullValueHandling = NullValueHandling.Ignore)] 
//     private Quaternion? _rotation;
//     public Quaternion rotation {
//         get => _rotation ?? new(0, 0, 0, 1);
//         set => _rotation = value;
//     }
//     [JsonProperty("localScale", NullValueHandling = NullValueHandling.Ignore)] 
//     private Vector2? _localScale;
//     public Vector2 localScale {
//         get => _localScale ?? new(1, 1);
//         set => _localScale = value;
//     }
//     [JsonProperty("anchorMin", NullValueHandling = NullValueHandling.Ignore)] 
//     private Vector2? _anchorMin;
//     public Vector2 anchorMin {
//         get => _anchorMin ?? new(0, 1);
//         set => _anchorMin = value;
//     }
//     [JsonProperty("anchorMax", NullValueHandling = NullValueHandling.Ignore)] 
//     private Vector2? _anchorMax;
//     public Vector2 anchorMax {
//         get => _anchorMax ?? new(0, 1);
//         set => _anchorMax = value;
//     }
//     [JsonProperty("pivot", NullValueHandling = NullValueHandling.Ignore)] 
//     private Vector2? _pivot;
//     public Vector2 pivot {
//         get => _pivot ?? new(0, 1);
//         set => _pivot = value;
//     }
//     [JsonProperty("anchoredPosition", NullValueHandling = NullValueHandling.Ignore)]
//     private Vector2? _anchoredPosition;
//     public Vector2 anchoredPosition {
//         get => _anchoredPosition ?? new(0, 0);
//         set => _anchoredPosition = value;
//     }
//     [JsonProperty("sizeDelta")]
//     public Vector2 sizeDelta;


//     // ---------- Interaction ----------
//     [JsonProperty("enableNavigation", NullValueHandling = NullValueHandling.Ignore)]
//     private bool? _enableNavigation;
//     public bool enableNavigation {
//         get => _enableNavigation ?? false;
//         set => _enableNavigation = value;
//     }


//     // ---------- UI ----------
//     [JsonProperty("subUIs", NullValueHandling = NullValueHandling.Ignore)]
//     public List<UIInfo>? subUIInfos; 
//     [JsonProperty("containerUIs", NullValueHandling = NullValueHandling.Ignore)]
//     public List<UIInfo>? containerUIInfos;
//     [JsonProperty("interactions", NullValueHandling = NullValueHandling.Ignore)]
//     public List<string>? interactions;

// }


// public struct UIInfo2{
//     // ---------- Name ----------
//     public string name;
//     public string type;
//     public string base_type;
//     public string prefab_key;
//     public string background_key;

//     // ---------- Position ----------
//     public Quaternion rotation;
//     public Vector2 anchorMin;
//     public Vector2 anchorMax;
//     public Vector2 pivot;
//     public Vector2 anchoredPosition;
//     public Vector2 sizeDelta;
//     public Vector2 localScale;

//     // ---------- Interaction ----------
//     public bool enableNavigation;

//     // ---------- UI ----------
//     public List<UIInfo> subUIInfos;
//     public List<UIInfo> containerUIInfos;
//     public List<string> interactions;
// }

// public class UIClass{
//     public static Dictionary<string, UIInfo> _UIInfos { get { return get_all_UIInfo(); } }
//     readonly public static UIInfo UIBackpack = new() {
//         name = "",
//         type = "UIBackpack",
//         base_type = "UIConfig",
//         background_key = "Default",
//         anchorMin = new(0, 1), anchorMax = new(0, 1), pivot = new (0, 1), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
//         sizeDelta = new(1600, 900), 
//         // subUIs = new List<string>() {
//         //     "UICloseButtom", 
//         //     "UIResizeButtom"
//         // },
//         subUIInfos = new List<UIInfo>(){
//             new() { type = "UICloseButtom" },
//             new() { type = "UIResizeButtom" },
//         },
//         interactions = new List<string>() {
//             "UISetTop",
//             "UIDrag",
//             "UIOpenRightMenu"
//         },
//     };
//     readonly public static UIInfo UICloseButtom = new() {
//         name = "",
//         type = "UICloseButtom",
//         base_type = "UIConfig",
//         background_key = "Close",
//         anchorMin = new(1, 1), anchorMax = new(1, 1), pivot = new (1, 1), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
//         sizeDelta = new(50, 50),
//         interactions = new List<string>() {
//             "UIClickClose",
//         },
//     };
//     readonly public static UIInfo UIResizeButtom = new() {
//         name = "",
//         type = "UIResizeButtom",
//         base_type = "UIConfig",
//         background_key = "ResizeButtom",
//         anchorMin = new(1, 0), anchorMax = new(1, 0), pivot = new (1, 0), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
//         sizeDelta = new (50, 50),
//         interactions = new List<string>() {
//             "UISetTop",
//             "UIResizeScaleConstrait",
//         },
//     };
//     readonly public static UIInfo UIRightMenu = new() {
//         name = "",
//         type = "UIRightMenu",
//         base_type = "UIConfig",
//         background_key = "RightMenu",
//         anchorMin = new(0, 1), anchorMax = new(0, 1), pivot = new (0, 1), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
//         enableNavigation = true,
//         sizeDelta = new (300, 200),
//         interactions = new List<string>() {
//             "UISetTop",
//             "UIDeselectClose",
//         },
//     };
//     readonly public static UIInfo UIContainer = new() {
//         name = "",
//         type = "UIContainer",
//         base_type = "UIConfig",
//         background_key = "Empty",
//         anchorMin = new(0, 1), anchorMax = new(0, 1), pivot = new (0, 1), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
//         sizeDelta = new (800, 800),
//         interactions = new List<string>() {
//             "UISetTop",
//             "UIDrop",
//             // "UIDrag",
//         },
//     };
//     readonly public static UIInfo UIScrollView = new() {
//         name = "",
//         type = "UIScrollView",
//         base_type = "UIScrollView",
//         prefab_key = "ScrollView",
//         background_key = "Empty",
//         anchorMin = new(0, 1), anchorMax = new(0, 1), pivot = new(0, 1), localScale = new(1, 1), rotation = new(0, 0, 0, 1),
//         sizeDelta = new(620, 240),
//         subUIInfos = new List<UIInfo>(){
//             new() { type = "UICloseButtom" },
//             new() { type = "UIResizeButtom" },
//         },
//         containerUIInfos = new List<UIInfo>(){
//             new() { type = "UICloseButtom" },
//         },
//         interactions = new List<string>() {
//             "UISetTop",
//             "UIDrag",
//         },
//     };

//     static Dictionary<string, UIInfo> get_all_UIInfo(){
//         FieldInfo[] fields = typeof(UIClass).GetFields(BindingFlags.Static | BindingFlags.Public);
//         Dictionary<string, UIInfo> UIInfos = new();

//         foreach (var field in fields){
//             if (field.FieldType == typeof(UIInfo)){
//                 UIInfo? info = (UIInfo)field.GetValue(null);
//                 if (info == null) continue;
//                 UIInfo info_ = (UIInfo)field.GetValue(null);
//                 UIInfos[info_.type] = info_;
//             }
//         }

//         return UIInfos;
//     }

//     public static UIInfo _set_default(string type, string name){
//         UIInfo info = _set_default(type);
//         if (name != ""){
//             info.name = name;
//         }
//         return info;
//     }
//     public static UIInfo _set_default(Type type, UIInfo? info = null){
//         return _set_default(type.Name, info);
//     }
//     public static UIInfo _set_default(string type, UIInfo? info=null){
//         UIInfo info_ = info ?? _UIInfos[type];
//         if (info == null){
//             info_ = _UIInfos[type].Copy();
//         }
//         if (info != null){
//             info_ = cover_default(info_);
//         }
//         // info_ = info_.Copy();
//         if (info_.name == ""){
//             info_.name = info_.type;
//         }
//         return info_;
//     }
//     static UIInfo cover_default(UIInfo new_UIInfo){
//         UIInfo base_UIInfo = _UIInfos[new_UIInfo.type];
//         return _inherit_struct(base_UIInfo, new_UIInfo);
    
//         // foreach (var field in typeof(UIInfo).GetFields()){
//         //     var base_value = field.GetValue(base_UIInfo);
//         //     var new_value = field.GetValue(new_UIInfo);
//         //     if (new_value == null || new_value.Equals(Activator.CreateInstance(field.FieldType))){
//         //         field.SetValue(new_UIInfo, base_value);
//         //     }
//         // }
//         // return new_UIInfo.Copy();
//     }

//     public static T _inherit_struct<T>(T baseStruct, T newStruct) where T : struct{
//         Type type = typeof(T);
//         // object tmp_struct = newStruct;
//         foreach (var field in type.GetFields()){
//             var baseValue = field.GetValue(baseStruct);
//             var newValue = field.GetValue(newStruct);
//             if (_check_default_value(newValue, field.FieldType)){
//                 field.SetValueDirect(__makeref(newStruct), baseValue);
//             }
//         }
//         return newStruct.Copy();
//     }
//     public static bool _check_default_value(object value, Type field_type){
//         if (field_type == typeof(string)){
//             return string.IsNullOrEmpty((string)value);
//         }
//         if (field_type.IsValueType){
//             return value.Equals(Activator.CreateInstance(field_type));
//         }
//         return value == null;
//     }

// }
