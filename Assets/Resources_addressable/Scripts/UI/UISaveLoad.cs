using UnityEngine;
using UnityEngine.UI;
using System.Collections.Generic;
using UnityEngine.EventSystems;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.IO;
using System;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;
using System.Linq;

public struct UIStorage{
    public Dictionary<string, UIInfo> fg;
    public List<string> fg_Hier;
}

public class UISaveLoad{
    // ---------- UI Tool ----------
    GameConfigs _GCfg;
    UISystem _UISys { get { return _GCfg._UISys; } }
    // ---------- Sub Tools ----------
    // ---------- Status ----------

    public UISaveLoad(GameConfigs GCfg){
        _GCfg = GCfg;
    }

    UIStorage init_UIStorage(){
        return new(){
            fg = new(),
            fg_Hier = new()
        };
    }

    public bool _save_UI(){
        UIs UIs = _UISys._UIMonitor._get_UIs().Copy();
        UIStorage storage = init_UIStorage();
        // Dictionary<string, UIInfo> UIInfos = new();
        foreach (var UI in UIs.fg.Values){
            UI._update_info();
            UIInfo info_clear = UI._info._prune();
            // UIs.fg[info_clear.name] = info_clear;
            storage.fg.Add(info_clear.name, info_clear);
        }
        storage.fg_Hier = UIs.fg_Hier;
        save_UIStorage(storage, _GCfg.__UI_path);
        return true;
    }

    public bool _load_UIs(){
        var UIStorage = load_UIStorage(_GCfg.__UI_path);
        _UISys._UIMonitor._clear_UIs();
        foreach (var UI in UIStorage.fg.Values){
            _UISys._UIDraw._draw(UI.type, UI);
            _UISys._UIMonitor._get_UI(UI.name)._disable();
        }
        foreach (var UI in UIStorage.fg_Hier){
            _UISys._UIMonitor._get_UI(UI)._enable();
        }
        return true;
    }

    static void save_UIStorage(UIStorage UIStorage, string save_path){
        JsonSerializerSettings settings = new JsonSerializerSettings{
            ReferenceLoopHandling = ReferenceLoopHandling.Ignore,
            Formatting = Formatting.Indented,
            Converters = new List<JsonConverter> { new Vector2Converter() }
        };
        string json = JsonConvert.SerializeObject(UIStorage, settings);
        File.WriteAllText(save_path, json);
    }

    // static UIStorage load_UIStorage(string load_path){
    //     // if (File.Exists(load_path)){
    //     //     string json = File.ReadAllText(load_path);
    //     //     UIStorage UIStorage = JsonConvert.DeserializeObject<UIStorage>(json);
    //     //     return UIStorage;
    //     // }
    //     if (File.Exists(load_path)){
    //         string json = File.ReadAllText(load_path);
    //         JsonSerializerSettings settings = new JsonSerializerSettings{
    //             TypeNameHandling = TypeNameHandling.Auto,
    //             Converters = new List<JsonConverter> { new UIInfoConverter() }
    //         };
    //         UIStorage UIStorage = JsonConvert.DeserializeObject<UIStorage>(json, settings);
    //         return UIStorage;
    //     }
    //     return new();
    // }

    static UIStorage load_UIStorage(string loadPath){
        if (File.Exists(loadPath)){
            string json = File.ReadAllText(loadPath);
            JObject jsonObject = JObject.Parse(json);

            UIStorage storage = new UIStorage{
                fg = new Dictionary<string, UIInfo>(),
                fg_Hier = jsonObject["fg_Hier"].ToObject<List<string>>()
            };

            foreach (var item in jsonObject["fg"]){
                string key = item.Path.Split('.').Last();
                JObject value = (JObject)item.First;

                string typeName = value["info_type"].ToString();
                Type type = Type.GetType(typeName);
                if (type != null){
                    UIInfo uiInfo = (UIInfo)value.ToObject(type);
                    storage.fg[key] = uiInfo;
                }
            }

            return storage;
        }

        return new();
    }

}
