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
            {new LayerTTT(0).ToString(), new() },
            {new LayerTTT(1).ToString(), new() },
            {new LayerTTT(2).ToString(), new() },
            {new LayerTTT(3).ToString(), new() },
            {new LayerTTT(4).ToString(), new() },
            {new LayerTTT(5).ToString(), new() },
        };

        queue = new() { 
            {new LayerTTT(0).ToString(), new() },
            {new LayerTTT(1).ToString(), new() },
            {new LayerTTT(2).ToString(), new() },
            {new LayerTTT(3).ToString(), new() },
            {new LayerTTT(4).ToString(), new() },
            {new LayerTTT(5).ToString(), new() },
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
    // public TileP3D _generate_P3D(Vector3Int map_pos, string tile_ID, string tile_subID, string layer){
    //     // queue[layer][map_pos] = new string[]{tile_ID, tile_subID};
    //     // Vector2 world_pos = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, new LayerTTT());
    //     // TileP3D P3D = new TileP3D(world_pos, _TMapBD_containers["TileP3D"], tile_ID, tile_subID);
    //     TileP3D P3D = new TileP3D(map_pos, tile_ID, tile_subID, layer);
    //     _P3Ds[layer].Add(map_pos, P3D);
    //     return P3D;
    // }

    public void _update_P3D(Vector3Int map_pos, LayerTTT layer){
        if (_P3Ds[layer.ToString()].ContainsKey(map_pos)){
                _P3Ds[layer.ToString()][map_pos]._update_sprite2().Forget();
        }
        else {
            TileP3D P3D = new TileP3D(map_pos, layer);
            _P3Ds[layer.ToString()].Add(map_pos, P3D);
        }
    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        Vector3Int block_offsets = _TMapSys._TMapAxis._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, new LayerTTT());
        TilemapBlock block = _TMapSys._TMapMon._get_block(block_offsets, new LayerTTT());
        block.status._update_status_typeMap("TileP3D");
        Tilemap TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, new LayerTTT()).TMap;
        foreach (var pos in block.status.positions["TileP3D"]){
            // Vector2 world_pos = _TMapSys._TMapAxis._mapping_inBlockPos_to_worldPos(pos, block_offsets, new LayerTTT());
            Vector3Int map_pos = _TMapSys._TMapAxis._mapping_inBlockPos_to_mapPos(pos, block_offsets);
            // string tile_subID = TMap.GetSprite(map_pos).name;
            // new TileP3D(world_pos, _TMapBD_containers["TileP3D"], block.map._get(pos), tile_subID);
            new TileP3D(map_pos, new LayerTTT());
        }
        return true;
    }

    
}
