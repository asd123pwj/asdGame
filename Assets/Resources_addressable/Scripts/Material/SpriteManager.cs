using System.IO;
using System.Collections.Generic;
using UnityEngine;
using Newtonsoft.Json;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;

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
    public Dictionary<string, Dictionary<string, AsyncOperationHandle<Sprite>>> _ID_to_subID2Sprites = new();

    public SpriteManager(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    // ---------- mapping ----------
    public Sprite _get_sprite(string ID, string subID){
        if (ID == "0") return null; // No sprite
        if (_ID_to_subID2Sprites.ContainsKey(ID)) return _ID_to_subID2Sprites[ID][subID].Result; // Sprite have been loaded
        return null; // !!! 记得更新默认sprite。Can't find sprite, return missing placeholder
    }

    public SpriteInfo _get_info(string ID){
        return _infos.items[ID];
    }
    public bool _check_loader(string ID, string subID){
        return _ID_to_subID2Sprites[ID].ContainsKey(subID);
    }
    
    // ---------- config ----------
    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__spritesInfo_path);
        _infos = JsonConvert.DeserializeObject<SpritesInfo>(jsonText);
        foreach (var tile_kv in _infos.items){
            load_item(tile_kv.Key);
        }
    }

    void load_item(string ID){
        _ID_to_subID2Sprites.Add(ID, new());
        foreach (string subID in _infos.items[ID].sprites){
            AsyncOperationHandle<Sprite> handle = Addressables.LoadAssetAsync<Sprite>(_infos.items[ID].path + subID);
            handle.Completed += (operationalHandle) => action_sprite_loaded(operationalHandle, ID, subID);

        }
    }

    void action_sprite_loaded(AsyncOperationHandle<Sprite> handle, string ID, string subID){
        if (handle.Status == AsyncOperationStatus.Succeeded) {
            _ID_to_subID2Sprites[ID].Add(subID, handle);
        }
        else 
            Debug.LogError("Failed to load sprite: " + handle.DebugName);
    }

}
