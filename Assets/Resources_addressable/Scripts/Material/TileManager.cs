using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;
using Newtonsoft.Json;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine.Animations;
using System.Collections.Concurrent;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;

public struct TileInfo{
    public string category;
    public string name;
    public string tileType;
    public string tilePerGrid;
    public string description;
    public string refUrl;
    public string root_path_key;
    public string sprite;
    public string relative_path;
    public string P3D_path;
    public string[] tags;
};

public struct TilesInfo{
    public string version;
    public Dictionary<string, TileInfo> items;
    public Dictionary<string, string> root_paths;
    public Dictionary<string, string> P3D_root;
    public int tile_num;   // == items.Count
    public int P3D_num;    // == items.P3D_path.Count
    public int sprite_num; // == items.sprite.Count
}

public class TileManager: BaseClass{
    public TilesInfo _infos;
    // public Dictionary<string, AsyncOperationHandle<TileBase>> _ID2Tile = new();
    // public Dictionary<string, Dictionary<string, Sprite>> _ID_to_subID2sprite = new();
    // public Dictionary<Sprite, string> _sprite_to_ID = new();
    // public Dictionary<string, Dictionary<string, Sprite>> _ID_to_subID2P3D = new();
    // public Dictionary<Sprite, string> _P3D_to_ID = new();
    // public GameObject obj;

    public TileManager(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }
    // public bool _check_P3D_all_loaded(){
    //     if (_ID_to_subID2P3D.Count == _infos.P3D_num) return true;
    //     return false;
    // }

    // // ---------- mapping ----------
    // public TileBase _get_tile(string ID){
    //     if (ID == "0") return null; // No tile
    //     if (_ID2Tile.ContainsKey(ID)) return _ID2Tile[ID].Result; // Tile have been loaded
    //     return _ID2Tile["p3"].Result; // Can't find tile, return missing placeholder
    // }
    // public Sprite _get_sprite(string ID, string sub_ID){
    //     if (ID == "0") return null; // No sprite
    //     if (_ID2Tile.ContainsKey(ID)) return _ID_to_subID2sprite[ID][sub_ID]; // Sprite have been loaded
    //     return null; // !!! TODO: Can't find sprite, return missing placeholder
    // }
    // public Sprite _get_P3D(string ID, string sub_ID){
    //     if (ID == "0") return null; // No sprite
    //     if (_ID2Tile.ContainsKey(ID)) return _ID_to_subID2P3D[ID][sub_ID]; // Sprite have been loaded
    //     return null; // !!! TODO: Can't find sprite, return missing placeholder
    // }
    // public string _get_ID(Sprite sprite){
    //     if (sprite == null) return null;
    //     if (_P3D_to_ID.ContainsKey(sprite)) return _P3D_to_ID[sprite];
    //     if (_sprite_to_ID.ContainsKey(sprite)) return _sprite_to_ID[sprite];
    //     return null;
    // }

    public TileInfo _get_info(string ID){
        return _infos.items[ID];
    }
    // public bool _check_tile_loaded(string ID){
    //     return _ID2Tile.ContainsKey(ID);
    // }
    // public bool _check_sprite_loaded(string ID){
    //     return _ID_to_subID2P3D.ContainsKey(ID);
    // }
    // public bool _check_sprite_loaded(string ID, string sub_ID){
    //     return _ID_to_subID2P3D[ID].ContainsKey(sub_ID);
    // }
    
    // ---------- config ----------
    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__tilesInfo_path);
        _infos = JsonConvert.DeserializeObject<TilesInfo>(jsonText);
        // foreach (var tile_kv in _infos.items){
        //     load_tile(tile_kv.Key);
        //     load_sprite(tile_kv.Key);
        //     load_P3D(tile_kv.Key);
        // }
    }

    // // ----- tile ----- //
    // void load_tile(string ID){
    //     TileInfo tile_info = _infos.items[ID];
    //     _infos.tile_num++;
    //     AsyncOperationHandle<TileBase> handle = Addressables.LoadAssetAsync<TileBase>(tile_info.relative_path);
    //     handle.Completed += (operationalHandle) => action_tile_loaded(operationalHandle, ID);
    // }

    // void action_tile_loaded(AsyncOperationHandle<TileBase> handle, string ID){
    //     if (handle.Status == AsyncOperationStatus.Succeeded) {
    //         _ID2Tile.Add(ID, handle);
    //     }
    //     else 
    //         Debug.LogError("Failed to load tile: " + handle.DebugName);
    // }

    // // ----- sprite ----- //
    // void load_sprite(string ID){
    //     if (_infos.items[ID].sprite == null || _infos.items[ID].sprite == "") return;
    //     _infos.sprite_num++;
    //     AsyncOperationHandle<Sprite[]> handle = Addressables.LoadAssetAsync<Sprite[]>(_infos.items[ID].sprite);
    //     handle.Completed += (operationalHandle) => action_sprite_loaded(operationalHandle, ID);
    // }

    // void action_sprite_loaded(AsyncOperationHandle<Sprite[]> handle, string ID){
    //     if (handle.Status == AsyncOperationStatus.Succeeded) {
    //         _ID_to_subID2sprite.Add(ID, new());
    //         foreach(var sprite in handle.Result){
    //             _ID_to_subID2sprite[ID].Add(sprite.name, sprite);
    //             _sprite_to_ID.Add(sprite, ID);
    //         }
    //     }
    //     else 
    //         Debug.LogError("Failed to load sprite: ID-" + ID);
    // }

    // // ----- P3D sprite ----- //
    // void load_P3D(string ID){
    //     if (_infos.items[ID].P3D_path == null || _infos.items[ID].P3D_path == "") return;
    //     _infos.P3D_num++;
    //     AsyncOperationHandle<Sprite[]> handle = Addressables.LoadAssetAsync<Sprite[]>(_infos.items[ID].P3D_path);
    //     handle.Completed += (operationalHandle) => action_P3D_loaded(operationalHandle, ID);
    // }

    // void action_P3D_loaded(AsyncOperationHandle<Sprite[]> handle, string ID){
    //     if (handle.Status == AsyncOperationStatus.Succeeded) {
    //         _ID_to_subID2P3D.Add(ID, new());
    //         foreach(var sprite in handle.Result){
    //             _ID_to_subID2P3D[ID].Add(sprite.name, sprite);
    //             _P3D_to_ID.Add(sprite, ID);
    //         }
    //     }
    //     else 
    //         Debug.LogError("Failed to load P3D: ID-" + ID);
    // }
    

}
