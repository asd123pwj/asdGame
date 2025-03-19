using System.Collections.Generic;
using UnityEngine;

public class TilemapTile: BaseClass{
    public static Dictionary<string, Dictionary<Vector3Int, TilemapTile>> _our = new();
    TilemapBlock block;
    Vector3Int map_pos;
    TileP3D P3D;
    TileTile tileTile;
    
    DecorationBase decoration;
    public string tile;
    bool enable_tile = true;
    bool enable_P3D = true;
    bool enable_decoration = true;
    string mineral_ID;

    public string _tile_ID => tileTile.tile_ID;
    public string _tile_subID => tileTile.tile_subID;
    // string mineral_subID = "__Full";
    // Sprite decoration_sprite;



    public TilemapTile(){}
    public TilemapTile(TilemapBlock block, Vector3Int map_pos){
        this.block = block;
        this.map_pos = map_pos;
        _our[block.layer.ToString()].Add(map_pos, this);
    }

    public void _set_tile(string tile) { this.tile = tile; }

    public string _get_tile() => tile;
    public static TilemapTile _get(LayerType layer, Vector3Int map_pos){
        if (!_our.ContainsKey(layer.ToString())) return null;
        if (!_our[layer.ToString()].ContainsKey(map_pos)) return null;
        return _our[layer.ToString()][map_pos];
    }


    public static bool _check_tile(LayerType layer, Vector3Int map_pos) {
        var tiles_in_layer = _our[layer.ToString()];
        if (!tiles_in_layer.ContainsKey(map_pos)){
            return false; // 20250303: I think this can not happen, it happen only in block no load
        }
        var tile = tiles_in_layer[map_pos];
        if (tile.tile == "0"){
            return false; // "0" is empty tile
        }
        return true;
    } 
    public static bool _check_fullTile(LayerType layer, Vector3Int map_pos) {        
        if (_check_tile(layer, map_pos) && _get(layer, map_pos)._tile_subID == GameConfigs._sysCfg.TMap_fullTile_subID) return true;          
        return false;
    }
    
    public void _update_tile(){
        if (enable_tile){
            if (tileTile == null){
                tileTile = new(map_pos, block.layer, block.obj.tile_container.transform);
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