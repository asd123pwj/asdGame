using System.IO;
using System.Collections.Generic;
using UnityEngine;
using Newtonsoft.Json;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using System.Linq;

// public class SpriteInfo{
//     public string path;
//     public string spriteSet_type;   // type of spriteSet
//     public string[] spriteSet;        // just for _infos.spriteSet[spriteSet_type]
// };

public class SpritesInfo{
    public string version;
    public Dictionary<string, string> items;
}

public class SpriteManager: BaseClass{
    public SpritesInfo _infos;
    public Dictionary<string, Dictionary<string, Sprite>> _ID_to_subID2Sprites = new();
    public List<string> item_loadDone = new();

    public SpriteManager(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    // ---------- mapping ----------
    public Sprite _get_sprite(string ID, string subID="_DefaultSprite_"){
        if (ID == "0" || ID == null) return null; // No sprite
        if (subID == "_DefaultSprite_") subID = _ID_to_subID2Sprites[ID].Keys.First(); // Some png only have one sprite, its subID is the same as ID
        if (_ID_to_subID2Sprites.ContainsKey(ID)) return _ID_to_subID2Sprites[ID][subID]; // Sprite have been loaded
        return null; // !!! 记得更新默认sprite。Can't find sprite, return missing placeholder
    }

    // public SpriteInfo _get_info(string ID){
    //     return _infos.items[ID];
    // }
    public string[] _get_spriteSet(string ID){
        return _ID_to_subID2Sprites[ID].Keys.ToArray();
    }
    public bool _check_loaded(string ID, string subID){
        return _ID_to_subID2Sprites[ID].ContainsKey(subID);
    }
    public bool _check_loaded(string ID){
        if (!item_loadDone.Contains(ID)) return false;
        // if (_ID_to_subID2Sprites[ID].Count == 0) 
        //     return false; // Some png only have one sprite, count = 0 means no loaded
        // if (!(_infos.items[ID].spriteSet == null)) {
        //     foreach(var sprite in _infos.items[ID].spriteSet)
        //         if (!_ID_to_subID2Sprites[ID].ContainsKey(sprite)) 
        //             return false;
        // }
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
        // _infos.items[ID].spriteSet = _infos.spriteSet[_infos.items[ID].spriteSet_type];
        _ID_to_subID2Sprites.Add(ID, new());
        AsyncOperationHandle<Sprite[]> handle = Addressables.LoadAssetAsync<Sprite[]>(_infos.items[ID]);
        handle.Completed += (operationalHandle) => action_sprite_loaded(operationalHandle, ID);
    }

    void action_sprite_loaded(AsyncOperationHandle<Sprite[]> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) {
            foreach(var sprite in handle.Result){
                _ID_to_subID2Sprites[ID].Add(sprite.name, sprite);
            }
            item_loadDone.Add(ID);
        }
        else 
            Debug.LogError("Failed to load sprite: ID-" + ID);
    }

}
