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
// using Force.DeepCloner;
using Unity.VisualScripting;

public struct UIStorage{
    public Dictionary<string, UIInfo> fg;
    public List<string> fg_Hier;
}

public class UISaveLoad: BaseClass{
    UIStorage init_UIStorage() => new(){ fg = new(), fg_Hier = new()};

    public bool _save_UI(){
        UIStorage storage = init_UIStorage();
        UIs UIs = _UISys._UIMonitor._get_UIs();
        storage.fg_Hier = UIs.fg_Hier;
        foreach (var UI in UIs.fg.Values){
            UI._update_info();
            UIInfo info_clear = UI._info._prune();
            storage.fg.Add(info_clear.name, info_clear);
        }

        save_UIStorage(storage, _GCfg.__UI_path);
        return true;
    }

    public bool _load_UIs(){
        var UIStorage = load_UIStorage(_GCfg.__UI_path);
        _UISys._UIMonitor._clear_UIs();
        foreach (var UI in UIStorage.fg.Values){
            _UISys._UIDraw._draw(UI.type, UI);
            _UISys._UIMonitor._get_UI_fg(UI.name)._disable();
        }
        foreach (var UI in UIStorage.fg_Hier){
            _UISys._UIMonitor._get_UI_fg(UI)._enable();
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

                UIInfo uiInfo = DeserializeUIInfo(value);
                if (uiInfo != null){
                    storage.fg[key] = uiInfo;
                }
            }
            return storage;
        }
        return new();
    }



    static UIInfo DeserializeUIInfo(JObject jsonObject){
        if (!jsonObject.ContainsKey("info_type")){
            return null;
        }

        string info_type = jsonObject["info_type"].ToString();
        Type type = Type.GetType(info_type);
        if (type == null){
            return null;
        }

        UIInfo info = (UIInfo)jsonObject.ToObject(type);

        if (jsonObject.ContainsKey("subUIs")){
            JArray subUIsArray = (JArray)jsonObject["subUIs"];
            List<UIInfo> subUIs = new();

            foreach (var subUI in subUIsArray){
                JObject subUIObject = (JObject)subUI;
                UIInfo subUIInfo = DeserializeUIInfo(subUIObject);
                if (subUIInfo != null){
                    subUIs.Add(subUIInfo);
                }
            }
            info.subUIs = subUIs; 
        }
        return info;
    }


}
