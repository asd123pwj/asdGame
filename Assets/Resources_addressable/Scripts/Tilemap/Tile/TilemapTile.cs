using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Threading;
using Cysharp.Threading.Tasks;
using UnityEngine;

public class TilemapTile: BaseClass{
    private readonly object _lock_our = new();
    public static ConcurrentDictionary<string, ConcurrentDictionary<Vector3Int, TilemapTile>> _our = new();
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
    public Dictionary<Vector2Int, bool> _neighbor_notEmpty = new();
    public bool _need_update_neighbor = false;


    public TilemapTile(){}
    public TilemapTile(TilemapBlock block, Vector3Int map_pos){
        this.block = block;
        this.map_pos = map_pos;
        lock(_lock_our){
            var our_layer = _our.GetOrAdd(block.layer.ToString(), _ => new ConcurrentDictionary<Vector3Int, TilemapTile>());
            our_layer.TryAdd(map_pos, this);
        }
        foreach (Vector2Int neighbor_pos in TileMatchRule.reference_pos){
            _neighbor_notEmpty.Add(neighbor_pos, false);
        }
    }

    public void _set_ID(string tile_ID) { 
        _update_need_update_neighbor(tile_ID);
        this.tile_ID = tile_ID; 
    }

    public void _update_need_update_neighbor(string tile_ID){
        if ((tile_ID == GameConfigs._sysCfg.TMap_empty_tile && this.tile_ID != GameConfigs._sysCfg.TMap_empty_tile)
         || (tile_ID != GameConfigs._sysCfg.TMap_empty_tile && this.tile_ID == GameConfigs._sysCfg.TMap_empty_tile)){
            _need_update_neighbor = true;
        }
    }

    public string _get_tile_ID() => tile_ID;
    public static TilemapTile _get(LayerType layer, Vector3Int map_pos){
        if (!_our.ContainsKey(layer.ToString())) return null;
        if (!_our[layer.ToString()].ContainsKey(map_pos)) return null;
        return _our[layer.ToString()][map_pos];
    }


    public static TilemapTile _try_get(LayerType layer, Vector3Int map_pos) {
        if (_our.TryGetValue(layer.ToString(), out var our_layer)){
            if (our_layer.TryGetValue(map_pos, out var tile)){
                return tile;
            }
        }
        return null;
    } 
    public static bool _check_tile_loaded_and_notEmpty(LayerType layer, Vector3Int map_pos) {
        TilemapTile tile = _try_get(layer, map_pos);
        if (tile == null) return false;
        return tile.tile_ID != GameConfigs._sysCfg.TMap_empty_tile;
    } 
    public static bool _check_tile_subID_full(LayerType layer, Vector3Int map_pos) {        
        if (_check_tile_loaded_and_notEmpty(layer, map_pos) && _get(layer, map_pos).__tile_subID == GameConfigs._sysCfg.TMap_fullTile_subID) return true;          
        return false;
    }
    
    public async UniTask _update_status(CancellationToken? ct, bool force_update = false){
        bool neighbor_isChanged = force_update;
        bool neighbor_notEmpty;
        bool need_update_neighbor = _need_update_neighbor;
        _need_update_neighbor = false;
        foreach (Vector2Int neighbor_pos in TileMatchRule.reference_pos){
            TilemapTile neighbor = _try_get(block.layer, map_pos + new Vector3Int(neighbor_pos.x, neighbor_pos.y, 0));
            if (neighbor == null) {
                neighbor_notEmpty = false;
            }
            else {
                neighbor_notEmpty = (neighbor.tile_ID != GameConfigs._sysCfg.TMap_empty_tile);
                if (need_update_neighbor) {
                    await neighbor._update_status(ct);
                }
            }
            if (neighbor_notEmpty != _neighbor_notEmpty[neighbor_pos]){
                _neighbor_notEmpty[neighbor_pos] = neighbor_notEmpty;
                neighbor_isChanged = true;
            }
        }
        if (neighbor_isChanged){
            string tile_subID_new = TileMatchRule.match(this);
            if (tile_subID_new != tile_subID){
                tile_subID = tile_subID_new;
                await _update_tile(ct);
            }
        }
    }

    public async UniTask _update_tile(CancellationToken? ct){
        if (enable_tile){
            tileTile ??= new(this);
            await tileTile._update_sprite(ct);
            // tileTile._update_sprite().Forget();
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