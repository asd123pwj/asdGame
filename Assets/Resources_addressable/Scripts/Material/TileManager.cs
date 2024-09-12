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
    public string relative_path;
    public string[] tags;
};

public struct TilesInfo{
    public string version;
    public Dictionary<string, TileInfo> items;
    public Dictionary<string, string> root_paths;
}

public class TileManager: BaseClass{
    public TilesInfo _infos;
    public Dictionary<string, AsyncOperationHandle<TileBase>> _ID2Tile = new();

    public TileManager(){
        load_items();
    }

    public bool _check_info_initDone(){
        return !(_infos.version == null);
    }

    // ---------- mapping ----------
    public TileBase _get_tile(string ID){
        if (ID == "0") return null; // No tile
        if (_ID2Tile.ContainsKey(ID)) return _ID2Tile[ID].Result; // Tile have been loaded
        return _ID2Tile["p3"].Result; // Can't find tile, return missing placeholder
    }

    public TileInfo _get_info(string ID){
        return _infos.items[ID];
    }
    public bool _check_loader(string ID){
        return _ID2Tile.ContainsKey(ID);
    }
    
    // ---------- config ----------
    void load_items(){
        string jsonText = File.ReadAllText(_GCfg.__tilesInfo_path);
        _infos = JsonConvert.DeserializeObject<TilesInfo>(jsonText);
        foreach (var tile_kv in _infos.items){
            load_tile(tile_kv.Key);
        }
    }

    void load_tile(string ID){
        TileInfo tile_info = _infos.items[ID];
        string tile_root_path = _infos.root_paths[tile_info.root_path_key];
        string tile_path = Path.Combine(tile_root_path, tile_info.relative_path);
        AsyncOperationHandle<TileBase> handle = Addressables.LoadAssetAsync<TileBase>(tile_path);
        handle.Completed += (operationalHandle) => action_tile_loaded(operationalHandle, ID);
    }

    void action_tile_loaded(AsyncOperationHandle<TileBase> handle, string ID){
        if (handle.Status == AsyncOperationStatus.Succeeded) {
            _ID2Tile.Add(ID, handle);
        }
        else 
            Debug.LogError("Failed to load tile: " + handle.DebugName);
    }

}
