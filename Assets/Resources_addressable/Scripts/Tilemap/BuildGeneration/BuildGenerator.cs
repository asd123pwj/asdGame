// 对于一个给定中心，以BuildGen_MatchKernelSize_RadiusMinusOne_max+1为半径匹配
// 例如，小营地只取一个区块，需要在平坦地形，即horizontal，
// 
// 小营地位置小，例如5x1，那么在非边缘部分找到地面最大的部分，

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class BuildGenerator : BaseClass{

    public Dictionary<string, string[,]> build_template => new(){
        {"Block", new string[,] {{ "f2", "f2", "f2",} } }
    };

    public void _BuildGenerator(){
        // this.place_tilemap = place_tilemap;

    }

    public void _generate_build(Vector2 mouse_pos){
        Tilemap posRef_tilemap = _TMapSys._TMapMon._get_TilemapBlockGameObject(Vector3Int.zero, "Block").TMap;
        Vector3Int block_pos;
        Vector3Int build_origin_pos = new(0, 0, 0);
        string build_overlap_rule = "completly overlap";
        Dictionary<string, string[,]> build_template = this.build_template;

        foreach (string key in build_template.Keys){
            // now test in "Block"
            for (int i = 0; i < build_template[key].GetLength(0); i++){
                for (int j = 0; j < build_template[key].GetLength(1); j++){
                    Vector3Int current_tile_pos = build_origin_pos + new Vector3Int(i, j, 0);
                    block_pos = _TMapSys._TMapCfg._mapping_worldXY_to_blockXY(current_tile_pos, posRef_tilemap);
                    TilemapBlock block = _TMapSys._TMapMon._get_block(block_pos);
                    string current_tile_ID = block.map[current_tile_pos.x, current_tile_pos.y];
                }
            }
        }
        
    }


    
}
