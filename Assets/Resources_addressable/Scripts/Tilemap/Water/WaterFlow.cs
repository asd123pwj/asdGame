// Ref: https://www.jgallant.com/2d-liquid-simulator-with-cellular-automaton-in-unity/
using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;

// public class WaterAmountDiff{
//     public bool isExist;
//     public int decrease;
//     public int increase;
//     public int total => increase - decrease;
// }

public class WaterFlow: BaseClass{
    // public Dictionary<string, Dictionary<Vector3Int, WaterAmountDiff>> _diff = new();

    // public void _flow_batch(){
    //     foreach(var layer in _diff.Keys){
    //         foreach(var pos in _diff[layer].Keys){
    //             // skip same
    //             if (_diff[layer][pos].total == 0) continue;
    //             // new when none
    //             if (!WaterBase._our[layer].ContainsKey(pos)) 
    //                 new WaterBase(pos, new(layer), _sys._TMapSys._TMapMon._transforms["Water"]);
    //             // update water amount
    //             WaterBase._our[layer][pos]._amount += _diff[layer][pos].total;
    //             // update water sprite
    //             WaterBase._our[layer][pos]._update_mesh().Forget();
    //         }
    //     }
    //     _diff.Clear();
    // }

    public void _flow_stage2(WaterBase water){
        if (water._diff == 0) return;
        water._amount = water._amount_after;
        water._decrease = 0;
        water._increase = 0;
        water._update_mesh().Forget();
    }

    public void _flow_single(WaterBase water){
        // Debug.Log("flow");
        bool flowed_down = false;
        if (!check_allow_flow(water)) return;
        if (check_flow_down(water)){    
            flow_down(water);       // Action 1: Flow down 
            flowed_down = true;
        }
        
        if (flowed_down) return;    // Action 2: Down means over

        if (!check_allow_flow(water)) return;
        bool flowed_left = false, flowed_right = false;
        if (check_flow_right(water)){
            flow_right(water);      // Action 3: Flow right, in case of: L4 R2 => L3 R3
            flowed_right = true;
        }
        else if (check_flow_right_step2(water)){
            flow_right(water);      // Action 4: Flow right, in case of: L4 M3 R2 => L3 M4 R2
            flowed_right = true;
        }
        // else if (get_next_amount_up(water) > 0)

        if (!check_allow_flow(water)) return;
        if (check_flow_left(water)){
            flow_left(water);       // Action 5: Flow left, in case of: L2 R4 => L3 R3
            flowed_left = true;
        }
        else if (check_flow_left_step2(water)){
            flow_left(water);       // Action 6: Flow left, in case of: L2 M3 R4 => L2 M4 R3
            flowed_left = true;
        }

        // if (flowed_left && flowed_right) return;
        // if (!check_allow_flow(water)) return;
        // int cur_next_amount = water._amount - get_diff(water).decrease;
        // int left_next_amount = get_next_amount(water._layer.ToString(), water._map_pos + Vector3Int.left);
        // int right_next_amount = get_next_amount(water._layer.ToString(), water._map_pos + Vector3Int.right);
        // if (left_next_amount > cur_next_amount && cur_next_amount > right_next_amount){
        //     flow_right(water);
        // }
        // else if (right_next_amount > cur_next_amount && cur_next_amount > left_next_amount){
        //     flow_left(water);
        // }
        
        // if (!check_allow_flow(water)) return;
        // if (check_flow_up(water)){
        //     flow_up(water);
        // }
    }

    bool check_allow_flow(WaterBase water){
        // if (_diff.ContainsKey(water._layer.ToString()) && _diff[water._layer.ToString()].ContainsKey(water._map_pos)) {
        //     if (water._amount - _diff[water._layer.ToString()][water._map_pos].decrease == 0) return false;
        // }
        // else{
        //     if (water._amount == 0) return false;
        // }
        if (water._amount_after == 0) return false;
        return true;
    }

    // WaterAmountDiff get_diff(WaterBase water) => get_diff(water._layer.ToString(), water._map_pos);
    // WaterAmountDiff get_diff(string layer, Vector3Int pos){
    //     if (_diff.ContainsKey(layer) && _diff[layer].ContainsKey(pos)) return _diff[layer][pos];
    //     return new();
    // }

    // int get_next_amount_up(WaterBase water) => get_next_amount(water._layer.ToString(), water._map_pos + Vector3Int.up);
    // int get_next_amount(string layer, Vector3Int pos){
    //     int next_amount = 0;
    //     if (WaterBase._our.ContainsKey(layer) && WaterBase._our[layer].ContainsKey(pos)){
    //         next_amount = WaterBase._our[layer][pos]._amount;
    //     }
    //     int next_diff = get_diff(layer, pos).total; // 0 if not exist
    //     return next_amount + next_diff;
    // }

    void flow_down(WaterBase water) => flow_amount(water, Vector3Int.down);
    void flow_right(WaterBase water) => flow_amount(water, Vector3Int.right);
    void flow_left(WaterBase water) => flow_amount(water, Vector3Int.left);
    // void flow_up(WaterBase water) => flow_amount(water, Vector3Int.up);
    void flow_amount(WaterBase water, Vector3Int dir){
        Vector3Int current_pos = water._map_pos;
        Vector3Int next_pos = current_pos + dir;
        
        // if (!_diff.ContainsKey(water._layer.ToString())) _diff.Add(water._layer.ToString(), new());
        // if (!get_diff(water).isExist) _diff[water._layer.ToString()].Add(current_pos, new() { isExist = true });
        // if (!get_diff(water._layer.ToString(), next_pos).isExist) _diff[water._layer.ToString()].Add(next_pos, new() { isExist = true });
        // // Step 1: Event: Current water amount decrease, _diff -
        // get_diff(water).decrease += 1;
        water._decrease += 1;
        // Step 2: Event: Next water amount increase, _diff +
        if (!WaterBase._our[water._layer.ToString()].ContainsKey(next_pos)) new WaterBase(next_pos, water._layer, _sys._TMapSys._TMapMon._transforms["Water"]);
        WaterBase._our[water._layer.ToString()][next_pos]._increase += 1;
        // get_diff(water._layer.ToString(), next_pos).increase += 1;
    }

    bool check_flow_down(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.down, true);
    bool check_flow_right(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.right);
    bool check_flow_right_step2(WaterBase water) => check_flow(water, water._map_pos + 2 * Vector3Int.right);
    bool check_flow_left(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.left);
    bool check_flow_left_step2(WaterBase water) => check_flow(water, water._map_pos + 2 * Vector3Int.left);
    // bool check_flow_up(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.up);
    bool check_flow(WaterBase water, Vector3Int next_pos, bool isDown=false){
        if (TilemapTile._check_tile(water._layer, next_pos)) return false;  // have tile, can't fill. But I think it also can fill, cause some tile only part
        if (WaterBase._our.ContainsKey(water._layer.ToString()) && WaterBase._our[water._layer.ToString()].ContainsKey(next_pos)){
            WaterBase water_next = WaterBase._our[water._layer.ToString()][next_pos];
            // int next_amount = WaterBase._our[water._layer.ToString()][next_pos]._amount;
            // int next_amount = get_next_amount(water._layer.ToString(), next_pos);
            int next_after = water_next._amount_after;
            int cur_remain = water._amount_remain;
            // int cur_amount = water._amount;
            // int cur_decrease = get_diff(water).decrease; // 0 if not exist
            if (isDown)  {
                if (next_after >= _sys._GCfg._sysCfg.water_full_amount) return false;  // Sample1: Left4 Right2 => L3 R3, S2: L4 R3 => L4 R3, S3: L3 R4 => L3 R4
            }
            if (!isDown) {
                if (next_after + 1 >= cur_remain) return false;  // why +1? Sample1: Left4 Right2 => L3 R3, S2: L4 R3 => L4 R3, S3: L3 R4 => L3 R4
            }
        }
        return true;
    }

    // bool check_flow_amount1(WaterBase water, Vector3Int dir){
        
    // }
}
