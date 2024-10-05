using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TileP3DMonitor: BaseClass{
    // ---------- Plant Container ----------
    public Dictionary<string, Transform> _TMapBD_containers;

    public TileP3DMonitor(){
    }

    public override void _init(){
        _TMapBD_containers = new();
        _TMapBD_containers.Add("TileP3D", new GameObject("TileP3D").transform);

        foreach(var obj in _TMapBD_containers.Values){
            obj.transform.SetParent(_sys._grid.transform);
        }

        _sys._InputSys._register_action("Number 4", tmp_draw, "isFirstDown");
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
            new TileP3D(world_pos, _TMapBD_containers["TileP3D"], block.map._get(pos), tile_subID);
        }
        return true;
    }

    
}
