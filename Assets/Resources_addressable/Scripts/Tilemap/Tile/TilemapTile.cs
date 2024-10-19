using System.Collections.Generic;
using UnityEngine;

public class TilemapTile{
    public static Dictionary<string, Dictionary<Vector3Int, TilemapTile>> our = new();
    TilemapBlock block;
    Vector3Int map_pos;
    TileP3D P3D;
    DecorationBase decoration;
    public string tile;
    bool enable_P3D = true;
    bool enable_decoration = true;



    public TilemapTile(){}
    public TilemapTile(TilemapBlock block, Vector3Int map_pos){
        this.block = block;
        this.map_pos = map_pos;
        our[block.layer.ToString()].Add(map_pos, this);
    }

    public void _set_tile(string tile) { this.tile = tile; }

    public string _get_tile() => tile;

    public void _update_P3D(){
        if (enable_P3D){
            if (P3D == null){
                P3D = new(map_pos, block.layer);
            }
            else{
                P3D._update_sprite().Forget();
            }
        }
        else{
            // TODO: delete P3D
        }
    }

    public void _update_decoration(){
        if (enable_decoration){
            if (decoration == null){
                decoration = new(map_pos, block.layer);
            }
            else{
                decoration._update_sprite().Forget();
            }
        }
        else{
            // TODO: delete decoration
        }
    }
}