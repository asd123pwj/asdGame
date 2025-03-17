// Ref: https://www.jgallant.com/2d-liquid-simulator-with-cellular-automaton-in-unity/
using System.Collections.Generic;
using System.Linq;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;

public class WaterFlow: BaseClass{
    public void _flow_stage3(){
        List<string> layers = WaterBase._our.Keys.ToList();
        for (int i = 0; i < layers.Count; i++){
            List<Vector3Int> waters = WaterBase._our[layers[i]].Keys.ToList();
            for (int j = 0; j < waters.Count; j++){
                WaterBase water = WaterBase._our[layers[i]][waters[j]];
                if (water._diff == 0) continue;
                water._amount = water._amount_after;
                water._decrease = 0;
                water._increase = 0;
                water._update_mesh().Forget();
            }
        }
    }

    public void _flow_stage2(){
        
    }

    public void _flow_stage1(){
        List<string> layers = WaterBase._our.Keys.ToList();
        for (int i = 0; i < layers.Count; i++){
            List<Vector3Int> waters = WaterBase._our[layers[i]].Keys.ToList();
            for (int j = 0; j < waters.Count; j++){
                WaterBase water = WaterBase._our[layers[i]][waters[j]];
                
                bool flowed_down = false;
                if (!check_allow_flow(water)) continue;
                if (check_flow_down(water)){    
                    flow_down(water);       // Action 1: Flow down 
                    flowed_down = true;
                }
                if (flowed_down) continue;    // Action 2: Down means over

                if (!check_allow_flow(water)) continue;
                if (check_flow_right(water)){
                    flow_right(water);      // Action 3: Flow right, in case of: L4 R2 => L3 R3
                }
                if (!check_allow_flow(water)) continue;
                if (check_flow_left(water)){
                    flow_left(water);       // Action 4: Flow left, in case of: L2 R4 => L3 R3
                }
            }
        }
    }

    bool check_allow_flow(WaterBase water) => !(water._amount_after == 0);

    void flow_down(WaterBase water) => flow_amount(water, Vector3Int.down);
    void flow_right(WaterBase water) => flow_amount(water, Vector3Int.right);
    void flow_left(WaterBase water) => flow_amount(water, Vector3Int.left);
    void flow_amount(WaterBase water, Vector3Int dir){
        Vector3Int current_pos = water._map_pos;
        Vector3Int next_pos = current_pos + dir;
        // Step 1: Event: Current water amount decrease, _diff -
        water._decrease += 1;
        // Step 2: Event: Next water amount increase, _diff +
        if (!WaterBase._our[water._layer.ToString()].ContainsKey(next_pos)) new WaterBase(next_pos, water._layer, _sys._TMapSys._TMapMon._transforms["Water"]);
        WaterBase._our[water._layer.ToString()][next_pos]._increase += 1;
    }

    bool check_flow_down(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.down, true);
    bool check_flow_right(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.right);
    bool check_flow_left(WaterBase water) => check_flow(water, water._map_pos + Vector3Int.left);
    bool check_flow(WaterBase water, Vector3Int next_pos, bool isDown=false){
        if (TilemapTile._check_tile(water._layer, next_pos)) return false;  // have tile, can't fill. But I think it also can fill, cause some tile only part
        if (WaterBase._our[water._layer.ToString()].ContainsKey(next_pos)){
            WaterBase water_next = WaterBase._our[water._layer.ToString()][next_pos];
            int next_after = water_next._amount_after;
            int cur_remain = water._amount_remain;
            if (isDown)  {
                if (next_after >= _sys._GCfg._sysCfg.water_full_amount) return false;  // Sample1: Left4 Right2 => L3 R3, S2: L4 R3 => L4 R3, S3: L3 R4 => L3 R4
            }
            if (!isDown) {
                if (next_after + 1 >= cur_remain) return false;  // why >, not >= ? Sample1: Left4 Right2 => L3 R3, S2: L4 R3 => L4 R3, S3: L3 R4 => L3 R4
            }
        }
        return true;
    }

}
