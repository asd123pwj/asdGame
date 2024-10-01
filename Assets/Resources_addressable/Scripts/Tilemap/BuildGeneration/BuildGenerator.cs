// 对于一个给定中心，以BuildGen_MatchKernelSize_RadiusMinusOne_max+1为半径匹配
// 例如，小营地只取一个区块，需要在平坦地形，即horizontal，
// 
// 小营地位置小，例如5x1，那么在非边缘部分找到地面最大的部分，

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class BuildGenerator : BaseClass{

    public Dictionary<string, string[,]> build_template => new(){
        {"L1_Middle", new string[,] {{ "f1", "f2", "f2",} } }
    };

    public void _BuildGenerator(){
        // this.place_tilemap = place_tilemap;

    }

    public override void _init(){
        _sys._InputSys._register_action("Number 2", tmp_draw, "isFirstDown");

    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        Vector3Int block_offsets = _TMapSys._TMapAxis._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, "L1_Middle");
    

        System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        stopwatch.Start();
        // foreach (Vector3Int BOffsets in block_offsets_list){
        //     TilemapBlock block = TMapGen._generate_block(BOffsets);
        //     _TMapSys._TMapMon._load_block(block);

            Region4DrawTilemapBlock region = _generate_build(keyPos.mouse_pos_world);
            // Dictionary<Vector3Int, Region4DrawTilemapBlock> regions_placeholder = TMapDraw._get_draw_regions_placeholder(block);

            Tilemap TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, "L1_Middle").TMap;
            _TMapSys._TMapDraw._draw_region(TMap, region).Forget();

        //     foreach (Vector3Int offsets in regions_placeholder.Keys){
        //         Tilemap TMap_placeholder = _TMapSys._TMapMon._get_blkObj(offsets, "L1_Middle").TMap;
        //         TMapDraw._draw_region(TMap_placeholder, regions_placeholder[offsets]).Forget();
        //     }
        // }

        // foreach (Vector3Int BOffsets in block_offsets_list){
        //     ShadowGenerator._generate_shadow_from_compCollider(
        //         _TMapSys._TMapMon._get_blkObj(BOffsets, "L1_Middle").obj,
        //         _TMapSys._TMapMon._get_blkObj(BOffsets, "L1_Middle").compositeCollider
        //     );
        // }

        stopwatch.Stop();
        Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds);
        // if (regions.Count > 0) {
        //     Tilemap TMap = _TMapSys._TMapMon._get_tilemap(block)
        //     TMapDraw._draw_region(TMap_modify, regions).Forget();
        // }
        return true;
    }


    public Region4DrawTilemapBlock _generate_build(Vector2 mouse_pos){
        // Tilemap posRef_tilemap = _TMapSys._TMapMon._get_TilemapBlockGameObject(Vector3Int.zero, "L1_Middle").TMap;
        string layer_type = "L1_Middle";
        Vector3Int mouse_origin_mapPos = _TMapSys._TMapAxis._mapping_worldPos_to_mapPos(mouse_pos, layer_type);;
        // Vector3Int currentBlock_offset;
        Vector3Int build_origin_relativePos = new(0, 0, 0);
        // string build_overlap_rule = "completly overlap";
        Dictionary<string, string[,]> build_template = this.build_template;
        Region4DrawTilemapBlock region = new();

        foreach (string key in build_template.Keys){
            // now test in "L1_Middle"
            for (int i = 0; i < build_template[key].GetLength(0); i++){
                for (int j = 0; j < build_template[key].GetLength(1); j++){
                    // ----- Get tile pos in block
                    Vector3Int currentTile_mapPos = mouse_origin_mapPos + build_origin_relativePos + new Vector3Int(j, i, 0);
                    Vector3Int currentBlock_offset = _TMapSys._TMapAxis._mapping_mapPos_to_blockOffsets(currentTile_mapPos);
                    TilemapBlock block = _TMapSys._TMapMon._get_block(currentBlock_offset, layer_type);

                    Vector3Int currentTile_inBlockPos = _TMapSys._TMapAxis._mapping_mapPos_to_posInBlock(currentTile_mapPos);
                    // Debug.Log(currentTile_inBlockPos);
                    string current_tile_ID = block._get_map(currentTile_inBlockPos);
                    string build_template_tile_ID = build_template[key][i, j];
                    
                    TileBase tile = _MatSys._tile._get_tile(build_template_tile_ID);
                    region._add(currentTile_mapPos, tile);
                }
            }
        }
        return region;
    }


    
}
