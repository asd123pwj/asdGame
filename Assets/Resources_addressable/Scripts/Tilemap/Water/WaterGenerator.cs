using UnityEngine;
using Cysharp.Threading.Tasks;
using System.Collections.Generic;

public class WaterGenerator: BaseClass{
    public Dictionary<string, Transform> _water_containers;
    public static WaterFlow _flow = new();
    public override float _update_interval { get; set; } = 0.5f;


    public override void _init(){
        _water_containers = new();
        _water_containers.Add("Water", new GameObject("Water").transform);

        foreach(var obj in _water_containers.Values){
            obj.transform.SetParent(_sys._grid.transform);
        }

        _sys._InputSys._register_action("Number 2", tmp_draw, "isFirstDown");
    }

    public override void _update(){
        foreach(var waters in WaterBase._our.Values){
            foreach(var water in waters.Values){
                _flow._flow_single(water);
            }
        }
        _flow._flow_batch();
    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        LayerType layer = new(0, MapLayerType.Middle);
        Vector3Int block_offsets = _TMapSys._TMapAxis._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, layer);
        TilemapBlock block = _TMapSys._TMapMon._get_block(block_offsets, layer);
        
        Vector3Int map_pos = _TMapSys._TMapAxis._mapping_worldPos_to_mapPos(keyPos.mouse_pos_world, layer);
        WaterBase water = new WaterBase(map_pos, block.layer, _sys._TMapSys._TMapMon._transforms["Water"]);
        water._full();
        return true;
    }
}
