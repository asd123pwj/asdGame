using System.Collections.Generic;
using UnityEngine;

public class TilemapTile: BaseClass{
    public static Dictionary<string, Dictionary<Vector3Int, TilemapTile>> our = new();
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
    // string mineral_subID = "__Full";
    // Sprite decoration_sprite;



    public TilemapTile(){}
    public TilemapTile(TilemapBlock block, Vector3Int map_pos){
        this.block = block;
        this.map_pos = map_pos;
        our[block.layer.ToString()].Add(map_pos, this);
    }

    public void _set_tile(string tile) { this.tile = tile; }

    public string _get_tile() => tile;
    
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