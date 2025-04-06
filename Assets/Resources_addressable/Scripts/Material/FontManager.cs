using System.Collections.Generic;
using System.IO;
using Newtonsoft.Json;
using UnityEngine;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using TMPro;

public struct FontInfo{
    public string font;
    public string fontTMP;
}

public struct FontsInfo{
    public string version;
    public Dictionary<string, FontInfo> items;
}

public class FontManager: BaseClass{
    public FontsInfo _infos;
    public Dictionary<string, AsyncOperationHandle<Font>> _name2font = new();
    public Dictionary<string, AsyncOperationHandle<TMP_FontAsset>> _name2fontTMP = new();

    public FontManager(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }

    public bool _check_loaded(string ID){
        return _name2font.ContainsKey(ID);
    }

    public Font _get_font(string ID){
        return _name2font[ID].Result;
    }

    public TMP_FontAsset _get_fontTMP(string ID){
        return _name2fontTMP[ID].Result;
    }

    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__FontsInfo_path);
        _infos = JsonConvert.DeserializeObject<FontsInfo>(jsonText);
        foreach (var object_kv in _infos.items){
            load_font(object_kv.Key);
            load_fontTMP(object_kv.Key);
        }
    }

    void load_font(string ID){
        string path = _infos.items[ID].font;
        AsyncOperationHandle<Font> handle = Addressables.LoadAssetAsync<Font>(path);
        handle.Completed += (operationHandle) => action_font_loaded(operationHandle, ID);
    }
    void action_font_loaded(AsyncOperationHandle<Font> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) _name2font.Add(ID, handle);
        else Debug.LogError("Failed to load font: " + handle.DebugName);
    }

    void load_fontTMP(string ID){
        string path = _infos.items[ID].fontTMP;
        AsyncOperationHandle<TMP_FontAsset> handle = Addressables.LoadAssetAsync<TMP_FontAsset>(path);
        handle.Completed += (operationHandle) => action_fontTMP_loaded(operationHandle, ID);
    }
    void action_fontTMP_loaded(AsyncOperationHandle<TMP_FontAsset> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) _name2fontTMP.Add(ID, handle);
        else Debug.LogError("Failed to load fontTMP: " + handle.DebugName);
    }

}
