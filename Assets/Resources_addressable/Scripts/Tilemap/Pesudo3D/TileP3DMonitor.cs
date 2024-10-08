using System;
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TileP3DMonitor: BaseClass{
    // ---------- Plant Container ----------
    public Dictionary<string, Transform> _TMapBD_containers;
    public Dictionary<string, Dictionary<Vector3Int, TileP3D>> _P3Ds;
    public Dictionary<string, Dictionary<Vector3Int, string[]>> queue;
    // public Dictionary<Pseudo3DRuleTile, TileP3D> _P3Dsssss;
    public int update_num = 100;

    public TileP3DMonitor(){
        // update_interval = 0.5f;
    }

    public override void _init(){
        _TMapBD_containers = new();
        _TMapBD_containers.Add("TileP3D", new GameObject("TileP3D").transform);
        foreach(var obj in _TMapBD_containers.Values){
            obj.transform.SetParent(_sys._grid.transform);
        }

        _P3Ds = new() { 
            {"L1_Middle", new() }
        };

        queue = new() { 
            {"L1_Middle", new() }
        };

        _sys._InputSys._register_action("Number 4", tmp_draw, "isFirstDown");
    }


    // public override async UniTask _loop(){
    //     while(true){
    //         // int i = 0;
    //         var queue_copy = queue.Copy();
    //         foreach (var layer in queue_copy.Keys){
    //             // if (i == update_num) break;
    //             foreach (var map_pos in queue_copy[layer].Keys){
    //                 // if (i == update_num) break;
    //                 string tile_ID = queue[layer][map_pos][0];
    //                 string tile_subID = queue[layer][map_pos][1];
    //                 if (_update_P3D(map_pos, tile_ID, tile_subID, layer)){
    //                     queue[layer].Remove(map_pos);
    //                     // i++;
    //                 }
    //             }
    //         }
    //         await UniTask.Delay(500);
    //     }
    // }

    // public override void _update(){
    // }

    // public void _generate_P3D(Vector3Int map_pos, string tile_ID, string tile_subID, string layer){
    //     queue[layer][map_pos] = new string[]{tile_ID, tile_subID};
    // }
    public TileP3D _generate_P3D(Vector3Int map_pos, string tile_ID, string tile_subID, string layer){
        // queue[layer][map_pos] = new string[]{tile_ID, tile_subID};
        Vector2 world_pos = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, "L1_Middle");
        // TileP3D P3D = new TileP3D(world_pos, _TMapBD_containers["TileP3D"], tile_ID, tile_subID);
        TileP3D P3D = new TileP3D(world_pos, tile_ID, tile_subID);
        _P3Ds[layer].Add(map_pos, P3D);
        return P3D;
    }

    public void _update_P3D(Vector3Int map_pos, string tile_ID, string tile_subID, string layer){
        if (_P3Ds[layer].ContainsKey(map_pos)){
            // if (_P3Ds[layer][map_pos]._initDone) {
                _P3Ds[layer][map_pos]._update_sprite2(tile_ID, tile_subID).Forget();
            //     return true;
            // }
            // else {
            //     return false;
            // }
        }
        else {
            Vector2 world_pos = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
            TileP3D P3D = new TileP3D(world_pos, tile_ID, tile_subID);
            // TileP3D P3D = new TileP3D(world_pos, _TMapBD_containers["TileP3D"], tile_ID, tile_subID);
            _P3Ds[layer].Add(map_pos, P3D);
            // return true;
        }

    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        Vector3Int block_offsets = _TMapSys._TMapAxis._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, "L1_Middle");
        TilemapBlock block = _TMapSys._TMapMon._get_block(block_offsets, "L1_Middle");
        block.status._update_status_typeMap("TileP3D");
        Tilemap TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, "L1_Middle").TMap;
        foreach (var pos in block.status.positions["TileP3D"]){
            Vector2 world_pos = _TMapSys._TMapAxis._mapping_inBlockPos_to_worldPos(pos, block_offsets, "L1_Middle");
            Vector3Int map_pos = _TMapSys._TMapAxis._mapping_inBlockPos_to_mapPos(pos, block_offsets);
            string tile_subID = TMap.GetSprite(map_pos).name;
            // new TileP3D(world_pos, _TMapBD_containers["TileP3D"], block.map._get(pos), tile_subID);
            new TileP3D(world_pos, block.map._get(pos), tile_subID);
        }
        return true;
    }

    
}
