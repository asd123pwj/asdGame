using System.Collections.Generic;
using System.Threading;
using Cysharp.Threading.Tasks;
using UnityEngine;

public class TilemapTile: BaseClass{
    public static Dictionary<string, Dictionary<Vector3Int, TilemapTile>> _our = new();
    public TilemapBlock block;
    public Vector3Int map_pos;
    public TileP3D P3D;
    public TileTile tileTile;
    
    public DecorationBase decoration;
    public string tile_ID = GameConfigs._sysCfg.TMap_empty_tile;
    public string tile_subID;
    bool enable_tile = true;
    bool enable_P3D = true;
    bool enable_decoration = true;
    string mineral_ID;

    public string __tile_ID => tileTile.tile_ID;
    public string __tile_subID => tileTile.tile_subID;
    // public string __actual_subID => tileTile.actual_subID;
    // string mineral_subID = "__Full";
    // Sprite decoration_sprite;
    // ---------- Status ---------- //
    CancellationTokenSource _delay_in_update_subID;
    // int update_times = 0;



    public TilemapTile(){}
    public TilemapTile(TilemapBlock block, Vector3Int map_pos){
        this.block = block;
        this.map_pos = map_pos;
        _our[block.layer.ToString()].Add(map_pos, this);
    }

    public void _set_ID(string tile_ID) { 
        _update_neighbor(tile_ID);
        this.tile_ID = tile_ID; 
        // _update_subID();        
    }
    public void _set_subID(string tile_subID) { this.tile_subID = tile_subID; }

    public void _update_neighbor(string tile){
        if ((tile_ID == GameConfigs._sysCfg.TMap_empty_tile && tile != GameConfigs._sysCfg.TMap_empty_tile)
         || (tile_ID != GameConfigs._sysCfg.TMap_empty_tile && tile == GameConfigs._sysCfg.TMap_empty_tile)){
            for (int x = -GameConfigs._sysCfg.TMap_tileNeighborsCheck_max.x; x <= GameConfigs._sysCfg.TMap_tileNeighborsCheck_max.x; x++){
                for (int y = -GameConfigs._sysCfg.TMap_tileNeighborsCheck_max.y; y <= GameConfigs._sysCfg.TMap_tileNeighborsCheck_max.y; y++){
                    if (!_check_tile_loaded(block.layer, map_pos + new Vector3Int(x, y, 0))) continue;
                    _get(block.layer, map_pos + new Vector3Int(x, y, 0))._update_subID();
                }
            }
        }
    }
    public void _update_subID(){
        UniTask.RunOnThreadPool(() => update_subID()).Forget();
    }
    async UniTask update_subID() {
        _delay_in_update_subID?.Cancel();
        _delay_in_update_subID = new CancellationTokenSource();
        await UniTask.Delay(10, cancellationToken: _delay_in_update_subID.Token); // very useful, update times from 1~14 to 1~3
        TileMatchRule.match(map_pos, block.layer);
        tileTile?._update_sprite().Forget();
    }

    public string _get_tile() => tile_ID;
    public static TilemapTile _get(LayerType layer, Vector3Int map_pos){
        if (!_our.ContainsKey(layer.ToString())) return null;
        if (!_our[layer.ToString()].ContainsKey(map_pos)) return null;
        return _our[layer.ToString()][map_pos];
    }
    // public static async UniTask<TilemapTile> _get_force_async(LayerType layer, Vector3Int map_pos){
    //     if (!_our.ContainsKey(layer.ToString())) { 
    //         _our.Add(layer.ToString(), new()); 
    //     }
    //     if (!_our[layer.ToString()].ContainsKey(map_pos)) { 
    //         Vector3Int block_offsets = TilemapAxis._mapping_mapPos_to_blockOffsets(map_pos);
    //         TilemapBlock block = await TilemapBlock._get_force_async(block_offsets, layer);
    //         _our[layer.ToString()].Add(map_pos, new(block, map_pos)); 
    //     }
    //     return _our[layer.ToString()][map_pos];
    // }


    public static bool _check_tile_loaded(LayerType layer, Vector3Int map_pos) {
        return _our[layer.ToString()].ContainsKey(map_pos);
    } 
    public static bool _check_tile_empty(LayerType layer, Vector3Int map_pos) {
        if (!_check_tile_loaded(layer, map_pos)){
            return false; 
        }
        if (_our[layer.ToString()][map_pos].tile_ID == GameConfigs._sysCfg.TMap_empty_tile){
            return false; 
        }
        return true;
    } 
    public static bool _check_tile_subID_full(LayerType layer, Vector3Int map_pos) {        
        if (_check_tile_empty(layer, map_pos) && _get(layer, map_pos).__tile_subID == GameConfigs._sysCfg.TMap_fullTile_subID) return true;          
        return false;
    }
    
    public void _update_tile(){
        if (enable_tile){
            if (tileTile == null){
                // tileTile = new(map_pos, block.layer, block.obj.tile_container.transform);
                tileTile = new(this);
            }
            else{
                tileTile._update_sprite().Forget();
            }
        }
        else{
            // TODO: delete P3D
        }
    }

    public void _update_P3D(){
        if (enable_P3D){
            if (P3D == null){
                P3D = new(map_pos, block.layer, block.obj.P3D_container.transform);
            }
            else{
                P3D._update_sprite().Forget();
            }
        }
        else{
            // TODO: delete P3D
        }
    }

    public void _clear_mineral() { _set_mineral(null); }
    public void _set_mineral(string mineral_ID) { 
        this.mineral_ID = mineral_ID; 
        // decoration_sprite = _MatSys._spr._get_sprite(mineral_ID, mineral_subID);
    }
    public void _update_decoration(){
        enable_decoration = mineral_ID != null;
        
        if (enable_decoration){
            if (decoration == null){
                decoration = new(map_pos, block.layer, mineral_ID, block.obj.Decoration_container.transform);
            }
            else{
                decoration._set_sprite(mineral_ID);
                decoration._update_sprite().Forget();
            }
        }
        else{
            // TODO: delete decoration
        }
    }
}