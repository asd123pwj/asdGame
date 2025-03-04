using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class WaterFlow: BaseClass{
    public void _flow(WaterBase water){
        // Debug.Log("flow");
        if (_check_empty_down(water)){
            _flow_down(water);
        }
    }

    public void _flow_down(WaterBase water){
        water._map_pos += new Vector3Int(0, -1, 0);
        water._self.transform.position += new Vector3(0, -1, 0);
    }

    public bool _check_empty_down(WaterBase water){
        Vector3Int pos = water._map_pos;
        Vector3Int down_pos = pos + new Vector3Int(0, -1, 0);
        return _check_empty(water._layer, down_pos);
    }

    public bool _check_empty(LayerType layer, Vector3Int map_pos){
        return !TilemapTile._check_tile(layer, map_pos);
    }
}
