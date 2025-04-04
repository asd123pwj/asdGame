using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using Newtonsoft.Json;
using System.Reflection;
using System.Linq;
using System;

public class UIInfo{
    // ---------- Name ----------
    [JsonProperty("name", NullValueHandling = NullValueHandling.Ignore)] 
    private string _name;
    private string _name_default { get => type; }
    [JsonIgnore] public string name {
        get => _name ?? _name_default;
        set => _name = value;
    }

    [JsonProperty("type")] 
    private string _type_fixed;
    private string _type_default { get => base_type; }
    [JsonIgnore] public string type {
        get => _type_fixed ?? _type_default;
        set => _type_fixed = value;
    }

    [JsonProperty("base_type", NullValueHandling = NullValueHandling.Ignore)] 
    private string _base_type;
    private string _base_type_default { get => "UIBase"; }
    [JsonIgnore] public string base_type { get => _base_type ?? _base_type_default; set => _base_type = value; }

    [JsonProperty("info_type")]
    private string _info_type_fixed { get => GetType().Name; }
    // public string info_type => GetType().AssemblyQualifiedName;
    
    [JsonProperty("prefab_key", NullValueHandling = NullValueHandling.Ignore)] 
    private string _prefab_key;
    [JsonIgnore] public string prefab_key { get => _prefab_key; set => _prefab_key = value; }

    // ---------- Image ---------- //
    [JsonProperty("background_key", NullValueHandling = NullValueHandling.Ignore)]
    private string _background_key;
    private string _background_key_default { get => ""; }
    [JsonIgnore] public string background_key { get => _background_key ?? _background_key_default; set => _background_key = value; }

    [JsonProperty("PixelsPerUnitMultiplier", NullValueHandling = NullValueHandling.Ignore)]
    private float? _PixelsPerUnitMultiplier;
    private float _PixelsPerUnitMultiplier_default = 1;
    [JsonIgnore] public float PixelsPerUnitMultiplier { get => _PixelsPerUnitMultiplier ?? _PixelsPerUnitMultiplier_default; set => _PixelsPerUnitMultiplier = value; }
    [JsonIgnore] public bool check_PixelsPerUnitMultiplier { get => _PixelsPerUnitMultiplier != null; }

    // ---------- Position ----------
    [JsonProperty("rotation", NullValueHandling = NullValueHandling.Ignore)] 
    private Quaternion? _rotation;
    private Quaternion _rotation_default { get => new(0, 0, 0, 1); }
    [JsonIgnore] public Quaternion rotation {
        get => _rotation ?? _rotation_default;
        set => _rotation = value;
    }

    [JsonProperty("localScale", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _localScale;
    private Vector2 _localScale_default { get => new(1, 1); }
    [JsonIgnore] public Vector2 localScale {
        get => _localScale ?? _localScale_default;
        set => _localScale = value;
    }

    [JsonProperty("anchorMin", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _anchorMin;
    private Vector2 _anchorMin_default { get => new(0, 1); }
    [JsonIgnore] public Vector2 anchorMin {
        get => _anchorMin ?? _anchorMin_default;
        set => _anchorMin = value;
    }

    [JsonProperty("anchorMax", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _anchorMax;
    private Vector2 _anchorMax_default { get => new(0, 1); }
    [JsonIgnore] public Vector2 anchorMax {
        get => _anchorMax ?? _anchorMax_default;
        set => _anchorMax = value;
    }

    [JsonProperty("pivot", NullValueHandling = NullValueHandling.Ignore)] 
    private Vector2? _pivot;
    private Vector2 _pivot_default { get => new(0, 1); }
    [JsonIgnore] public Vector2 pivot {
        get => _pivot ?? _pivot_default;
        set => _pivot = value;
    }

    [JsonProperty("anchoredPosition", NullValueHandling = NullValueHandling.Ignore)]
    private Vector2? _anchoredPosition;
    private Vector2 _anchoredPosition_default { get => new(0, 0); }
    [JsonIgnore] public Vector2 anchoredPosition {
        get => _anchoredPosition ?? _anchoredPosition_default;
        set => _anchoredPosition = value;
    }

    [JsonProperty("sizeDelta", NullValueHandling = NullValueHandling.Ignore)]
    private Vector2? _sizeDelta;
    private Vector2 _sizeDelta_default { get => new(50, 50); }
    [JsonIgnore] public Vector2 sizeDelta {
        get => _sizeDelta ?? _sizeDelta_default;
        set => _sizeDelta = value;
    }   


    // ---------- Interaction ----------
    [JsonProperty("enableNavigation", NullValueHandling = NullValueHandling.Ignore)]
    private bool? _enableNavigation;
    private bool _enableNavigation_default { get => false; }
    [JsonIgnore] public bool enableNavigation {
        get => _enableNavigation ?? _enableNavigation_default;
        set => _enableNavigation = value;
    }

    [JsonProperty("messageID", NullValueHandling = NullValueHandling.Ignore)]
    private string _messageID;
    private string _messageID_default { get => ""; }
    [JsonIgnore] public string messageID {
        get => _messageID ?? _messageID_default;
        set => _messageID = value;
    }

    // ---------- Status ----------
    [JsonIgnore] public bool isItem = false;
    [JsonProperty("item_index", NullValueHandling = NullValueHandling.Ignore)]
    private int? _item_index;
    private int _item_index_default { get => -1; }
    [JsonIgnore] public int item_index {
        get => _item_index ?? _item_index_default;
        set => _item_index = value;
    }
    
    [JsonProperty("attribute", NullValueHandling = NullValueHandling.Ignore)]
    private Dictionary<string, DynamicValue> _attribute;
    private Dictionary<string, DynamicValue> _attribute_default { get => null; }
    [JsonIgnore] public Dictionary<string, DynamicValue> attributes {
        get => _attribute ?? _attribute_default;
        set => _attribute = value;
    }

    // ---------- UI ----------
    [JsonProperty("subUIs", NullValueHandling = NullValueHandling.Ignore)]
    private List<UIInfo> _subUIs; 
    [JsonIgnore] public List<UIInfo> subUIs { get => _subUIs; set => _subUIs = value; }

    [JsonProperty("interactions", NullValueHandling = NullValueHandling.Ignore)]
    private List<string> _interactions;
    [JsonIgnore] public List<string> interactions { get => _interactions; set => _interactions = value; }

    [JsonProperty("rightMenu_name", NullValueHandling = NullValueHandling.Ignore)]
    private string _rightMenu_name;
    private string _rightMenu_name_default { get => "UIRightMenuInteractionManager"; }
    [JsonIgnore] public string rightMenu_name {
        get => _rightMenu_name ?? _rightMenu_name_default;
        set => _rightMenu_name = value;
    }
    
    // ---------- Tools ----------
    public UIInfo _prune(){
        UIInfo base_info = UIClass._set_default(type);
        prune_as_item();

        // loop for prune baseClass
        Type typ = GetType();
        Type typ_base = base_info.GetType();
        while(typ != null && typ != typeof(object)){
            FieldInfo[] fields = typ.GetFields(BindingFlags.NonPublic | BindingFlags.Instance);
            foreach (var field in fields){
                if (field.Name.EndsWith("_fixed")) continue;
                FieldInfo base_field = typ_base.GetField(field.Name, BindingFlags.NonPublic | BindingFlags.Instance);
                
                var base_value = base_field.GetValue(base_info);
                var current_value = field.GetValue(this);
                
                // Prune Field with default value of their type
                if (current_value == null || check_equal(current_value, base_value)){
                    field.SetValue(base_info, null);
                    continue;
                }

                // Prune Field with default value of baseClass
                PropertyInfo  defaultField = typ.GetProperty(field.Name + "_default", BindingFlags.NonPublic | BindingFlags.Instance);
                if (defaultField != null) {
                    var default_value = defaultField.GetValue(this);
                    if(check_equal(current_value, default_value)){
                        field.SetValue(base_info, null);
                        continue;
                    }
                }

                if (field.FieldType.IsGenericType && field.FieldType.GetGenericTypeDefinition() == typeof(List<>)){
                    // Purne sub UIInfos in List<UIInfo>
                    if (field.FieldType.GetGenericArguments()[0] == typeof(UIInfo)){
                        var list = (List<UIInfo>)field.GetValue(this).Copy();
                        for (int i = 0; i < list.Count; i++){
                            list[i] = list[i]._prune();
                        }
                        field.SetValue(base_info, list);
                        continue;
                    }
                }

                if (field.FieldType.IsGenericType && field.FieldType.GetGenericTypeDefinition() == typeof(Dictionary<,>)){
                    // Purne sub UIInfos in Dictionary<string, List<UIInfo>>
                    var keyType = field.FieldType.GetGenericArguments()[0];
                    var valueType = field.FieldType.GetGenericArguments()[1];

                    if (keyType == typeof(string) && valueType.IsGenericType && valueType.GetGenericTypeDefinition() == typeof(List<>)){
                        var innerListType = valueType.GetGenericArguments()[0];
                        if (innerListType == typeof(UIInfo)){
                            var dict = (Dictionary<string, List<UIInfo>>)field.GetValue(this);
                            var newDict = new Dictionary<string, List<UIInfo>>();

                            foreach (var kvp in dict){
                                var newList = new List<UIInfo>();
                                foreach (var uiInfo in kvp.Value){
                                    newList.Add(uiInfo._prune());
                                }
                                newDict[kvp.Key] = newList;
                            }
                            field.SetValue(base_info, newDict);
                            continue;
                        }
                    }
                }


                field.SetValue(base_info, current_value);

            }
            typ = typ.BaseType;
            typ_base = typ_base.BaseType;
        }
        return base_info;
    }

    void prune_as_item(){
        if (!isItem) return;
        _anchoredPosition = null;
        _anchorMax = null;
        _anchorMin = null;
        _pivot = null;
        _localScale = null;
    }

    bool check_equal(object current_value, object base_value){
        // List<string>
        if (current_value is IEnumerable<string> current_list && base_value is IEnumerable<string> base_list){
            return current_list.SequenceEqual(base_list);
        }
        if (current_value is RectOffset current_rect && base_value is RectOffset base_rect){
            if (current_rect == null || base_rect == null){
                return (current_rect == null) && ( base_rect == null);
            }

            return current_rect.left == base_rect.left &&
                   current_rect.right == base_rect.right &&
                   current_rect.top == base_rect.top &&
                   current_rect.bottom == base_rect.bottom;
        }
        return current_value.Equals(base_value);
    }
}

