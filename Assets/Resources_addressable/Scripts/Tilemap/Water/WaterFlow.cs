using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class WaterFlow: BaseClass{
    public Dictionary<string, Dictionary<Vector3Int, int>> _diff = new();

    public void _flow_batch(){
        foreach(var layer in _diff.Keys){
            foreach(var pos in _diff[layer].Keys){
                // skip same
                if (_diff[layer][pos] == 0) continue;
                // new when none
                if (!WaterBase._our[layer].ContainsKey(pos)) 
                    new WaterBase(pos, new(layer), _sys._TMapSys._TMapMon._transforms["Water"]);
                // update water amount
                WaterBase._our[layer][pos]._amount += _diff[layer][pos];
                // update water sprite
                WaterBase._our[layer][pos]._update_sprite().Forget();
            }
        }
        _diff.Clear();
    }

    public void _flow_single(WaterBase water){
        // Debug.Log("flow");
        if (!check_allow_flow(water)) return;
        if (check_empty_down(water)){
            flow_down(water);
        }
    }

    bool check_allow_flow(WaterBase water){
        if (water._amount == 0) return false;
        return true;
    }

    void flow_down(WaterBase water){
        Vector3Int current_pos = water._map_pos;
        Vector3Int next_pos = current_pos + new Vector3Int(0, -1, 0);
        if (!_diff.ContainsKey(water._layer.ToString())) _diff.Add(water._layer.ToString(), new());
        if (!_diff[water._layer.ToString()].ContainsKey(current_pos)) _diff[water._layer.ToString()].Add(current_pos, 0);
        if (!_diff[water._layer.ToString()].ContainsKey(next_pos)) _diff[water._layer.ToString()].Add(next_pos, 0);
        // Step 1: Event: Current water amount decrease, _diff -
        _diff[water._layer.ToString()][current_pos] -= 1;
        // Step 2: Event: Next water amount increase, _diff +
        _diff[water._layer.ToString()][next_pos] += 1;
    }

    bool check_empty_down(WaterBase water){
        Vector3Int pos = water._map_pos;
        Vector3Int down_pos = pos + new Vector3Int(0, -1, 0);
        if (check_empty(water._layer, down_pos)) return true;
        return false;
    }

    bool check_empty(LayerType layer, Vector3Int map_pos){
        return !TilemapTile._check_tile(layer, map_pos);
    }
}
