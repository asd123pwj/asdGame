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
    // public TilemapTileP3D P3D;
    // public TilemapTileTile tileTile;
    public TilemapTileTexture texture;
    // public Vector2 world_pos;
    
    // public TilemapTileDecoration decoration;
    public string tile_ID = GameConfigs._sysCfg.TMap_empty_tile;
    public string tile_subID = GameConfigs._sysCfg.TMap_fullTile_subID;
    // bool enable_tile = true;
    // bool enable_P3D = true;
    // bool enable_decoration = true;
    public string tile_ID_terrain;
    public string mineral_ID;
    // bool firstLoadDone = false;

    // public string __tile_ID => tileTile.tile_ID;
    // public string __tile_subID => tileTile.tile_subID;
    // public string __actual_subID => tileTile.actual_subID;
    // string mineral_subID = "__Full";
    // Sprite decoration_sprite;
    // ---------- Status ---------- //
    public Dictionary<Vector2Int, bool> _neighbor_notEmpty = new();
    public bool _need_update_neighbor = false;
    public bool _need_update_texture = false;


    public TilemapTile(){}
    public TilemapTile(TilemapBlock block, Vector3Int map_pos){
        this.block = block;
        this.map_pos = map_pos;
        // world_pos = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, block.layer);
        lock(_lock_our){
            var our_layer = _our.GetOrAdd(block.layer.ToString(), _ => new());
            our_layer.TryAdd(map_pos, this);
        }
        foreach (Vector2Int neighbor_pos in TileMatchRule.reference_pos){
            _neighbor_notEmpty.Add(neighbor_pos, true);
        }
    }

    public static async UniTask _modify(LayerType layer, Vector3Int map_pos, string tile_ID, CancellationToken? ct, bool needDraw=false){
        ct?.ThrowIfCancellationRequested();
        TilemapTile tile = await _get_force_async(layer, map_pos);
        tile._set_ID(tile_ID);
        if (needDraw){
            await tile._update_status(ct);
        }
    }

    public bool _check_terrainDone() => tile_ID_terrain != null;
    public void _set_ID_terrain(string tile_ID){
        tile_ID_terrain = tile_ID;
        _set_ID(tile_ID);
    }
    public void _set_ID(string tile_ID) { 
        _update_need_update_neighbor(tile_ID);
        _update_need_update_texture(tile_ID);
        this.tile_ID = tile_ID; 
    }

    public void _update_need_update_neighbor(string tile_ID){
        if ((tile_ID == GameConfigs._sysCfg.TMap_empty_tile && this.tile_ID != GameConfigs._sysCfg.TMap_empty_tile)
         || (tile_ID != GameConfigs._sysCfg.TMap_empty_tile && this.tile_ID == GameConfigs._sysCfg.TMap_empty_tile)){
            _need_update_neighbor = true;
        }
    }
    
    public void _update_need_update_texture(string tile_ID){
        _need_update_texture = (tile_ID != this.tile_ID);
    }

    public string _get_tile_ID() => tile_ID;

    public static async UniTask<TilemapTile> _get_force_async(LayerType layer, Vector3Int map_pos) {
        TilemapTile tile = _try_get(layer, map_pos);
        if (tile == null) {
            TilemapBlock block = await TilemapBlock._get_force_waitInitDone_useMapPos(map_pos, layer);
            return new(block, map_pos);
        }
        return tile;
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
        TilemapTile tile = _try_get(layer, map_pos);
        if (tile == null) return false;
        return tile.tile_subID != GameConfigs._sysCfg.TMap_fullTile_subID;
    }
    
    public async UniTask _update_status(CancellationToken? ct=null){
        ct?.ThrowIfCancellationRequested();
        bool neighbor_isChanged = tile_subID == null;
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
                    await neighbor._update_status();
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
                _need_update_texture = true;
                tile_subID = tile_subID_new;
            }
        }
        if (_need_update_texture){
            _need_update_texture = false;
            // await _update_texture(); 
            _update_texture(); 
        }
    }

    // public async UniTask _update_texture(){
    public void _update_texture(){
        if (texture == null){
            ObjectConfig cfg = ObjectClass._set_default("tile_default", $"tile_{map_pos.x}_{map_pos.y}");
            cfg.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, block.layer);;
            texture = new(this, block.obj.tile_container, cfg);
        }
        // await texture._update_texture();
        texture._update_texture();
        // _update_tile();
        // _update_P3D();
        // _update_decoration();
    }

    // public void _update_tile(){
    //     if (enable_tile){
    //         tileTile ??= new(this);
    //         tileTile._update_sprite();
    //         // await tileTile._update_sprite(ct);
    //     }
    //     else{
    //         // TODO: delete P3D
    //     }
    // }

    // public void _update_P3D(){
    //     if (enable_P3D){
    //         P3D ??= new(this);
    //         P3D._update_sprite();
    //         // await P3D._update_sprite(ct);
    //     }
    //     else{
    //         // TODO: delete P3D
    //     }
    // }

    public void _clear_mineral() { _set_mineral(null); }
    public void _set_mineral(string mineral_ID) => this.mineral_ID = mineral_ID; 
    // public void _update_decoration(){
    //     if (enable_decoration && mineral_ID != null){
    //         decoration ??= new(this);
    //         // await decoration._update_sprite(ct);
    //         decoration._update_sprite();
    //     }
    //     else{
    //         // TODO: delete decoration
    //     }
    // }
}