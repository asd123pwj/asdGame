using System.IO;
using System.Collections.Generic;
using UnityEngine;
using Newtonsoft.Json;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using System.Linq;

public struct SpriteInfo{
    public string name;
    public string refUrl;
    public string description;
    public string path;
    public string[] tags;
    public string[] sprites;
};

public struct SpritesInfo{
    public string version;
    public Dictionary<string, SpriteInfo> items;
}

public class SpriteManager: BaseClass{
    public SpritesInfo _infos;
    public Dictionary<string, Dictionary<string, Sprite>> _ID_to_subID2Sprites = new();

    public SpriteManager(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    // ---------- mapping ----------
    public Sprite _get_sprite(string ID, string subID="_SingleSprite_"){
        if (ID == "0") return null; // No sprite
        if (subID == "_SingleSprite_") subID = _ID_to_subID2Sprites[ID].Keys.First(); // Some png only have one sprite, its subID is the same as ID
        if (_ID_to_subID2Sprites.ContainsKey(ID)) return _ID_to_subID2Sprites[ID][subID]; // Sprite have been loaded
        return null; // !!! 记得更新默认sprite。Can't find sprite, return missing placeholder
    }

    public SpriteInfo _get_info(string ID){
        return _infos.items[ID];
    }
    public bool _check_loaded(string ID, string subID){
        return _ID_to_subID2Sprites[ID].ContainsKey(subID);
    }
    public bool _check_loaded(string ID){
        if (_infos.items[ID].sprites == null) {
            if (_ID_to_subID2Sprites[ID].Count == 0) 
                return false; // Some png only have one sprite, count = 0 means no loaded
        }
        else {
            foreach(var sprite in _infos.items[ID].sprites)
                if (!_ID_to_subID2Sprites[ID].ContainsKey(sprite)) 
                    return false;
        }
        return true;
    }
    
    public bool _check_exist(string ID){
        return _infos.items.ContainsKey(ID);
    }

    // ---------- config ----------
    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__SpritesInfo_path);
        _infos = JsonConvert.DeserializeObject<SpritesInfo>(jsonText);
        foreach (var tile_kv in _infos.items){
            load_item(tile_kv.Key);
        }
    }

    void load_item(string ID){
        _ID_to_subID2Sprites.Add(ID, new());
        AsyncOperationHandle<Sprite[]> handle = Addressables.LoadAssetAsync<Sprite[]>(_infos.items[ID].path);
        handle.Completed += (operationalHandle) => action_sprite_loaded(operationalHandle, ID);
    }

    void action_sprite_loaded(AsyncOperationHandle<Sprite[]> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) {
            foreach(var sprite in handle.Result){
                _ID_to_subID2Sprites[ID].Add(sprite.name, sprite);
            }
        }
        else 
            Debug.LogError("Failed to load sprite: ID-" + ID);
    }

}
