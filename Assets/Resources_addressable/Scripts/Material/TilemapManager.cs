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
    public int ID;
    public string name;
    public string description;
    public string path;
    public string[] tags;
};

public struct TilesInfo{
    public string version;
    public Dictionary<string, TileInfo> tiles;
}

public class TilemapManager: BaseClass{
    // ---------- object ----------
    // public SaveLoadBase __save_load_base;
    // GameConfigs _GCfg;
    // ---------- info ----------
    public TilesInfo __tiles_info;
    public Dictionary<string, TileBase> __name2tile = new();
    public Dictionary<int, string> __ID2tileName = new();
    // ---------- state ----------
    // public List<Vector3Int> __blockLoads_list = new();
    // public Dictionary<Vector3Int, TilemapBlock> __blockLoads_infos = new();

    public TilemapManager(){
        // this._GCfg = GCfg;
        load_tiles_info();
    }

    public bool _check_info_initDone(){
        return !(__tiles_info.version == null);
    }

    // ---------- mapping ----------
    public TileBase _get_tile(string name){
        if (name == "") return null; // No tile
        if (__name2tile.ContainsKey(name)) return __name2tile[name]; // Tile have been loaded
        return __name2tile[name];
    }

    public TileBase _get_tile(int ID){
        return _get_tile(__ID2tileName[ID]);
    }

    public TileInfo _get_info(string name){
        return __tiles_info.tiles[name];
    }
    public TileInfo _get_info(int ID){
        return _get_info(__ID2tileName[ID]);
    }

    public bool _check_loader(string name){
        return __name2tile.ContainsKey(name);
    }
    public bool _check_loader(int ID){
        return _check_loader(__ID2tileName[ID]);
    }

    // public int _map_tile_to_ID(TileBase tile){
    //     if (tile == null) return 0;
    //     else return _tiles_info.tiles[tile.name].ID;
    // }

    // public Vector3Int _mapping_worldXY_to_mapXY(Vector3 world_pos, Tilemap tilemap){
    //     Vector3Int map_pos = tilemap.WorldToCell(world_pos);
    //     return map_pos;
    // }

    // public Vector3Int _mapping_worldXY_to_blockXY(Vector3 world_pos, Tilemap tilemap){
    //     Vector3Int map_pos = tilemap.WorldToCell(world_pos);
    //     return _mapping_mapXY_to_blockXY(map_pos);
    // }

    // public Vector3Int _mapping_mapXY_to_blockXY(Vector3Int map_pos){
    //     Vector3Int block_offsets = new Vector3Int {
    //         x = Mathf.Abs(map_pos.x) / __game_configs.__block_size.x,
    //         y = Mathf.Abs(map_pos.y) / __game_configs.__block_size.y};
    //     if (map_pos.x < 0) block_offsets.x = -block_offsets.x - 1;
    //     if (map_pos.y < 0) block_offsets.y = -block_offsets.y - 1;
    //     // Debug.Log("Mouse pos: [" + pos_tilemap.x + ", " + pos_tilemap.y + "].");
    //     // Debug.Log("Block offset: [" + block_offset[0] + ", " + block_offset[1] + "].");
    //     return block_offsets;
    // }

    // public Vector3Int _mapping_mapXY_to_tileXY_in_block(Vector3Int map_pos){
    //     Vector3Int block_offsets = _mapping_mapXY_to_blockXY(map_pos);
    //     Vector3Int tile_offsets = new Vector3Int {
    //         x = map_pos.x - block_offsets.x * __game_configs.__block_size.x,
    //         y = map_pos.y - block_offsets.y * __game_configs.__block_size.y};
    //     return tile_offsets;
    // }

    // ---------- config ----------
    void load_tiles_info(){
        // load config
        string tiles_info_path = _GCfg.__tilesInfo_path;
        string jsonText = File.ReadAllText(tiles_info_path);
        __tiles_info = JsonConvert.DeserializeObject<TilesInfo>(jsonText);
        // init ID2tileName
        __ID2tileName.Add(0, "");
        foreach (var tile_kv in __tiles_info.tiles){
            __ID2tileName.Add(tile_kv.Value.ID, tile_kv.Key);
            load_tile(tile_kv.Key).Forget();
        }
    }

    async UniTaskVoid load_tile(string name){
        string object_path = __tiles_info.tiles[name].path;
        AsyncOperationHandle<TileBase> handle = Addressables.LoadAssetAsync<TileBase>(object_path);
        if (name == "") // that is false.
            handle.Completed += (operationalHandle) => action_tile_loaded(operationalHandle, name);
        else{
            handle.WaitForCompletion();
            __name2tile.Add(name, handle.Result);
            Addressables.Release(handle);
        }
        await UniTask.Yield();
    }

    void action_tile_loaded(AsyncOperationHandle<TileBase> handle, string name){
        if (handle.Status == AsyncOperationStatus.Succeeded) __name2tile.Add(name, handle.Result);
        else Debug.LogError("Failed to load tile: " + handle.DebugName);
        Addressables.Release(handle);
    }
}
