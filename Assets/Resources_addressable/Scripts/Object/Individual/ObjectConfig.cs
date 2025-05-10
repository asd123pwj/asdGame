using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using Newtonsoft.Json;
using System.Reflection;
using System.Linq;
using System;

public class ObjectConfig{
    // ---------- Name ----------
    [JsonProperty("name", NullValueHandling = NullValueHandling.Ignore)] 
    private string _name;
    private string _name_default { get => class_type; }
    [JsonIgnore] public string name { get => _name ?? _name_default; set => _name = value; }

    [JsonProperty("class_type")] 
    private string _class_type;
    private string _class_type_default { get => base_type; }
    [JsonIgnore] public string class_type { get => _class_type ?? _class_type_default; set => _class_type = value; }

    [JsonProperty("base_type", NullValueHandling = NullValueHandling.Ignore)] 
    private string _base_type;
    private string _base_type_default { get => nameof(ObjectBase); }
    [JsonIgnore] public string base_type { get => _base_type ?? _base_type_default; set => _base_type = value; }

    [JsonProperty("info_type")]
    private string _info_type_fixed { get => GetType().Name; }
    // public string info_type => GetType().AssemblyQualifiedName;
    
    [JsonProperty("prefab_key", NullValueHandling = NullValueHandling.Ignore)] 
    private string _prefab_key;
    [JsonIgnore] public string prefab_key { get => _prefab_key; set => _prefab_key = value; }

    [JsonProperty("sprite_key", NullValueHandling = NullValueHandling.Ignore)] 
    private string _sprite_key;
    [JsonIgnore] public string sprite_key { get => _sprite_key; set => _sprite_key = value; }
    
    [JsonProperty("position", NullValueHandling = NullValueHandling.Ignore)]
    private Vector2? _position;
    private Vector2 _position_default { get => new(0, 0); }
    [JsonIgnore] public Vector2 position { get => _position ?? _position_default; set => _position = value; }

    [JsonProperty("tags", NullValueHandling = NullValueHandling.Ignore)]
    private Dictionary<string, List<string>> _tags;
    private Dictionary<string, List<string>> _tags_default { get => null; }
    [JsonIgnore] public Dictionary<string, List<string>> tags { get => _tags ?? _tags_default; set => _tags = value; }


    // ---------- Tools ----------
    public ObjectConfig _prune(){
        ObjectConfig base_info = ObjectClass._set_default(class_type);
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
                    if (field.FieldType.GetGenericArguments()[0] == typeof(ObjectConfig)){
                        var list = (List<ObjectConfig>)field.GetValue(this).Copy();
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
                        if (innerListType == typeof(ObjectConfig)){
                            var dict = (Dictionary<string, List<ObjectConfig>>)field.GetValue(this);
                            var newDict = new Dictionary<string, List<ObjectConfig>>();

                            foreach (var kvp in dict){
                                var newList = new List<ObjectConfig>();
                                foreach (var info in kvp.Value){
                                    newList.Add(info._prune());
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
        // if (!isItem) return;
        // _anchoredPosition = null;
        // _anchorMax = null;
        // _anchorMin = null;
        // _pivot = null;
        // _localScale = null;
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

