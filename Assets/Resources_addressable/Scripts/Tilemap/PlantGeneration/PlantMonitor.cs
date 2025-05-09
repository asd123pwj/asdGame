using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class PlantMonitor: BaseClass{
    // ---------- Plant Container ----------
    public Dictionary<string, Transform> _TMapBD_containers;

    public PlantMonitor(){
    }

    public override void _init(){
        _TMapBD_containers = new();
        _TMapBD_containers.Add("BlockDecoration", new GameObject("BlockDecoration").transform);

        foreach(var obj in _TMapBD_containers.Values){
            obj.transform.SetParent(_sys._grid.transform);
        }

        // _sys._InputSys._register_action("Number 1", tmp_draw, "isFirstDown");
    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        // new PlantBase(keyPos.mouse_pos_world, _TMapBD_containers["BlockDecoration"]);
        Vector3Int block_offsets = TilemapAxis._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, _CtrlSys._get_current_layer());
        // TilemapBlock block = _TMapSys._TMapMon._get_block(block_offsets, new LayerType());
        TilemapBlock block = TilemapBlock._get_force(block_offsets, _CtrlSys._get_current_layer());

        block.status._update_status_typeMap("Ground");
        foreach (var pos in block.status.positions["Ground"]){
            Vector2 world_pos = TilemapAxis._mapping_inBlockPos_to_worldPos(pos, block_offsets, _CtrlSys._get_current_layer());
            new PlantBase(world_pos, _TMapBD_containers["BlockDecoration"]);
        }
        return true;
    }

    
}
